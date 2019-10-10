import 'dart:convert';
import 'dart:io';

import 'package:epicture/colors.dart';
import 'package:epicture/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ImgurImage extends StatefulWidget {
  const ImgurImage({Key key, @required this.data}) : super(key: key);
  final data;

  _ImgurImageState createState() => _ImgurImageState();
}

class _ImgurImageState extends State<ImgurImage> with AutomaticKeepAliveClientMixin<ImgurImage> {
  var data = {};
  Future<String> avatar_url;
  Future<String> img_url;
  bool got_avatar = false;
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!got_avatar) {
      avatar_url = getAvatar();
      img_url = getImg();
    }
    setState(() {
        data = widget.data;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var title = getTitle();

    if (widget.data != data) {
      data = widget.data;
    }
    if (data['link'] == null) {
      return Text('Loading');
    }
    return Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(52, 55, 60, 1),
      ),
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    FutureBuilder(
                      future: avatar_url,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(100)),
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
                    VerticalDivider(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                            textAlign: TextAlign.left,
                          ),
                          Text(
                            data['account_url'],
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      )
                    )
                  ],
                ),
                Divider(color: Colors.transparent, height: 5,),
              ],
            )
          ),
          FutureBuilder(
            future: img_url,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                return Image.network(snapshot.data);
              } else {
                return CircularProgressIndicator();
              }
            },
          ),
          Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  metric(data['views'], Icons.remove_red_eye),
                  metric(data['ups'], Icons.keyboard_arrow_up),
                  metric(data['downs'], Icons.keyboard_arrow_down),
                ],
              )
            ],
          ),
          Divider(
            color: colorMetrics,
          ),
        ],
      )
    );
  }

  String getTitle() {
    if (data['description'] != null) {
      return data['description'];
    }
    if (data['title'] != null) {
      return data['title'];
    }
    return '';
  }

  Future<String> getAvatar() async {
    var response = await http.get(
      'https://api.imgur.com/3/account/${widget.data['account_url']}/avatar',
      headers: {HttpHeaders.authorizationHeader: "Bearer $global_access_token"},
    );
    var data = jsonDecode(response.body)['data'];
    setState(() {
      got_avatar = true;
    });
    return data['avatar'];
  }

  Future<String> getImg() async {
    String client_id = "a14de0322afe7eb";
    if (!widget.data['link'].toString().endsWith('.png')) {
//      var hash = widget.data['link'].toString().substring(widget.data['link'].toString().lastIndexOf('/') + 1);
//      print(hash);
//      print(widget.data);
//      print('https://api.imgur.com/3/image/$hash');
      var hash = widget.data['cover'];
      var response = await http.get(
        'https://api.imgur.com/3/image/$hash',
        headers: {HttpHeaders.authorizationHeader: "Client-ID $client_id"},
      );
      var data = jsonDecode(response.body)['data'];
      return data['link'];
    } else {
      return widget.data['link'];
    }
  }

  Widget metric(int nb, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        children: <Widget>[
          Icon(icon, color: colorMetrics,),
          VerticalDivider(width: 5,),
          Text('$nb', style: TextStyle(color: colorMetrics),)
        ],
      ),
    );
  }
}