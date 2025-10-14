import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../core/constants.dart';
import '../core/utils/image_utils.dart';
import '../widgets/loading_overlay.dart';
import 'home_screen.dart';
import 'image_editor_screen.dart';
import 'image_generation_screen.dart';

class ResultScreen extends StatefulWidget {
  final File originalImageFile;
  final String enhancedImageUrl;
  final bool isGeneratedImage;
  final String? generationPrompt;

  const ResultScreen({
    Key? key,
    required this.originalImageFile,
    required this.enhancedImageUrl,
    this.isGeneratedImage = false,
    this.generationPrompt,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  bool isSaved = false;
  late TabController _tabController;
  String? localEnhancedImagePath;
  File? editedOriginalFile;
  File? editedEnhancedFile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isGeneratedImage ? 1 : 2,
      vsync: this,
    );
    _downloadEnhancedImage();

    // Only save to recent images if it's not a generated image
    if (!widget.isGeneratedImage) {
      _saveToRecentImages();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _downloadEnhancedImage() async {
    setState(() {
      isLoading = true;
    });

    try {
      final imagePath = await ImageUtils.downloadAndSaveImage(
        widget.enhancedImageUrl,
      );

      if (imagePath != null) {
        setState(() {
          localEnhancedImagePath = imagePath;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'Failed to download enhanced image',
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error downloading enhanced image: ${e.toString()}');
      Fluttertoast.showToast(
        msg: 'Error downloading enhanced image',
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Future<void> _saveToRecentImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentImages = prefs.getStringList('recent_images') ?? [];

      // Add current image to the beginning of the list
      if (!recentImages.contains(widget.originalImageFile.path)) {
        recentImages.insert(0, widget.originalImageFile.path);

        // Keep only the last 10 images
        if (recentImages.length > 10) {
          recentImages.removeLast();
        }

        await prefs.setStringList('recent_images', recentImages);
      }
    } catch (e) {
      debugPrint('Error saving to recent images: ${e.toString()}');
    }
  }

  Future<void> _saveToGallery() async {
    final imageToSave = _getCurrentEnhancedImage();

    if (imageToSave == null) {
      Fluttertoast.showToast(
        msg: 'Enhanced image not available yet',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final success = await GallerySaver.saveImage(
        imageToSave.path,
        albumName: AppConstants.galleryFolderName,
      );

      setState(() {
        isLoading = false;
        isSaved = success ?? false;
      });

      if (success ?? false) {
        Fluttertoast.showToast(
          msg: 'Image saved to gallery',
          toastLength: Toast.LENGTH_SHORT,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to save image',
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error saving to gallery: ${e.toString()}');
      Fluttertoast.showToast(
        msg: 'Error saving image: ${e.toString()}',
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  File? _getCurrentOriginalImage() {
    return editedOriginalFile ?? widget.originalImageFile;
  }

  File? _getCurrentEnhancedImage() {
    if (editedEnhancedFile != null) {
      return editedEnhancedFile;
    } else if (localEnhancedImagePath != null) {
      return File(localEnhancedImagePath!);
    }
    return null;
  }

  Future<void> _editImage(bool isOriginal) async {
    final imageToEdit =
        isOriginal ? _getCurrentOriginalImage() : _getCurrentEnhancedImage();

    if (imageToEdit == null) {
      Fluttertoast.showToast(
        msg: 'Image not available for editing yet',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ImageEditorScreen(
              imageFile: imageToEdit,
              onImageEdited: (File editedFile) {
                setState(() {
                  if (isOriginal) {
                    editedOriginalFile = editedFile;
                  } else {
                    editedEnhancedFile = editedFile;
                    // Reset saved state since we have a new edited image
                    isSaved = false;
                  }
                });
              },
            ),
      ),
    );
  }

  void _generateNewImage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ImageGenerationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            widget.isGeneratedImage
                ? const Text('Generated Image')
                : const Text('Result'),
        bottom:
            widget.isGeneratedImage
                ? null
                : TabBar(
                  controller: _tabController,
                  tabs: const [Tab(text: 'Before'), Tab(text: 'After')],
                ),
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        message: 'Saving image...',
        child: SafeArea(
          child: Column(
            children: [
              if (widget.isGeneratedImage && widget.generationPrompt != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prompt:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.generationPrompt!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child:
                    widget.isGeneratedImage
                        ? _buildGeneratedImageView()
                        : TabBarView(
                          controller: _tabController,
                          children: [
                            // Before image
                            Stack(
                              children: [
                                Center(
                                  child: Image.file(
                                    _getCurrentOriginalImage()!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  bottom: 16,
                                  right: 16,
                                  child: FloatingActionButton(
                                    mini: true,
                                    onPressed: () => _editImage(true),
                                    backgroundColor: Colors.white,
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // After image
                            Stack(
                              children: [
                                Center(
                                  child:
                                      _getCurrentEnhancedImage() != null
                                          ? Image.file(
                                            _getCurrentEnhancedImage()!,
                                            fit: BoxFit.contain,
                                          )
                                          : CachedNetworkImage(
                                            imageUrl: widget.enhancedImageUrl,
                                            fit: BoxFit.contain,
                                            placeholder:
                                                (context, url) => const Center(
                                                  child: SpinKitPulse(
                                                    color: Colors.blue,
                                                    size: 50,
                                                  ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Center(
                                                      child: Icon(
                                                        Icons.error,
                                                        color: Colors.red,
                                                        size: 50,
                                                      ),
                                                    ),
                                          ),
                                ),
                                if (_getCurrentEnhancedImage() != null)
                                  Positioned(
                                    bottom: 16,
                                    right: 16,
                                    child: FloatingActionButton(
                                      mini: true,
                                      onPressed: () => _editImage(false),
                                      backgroundColor: Colors.white,
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isSaved ? null : _saveToGallery,
                        icon: Icon(
                          isSaved ? Icons.check : Icons.download,
                          color: isSaved ? Colors.green : Colors.white,
                        ),
                        label: Text(
                          isSaved ? 'Saved' : 'Save to Gallery',
                          style: TextStyle(
                            color: isSaved ? Colors.green : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSaved ? Colors.grey.shade200 : Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            widget.isGeneratedImage
                                ? _generateNewImage
                                : () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const HomeScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                        icon: Icon(
                          widget.isGeneratedImage
                              ? Icons.auto_awesome
                              : Icons.refresh,
                          color: Colors.white,
                        ),
                        label: Text(
                          widget.isGeneratedImage
                              ? 'New Generation'
                              : 'New Image',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratedImageView() {
    return Stack(
      children: [
        Center(
          child:
              _getCurrentEnhancedImage() != null
                  ? Image.file(_getCurrentEnhancedImage()!, fit: BoxFit.contain)
                  : CachedNetworkImage(
                    imageUrl: widget.enhancedImageUrl,
                    fit: BoxFit.contain,
                    placeholder:
                        (context, url) => const Center(
                          child: SpinKitPulse(color: Colors.blue, size: 50),
                        ),
                    errorWidget:
                        (context, url, error) => const Center(
                          child: Icon(Icons.error, color: Colors.red, size: 50),
                        ),
                  ),
        ),
        if (_getCurrentEnhancedImage() != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: () => _editImage(false),
              backgroundColor: Colors.white,
              child: const Icon(Icons.edit, color: Colors.blue),
            ),
          ),
      ],
    );
  }
}
