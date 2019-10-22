import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import 'fold.dart';
import 'home.dart';
import 'colors.dart';
import 'animation.dart';
import 'imageAlbumUpload.dart';

/// An enum used to define PrivacySettings
enum PrivacySettings { public, hidden, secret }

class UploaderFlutter extends StatefulWidget {
  final String imagePath;

  UploaderFlutter({this.imagePath});

  @override
  UploadFlutterState createState() => UploadFlutterState();
}

/// The Uploader class.
/// Contains all uploading logic.
/// Displays a page with title, pictures and actions
class UploadFlutterState extends State<UploaderFlutter> {
  final TextEditingController _tecTitle = new TextEditingController();
//  final TextEditingController _tecDescription = new TextEditingController();
  final SnackBar snack = SnackBar(content: Text('Toilettes'));
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PrivacySettings _privacySelected = PrivacySettings.hidden;
  List<ImageAlbumUpload> imagesAlbum;

  Widget _appBatTitle = Text('Upload to Imgur');
  bool loading;
  int responseUpload;

  @override
  void initState() {
    super.initState();
    loading = false;
    responseUpload = 0;
    imagesAlbum = [(ImageAlbumUpload(imagePath: widget.imagePath,))];
  }

  /// Listview with in order:
  ///   TextField to get title
  ///   DropdownButton to chose privacy setting
  ///   A list of imageAlbumUploaded generated with a map
  ///   A FlatButton to add more images
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
              child: Row(
                children: <Widget>[
                  Expanded(
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
                  DropdownButton<PrivacySettings>(
                    value: _privacySelected,
                    icon: Icon(
                      Icons.arrow_downward,
                      color: colorGreen,
                    ),
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(
                      color: Colors.white
                    ),
                    underline: Container(
                      height: 2,
                      color: colorGreen,
                    ),
                    onChanged: (PrivacySettings newSetting) {
                      setState(() {
                        _privacySelected = newSetting;
                        print("new setting : ${_privacySelected.toString().split('.').last}");
                      });
                    },
                    items: <PrivacySettings>[PrivacySettings.public, PrivacySettings.hidden, PrivacySettings.secret]
                    .map<DropdownMenuItem<PrivacySettings>>((PrivacySettings elem) {
                      return DropdownMenuItem<PrivacySettings>(
                        value: elem,
                        child: Text(elem.toString().split('.').last),
                      );
                    }).toList(),
                  )
                ],
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: colorBottomAppBar
              ),
            ),
            ...imagesAlbum,
            FlatButton(
              color: colorGreen,
              textColor: Colors.white,
              child: Text("Add more images"),
              onPressed: () async {
                String path = await getImage();
                imagesAlbum.add(ImageAlbumUpload(imagePath: path,));
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Uploads a image to imgur
  /// image: The image to be uploaded
  /// multi: Is this image uploading in a album ?
  /// albumToken: The Album ID
  /// https://apidocs.imgur.com/?version=latest#c85c9dfc-7487-4de2-9ecd-66f727cf3139
  Future<http.Response> _imageUpload(ImageAlbumUpload image, bool multi, String albumToken) async {
    String title = _tecTitle.text;
    String description = image.tecDescription.text;
    String base64Image = base64.encode(File(image.imagePath).readAsBytesSync());
    Map body = {};

    body['image'] = base64Image;
    if (!multi) {
      body['title'] = title;
    } else {
      body['album'] = albumToken;
    }
    if (description != '') {
      body['description'] = description;
    }

    var response = await http.post('https://api.imgur.com/3/upload',
        headers: {HttpHeaders.authorizationHeader: 'Bearer $globalAccessToken'},
        body: body
    );
    return response;
  }

  /// Uploads a single image to Imgur
  /// Calls _imageUpload.
  void _soloImageUpload(ImageAlbumUpload image) async {
    GlobalKey<TestState> key = GlobalKey<TestState>();
    Navigator.of(context).push(
        SlideLeftRoute(page: Test(key: key, parent: this, title: _tecTitle.text,))
    );

    var response = await _imageUpload(image, false, '');

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

  /// Uploads an album to imgur
  /// Calls _imageUpload multiple time.
  /// https://apidocs.imgur.com/?version=latest#8f89bd41-28a1-4624-9393-95e12cec509a
  void _onAlbumUpload() async {
    GlobalKey<TestState> key = GlobalKey<TestState>();
    Navigator.of(context).push(
        SlideLeftRoute(page: Test(key: key, parent: this, title: _tecTitle.text,))
    );
    print("dans album : $_privacySelected");

    var response = await http.post('https://api.imgur.com/3/album',
    headers: {HttpHeaders.authorizationHeader: 'Bearer $globalAccessToken'},
    body: {
      'title': _tecTitle.text,
      'privacy': _privacySelected.toString().split('.').last
    });

    if (response.statusCode == 200) {
      String token;
      if (_tecTitle.text == '') {
        token = jsonDecode(response.body)['data']['deletehash'];
      } else {
        token = jsonDecode(response.body)['data']['id'];
      }
      Future.wait(imagesAlbum.map((ImageAlbumUpload image) async {
        var response = await _imageUpload(image, true, token);
        return response.statusCode;
      })).then((_) {
        setState(() {
          responseUpload = response.statusCode;
          loading = false;
        });
        key.currentState.setState(() {});
      });
    }
  }

  /// FAB upload callback. Will call solo / album upload according to Uploader state
  void _onfabUploadPressed() async {
    if (loading) {
      return;
    }
    setState(() {
      loading = true;
    });
    if (imagesAlbum.length == 1 && _privacySelected == PrivacySettings.hidden) {
      _soloImageUpload(imagesAlbum[0]);
    } else {
      _onAlbumUpload();
    }
  }

  /// Opens the gallery and get the path to the chosen image
  Future<String> getImage() async {
    File _image = await ImagePicker.pickImage(source: ImageSource.gallery);

    return _image.path;
  }
}

/// A class that generates a FAB that will call the uploader.
/// Usable anywhere in the app
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