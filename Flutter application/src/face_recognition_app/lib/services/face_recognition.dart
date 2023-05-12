// Importing project packages
import 'package:face_recognition_app/utilities/alert.dart';

// Importing other Dart and Flutter packages
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'face_detection.dart';

// Service for recognizing face from a cropped face detected image using TFlite models
class FaceRecognitionService {

  final FaceDetectionService faceDetectionService;
  final BuildContext context;
  Interpreter? interpreter; // Internal process which runs the TFlite model on input to produce output
  late int inputSize;
  late int outputSize;
  late List imageVector;
  late List faceVector;

  FaceRecognitionService({required this.faceDetectionService, required this.context});

  // One of the models is loaded appropriately to the Interpreter process, and model I/O configurations are printed
  // The TFlite models are stored as project assets using 'pubspec.yaml'
  // In case the model fails to load, error is displayed using the showAlert() utility
  Future<void> initialize() async {
    late Delegate delegate;
    try {

      // // For using mobilefacenet.tflite
      // this.interpreter = await Interpreter.fromAsset(
      //   'mobilefacenet.tflite',
      // );
      // this.inputSize = 112;
      // this.outputSize = 192;

      // For using facenet_512.tflite (Recommended)
      this.interpreter = await Interpreter.fromAsset(
        'facenet_512.tflite',
      );
      this.inputSize = 160;
      this.outputSize = 512;

      // // For using facenet.tflite
      // this.interpreter = await Interpreter.fromAsset(
      //   'facenet.tflite',
      // );
      // this.inputSize = 160;
      // this.outputSize = 128;

      print('---MODEL DETAILS---');
      print(this.interpreter?.getInputTensors());
      print(this.interpreter?.getOutputTensors());
    }
    catch (err) {
      showAlert(this.context, 'Unable to load model\n' + err.toString());
    }
  }

  // The cropped face detected image is processed to an accepted model input format
  void processImage() {
    img.Image resizedImage = img.copyResizeCropSquare(faceDetectionService.processedImage, size: this.inputSize);
    imageVector = imageToByteListFloat32(resizedImage);
  }

  // A vector of floating RBG pixel values are obtained from the cropped face detected image
  // The size of the vector is as per input configuration of the chosen model
  Float32List imageToByteListFloat32(img.Image image){
    var convertedBytes = Float32List(1 * this.inputSize * this.inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for(int i=0; i<this.inputSize; i++){
      for(int j=0; j<this.inputSize; j++){
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - 128) / 128;
        buffer[pixelIndex++] = (pixel.g - 128) / 128;
        buffer[pixelIndex++] = (pixel.b - 128) / 128;
      }
    }

    return convertedBytes.buffer.asFloat32List();
  }

  // The interpreter takes the RBG pixel vector as input. Runs the model. Produces the face vector as output
  void predictFace() {
    List input = this.imageVector;
    input = input.reshape([1, this.inputSize, this.inputSize, 3]);
    
    List output = List.generate(1, (index) => List.filled(this.outputSize, 0));
    this.interpreter?.run(input, output);

    output = output.reshape([this.outputSize]);
    this.faceVector = List.from(output);
  }

}