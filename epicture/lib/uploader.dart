import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'fold.dart';

import 'colors.dart';
import 'home.dart';
import 'animation.dart';

class UploaderFlutter extends StatefulWidget {
  final String imagePath;

  UploaderFlutter({this.imagePath});

  @override
  UploadFlutterState createState() => UploadFlutterState();
}

class UploadFlutterState extends State<UploaderFlutter> {
  final TextEditingController _tecTitle = new TextEditingController();
  final TextEditingController _tecDescription = new TextEditingController();
  final SnackBar snack = SnackBar(content: Text('Toilettes'));
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<String> imagesAlbum;

  Widget _appBatTitle = Text('Upload to Imgur');
  bool loading;
  int responseUpload;

  @override
  void initState() {
    super.initState();
    loading = false;
    responseUpload = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
    if (loading) {
      return;
    }
    setState(() {
      loading = true;
    });
    String title = _tecTitle.text;
    String description = _tecDescription.text;
    String base64Image = base64.encode(File(widget.imagePath).readAsBytesSync());
    Map body = {};

    if (title == null) {
      print("thinkng");
      return;
    }

    body['image'] = base64Image;
    body['title'] = title;
    if (description != '') {
      body['description'] = description;
    }

    GlobalKey<TestState> key = GlobalKey<TestState>();
    Navigator.of(context).push(
        SlideLeftRoute(page: Test(key: key, parent: this, title: title,))
    );

    var response = await http.post('https://api.imgur.com/3/upload',
    headers: {HttpHeaders.authorizationHeader: 'Bearer $globalAccessToken'},
    body: body
    );

    if (response.statusCode == 200) {
      print("in response\n##############");
      setState(() {
        responseUpload = response.statusCode;
        loading = false;
      });
      key.currentState.setState(() {});
    } else {
      print("ERROR: ${response.statusCode}");
      setState(() {
        responseUpload = response.statusCode;
        loading = false;
      });
      key.currentState.setState(() {});
    }
  }
}


class UploaderFAB extends StatelessWidget {
  final String imagePath;
  final Color backgroundColor;
  final Icon fabIcon;

  UploaderFAB({this.imagePath, this.backgroundColor, this.fabIcon});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "uploaderFABHero",
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return UploaderFlutter(
              imagePath: imagePath,
            );
          },
        ));
      },
    );
  }
}