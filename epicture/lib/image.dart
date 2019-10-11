import 'dart:convert';
import 'dart:io';

import 'package:epicture/colors.dart';
import 'package:epicture/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;

class ImgurImage extends StatefulWidget {
  const ImgurImage({Key key, @required this.data}) : super(key: key);
  final data;

  _ImgurImageState createState() => _ImgurImageState();
}

class _ImgurImageState extends State<ImgurImage> {
  var data = {};
  Future<String> avatar_url;
  Future<String> img_url;
  bool got_avatar = false;

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
    if (widget.data['id']!= data['id']) {
      setState(() {
        data = widget.data;
        avatar_url = getAvatar();
        img_url = getImg();
      });
    }
    if (data['link'] == null) {
      return Text('Loading');
    }
    var title = getTitle();
    var username = data['account_url'] != null ? data['account_url'] : 'unknown';
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
                            username + ' • ' + get_timeago() + get_section(),
                            style: TextStyle(color: Colors.white70),
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
              Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Row(
                  children: <Widget>[
                    metric(data['views'], Icons.remove_red_eye),
                    metric(data['ups'], Icons.keyboard_arrow_up),
                    metric(data['downs'], Icons.keyboard_arrow_down),
                  ],
                ),
              ),
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
    if (data['title'] != null) {
      return data['title'];
    }
    if (data['description'] != null) {
      return data['description'];
    }
    return ' ';
  }

  Future<String> getAvatar() async {
    if (widget.data['account_url'] == null) {
      return '';
    }
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
    var link = widget.data['link'].toString();
    if (!(link.endsWith('.png') || link.endsWith('.jpg') || link.endsWith('.gif'))) {
      var hash = widget.data['cover'];
      var response = await http.get(
        'https://api.imgur.com/3/image/$hash',
        headers: {HttpHeaders.authorizationHeader: "Client-ID $global_client_id"},
      );
      var data = jsonDecode(response.body)['data'];
      return data['link'];
    } else {
      return widget.data['link'];
    }
  }

  String get_timeago() {
    final startTime = DateTime.fromMillisecondsSinceEpoch(data['datetime'] * 1000);
    final now = DateTime.now();
    final diff = now.difference(startTime);
    final time = timeago.format(now.subtract(diff), locale: 'en_short');
    return time;
  }

  String get_section() {
    if (data['section'] != null && data['section'] != '')
      return (' / ' + data['section']);
    else
      return '';
  }

  Widget metric(int nb, IconData icon) {
    if (nb != null) {
      return Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: colorMetrics,),
            VerticalDivider(width: 5,),
            Text('$nb', style: TextStyle(color: colorMetrics),)
          ],
        )
      );
    } else {
      return Spacer();
    }
  }
}