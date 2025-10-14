import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart';
import '../core/constants.dart';

enum EnhancementType { upscale, generate, removeWatermark, removeBackground }

class AIService {
  final Dio _dio = Dio();

  AIService() {
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 120);
  }

  /// Get the API key from environment variables
  String? _getApiKey(bool useKieAI) {
    try {
      return useKieAI
          ? dotenv.env['KIE_AI_API_KEY']
          : dotenv.env['TOGETHER_AI_API_KEY'];
    } catch (e) {
      debugPrint('Error getting API key: ${e.toString()}');
      return null;
    }
  }

  /// Generate an image using Together AI's API
  Future<String?> generateImage({
    required String prompt,
    String? referenceImageUrl,
    int width = 1024,
    int height = 768,
    int steps = 28,
    String model = "black-forest-labs/FLUX.1-schnell-Free",
  }) async {
    try {
      final apiKey = _getApiKey(false); // Using Together AI API

      if (apiKey == null) {
        debugPrint('Together AI API key not found');
        return _mockEnhancedImage(EnhancementType.generate);
      }

      final Map<String, dynamic> requestBody = {
        "model": model,
        "prompt": prompt,
        "width": width,
        "height": height,
        "steps": steps,
        "n": 1,
        "response_format": "url",
      };

      // Add reference image if provided
      if (referenceImageUrl != null && referenceImageUrl.isNotEmpty) {
        requestBody["image_url"] = referenceImageUrl;
      }

      // Add headers
      final options = Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      // Make API call
      final response = await _dio.post(
        'https://api.together.xyz/v1/images/generations',
        data: requestBody,
        options: options,
      );

      if (response.statusCode == 200) {
        // Parse response based on Together AI's structure
        if (response.data['data'] != null && response.data['data'].isNotEmpty) {
          return response.data['data'][0]['url'];
        }
      }

      debugPrint('API error: ${response.statusCode} - ${response.data}');
      return _mockEnhancedImage(EnhancementType.generate);
    } catch (e) {
      debugPrint('Error generating image: ${e.toString()}');
      // Return mock data for development
      return _mockEnhancedImage(EnhancementType.generate);
    }
  }

  /// Enhance an image using AI
  Future<String?> enhanceImage(
    File imageFile,
    EnhancementType enhancementType, {
    bool useKieAI = true,
  }) async {
    // For image generation, use the dedicated method
    if (enhancementType == EnhancementType.generate) {
      // This will be handled by the generateImage method
      return _mockEnhancedImage(enhancementType);
    }

    try {
      final apiKey = _getApiKey(useKieAI);

      if (apiKey == null) {
        debugPrint('API key not found');
        return _mockEnhancedImage(enhancementType);
      }

      final String endpoint =
          useKieAI
              ? AppConstants.kieAiEndpoint
              : 'https://api.together.ai/v1/image-enhance';

      final String fileName = imageFile.path.split('/').last;
      final String mimeType = _getMimeType(fileName);

      // Create form data
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
        'enhancement_type': enhancementType.toString().split('.').last,
      });

      // Add headers
      final options = Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'multipart/form-data',
        },
      );

      // Make API call
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: options,
      );

      if (response.statusCode == 200) {
        // Parse response based on API structure
        if (response.data['success'] == true) {
          return response.data['enhanced_image_url'];
        }
      }

      debugPrint('API error: ${response.statusCode} - ${response.data}');
      return _mockEnhancedImage(enhancementType);
    } catch (e) {
      debugPrint('Error enhancing image: ${e.toString()}');
      // Return mock data for development
      return _mockEnhancedImage(enhancementType);
    }
  }

  /// Upload an image and return its URL (for reference images)
  Future<String?> uploadImageForReference(File imageFile) async {
    try {
      // For now, we'll return a mock URL
      // In a production app, you would implement a proper image upload service
      // to a storage service like AWS S3, Firebase Storage, etc.
      return 'https://huggingface.co/datasets/patrickvonplaten/random_img/resolve/main/yosemite.png';
    } catch (e) {
      debugPrint('Error uploading image: ${e.toString()}');
      return null;
    }
  }

  /// Get mime type from file name
  String _getMimeType(String fileName) {
    if (fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg')) {
      return 'image/jpeg';
    } else if (fileName.toLowerCase().endsWith('.png')) {
      return 'image/png';
    }
    return 'image/jpeg'; // Default
  }

  /// Mock enhanced image URL for development
  String _mockEnhancedImage(EnhancementType type) {
    switch (type) {
      case EnhancementType.upscale:
        return 'https://images.unsplash.com/photo-1682687982167-d7fb3ed8541d?q=80&w=2071&auto=format&fit=crop';
      case EnhancementType.generate:
        return 'https://images.unsplash.com/photo-1682687982501-1e58ab814714?q=80&w=2070&auto=format&fit=crop';
      case EnhancementType.removeWatermark:
        return 'https://images.unsplash.com/photo-1682687982093-4ca1a2863f92?q=80&w=1974&auto=format&fit=crop';
      case EnhancementType.removeBackground:
        return 'https://images.unsplash.com/photo-1682687220063-3a154dc90a56?q=80&w=2070&auto=format&fit=crop';
    }
  }
}
