import 'dart:convert';
import 'dart:io';

import 'package:epicture/album.dart';
import 'package:epicture/colors.dart';
import 'package:epicture/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';

class ImgurImage extends StatefulWidget {
  const ImgurImage({Key key, @required this.data}) : super(key: key);
  final data;

  _ImgurImageState createState() => _ImgurImageState();
}

class _ImgurImageState extends State<ImgurImage> {
  var data = {};
  Future<String> avatarUrl;
  bool gotAvatar = false;

  @override
  void initState() {
    super.initState();
    if (!gotAvatar) {
      avatarUrl = getAvatar();
    }
    if (widget.data['images'] == null) {
      getData();
    } else {
      setState(() {
        data = widget.data;
      });
    }
  }

  void getData() async {
    var hash = widget.data['id'];
    var response = await http.get(
      'https://api.imgur.com/3/album/$hash',
      headers: {HttpHeaders.authorizationHeader: "Bearer $globalAccessToken"},
    );
    if (mounted) {
      setState(() {
        data = jsonDecode(response.body)['data'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data['link'] == null) {
      return Divider();
    }
    var title = getTitle();
    var username = data['account_url'] != null ? data['account_url'] : 'unknown';
    return Column(
      children: <Widget> [
        Container(
          decoration: BoxDecoration(
            color: colorImageBackground,
            boxShadow: [BoxShadow(
              color: Colors.black,
              blurRadius: 20.0,
            )]
          ),
          child: Column(
            children: <Widget>[
              InkWell(
                onTap: () {if (data['is_album']) Navigator.push(context, MaterialPageRoute(builder: (context) => Album(key: ValueKey(data['id']), images: data)));},
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          FutureBuilder(
                            future: avatarUrl,
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
                                  style: TextStyle(color: colorText, fontWeight: FontWeight.w800, fontSize: 15),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  username + ' • ' + getTimeago() + getAlbum() + getSection(),
                                  style: TextStyle(color: colorFadedText),
                                  textAlign: TextAlign.left,
                                ),
                              ],
                            )
                          ),
                          FloatingActionButton(
                            heroTag: null,
                            elevation: 0,
                            backgroundColor: colorImageBackground,
                            onPressed: _favImage,
                            child: data['favorite'] ? Icon(Icons.favorite, color: colorFavorite,) : Icon(Icons.favorite_border, color: colorMetrics,),
                          )
                        ],
                      ),
                      Divider(color: Colors.transparent, height: 5,),
                    ],
                  )
                ),
              ),
              ImageLoader(data: data, index: 0,),
              Column(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    child: Row(
                      children: <Widget>[
                        metric(data['views'], Icon(Icons.remove_red_eye, color: colorMetrics,)),
                        metric_button(data['ups'], Icon(Icons.keyboard_arrow_up, color: (data['vote'] == 'up') ? Colors.green : colorMetrics, size: 30,), () {_vote(true);}),
                        metric_button(data['downs'], Icon(Icons.keyboard_arrow_down, color: (data['vote'] == 'down') ? Colors.red : colorMetrics, size: 30), () {_vote(false);}),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          )
        ),
        Divider(height: 30,)
      ]
    );
  }

  void _favImage() async {
    if (data['is_album']) {
      await http.post('https://api.imgur.com/3/album/${data['id']}/favorite',
      headers: {HttpHeaders.authorizationHeader: 'Bearer $globalAccessToken'});
    } else {
      await http.post('https://api.imgur.com/3/image/${data['cover']}/favorite',
      headers: {HttpHeaders.authorizationHeader: 'Bearer $globalAccessToken'});
    }
    setState(() {
      data['favorite'] = !data['favorite'];
    });
  }

  void _vote(bool upvote) async {
    String last_vote = data['vote'];
    String vote = "up";
    if (!upvote) {
      vote = "down";
    }
    if (vote == data['vote']) {
      vote = "veto";
    }
    await http.post('https://api.imgur.com/3/gallery/${data['id']}/vote/${vote}',
    headers: {HttpHeaders.authorizationHeader: 'Bearer $globalAccessToken'});
    setState(() {
      data['vote'] = vote;
      if (last_vote == "up")
        data['ups']--;
      if (last_vote == "down")
        data['downs']--;
      if (vote == "up")
        data['ups']++;
      if (vote == "down")
        data['downs']++;
    });
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
      headers: {HttpHeaders.authorizationHeader: "Bearer $globalAccessToken"},
    );
    var data = jsonDecode(response.body)['data'];
    if (mounted) {
      setState(() {
        gotAvatar = true;
      });
    }
    return data['avatar'];
  }

  String getTimeago() {
    if (data['datetime'] == null)
      return '';
    final startTime = DateTime.fromMillisecondsSinceEpoch(data['datetime'] * 1000);
    final now = DateTime.now();
    final diff = now.difference(startTime);
    final time = timeago.format(now.subtract(diff), locale: 'en_short');
    return time;
  }

  String getSection() {
    if (data['section'] != null && data['section'] != '')
      return (' / ' + data['section']);
    else
      return '';
  }

  String getAlbum() {
    if (data['is_album'] != null) {
      return ' • Album';
    } else {
      return '';
    }
  }
  Widget metric_button(int nb, Icon icon, function) {
    if (nb != null) {
      return Expanded(
        child: FlatButton(
          onPressed: function,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              icon,
              VerticalDivider(width: 5,),
              Text('$nb', style: TextStyle(color: colorMetrics),)
            ],
          )
        ),
      );
    } else {
      return Spacer();
    }
  }

  Widget metric(int nb, Icon icon) {
    if (nb != null) {
      return Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            icon,
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

class ImageLoader extends StatefulWidget {
  const ImageLoader({Key key, @required this.data, @required this.index}) : super(key: key);
  final data;
  final int index;

  _ImageLoaderState createState() => _ImageLoaderState();
}

class _ImageLoaderState extends State<ImageLoader> {
  Future<String> imgUrl;
  VideoPlayerController _videoController;
  bool _videoLoaded = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      imgUrl = getImg();
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (_videoController != null) {
      print('disposed !');
      _videoController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: imgUrl,
      builder: (context, snapshot) {
        var width = widget.data['width'];
        var height = widget.data['height'];
        if (width == null || height == null) {
          width = widget.data['cover_width'];
          height = widget.data['cover_height'];
        }
        if (widget.data.isEmpty) {
          return Text('');
        }
        var neededHeight = height / (width / MediaQuery.of(context).size.width);
        if (width < MediaQuery.of(context).size.width)
          neededHeight = height.toDouble();
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          print(snapshot.data);
          if (!snapshot.data.toString().endsWith('.mp4')) {
            return Container(
              height: neededHeight,
              child: Image.network(snapshot.data),
            );
          } else {
            if (_videoLoaded && _videoController != null) {
              return MyVideoPlayer(controller: _videoController, height: neededHeight,);
            } else {
              return Container(
                  height: neededHeight,
                  child: Icon(Icons.play_circle_outline, color: colorText, size: 50,)
              );
            }
          }
        } else {
          return Container(
              height: neededHeight,
              child: Center(child: CircularProgressIndicator())
          );
        }
      },
    );
  }

  Future<String> getImg() async {
    if (widget.data == null) {
      return '';
    }
    var link = widget.data['link'];
    if (!(link.endsWith('.png') || link.endsWith('.jpg') || link.endsWith('.gif'))) {
      if (widget.data['images'] != null) {
        link = widget.data['images'][widget.index]['link'];
        var type = widget.data['images'][widget.index]['type'];
        if (type.startsWith('video/') || widget.data['images'][widget.index]['mp4'] != null) {
          if (link == null || link == '') {
            link = widget.data['images'][widget.index]['mp4'];
          }
          setState(() {
            _videoController = new VideoPlayerController.network(link)..initialize();
            _videoLoaded = true;
          });
          _videoController.setLooping(true);
          _videoController.setVolume(0);
        }
        print(link);
        return link;
      } else {
        var hash = widget.data['cover'];
        var response = await http.get(
          'https://api.imgur.com/3/image/$hash',
          headers: {HttpHeaders.authorizationHeader: "Client-ID $globalClientId"},
        );
        var _data = jsonDecode(response.body)['data'];
        return _data['link'];
    }
    } else {
      return widget.data['link'];
    }
  }
}

class MyVideoPlayer extends StatefulWidget {
  const MyVideoPlayer({Key key, this.controller, this.height}) : super(key: key);
  final VideoPlayerController controller;
  final double height;

  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<MyVideoPlayer> {
  bool displayButtons = true;
  bool paused = true;
  bool sound = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      child: Stack(
        children: <Widget>[
          VideoPlayer(widget.controller),
          Align(
            alignment: Alignment.bottomRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FloatingActionButton(
                  heroTag: null,
                  onPressed: soundButton,
                  child: sound ? Icon(Icons.volume_up, color: colorText, size: 50,) : Icon(Icons.volume_off, color: colorText, size: 50),
                  backgroundColor: Colors.transparent,
                  elevation: 0
                ),
                FloatingActionButton(
                  heroTag: null,
                  onPressed: playButton,
                  child: paused ? Icon(Icons.play_arrow, color: colorText, size: 50,) : Icon(Icons.pause, color: colorText, size: 50),
                  backgroundColor: Colors.transparent,
                  elevation: 0
                ),
              ],
            )
          ),
        ],
      )
    );
  }

  void soundButton() {
    if (sound) {
      widget.controller.setVolume(0);
    } else {
      widget.controller.setVolume(100);
    }
    setState(() {
      sound = !sound;
    });
  }

  void playButton() {
    if (paused) {
      widget.controller.play();
    } else {
      widget.controller.pause();
    }
    setState(() {
      paused = !paused;
    });
  }
}