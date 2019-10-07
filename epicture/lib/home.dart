import 'dart:async';

import 'package:epicture/connection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: ConnectionPage(),
//      body: WebView(
//        initialUrl: 'https://en.wikipedia.org/wiki/Kraken',
//        initialUrl: 'https://api.imgur.com/oauth2/authorize?client_id=$client_id&response_type=token&state=login_token',
//        onWebViewCreated: (WebViewController webViewController) {
//          webViewController.currentUrl().then((val) { print(val); });
//        },
//      )
    );
  }
}