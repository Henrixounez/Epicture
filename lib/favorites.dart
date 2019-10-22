import 'dart:convert';
import 'dart:io';

import 'package:epicture/colors.dart';
import 'package:epicture/home.dart';
import 'package:epicture/pictureList.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserFavorites extends StatefulWidget {
  @override
  UserFavoritesState createState() => UserFavoritesState();
}

/// Page for displaying User Favorites
class UserFavoritesState extends State<UserFavorites> {
  var _pictures = [];
  var _page = 0;
  var _sort = "newest";

  @override
  void initState() {
    super.initState();
    getPictures();
  }

  /// Fetch User Favorites from API
  /// https://apidocs.imgur.com/?version=latest#a432a8e6-2ece-4544-bc7a-2999eb586f06
  Future<Null> getPictures() async {
    var response = await http.get(
      'https://api.imgur.com/3/account/$globalUsername/favorites/$_page/$_sort',
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
        title: Text('Your Favorites', style: TextStyle(color: colorText),),
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