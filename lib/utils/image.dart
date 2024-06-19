import 'dart:async';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

abstract class Assets {
  static AssetImage image(BuildContext context, String imagePath,
      {bool isDarkModeAware = false}) {
    return Theme.of(context).brightness == Brightness.light || !isDarkModeAware
        ? AssetImage('$_imagesFolder/$imagePath')
        : AssetImage(
            '$_imagesFolder/${basenameWithoutExtension(imagePath)}-dark${extension(imagePath)}');
  }

  static const _imagesFolder = 'assets/images';
}

Future<Uint8List?> getImageFromUser(BuildContext context) async {
  ImageSource? sourceType = await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("选择照片来源"),
        actions: <Widget>[
          ElevatedButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text("图库"),
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text("相机"),
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceBetween,
      );
    },
  );
  if (sourceType == null) return null;

  final ImagePicker imagePicker = ImagePicker();
  XFile? image = await imagePicker.pickImage(
    source: sourceType,
    imageQuality: 100,
  );
  return image?.readAsBytes();
}
