import 'dart:convert';
import 'dart:io';

import 'package:epicture/colors.dart';
import 'package:epicture/home.dart';
import 'package:epicture/image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Album extends StatefulWidget {
  const Album({Key key, this.images}) : super(key: key);
  final images;

  @override
  _AlbumState createState() => _AlbumState();
}

class _AlbumState extends State<Album> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBottomAppBar,
        title: Text('', style: TextStyle(color: colorText),),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  widget.images['title'] != null ? Text(widget.images['title'], style: TextStyle(color: colorText, fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.left,) : Text(''),
                  widget.images['description'] != null ? Text(widget.images['description'], style: TextStyle(color: colorText, fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.left,) : Text(''),
                ],
              )
            ),
            Expanded(
                child: AlbumPicture(data: widget.images),
            ),
          ]
        )
      )
    );
  }

//  Future<Widget> albumPicture(index) async {
//    return
//                  }
//    return Container(
//        child: Column(
//          children: <Widget>[
//            ImageLoader(data: _data);
//          ],
//        )
//    );
//  }

}

class AlbumPicture extends StatefulWidget {
  const AlbumPicture({Key key, this.data}) : super(key: key);
  final data;

  _AlbumPictureState createState() => _AlbumPictureState();
}

class _AlbumPictureState extends State<AlbumPicture> {
  var _data = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    var hash = widget.data['id'];
//    var hash = widget.data.images['images'][widget.index]['id'];
    var response = await http.get(
//      'https://api.imgur.com/3/image/$hash',
      'https://api.imgur.com/3/album/$hash',
      headers: {HttpHeaders.authorizationHeader: "Client-ID $globalClientId"},
    );
    if (mounted) {
      setState(() {
        _data = jsonDecode(response.body)['data'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null || _data['images'] == null) {
      return Divider();
    }
    return ListView.builder(
      itemCount: _data['images'].length,
      cacheExtent: cacheLimit,
      itemBuilder: (BuildContext context, int index) {
        print(_data['images'][index]);
        return Container(
          child: Column(
            children: <Widget>[
              ImageLoader(data: _data, index: index,)
//              ImageLoader(data: _data['images'][index])
            ],
          ),
        );
      }
    );
  }
}