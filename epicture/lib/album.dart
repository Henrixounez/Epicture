import 'dart:convert';
import 'dart:io';

import 'package:epicture/colors.dart';
import 'package:epicture/home.dart';
import 'package:epicture/image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:http/http.dart' as http;

class Album extends StatefulWidget {
  const Album({Key key, this.images}) : super(key: key);
  final images;

  @override
  _AlbumState createState() => _AlbumState();
}

class _AlbumState extends State<Album> {
  ScrollController _scrollController;
  var _comments = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    getComments();
  }

  void getComments() async {
    var response = await http.get(
      'https://api.imgur.com/3/gallery/${widget.images['id']}/comments/best',
      headers: {HttpHeaders.authorizationHeader: "Client-ID $globalClientId"}
    );
    if (mounted) {
      setState(() {
        _comments = jsonDecode(response.body)['data'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBottomAppBar,
        title: Text('', style: TextStyle(color: colorText),),
      ),
      body: CustomScrollView(
          cacheExtent: 1000,
          scrollDirection: Axis.vertical,
          controller: _scrollController,
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    widget.images['title'] != null ? Text(widget.images['title'], style: TextStyle(color: colorText, fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.left,) : Text(''),
                    widget.images['description'] != null ? Text(widget.images['description'], style: TextStyle(color: colorText, fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.left,) : Text(''),
                    Text(
                      (widget.images['account_url'] != null ? widget.images['account_url'] : 'unknown') + ' • ' + _getTimeago(),
                      style: TextStyle(color: colorFadedText),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ),
            AlbumPicture(data: widget.images),
            SliverToBoxAdapter(
              child: Divider(height: 30,),
            ),
            AlbumComments(comments: _comments, depth: 0,),
          ],
        ),
    );
  }

  String _getTimeago() {
    if (widget.images['datetime'] == null)
      return '';
    final startTime = DateTime.fromMillisecondsSinceEpoch(widget.images['datetime'] * 1000);
    final now = DateTime.now();
    final diff = now.difference(startTime);
    final time = timeago.format(now.subtract(diff), locale: 'en_short');
    return time;
  }
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
    var response = await http.get(
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
      return SliverToBoxAdapter(
        child: Divider(),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Container(
            child: Column(
              children: <Widget>[
                ImageLoader(data: _data, index: index,),
                _data['images'][index]['title'] != null ? Text(_data['images'][index]['title'], style: TextStyle(color: colorText, fontSize: 20),) : Divider(height: 0,),
                _data['images'][index]['description'] != null ? Text(_data['images'][index]['description'], style: TextStyle(color: colorText, fontSize: 15), softWrap: true,) : Divider(height: 0,),
                Divider(height: 20,)
              ],
            ),
          );
        },
        childCount: _data['images'].length,
      ),
    );
  }
}

class AlbumComments extends StatefulWidget {
  const AlbumComments({Key key, @required this.comments, @required this.depth});
  final comments;
  final depth;

  _AlbumCommentsState createState() => _AlbumCommentsState();
}

class _AlbumCommentsState extends State<AlbumComments> {
  List<bool> showChildren;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (showChildren == null || showChildren.isEmpty) {
      setState(() {
        showChildren = new List.filled(widget.comments.length, false, growable: true);
      });
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return InkWell(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            onLongPress: () {setState(() {if (widget.comments[index]['children'] != null && widget.comments[index]['children'].length > 0) showChildren[index] = !showChildren[index];});},
            child: Container(
              padding: EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 5),
              margin: EdgeInsets.only(top: 5, bottom: 5, left: 3, right: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Color.fromRGBO(52 + widget.depth * 10, 55 + widget.depth * 10, 60 + widget.depth * 10, 1),
                boxShadow: [BoxShadow(
                  color: Colors.black,
                  blurRadius: 5.0,
                )],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(widget.comments[index]['author'], style: TextStyle(color: colorText, fontSize: 15, fontWeight: FontWeight.bold),),
                      VerticalDivider(),
                      Text(_getTimeago(widget.comments[index]['datetime']), style: TextStyle(color: colorFadedText, fontSize: 14),),
                      VerticalDivider(),
                      Text('${widget.comments[index]['points']} pts', style: TextStyle(color: colorFadedText, fontSize: 14),),
                    ],
                  ),
                  Divider(height: 3,),
                  Text(widget.comments[index]['comment'], style: TextStyle(color: colorText, fontSize: 14),),
                  Divider(height: 5,),
                  showChildren[index] ? (
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        InkWell(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                            child: Text('Close', style: TextStyle(color: colorMetrics, fontSize: 14)),
                            decoration: BoxDecoration(
                              color: colorMiddle,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onTap: () {setState(() {if (widget.comments[index]['children'] != null && widget.comments[index]['children'].length > 0) showChildren[index] = !showChildren[index];});},
                        ),
                        CustomScrollView(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          slivers: <Widget>[
                            AlbumComments(comments: widget.comments[index]['children'], depth: widget.depth + 1,)
                          ],
                        ),
                      ],
                    )
                  ) : (
                    (widget.comments[index]['children'] != null && widget.comments[index]['children'].length > 0) ? (
                      InkWell(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                          child: Text('${widget.comments[index]['children'].length} replies', style: TextStyle(color: colorMetrics, fontSize: 14)),
                          decoration: BoxDecoration(
                            color: colorMiddle,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onTap: () {setState(() {if (widget.comments[index]['children'] != null && widget.comments[index]['children'].length > 0) showChildren[index] = !showChildren[index];});},
                      )
                    ) : (
                      Text('')
                    )
                  )
                ],
              ),
            )
          );
        },
        childCount: widget.comments.length,
      )
    );
  }

  String _getTimeago(int date) {
    if (date == null)
      return '';
    final startTime = DateTime.fromMillisecondsSinceEpoch(date * 1000);
    final now = DateTime.now();
    final diff = now.difference(startTime);
    final time = timeago.format(now.subtract(diff), locale: 'en_short');
    return time;
  }
}