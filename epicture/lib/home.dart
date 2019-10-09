import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epicture/colors.dart';
import 'package:epicture/connection.dart';
import 'package:epicture/image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
    if (name == null) {
      return;
    }
    var response = await http.get(
      'https://api.imgur.com/3/account/me/images',
      headers: {HttpHeaders.authorizationHeader: "Bearer $access_token"},
    );
    var data = jsonDecode(response.body);
    var images = data["data"];
    setState(() {
      _is_connected = true;
      _username = name;
      _account_id = prefs.getString('account_id');
      _access_token = prefs.getString('access_token');
      _images = images;
    });
    print(images);
    print(_images[0]['link']);
  }

  @override
  Widget build(BuildContext context) {
    if (_is_connected) {
      return Scaffold(
        backgroundColor: colorBackground,
        body: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: _images.length,
                itemBuilder: (BuildContext ctx, int index) {
                  return ImgurImage(data: _images[index]);
                },
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