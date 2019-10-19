import 'package:flutter/material.dart';
import 'dart:io';

import 'colors.dart';

class ImageAlbumUpload extends StatefulWidget {
  String imagePath;
  final TextEditingController tecDescription = new TextEditingController();

  ImageAlbumUpload({this.imagePath});

  @override
  ImageAlbumUploadState createState() => ImageAlbumUploadState();
}

class ImageAlbumUploadState extends State<ImageAlbumUpload> {

  @override
  void dispose() {
    widget.tecDescription.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      return Column(
        children: <Widget>[
          Container(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Container(
                child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.fitWidth
                ),
              ),
            ),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: colorBottomAppBar
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            margin: EdgeInsets.symmetric(vertical: 10),
            child: TextField(
              style: TextStyle(color: Colors.white),
              controller: widget.tecDescription,
              cursorColor: Colors.white,
              decoration: InputDecoration(
                prefixIcon: null,
                hintText: 'Add a descripttion',
                hintStyle: TextStyle(color: Colors.white),
              ),
            ),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: colorBottomAppBar),
          ),
        ],
      );
  }
}