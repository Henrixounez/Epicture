import 'dart:convert';
import 'dart:io';

import 'package:epicture/colors.dart';
import 'package:epicture/connection.dart';
import 'package:epicture/image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

var global_access_token = "";
var global_client_id = "a14de0322afe7eb";

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _is_connected = false;
  var _username = "";
  var _account_id = "";
  var _access_token = "";
  var _images = [];

  @override
  void initState() {
    super.initState();
    find_prefs();
  }

  void find_prefs() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('account_username');
    final access_token = prefs.getString('access_token');
    global_access_token = access_token;
    if (name == null) {
      return;
    }
    setState(() {
      _is_connected = true;
      _username = name;
      _account_id = prefs.getString('account_id');
      _access_token = prefs.getString('access_token');
    });
    _refresh();
  }

  Future<Null> _refresh() async {
    var response = await http.get(
      'https://api.imgur.com/3/account/me/images',
      headers: {HttpHeaders.authorizationHeader: "Bearer $_access_token"},
    );
    var data = jsonDecode(response.body);
    var images = data["data"];
    setState(() {
      _images = images;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_is_connected) {
      return Scaffold(
        backgroundColor: colorBackground,
        body: Column(
          children: <Widget>[
            Expanded(
              child: RefreshIndicator(
                child: ListView.builder(
                  itemCount: _images.length,
                  itemBuilder: (BuildContext ctx, int index) {
                    return ImgurImage(key: ValueKey(index),data: _images[index]);
                  },
                  addAutomaticKeepAlives: true,
                ),
                onRefresh: _refresh
              )
            )
          ],
        )
      );
    } else {
      return Scaffold(
        backgroundColor: colorBackground,
        appBar: AppBar(
          title: Text('Home'),
        ),
        body: ConnectionPage(),
      );
    }
  }
}