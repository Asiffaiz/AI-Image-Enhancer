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

class ResultScreen extends StatefulWidget {
  final File originalImageFile;
  final String enhancedImageUrl;

  const ResultScreen({
    Key? key,
    required this.originalImageFile,
    required this.enhancedImageUrl,
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _downloadEnhancedImage();
    _saveToRecentImages();
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
    if (localEnhancedImagePath == null) {
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
        localEnhancedImagePath!,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        bottom: TabBar(
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
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Before image
                    Center(
                      child: Image.file(
                        widget.originalImageFile,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // After image
                    Center(
                      child:
                          localEnhancedImagePath != null
                              ? Image.file(
                                File(localEnhancedImagePath!),
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
                                    (context, url, error) => const Center(
                                      child: Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 50,
                                      ),
                                    ),
                              ),
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
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text(
                          'New Image',
                          style: TextStyle(
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
}
