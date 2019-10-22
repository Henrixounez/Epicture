import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'uploader.dart';

class PictureEditor extends StatefulWidget {
  final Function updateParent;
  final String imagePath;

  PictureEditor({this.updateParent, this.imagePath});

  @override
  _PictureEditorState createState() => _PictureEditorState();
}

/// A simple Editor for Epicture
/// Let you have a look at what you've created
/// Can save or ditch your picture
class _PictureEditorState extends State<PictureEditor> {
  bool saved;

  @override
  void initState() {
    super.initState();
    saved = false;
  }

  /// Build a view with three FAB
  ///   - A 'go-back' button
  ///   - A 'save' button
  ///   - A 'upload' button
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Expanded(
                  child: Container(
                    child: Center(
                      child: widget.imagePath == null
                          ? Container()
                          : Image.file(File(widget.imagePath),
                          fit: BoxFit.fill),
                    ),
                    decoration: BoxDecoration(color: Colors.black),
                  ),
                )
              ],
            ),
            Positioned(
              child: Align(
                alignment: FractionalOffset.topLeft,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
                  child: FloatingActionButton(
                      heroTag: "quitHero",
                      backgroundColor: Colors.red,
                      child: Icon(
                        Icons.clear,
                        color: Colors.white,
                      ),
                      onPressed: () => setState(() {
                        Navigator.of(context).pop();
                      }),
                    mini: true,
                  ),
                ),
              ),
            ),
            Positioned(
              child: Align(
                alignment: FractionalOffset.bottomLeft,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
                  child: FloatingActionButton(
                    heroTag: "saveHero",
                    backgroundColor: !saved ? Colors.white : Colors.green,
                    child: Icon(
                      !saved ? Icons.save_alt : Icons.check_circle_outline,
                      color: !saved ? Colors.grey : Colors.white,
                    ),
                    onPressed: () => setState(() {
                      saved = true;
                    }),
                    mini: true,
                  ),
                ),
              ),
            ),
            Positioned(
              child: Align(
                alignment: FractionalOffset.bottomRight,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
                  child: FloatingActionButton(
                    heroTag: "uploadHero",
                    backgroundColor: Colors.blue,
                    child: Icon(
                      Icons.file_upload,
                      color: Colors.white,
                    ),
                    onPressed: onUploadPressed,
                  ),
                ),
              )
            )
          ],
        ),
      ),
      onWillPop: () async  {
        if (!saved) {
          await File(widget.imagePath).delete();
          widget.updateParent();
        }
        Navigator.of(context).pop();
        return Future(() => false);
      },
    );
  }

  /// Calls the uploader
  void onUploadPressed() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return UploaderFlutter(
          imagePath: widget.imagePath,
        );
      },
    ));
  }
}