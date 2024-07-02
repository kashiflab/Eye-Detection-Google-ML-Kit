import 'dart:io';

import 'package:face_detection/camera_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraScreen(),
    );
  }
}

class FaceDetectionPage extends StatefulWidget {
  @override
  _FaceDetectionPageState createState() => _FaceDetectionPageState();
}

class _FaceDetectionPageState extends State<FaceDetectionPage> {
  final FaceDetector faceDetector =
      GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
    enableClassification: true,
    enableTracking: true,
    enableContours: true,
    enableLandmarks: true,
    performanceMode: FaceDetectorMode.accurate,
  ));

  String result = '';

  @override
  void dispose() {
    faceDetector.close();
    super.dispose();
  }

  void detectFaces(InputImage image) async {
    final List<Face> faces = await faceDetector.processImage(image);
    for (Face face in faces) {
      final bool? leftEyeOpen = (face.leftEyeOpenProbability ?? 0.0) > 0.5;
      final bool? rightEyeOpen = (face.rightEyeOpenProbability ?? 0.0) > 0.5;
      if (leftEyeOpen == true && rightEyeOpen == true) {
        result = 'Both eyes are open';
        print('Both eyes are open');
      } else {
        result = 'One or both eyes are closed';
        print('One or both eyes are closed');
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Detection'),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              result,
              style: TextStyle(fontSize: 20),
            ),
            ElevatedButton(
              onPressed: () async {
                ImagePicker imagePicker = ImagePicker();
                final XFile? image =
                    await imagePicker.pickImage(source: ImageSource.gallery);
                final inputImage = InputImage.fromFile(File(image!.path));
                detectFaces(inputImage);
              },
              child: Text('Detect Faces'),
            ),
          ],
        ),
      ),
    );
  }
}
