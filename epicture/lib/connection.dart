import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
/*

class ConnectionPage extends StatefulWidget {
  @override
  _ConnectionPageState createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  String client_id = "a14de0322afe7eb";
  WebViewController _controller;
  final flutterWebviewPlugin = FlutterWebviewPlugin();

  @override
  Widget build(BuildContext context) {
    flutterWebviewPlugin.onUrlChanged.listen((String url) {
      print('Hey !');
      print(url);
    });
    flutterWebviewPlugin.launch('https://api.imgur.com/oauth2/authorize?client_id=$client_id&response_type=token&state=login_token');
    flutterWebviewPlugin.close();
//    return Scaffold(
//      body: Text('Lol')
//    );
//    return Scaffold(
//        body: WebView(
////        initialUrl: 'https://en.wikipedia.org/wiki/Kraken',
////        initialUrl: 'https://api.imgur.com/oauth2/authorize?client_id=$client_id&response_type=token&state=login_token',
//          onWebViewCreated: (WebViewController webViewController) {
//            _controller = webViewController;
//            getToken();
//          },
//        )
//    );
  }
}
*/

class ConnectionPage extends StatefulWidget {
  @override
  _ConnectionPageState createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
//  String client_id = "a14de0322afe7eb";
  WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    getToken();
    return Scaffold(
      body: Text('lol'),
    );
//    return Scaffold(
//      body: WebView(
////        initialUrl: 'https://en.wikipedia.org/wiki/Kraken',
////        initialUrl: 'https://api.imgur.com/oauth2/authorize?client_id=$client_id&response_type=token&state=login_token',
//        onWebViewCreated: (WebViewController webViewController) {
//          _controller = webViewController;
//          getToken();
//        },
//      )
//    );
  }

  Future<String> getToken() async {
    String client_id = "a14de0322afe7eb";
    String url = "https://api.imgur.com/oauth2/authorize?client_id=$client_id&response_type=token&state=login_token";

    final FlutterWebviewPlugin webViewPlugin = new FlutterWebviewPlugin();
    webViewPlugin.onUrlChanged.listen((String url) {
      if (url.startsWith('http://localhost')) {
        webViewPlugin.close();
        webViewPlugin.dispose();
        url = url.replaceFirst('#', '&');
        print(url);
        var decoded = Uri.parse(url);
        print(decoded.queryParameters);
      }
    });
    webViewPlugin.launch(url);
  }
}
