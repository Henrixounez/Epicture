import 'dart:async';
import 'dart:io';

import 'package:epicture/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ConnectionPage extends StatefulWidget {
  @override
  _ConnectionPageState createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  static String client_id = "a14de0322afe7eb";
  static String url = 'https://api.imgur.com/oauth2/authorize?client_id=$client_id&response_type=token&state=login_token';
  StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    initLinks();
  }

  @override
  void dispose() {
    super.dispose();
    _sub.cancel();

  }

  void initLinks() async {
    await initUniLinks();
  }

  void get_link(String url) async {
    url = url.replaceFirst('#', '&');
    Uri uri = Uri.parse(url);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('access_token', uri.queryParameters['access_token']);
    prefs.setString('refresh_token', uri.queryParameters['refresh_token']);
    prefs.setString('account_username', uri.queryParameters['account_username']);
    prefs.setString('account_id', uri.queryParameters['account_id']);
    prefs.setInt('expires', DateTime.now().millisecondsSinceEpoch + int.parse(uri.queryParameters['expires_in']));
  }

  Future<Null> initUniLinks() async {
    try {
      String initialLink = await getInitialLink();
      if (initialLink != null) {
        await get_link(initialLink);
      }
    } on PlatformException {
      return;
    }
    _sub = getLinksStream().listen((String link) async {
      await get_link(link);
    }, onError: (err) {
      print(err);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: Column(
        children: <Widget>[
          RaisedButton(
            child: Text('Login on Imgur !'),
            onPressed: () async {
              launch(url);
            },
          )
        ],
      )
    );
  }
}