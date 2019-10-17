import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

import 'colors.dart';
import 'home.dart';

class UploaderFlutter extends StatefulWidget {
  final String imagePath;

  UploaderFlutter({this.imagePath});

  @override
  _UploadFlutterState createState() => _UploadFlutterState();
}

class _UploadFlutterState extends State<UploaderFlutter> {
  final TextEditingController _tecTitle = new TextEditingController();
  final TextEditingController _tecDescription = new TextEditingController();
  Widget _appBatTitle = Text('Upload to Imgur');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      floatingActionButton: FloatingActionButton(
        heroTag: 'fabUploadHero',
        backgroundColor: Colors.green,
        child: Icon(
          Icons.cloud_upload,
          color: Colors.white,
        ),
        onPressed: _onfabUploadPressed,
      ),
      appBar: AppBar(
        title: _appBatTitle,
      ),
      body: Container(
        padding: EdgeInsets.all(5),
        child: ListView(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: EdgeInsets.symmetric(vertical: 10),
              child: TextField(
                style: TextStyle(color: Colors.white),
                controller: _tecTitle,
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  prefixIcon: null,
                  hintText: 'Title (required)',
                  hintStyle: TextStyle(color: Colors.white),
                ),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: colorBottomAppBar
              ),
            ),
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
                controller: _tecDescription,
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
        ),
      ),
    );
  }

  void _onfabUploadPressed() async {
    String title = _tecTitle.text;
    String description = _tecDescription.text;
    String base64Image = base64.encode(File(widget.imagePath).readAsBytesSync());

    if (title == null) {
      print("thinkng");
      return;
    }
    var response = await http.post('https://api.imgur.com/3/upload',
    headers: {HttpHeaders.authorizationHeader: 'Bearer $globalAccessToken'},
    body: {
      'image': base64Image,
      'title': title,
    });
    print(response.statusCode);
    if (response.statusCode == 200) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }
}
