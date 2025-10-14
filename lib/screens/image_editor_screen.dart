import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_editor_plus/options.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as path;

class ImageEditorScreen extends StatefulWidget {
  final File imageFile;
  final Function(File) onImageEdited;

  const ImageEditorScreen({
    Key? key,
    required this.imageFile,
    required this.onImageEdited,
  }) : super(key: key);

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Image editor will be opened directly from initState
          if (isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Open the editor immediately when the screen loads
    _openImageEditor();
  }

  Future<void> _openImageEditor() async {
    setState(() {
      isLoading = true;
    });

    try {
      final editedImage = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  ImageEditor(image: widget.imageFile.readAsBytesSync()),
        ),
      );

      if (editedImage != null) {
        // Save the edited image to a temporary file
        final tempDir = await getTemporaryDirectory();
        final fileName =
            'edited_${DateTime.now().millisecondsSinceEpoch}${path.extension(widget.imageFile.path)}';
        final editedFile = File(path.join(tempDir.path, fileName));

        await editedFile.writeAsBytes(editedImage);

        // Return the edited file
        widget.onImageEdited(editedFile);
      } else {
        // User canceled editing, return the original file
        widget.onImageEdited(widget.imageFile);
      }
    } catch (e) {
      debugPrint('Error editing image: $e');
      Fluttertoast.showToast(
        msg: 'Error editing image',
        toastLength: Toast.LENGTH_SHORT,
      );
      // Return the original file on error
      widget.onImageEdited(widget.imageFile);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
