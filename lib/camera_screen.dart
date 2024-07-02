import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  String result = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeDetector();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    await _cameraController?.initialize();

    _cameraController?.startImageStream((CameraImage image) {
      if (_isDetecting) return;

      _isDetecting = true;

      _processCameraImage(image);
    });

    setState(() {});
  }

  void _initializeDetector() {
    _faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.accurate,
    ));
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final InputImageRotation imageRotation =
        InputImageRotationValue.fromRawValue(
                _cameraController!.description.sensorOrientation) ??
            InputImageRotation.rotation0deg;

    final InputImageFormat inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    // final planeData = image.planes.map(
    //   (Plane plane) {
    //     return InputImagePlaneMetadata(
    //       bytesPerRow: plane.bytesPerRow,
    //       height: plane.height,
    //       width: plane.width,
    //     );
    //   },
    // ).toList();

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow:
          image.planes.map((Plane plane) => plane.bytesPerRow).first.toInt(),
    );

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageData,
    );

    final faces = await _faceDetector?.processImage(inputImage);

    if (faces != null) {
      for (Face face in faces) {
        if (face.leftEyeOpenProbability != null &&
            face.rightEyeOpenProbability != null) {
          final leftEyeOpen = face.leftEyeOpenProbability! > 0.5;
          final rightEyeOpen = face.rightEyeOpenProbability! > 0.5;
          if (leftEyeOpen && rightEyeOpen) {
            result = 'Both eyes are open';
            print('Both eyes are open');
          } else {
            result = 'One or both eyes are closed';
            print('One or both eyes are closed');
          }
        }
        if (result.isNotEmpty && (face.smilingProbability ?? 0.0) > 0.2) {
          result = result + '\nSmilling face detected';
        }

        setState(() {});
      }
    }

    _isDetecting = false;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController!.value.isInitialized) {
      return Container();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Face Detection'),
      ),
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          Positioned(top: 10, left: 10, child: Text(result))
        ],
      ),
    );
  }
}
