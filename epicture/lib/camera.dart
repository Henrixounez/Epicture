import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'editor.dart';

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
                  heroTag: "widgetHero",
                  backgroundColor: Colors.white,
                  child: _thumbnailWidget(),
                  onPressed: controller != null &&
                          controller.value.isInitialized &&
                          !controller.value.isRecordingVideo
                      ? onWidgetPreviewButtonPressed
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
//      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//      floatingActionButton: FloatingActionButton(
//        child: Icon(Icons.camera),
//        onPressed: controller != null &&
//            controller.value.isInitialized &&
//            !controller.value.isRecordingVideo
//            ? onTakePictureButtonPressed
//            : null,
//      ),
//      bottomNavigationBar: BottomAppBar(
//        color: Colors.red,
//        shape: CircularNotchedRectangle(),
//        notchMargin: 4.0,
//        child: Row(
//          mainAxisSize: MainAxisSize.max,
//          mainAxisAlignment: MainAxisAlignment.spaceBetween,
//          children: <Widget>[
//            IconButton(icon: Icon(Icons.home), onPressed: (){},),
//            IconButton(icon: Icon(Icons.search), onPressed: (){},),
//          ],
//        ),
//      ),
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

  Widget _thumbnailWidget() {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(64.0)),
      child: imagePath == null
          ? Container()
          : SizedBox(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.fitWidth,
              ),
              width: 64.0,
              height: 64.0,
            ),
    );
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.camera_alt),
          color: Colors.blue,
          onPressed: controller != null &&
                  controller.value.isInitialized &&
                  !controller.value.isRecordingVideo
              ? onTakePictureButtonPressed
              : null,
        ),
      ],
    );
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  Widget _cameraTogglesRowWidget() {
    final List<Widget> toggles = <Widget>[];

    if (cameras.isEmpty) {
      return const Text('No camera found');
    } else {
      print(cameras);
      for (CameraDescription cameraDescription in cameras) {
        toggles.add(
          SizedBox(
            width: 90.0,
            child: RadioListTile<CameraDescription>(
              title: Icon(getCameraLensIcon(cameraDescription.lensDirection)),
              groupValue: controller?.description,
              value: cameraDescription,
              onChanged: controller != null && controller.value.isRecordingVideo
                  ? null
                  : onNewCameraSelected,
            ),
          ),
        );
      }
    }

    return Row(children: toggles);
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

  void onWidgetPreviewButtonPressed() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return Scaffold(
          body: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      child: Center(
                        child: imagePath == null
                            ? Container()
                            : Image.file(File(imagePath), fit: BoxFit.fill),
                      ),
                      decoration: BoxDecoration(color: Colors.black),
                    ),
                  )
                ],
              )
            ],
          ),
        );
      },
    ));
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
}
