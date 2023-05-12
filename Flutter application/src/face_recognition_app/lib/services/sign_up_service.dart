// Importing project packages
import 'package:face_recognition_app/services/face_detection.dart';
import 'package:face_recognition_app/services/face_recognition.dart';

// Importing other Dart and Flutter packages
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// Service to run upload face vector of a user
// The following tasks are performed:
// 1. The user image is sent to Face Detection service to detect human faces using Google ML Kit. The image is cropped to contain only the prominent face
// 2. The cropped face detected image is sent to Face Recognition service to generate the face vectors by running a TFlite model
// 3. The obtained face vector is uploaded to Cloud Firestore
// If any of the above tasks are failed, error is displayed using the showAlert() utility
Future<FaceRecognitionService> signUp(List<File> images, BuildContext context) async {
  final FaceDetectionService faceDetectionService = FaceDetectionService(image: images[0], context: context);
  await faceDetectionService.detectFace();
  await faceDetectionService.cropFace();

  final FaceRecognitionService faceRecognitionService = FaceRecognitionService(faceDetectionService: faceDetectionService, context: context);
  await faceRecognitionService.initialize();
  faceRecognitionService.processImage();
  faceRecognitionService.predictFace();

  print('INFO: ' + faceRecognitionService.faceVector.toString());

  return faceRecognitionService;
}