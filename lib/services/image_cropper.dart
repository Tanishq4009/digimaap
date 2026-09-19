import 'dart:io';
import 'dart:ui' as ui; // UI masking ke liye alias
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../models/seal_type.dart';

class ImageCropperService {
  ImageCropperService._();

  static Future<File?> cropImage(
    File rawFile,
    SealType sealType,
  ) async {
    try {
      final style = (sealType == SealType.lead)
          ? CropStyle.circle
          : CropStyle.rectangle;

      final ratio = (sealType == SealType.sticker)
          ? const CropAspectRatio(ratioX: 3, ratioY: 1)
          : const CropAspectRatio(ratioX: 1, ratioY: 1);

      // 1. Pehle Manual Cropping UI dikhao
      final CroppedFile? croppedFile = await ImageCropper()
          .cropImage(
            sourcePath: rawFile.path,
            compressQuality: 90,
            aspectRatio: ratio,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Adjust Seal Boundary',
                toolbarColor: Colors.black87,
                toolbarWidgetColor: Colors.white,
                initAspectRatio:
                    CropAspectRatioPreset.original,
                lockAspectRatio: true,
                hideBottomControls: true,
                cropStyle: style,
              ),
              IOSUiSettings(
                title: 'Adjust Seal Boundary',
                cancelButtonTitle: 'Cancel',
                doneButtonTitle: 'Done',
                aspectRatioLockEnabled: true,
                cropStyle: style,
              ),
            ],
          );

      // Agar user ne cancel kar diya
      if (croppedFile == null) return null;

      File finalFile = File(croppedFile.path);

      // 2. 🌟 POST-PROCESSING: Strict Circular Masking for AI 🌟
      // Agar seal gol hai (Lead), toh corners ko pitch black kar do
      if (sealType == SealType.lead) {
        finalFile = await _applyBlackCircularMask(
          finalFile,
        );
      }

      return finalFile;
    } catch (e) {
      debugPrint('Error manually cropping seal image: $e');
      return null;
    }
  }

  /// Ye function purely hardware-accelerated Canvas use karke corners black karta hai
  static Future<File> _applyBlackCircularMask(
    File inputFile,
  ) async {
    // A. Image ko load karo
    final bytes = await inputFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final rect = Rect.fromLTWH(0, 0, width, height);

    // B. Naya Canvas banao
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Step 1: Poore background ko solid BLACK paint kar do
    canvas.drawRect(
      rect,
      ui.Paint()..color = const ui.Color(0xFF000000),
    );

    // Step 2: Ab aage ki drawing sirf ek Circle ke andar limit (clip) kar do
    canvas.clipPath(ui.Path()..addOval(rect));

    // Step 3: Cropped image draw karo (ye sirf circle me draw hogi, baaki black bachega)
    canvas.drawImage(image, ui.Offset.zero, ui.Paint());

    // C. Final image nikal kar PNG format me save karo
    final maskedImage = await recorder
        .endRecording()
        .toImage(image.width, image.height);
    final pngBytes = await maskedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    codec.dispose();
    image.dispose();
    maskedImage.dispose();

    // D. Nayi file return karo
    final outPath =
        '${Directory.systemTemp.path}/masked_seal_${DateTime.now().millisecondsSinceEpoch}.png';
    final outFile = File(outPath);
    await outFile.writeAsBytes(
      pngBytes!.buffer.asUint8List(),
    );

    return outFile;
  }
}
