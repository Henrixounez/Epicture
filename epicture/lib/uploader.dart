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
    // TODO: implement build
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: <Widget>[
                Container(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                  ),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      color: colorBottomAppBar),
                ),
                Container(
                  child: Padding(
                    padding: EdgeInsets.all(5.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: SizedBox(
                        child: Image.file(File(widget.imagePath),
                            fit: BoxFit.fitWidth),
                        width: 300,
                        height: 300,
                      ),
                    ),
                  ),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      color: colorBottomAppBar),
                ),
                Container(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                  ),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      color: colorBottomAppBar),
                ),
              ],
            ),
          ),
        ));
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
