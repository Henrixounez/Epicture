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
  _UserPicturesState createState() => _UserPicturesState();
}

class _UserPicturesState extends State<UserPictures> {
  var _pictures = [];

  @override
  void initState() {
    super.initState();
    getPictures();
  }

  Future<Null> getPictures() async {
    var response = await http.get(
      'https://api.imgur.com/3/account/me/images',
      headers: {HttpHeaders.authorizationHeader: "Bearer $globalAccessToken"},
    );
    var data = jsonDecode(response.body);
    var pictures = data["data"];
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
          cacheExtent: 1000,
          scrollDirection: Axis.vertical,
          slivers: <Widget>[
            PictureList(pictures: _pictures,)
          ],
        ),
      ),
    );
  }
}