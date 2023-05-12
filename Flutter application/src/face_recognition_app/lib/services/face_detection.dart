// Importing project packages
import 'package:face_recognition_app/utilities/alert.dart';

// Importing other Dart and Flutter packages
import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

// Service for detecting] human faces present in an image
class FaceDetectionService {

  // Image and Face Data
  final File image;
  final BuildContext context;
  late List<Face> faces;
  late img.Image processedImage; // Contains cropped image of most prominent face

  FaceDetectionService({required this.image, required this.context});

  // Detects faces present in an image file using Google ML Kit
  // If the above task fails, error is displayed using the showAlert() utility
  Future<void> detectFace() async {
    final FaceDetector _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.accurate
        )
    );
    faces = await _faceDetector.processImage(InputImage.fromFile(this.image)).catchError((err) {
      showAlert(context, err.toString());
    });
  }

  // Based on coordinates of the detected face, the image is cropped to only contain the most prominent face only
  Future<void> cropFace() async{
    double x = this.faces[0].boundingBox.left - 10.0;
    double y = this.faces[0].boundingBox.top - 10.0;
    double width = this.faces[0].boundingBox.width + 10.0;
    double height = this.faces[0].boundingBox.height + 10.0;
    img.Image? temp = await img.decodeImageFile(this.image.path);
    this.processedImage = img.copyCrop(temp!, x: x.round(), y: y.round(), width: width.round(), height: height.round());
  }

}