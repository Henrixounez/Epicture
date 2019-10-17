import 'dart:async';

import 'package:epicture/colors.dart';
import 'package:epicture/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ConnectionPage extends StatefulWidget {
  const ConnectionPage({Key key, @required this.parent}) : super(key: key);
  final parent;

  @override
  _ConnectionPageState createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  static String url = 'https://api.imgur.com/oauth2/authorize?client_id=$globalClientId&response_type=token&state=login_token';
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

  Future<void> getLink(String url) async {
    url = url.replaceFirst('#', '&');
    Uri uri = Uri.parse(url);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('access_token', uri.queryParameters['access_token']);
    prefs.setString('refresh_token', uri.queryParameters['refresh_token']);
    prefs.setString('account_username', uri.queryParameters['account_username']);
    prefs.setString('account_id', uri.queryParameters['account_id']);
    prefs.setInt('expires', DateTime.now().millisecondsSinceEpoch + int.parse(uri.queryParameters['expires_in']));
    widget.parent.setState((){widget.parent.findPrefs();});
  }

  Future<Null> initUniLinks() async {
    try {
      String initialLink = await getInitialLink();
      if (initialLink != null) {
        await getLink(initialLink);
      }
    } on PlatformException {
      return;
    }
    _sub = getLinksStream().listen((String link) async {
      await getLink(link);
    }, onError: (err) {
      print(err);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: RaisedButton(
              color: colorGreen,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Login on Imgur !', style: TextStyle(color: colorText, fontSize: 30),),
              ),
              onPressed: () async {
                launch(url);
              },
            ),
          )
        ],
      )
    );
  }
}