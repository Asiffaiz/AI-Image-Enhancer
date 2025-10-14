import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../core/constants.dart';
import '../providers/credit_provider.dart';
import '../services/ai_service.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/upgrade_dialog.dart';
import 'result_screen.dart';

class PreviewScreen extends StatefulWidget {
  final File imageFile;

  const PreviewScreen({Key? key, required this.imageFile}) : super(key: key);

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool isProcessing = false;
  EnhancementType selectedType = EnhancementType.upscale;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Image')),
      body: LoadingOverlay(
        isLoading: isProcessing,
        message: 'Enhancing your image...',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(widget.imageFile, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Select Enhancement Type:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildEnhancementOptions(),
                const SizedBox(height: 24),
                _buildEnhanceButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancementOptions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildEnhancementOption(
            EnhancementType.upscale,
            'Upscale',
            Icons.auto_awesome,
          ),
          _buildEnhancementOption(
            EnhancementType.generate,
            'Generate',
            Icons.image,
          ),
          _buildEnhancementOption(
            EnhancementType.removeWatermark,
            'Remove Watermark',
            Icons.water_drop_outlined,
          ),
          _buildEnhancementOption(
            EnhancementType.removeBackground,
            'Remove Background',
            Icons.layers,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancementOption(
    EnhancementType type,
    String label,
    IconData icon,
  ) {
    final isSelected = selectedType == type;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedType = type;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhanceButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processImage,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Enhance Image',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _processImage() async {
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

      // Process image
      final aiService = AIService();
      final enhancedImageUrl = await aiService.enhanceImage(
        widget.imageFile,
        selectedType,
      );

      if (enhancedImageUrl != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => ResultScreen(
                  originalImageFile: widget.imageFile,
                  enhancedImageUrl: enhancedImageUrl,
                ),
          ),
        );
      } else {
        Fluttertoast.showToast(
          msg: AppConstants.apiErrorMessage,
          toastLength: Toast.LENGTH_SHORT,
        );
        setState(() {
          isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('Error processing image: ${e.toString()}');
      Fluttertoast.showToast(
        msg: AppConstants.apiErrorMessage,
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
