import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/utils/image_utils.dart';
import '../providers/credit_provider.dart';
import '../services/ai_service.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/upgrade_dialog.dart';
import 'result_screen.dart';

class ImageGenerationScreen extends StatefulWidget {
  const ImageGenerationScreen({Key? key}) : super(key: key);

  @override
  State<ImageGenerationScreen> createState() => _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends State<ImageGenerationScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _referenceUrlController = TextEditingController();
  bool isProcessing = false;
  bool useReferenceImage = false;
  File? referenceImageFile;
  String? referenceImageUrl;

  // Default settings
  int _width = 1024;
  int _height = 768;
  int _steps = 28;

  final List<Map<String, dynamic>> _resolutionOptions = [
    {'label': '1024 × 768', 'width': 1024, 'height': 768},
    {'label': '768 × 1024', 'width': 768, 'height': 1024},
    {'label': '512 × 512', 'width': 512, 'height': 512},
    {'label': '1024 × 1024', 'width': 1024, 'height': 1024},
  ];

  int _selectedResolutionIndex = 0;

  @override
  void dispose() {
    _promptController.dispose();
    _referenceUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Image Generation')),
      body: LoadingOverlay(
        isLoading: isProcessing,
        message: 'Generating your image...',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prompt input
                const Text(
                  'Enter your prompt:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _promptController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe the image you want to generate...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 24),

                // Resolution selector
                const Text(
                  'Select Resolution:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _resolutionOptions.length,
                    itemBuilder: (context, index) {
                      final option = _resolutionOptions[index];
                      final isSelected = _selectedResolutionIndex == index;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(option['label']),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedResolutionIndex = index;
                                _width = option['width'];
                                _height = option['height'];
                              });
                            }
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: Colors.blue,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Steps slider
                Row(
                  children: [
                    const Text(
                      'Quality Steps:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _steps.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _steps.toDouble(),
                  min: 20,
                  max: 50,
                  divisions: 6,
                  label: _steps.toString(),
                  onChanged: (value) {
                    setState(() {
                      _steps = value.toInt();
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Reference image option
                SwitchListTile(
                  title: const Text(
                    'Use Reference Image',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Generate based on a reference image'),
                  value: useReferenceImage,
                  onChanged: (value) {
                    setState(() {
                      useReferenceImage = value;
                    });
                  },
                  activeColor: Colors.blue,
                ),

                if (useReferenceImage) _buildReferenceImageSection(),

                const SizedBox(height: 32),

                // Generate button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _generateImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Generate Image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Reference Image:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickReferenceImage,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    referenceImageFile = null;
                  });
                  _showUrlInputDialog();
                },
                icon: const Icon(Icons.link),
                label: const Text('Image URL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Preview of reference image
        if (referenceImageFile != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              referenceImageFile!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else if (referenceImageUrl != null && referenceImageUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              referenceImageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          )
        else
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 50, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No reference image selected',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickReferenceImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);

        if (ImageUtils.isValidImage(file.path)) {
          setState(() {
            referenceImageFile = file;
            referenceImageUrl = null;
          });
        } else {
          Fluttertoast.showToast(
            msg: AppConstants.invalidImageErrorMessage,
            toastLength: Toast.LENGTH_SHORT,
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: ${e.toString()}');
      Fluttertoast.showToast(
        msg: 'Failed to pick image',
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Future<void> _showUrlInputDialog() {
    _referenceUrlController.text = referenceImageUrl ?? '';

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter Image URL'),
            content: TextField(
              controller: _referenceUrlController,
              decoration: const InputDecoration(
                hintText: 'https://example.com/image.jpg',
              ),
              keyboardType: TextInputType.url,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    referenceImageUrl = _referenceUrlController.text.trim();
                  });
                  Navigator.pop(context);
                  _validateImageUrl();
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _validateImageUrl() async {
    if (referenceImageUrl == null || referenceImageUrl!.isEmpty) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final response = await http.head(Uri.parse(referenceImageUrl!));

      if (response.statusCode != 200 ||
          !response.headers['content-type']!.contains('image')) {
        setState(() {
          referenceImageUrl = null;
        });

        Fluttertoast.showToast(
          msg: 'Invalid image URL',
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    } catch (e) {
      setState(() {
        referenceImageUrl = null;
      });

      Fluttertoast.showToast(
        msg: 'Invalid image URL',
        toastLength: Toast.LENGTH_SHORT,
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _generateImage() async {
    final prompt = _promptController.text.trim();

    if (prompt.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter a prompt',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    final creditState = context.read<CreditBloc>().state;

    // Check if user has available credits
    if (creditState is CreditExhausted) {
      _showUpgradeDialog();
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      // Use credits
      context.read<CreditBloc>().add(UseCreditsEvent());

      // Prepare reference image if needed
      String? imageUrlForReference;
      if (useReferenceImage) {
        if (referenceImageFile != null) {
          // Upload the local image to get a URL
          final aiService = AIService();
          imageUrlForReference = await aiService.uploadImageForReference(
            referenceImageFile!,
          );
        } else if (referenceImageUrl != null && referenceImageUrl!.isNotEmpty) {
          imageUrlForReference = referenceImageUrl;
        }
      }

      // Generate image
      final aiService = AIService();
      final generatedImageUrl = await aiService.generateImage(
        prompt: prompt,
        referenceImageUrl: imageUrlForReference,
        width: _width,
        height: _height,
        steps: _steps,
      );

      if (generatedImageUrl != null && mounted) {
        // Create a temporary file for the "original" image
        final tempDir = await getTemporaryDirectory();
        final promptFileName =
            'prompt_${DateTime.now().millisecondsSinceEpoch}.txt';
        final promptFilePath = path.join(tempDir.path, promptFileName);

        final promptFile = File(promptFilePath);
        await promptFile.writeAsString(prompt);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => ResultScreen(
                  originalImageFile: promptFile, // This is just a placeholder
                  enhancedImageUrl: generatedImageUrl,
                  isGeneratedImage: true,
                  generationPrompt: prompt,
                ),
          ),
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to generate image',
          toastLength: Toast.LENGTH_SHORT,
        );
        setState(() {
          isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('Error generating image: ${e.toString()}');
      Fluttertoast.showToast(
        msg: 'Error generating image',
        toastLength: Toast.LENGTH_SHORT,
      );
      setState(() {
        isProcessing = false;
      });
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder:
          (context) => UpgradeDialog(
            onUpgrade: () {
              // In a real app, this would navigate to payment/subscription screen
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: 'Upgrade feature will be available in future updates',
                toastLength: Toast.LENGTH_LONG,
              );
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
    );
  }
}
