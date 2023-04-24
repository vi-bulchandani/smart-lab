import 'dart:io';
import 'dart:async';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class FaceDetectionService {

  final File image;
  late List<Face> faces;
  late img.Image processedImage; // Contains cropped image of most prominent face

  FaceDetectionService({required this.image});

  Future<void> detectFace() async {
    final FaceDetector _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.accurate
        )
    );
    faces = await _faceDetector.processImage(InputImage.fromFile(this.image));
  }

  Future<void> cropFace() async{
    double x = this.faces[0].boundingBox.left - 10.0;
    double y = this.faces[0].boundingBox.top - 10.0;
    double width = this.faces[0].boundingBox.width + 10.0;
    double height = this.faces[0].boundingBox.height + 10.0;
    img.Image? temp = await img.decodeImageFile(this.image.path);
    this.processedImage = img.copyCrop(temp!, x: x.round(), y: y.round(), width: width.round(), height: height.round());
  }

}