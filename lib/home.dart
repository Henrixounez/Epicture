import 'dart:convert';
import 'dart:io';

import 'package:epicture/colors.dart';
import 'package:epicture/connection.dart';
import 'package:epicture/favorites.dart';
import 'package:epicture/pictureList.dart';
import 'package:epicture/userPictures.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

var globalAccessToken = "";
var globalClientId = "a14de0322afe7eb";
var globalUsername = "";
var mature = false;
var cacheLimit = 200.0;

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

/// Home Page with most Popular Images on Imgur
/// Have a Drawer to Access User specific features (Favorites, UserPictures, Settings, Disconnection...)
class HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  var _isConnected = false;
  var _images = [];
  Future<String> _avatarUrl;

  @override
  void initState() {
    super.initState();
    findPrefs();
  }

  /// Get user data from phone storage and sets global variables
  /// Tells if user is connected or not
  void findPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('account_username');
    final accessToken = prefs.getString('access_token');
    if (name == null) {
      return;
    }
    globalUsername = name;
    globalAccessToken = accessToken;
    setState(() {
      _isConnected = true;
    });
    refresh();
    getMature();
  }

  /// Fetch settings to tell if mature filter is activated
  /// https://apidocs.imgur.com/?version=latest#ce57e346-3515-4381-a772-ef5ade60bdee
  void getMature() async {
    var response = await http.get(
        'https://api.imgur.com/3/account/me/settings',
        headers: {HttpHeaders.authorizationHeader: 'Bearer $globalAccessToken'}
    );
    if (mounted) {
      setState(() {
        mature = jsonDecode(response.body)['data']['show_mature'];
      });
    }
  }

  /// Disconnects user by clearing the phone storage of user data
  void disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _scaffoldKey.currentState.openEndDrawer();
    globalUsername = "";
    globalAccessToken = "";
    setState(() {
      _images = [];
      _isConnected = false;
    });
  }

  /// Refresh the current image list by fetching the API
  /// Shows the most popular images on Imgur
  /// https://apidocs.imgur.com/?version=latest#eff60e84-5781-4c12-926a-208dc4c7cc94
  Future<Null> refresh() async {
    var response = await http.get(
      'https://api.imgur.com/3/gallery/hot/time/0?showViral=true&album_previews=false&mature=$mature',
      headers: {HttpHeaders.authorizationHeader: "Bearer $globalAccessToken"},
    );
    var data = jsonDecode(response.body)['data'];
    setState(() {
      _images = data;
      _avatarUrl = getAvatar();
    });
  }

  /// Fetch the User avatar to show on AppBar
  /// https://apidocs.imgur.com/?version=latest#6427d23d-2ad2-44e3-846d-65d7b042afbd
  Future<String> getAvatar() async {
    if (globalUsername == "") {
      return '';
    }
    var response = await http.get(
      'https://api.imgur.com/3/account/$globalUsername/avatar',
      headers: {HttpHeaders.authorizationHeader: "Bearer $globalAccessToken"},
    );
    var data = jsonDecode(response.body)['data'];
    return data['avatar'];
  }

  /// Shows the page
  /// If connected shows
  /// * AppBar with Avatar Button to show Drawer
  /// * PictureList displaying all fetched images (pictureList.dart)
  /// If not connected shows
  /// * ConnectionPage (connection.dart)
  @override
  Widget build(BuildContext context) {
    if (_isConnected) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: colorBackground,
        body: SafeArea(
          child: NestedScrollView(
            scrollDirection: Axis.vertical,
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget> [
                foldableTopAppBar()
              ];
            },
            body: RefreshIndicator(
              color: colorBackground,
              onRefresh: refresh,
              child: CustomScrollView(
                cacheExtent: cacheLimit,
                scrollDirection: Axis.vertical,
                slivers: <Widget>[
                  PictureList(pictures: _images,)
                ],
              ),
            )
          ),
        ),
        drawer: drawer(),
      );
    } else {
      return Scaffold(
        backgroundColor: colorBackground,
        appBar: AppBar(
          title: Text('Home'),
        ),
        body: ConnectionPage(parent: this),
      );
    }
  }

  /// AppBar that disappear when scrolling down and reappear scrolling up
  /// Has Avatar Button to display the User drawer
  Widget foldableTopAppBar() {
    Widget _avatarButton = Spacer();
    if (_scaffoldKey.currentState != null) {
      _avatarButton = avatarButton(_scaffoldKey.currentState.openDrawer, _avatarUrl);
    }
    return SliverAppBar(
      leading: _avatarButton,
      backgroundColor: colorBottomAppBar,
      expandedHeight: 0.0,
      floating: true,
      pinned: false,
      snap: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Home'),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }

  /// Drawer displaying user informations
  /// * Username
  /// * Access to User Pictures (userPictures.dart)
  /// * Access to User Favorites (favorites.dart)
  /// * Setting for Mature Content
  /// * Disconnection button
  Widget drawer() {
    Widget _avatarButton = Spacer();
    if (_scaffoldKey.currentState != null) {
      _avatarButton = avatarButton(_scaffoldKey.currentState.openEndDrawer, _avatarUrl);
    }
    return Theme(
      data: ThemeData(canvasColor: colorMiddle),
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: 150,
              child: DrawerHeader(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: colorBottomAppBar
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _avatarButton,
                        VerticalDivider(),
                        Expanded(
                          child:Text(
                            globalUsername,
                            style: TextStyle(
                              color: colorText,
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                            ),
                          )
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.collections, color: colorText,),
              title: Text('Your Pictures', style: TextStyle(color: colorText, fontWeight: FontWeight.bold, fontSize: 20),),
              onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => UserPictures())); },
            ),
            ListTile(
              leading: Icon(Icons.favorite, color: colorText,),
              title: Text('Your Favorites', style: TextStyle(color: colorText, fontWeight: FontWeight.bold, fontSize: 20),),
              onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => UserFavorites())); },
            ),
            Divider(),
            ListTile(
              leading: Icon(mature ? Icons.whatshot : Icons.lock, color: colorText),
              title: Text('Mature Content' + (mature ? ' On' : ' Off'), style: TextStyle(color: colorText, fontWeight: FontWeight.bold, fontSize: 20),),
              onTap: () async {
                mature = !mature;
                setState(() {});
                refresh();
                await http.put(
                  'https://api.imgur.com/3/account/$globalUsername/settings?show_mature=$mature',
                  headers: {HttpHeaders.authorizationHeader: 'Bearer $globalAccessToken'}
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: colorText),
              title: Text('Disconnect', style: TextStyle(color: colorText, fontWeight: FontWeight.bold, fontSize: 20),),
              onTap: disconnect,
            ),
          ],
        ),
      )
    );
  }

  /// AvatarButton to be used in AppBar and Drawer
  Widget avatarButton(var function, Future<String> avatar) {
    return Container(
      width: 60,
      height: 60,
      child: FlatButton(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(40))
        ),
        padding: EdgeInsets.all(0),
        onPressed: () { function(); },
        child: FutureBuilder(
          future: avatar,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.network(
                  snapshot.data,
                  width: 40,
                  height: 40,
                ),
              );
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      )
    );
  }
}