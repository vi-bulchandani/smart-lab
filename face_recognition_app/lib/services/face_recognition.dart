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
      this.interpreter = await Interpreter.fromAsset(
        'mobilefacenet.tflite',
        // options: interpreterOptions
      );
    }
    catch (err) {
      showAlert(this.context, 'Unable to load model\n' + err.toString());
    }
  }

  void processImage() {
    img.Image resizedImage = img.copyResizeCropSquare(faceDetectionService.processedImage, size: 112);
    imageVector = imageToByteListFloat32(resizedImage);
  }

  Float32List imageToByteListFloat32(img.Image image){
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for(int i=0; i<112; i++){
      for(int j=0; j<112; j++){
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
    input = input.reshape([1, 112, 112, 3]);
    
    List output = List.generate(1, (index) => List.filled(192, 0));
    this.interpreter?.run(input, output);

    output = output.reshape([192]);
    this.faceVector = List.from(output);
  }

}