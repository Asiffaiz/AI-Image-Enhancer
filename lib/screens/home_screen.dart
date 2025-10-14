import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../core/constants.dart';
import '../core/utils/image_utils.dart';
import '../providers/credit_provider.dart';
import '../widgets/upgrade_dialog.dart';
import 'preview_screen.dart';
import 'image_generation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> recentImages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentImages();

    // Check credits on app start
    context.read<CreditBloc>().add(CheckCreditsEvent());
  }

  Future<void> _loadRecentImages() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final images = prefs.getStringList('recent_images') ?? [];

      // Filter out images that no longer exist
      final existingImages = <String>[];
      for (final imagePath in images) {
        final file = File(imagePath);
        if (await file.exists()) {
          existingImages.add(imagePath);
        }
      }

      setState(() {
        recentImages = existingImages;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading recent images: ${e.toString()}');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleFeatureSelection(String feature, int index) async {
    final creditState = context.read<CreditBloc>().state;

    // Check if user has available credits
    if (creditState is CreditExhausted) {
      _showUpgradeDialog();
      return;
    }

    // Handle AI Image Generation separately
    if (feature == 'AI Image Generation') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ImageGenerationScreen()),
      );
      return;
    }

    // For other features, pick an image
    await _pickImage();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);

        if (ImageUtils.isValidImage(file.path)) {
          // Navigate to preview screen
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PreviewScreen(imageFile: file),
              ),
            );
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Image Enhancer'), centerTitle: true),
      body: BlocListener<CreditBloc, CreditState>(
        listener: (context, state) {
          if (state is CreditError) {
            Fluttertoast.showToast(
              msg: state.message,
              toastLength: Toast.LENGTH_SHORT,
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and credits info
                _buildHeader(),
                const SizedBox(height: 24),

                // Features grid
                _buildFeaturesGrid(),
                const SizedBox(height: 32),

                // Recent images
                _buildRecentImagesSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enhance your images with AI',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        BlocBuilder<CreditBloc, CreditState>(
          builder: (context, state) {
            if (state is CreditAvailable) {
              return Text(
                'Free credits remaining: ${state.remainingCredits}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              );
            } else if (state is CreditExhausted) {
              return GestureDetector(
                onTap: _showUpgradeDialog,
                child: const Row(
                  children: [
                    Text(
                      'No credits remaining. ',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      'Upgrade to Pro',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: AppConstants.features.length,
      itemBuilder: (context, index) {
        return _buildFeatureCard(AppConstants.features[index], index);
      },
    );
  }

  Widget _buildFeatureCard(String feature, int index) {
    final icons = [
      Icons.auto_awesome,
      Icons.image,
      Icons.water_drop_outlined,
      Icons.layers,
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _handleFeatureSelection(feature, index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icons[index], size: 40, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                feature,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentImagesSection() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (recentImages.isEmpty) {
      return const SizedBox();
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Images',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentImages.length,
              itemBuilder: (context, index) {
                final imagePath = recentImages[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  PreviewScreen(imageFile: File(imagePath)),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(imagePath),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
