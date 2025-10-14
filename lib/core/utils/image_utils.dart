import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import '../constants.dart';

class ImageUtils {
  /// Validates if the file is an image (jpg or png)
  static bool isValidImage(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return extension == '.jpg' || extension == '.jpeg' || extension == '.png';
  }

  /// Saves an image to the gallery
  static Future<bool> saveImageToGallery(String imagePath) async {
    try {
      final result = await GallerySaver.saveImage(
        imagePath,
        albumName: AppConstants.galleryFolderName,
      );

      if (result ?? false) {
        Fluttertoast.showToast(msg: 'Image saved to gallery');
        return true;
      } else {
        Fluttertoast.showToast(msg: 'Failed to save image');
        return false;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error saving image: ${e.toString()}');
      return false;
    }
  }

  /// Downloads an image from URL and saves it locally
  static Future<String?> downloadAndSaveImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = path.join(tempDir.path, fileName);

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading image: ${e.toString()}');
      return null;
    }
  }
}
