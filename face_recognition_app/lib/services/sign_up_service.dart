import 'dart:io';
import 'dart:async';
import 'face_detection.dart';
import 'face_recognition.dart';

Future<FaceRecognitionService> signUp(List<File> images) async {
  final FaceDetectionService faceDetectionService = FaceDetectionService(image: images[0]);
  await faceDetectionService.detectFace();
  await faceDetectionService.cropFace();

  final FaceRecognitionService faceRecognitionService = FaceRecognitionService(faceDetectionService: faceDetectionService);
  await faceRecognitionService.initialize();
  faceRecognitionService.processImage();
  faceRecognitionService.predictFace();

  return faceRecognitionService;
}