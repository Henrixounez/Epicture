import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'editor.dart';
import 'uploader.dart';

List<CameraDescription> cameras;

class CameraExampleHome extends StatefulWidget {
  @override
  CameraExampleHomeState createState() => CameraExampleHomeState();
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  throw ArgumentError('Unknown lens direction');
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class CameraExampleHomeState extends State<CameraExampleHome>
    with WidgetsBindingObserver {
  CameraController controller;
  CameraDescription actualCamera;
  CameraDescription frontCamera;
  CameraDescription backCamera;
  String imagePath;
  String oldImagePath;
  String videoPath;
  VoidCallback videoPlayerListener;
  bool enableAudio = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for (CameraDescription cameraDescription in cameras) {
      if (cameraDescription.lensDirection == CameraLensDirection.back) {
        onNewCameraSelected(cameraDescription);
        actualCamera = cameraDescription;
        backCamera = cameraDescription;
      } else if (cameraDescription.lensDirection == CameraLensDirection.front) {
        frontCamera = cameraDescription;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Expanded(
              child: Container(
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        Positioned(
          child: Align(
            alignment: FractionalOffset.bottomLeft,
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                child: FloatingActionButton(
                  heroTag: "galleryHero",
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.image,
                    color: Colors.grey
                  ),
                  onPressed: controller != null &&
                          controller.value.isInitialized &&
                          !controller.value.isRecordingVideo
                      ? onGalleryButtonPressed
                      : null,
                )),
          ),
        ),
        Positioned(
            child: Align(
                alignment: FractionalOffset.bottomCenter,
                child: Container(
                    padding: EdgeInsets.all(20.0),
                    child: FloatingActionButton(
                      heroTag: "pictureButtonHero",
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.camera,
                        color: Colors.grey,
                      ),
                      onPressed: controller != null &&
                              controller.value.isInitialized &&
                              !controller.value.isRecordingVideo
                          ? onTakePictureButtonPressed
                          : null,
                    )))),
        Positioned(
          child: Align(
            alignment: FractionalOffset.bottomRight,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
              child: FloatingActionButton(
                heroTag: "changeCameraHero",
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.switch_camera,
                  color: Colors.grey,
                ),
                onPressed: controller != null &&
                        controller.value.isInitialized &&
                        !controller.value.isRecordingPaused
                    ? onCameraSwitchButtonPressed
                    : null,
              ),
            ),
          ),
        )
      ],
    )
        );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Stack(
        children: <Widget>[
          Positioned.fill(
            child: CameraPreview(controller),
          )
        ],
      );
    }
  }
  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.ultraHigh,
      enableAudio: enableAudio,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onTakePictureButtonPressed() {
    takePicture().then((String filePath) {
      onPictureTaken(filePath);
      if (mounted) {
        setState(() {
          oldImagePath = imagePath;
          imagePath = filePath;
        });
//        if (filePath != null) showInSnackBar('Picture saved to $filePath');
      }
    });
  }

  void onCameraSwitchButtonPressed() {
    if (actualCamera.lensDirection == CameraLensDirection.back) {
      onNewCameraSelected(frontCamera);
      actualCamera = frontCamera;
    } else {
      onNewCameraSelected(backCamera);
      actualCamera = backCamera;
    }
  }

  Future<String> getImage() async {
    File _image = await ImagePicker.pickImage(source: ImageSource.gallery);

    return _image.path;
  }

  void onGalleryButtonPressed() async {
    String path = await getImage();
    onUploadPressed(path);
  }

  void onPictureTaken(String tmpImagePath) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return PictureEditor(
          updateParent: updateOldImagePath,
          imagePath: tmpImagePath,
        );
      },
    ));
  }

  Future<String> takePicture() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  updateOldImagePath() => setState(() {
    imagePath = oldImagePath;
  });

  void onUploadPressed(imagePath) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return UploaderFlutter(
          imagePath: imagePath,
        );
      },
    ));
  }
}
