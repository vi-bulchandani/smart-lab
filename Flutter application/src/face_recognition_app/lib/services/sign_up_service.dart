import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';

import 'face_detection.dart';
import 'face_recognition.dart';

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