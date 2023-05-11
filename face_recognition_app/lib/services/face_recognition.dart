import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:face_recognition_app/utilities/alert.dart';
import 'package:flutter/cupertino.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'face_detection.dart';

class FaceRecognitionService {

  final FaceDetectionService faceDetectionService;
  final BuildContext context;
  Interpreter? interpreter;
  double threshold = 0.5;
  late int inputSize;
  late int outputSize;
  late List imageVector;
  late List faceVector;

  FaceRecognitionService({required this.faceDetectionService, required this.context});

  Future<void> initialize() async {
    late Delegate delegate;
    try {
      // if(Platform.isAndroid){
      //   delegate = GpuDelegateV2(
      //     options: GpuDelegateOptionsV2(
      //       isPrecisionLossAllowed: false,
      //       inferencePreference: TfLiteGpuInferenceUsage.fastSingleAnswer,
      //       inferencePriority1: TfLiteGpuInferencePriority.minLatency,
      //       inferencePriority2: TfLiteGpuInferencePriority.auto,
      //       inferencePriority3: TfLiteGpuInferencePriority.auto
      //     )
      //   );
      // }
      // else if(Platform.isIOS){
      //   delegate = GpuDelegate(
      //     options: GpuDelegateOptions(
      //       allowPrecisionLoss: true,
      //       waitType: TFLGpuDelegateWaitType.active
      //     )
      //   );
      // }
      //
      // var interpreterOptions = InterpreterOptions()..addDelegate(delegate);

      // // For using mobilefacenet.tflite
      // this.interpreter = await Interpreter.fromAsset(
      //   'mobilefacenet.tflite',
      //   // options: interpreterOptions
      // );
      // this.inputSize = 112;
      // this.outputSize = 192;

      // For using facenet_512.tflite
      this.interpreter = await Interpreter.fromAsset(
        'facenet_512.tflite',
        // options: interpreterOptions
      );
      this.inputSize = 160;
      this.outputSize = 512;

      // // For using facenet.tflite
      // this.interpreter = await Interpreter.fromAsset(
      //   'facenet.tflite',
      //   // options: interpreterOptions
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

  void processImage() {
    // For mobilefacenet.tflite
    img.Image resizedImage = img.copyResizeCropSquare(faceDetectionService.processedImage, size: this.inputSize);
    imageVector = imageToByteListFloat32(resizedImage);
  }

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

  void predictFace() {
    List input = this.imageVector;
    input = input.reshape([1, this.inputSize, this.inputSize, 3]);
    
    List output = List.generate(1, (index) => List.filled(this.outputSize, 0));
    this.interpreter?.run(input, output);

    output = output.reshape([this.outputSize]);
    this.faceVector = List.from(output);
  }

}