import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ImageCard extends StatelessWidget {
  final String? imagePath;
  final String? imageUrl;
  final String title;
  final double height;
  final double width;
  final BoxFit fit;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const ImageCard({
    Key? key,
    this.imagePath,
    this.imageUrl,
    required this.title,
    this.height = 200,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.onTap,
    this.borderRadius,
  }) : assert(
         imagePath != null || imageUrl != null,
         'Either imagePath or imageUrl must be provided',
       ),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(borderRadius?.topLeft.y ?? 16),
              ),
              child: SizedBox(
                height: height,
                width: width,
                child: _buildImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imagePath != null) {
      return Image.file(
        File(imagePath!),
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.broken_image, size: 50));
        },
      );
    } else if (imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: fit,
        placeholder:
            (context, url) =>
                const Center(child: SpinKitPulse(color: Colors.blue, size: 30)),
        errorWidget: (context, url, error) {
          return const Center(child: Icon(Icons.broken_image, size: 50));
        },
      );
    }

    // This should never happen due to the assert in the constructor
    return const SizedBox();
  }
}
