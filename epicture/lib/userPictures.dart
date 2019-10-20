import 'dart:convert';
import 'dart:io';

import 'package:epicture/colors.dart';
import 'package:epicture/home.dart';
import 'package:epicture/pictureList.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserPictures extends StatefulWidget {
  @override
  UserPicturesState createState() => UserPicturesState();
}

/// Page for displaying User posted pictures
class UserPicturesState extends State<UserPictures> {
  var _pictures = [];

  @override
  void initState() {
    super.initState();
    getPictures();
  }

  /// Fetch User Pictures from API
  /// If have albums add them and removes alone pictures
  /// https://apidocs.imgur.com/?version=latest#ee366f7c-69e6-46fd-bf26-e93303f64c84
  /// https://apidocs.imgur.com/?version=latest#a9931b00-47ab-4144-b058-a15906bf3e15
  /// https://apidocs.imgur.com/?version=latest#f57e9ff3-0d25-4804-bc53-53e9e54be813
  Future<Null> getPictures() async {
    var response = await http.get(
      'https://api.imgur.com/3/account/me/images',
      headers: {HttpHeaders.authorizationHeader: "Bearer $globalAccessToken"},
    );
    if (response.statusCode != 200) {
      return;
    }
    var data = jsonDecode(response.body);
    List pictures = data["data"];
    var responseAlbums = await http.get(
      'https://api.imgur.com/3/account/me/albums/0',
      headers: {HttpHeaders.authorizationHeader: "Bearer $globalAccessToken"},
    );
    if (responseAlbums.statusCode != 200) {
      return;
    }
    var albumData = jsonDecode(responseAlbums.body)['data'];
    for (var album in albumData) {
      var res = await http.get(
        'https://api.imgur.com/3/account/me/album/${album['id']}',
        headers: {HttpHeaders.authorizationHeader: "Bearer $globalAccessToken"},
      );
      var albumRes = await jsonDecode(res.body)['data'];
      if (albumRes['images'] == null)
        continue;
      for (var imageAlbum in albumRes['images']) {
        pictures.removeWhere((element) => (element['id'] == imageAlbum['id']));
      }
      pictures.add(albumRes);
    }
    pictures.sort((a, b) => b['datetime'].compareTo(a['datetime']));
    setState(() {
      _pictures = pictures;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBottomAppBar,
        title: Text('Your Pictures', style: TextStyle(color: colorText),),
      ),
      body: RefreshIndicator(
        color: colorBackground,
        onRefresh: getPictures,
        child: CustomScrollView(
          cacheExtent: cacheLimit,
          scrollDirection: Axis.vertical,
          slivers: <Widget>[
            PictureList(pictures: _pictures,)
          ],
        ),
      ),
    );
  }
}