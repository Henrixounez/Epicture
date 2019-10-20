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
import 'package:cached_network_image/cached_network_image.dart';

var loaded = 0;

/// Returns formatted string showing time of upload relative to now
String getTimeago(date) {
  if (date == null)
    return '';
  final startTime = DateTime.fromMillisecondsSinceEpoch(date * 1000);
  final now = DateTime.now();
  final diff = now.difference(startTime);
  final time = timeago.format(now.subtract(diff), locale: 'en_short');
  return time;
}

class ImgurImage extends StatefulWidget {
  const ImgurImage({Key key, @required this.data}) : super(key: key);
  final data;

  ImgurImageState createState() => ImgurImageState();
}

/// ImgurImage used for displaying Images with more information
class ImgurImageState extends State<ImgurImage> {
  var data = {};
  Future<String> avatarUrl;
  bool gotAvatar = false;
  bool isInit = false;

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
        isInit = true;
      });
    }
  }

  /// Fetch more information about an Image or Album
  /// https://apidocs.imgur.com/?version=latest#5369b915-ad8b-47b1-b44b-8e2561e41cee
  void getData() async {
    var hash = widget.data['id'];
    var response = await http.get(
      'https://api.imgur.com/3/album/$hash',
      headers: {HttpHeaders.authorizationHeader: "Bearer $globalAccessToken"},
    );
    if (widget.data['is_album'] == true) {
      if (mounted) {
        setState(() {
          data = jsonDecode(response.body)['data'];
          isInit = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          data['images'] = {jsonDecode(response.body)};
          isInit = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isInit && data['id'] != widget.data['id']) {
      data = widget.data;
      avatarUrl = getAvatar();
      getData();
    }
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
              header(title, username),
              image(),
              footer(),
            ],
          )
        ),
        Divider(height: 30,)
      ]
    );
  }

  /// Image header with information
  /// * Poster Avatar
  /// * Title
  /// * Poster Username
  /// * Time of post
  /// * Is album
  /// Favorite button
  /// On click, open the album
  Widget header(title, username) {
    return InkWell(
      onTap: () {
        if (data['is_album'] != null && data['is_album'])
          Navigator.push(context, MaterialPageRoute(builder: (context) => Album(key: ValueKey(data['id']), images: data)));
      },
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
                            username + ' • ' + getTimeago(data['datetime']) + getAlbum() + getSection(),
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
                    onPressed: favImage,
                    child: data['favorite'] ? Icon(Icons.favorite, color: colorFavorite,) : Icon(Icons.favorite_border, color: colorMetrics,),
                  )
                ],
              ),
              Divider(color: Colors.transparent, height: 5,),
            ],
          )
      ),
    );
  }

  /// Display image using ImageLoader
  /// On click open the image fullscreen with BigPicture
  Widget image() {
    return InkWell(
      onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => BigPicture(data: data)));},
      child: ImageLoader(data: data, index: 0,),
    );
  }

  /// Image footer with information
  /// * Metric of views
  /// * Metric of upvotes
  /// * Metric of downvotes
  /// Voting by clicking on upvote or downvote
  Widget footer() {
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            children: <Widget>[
              metric(data['views'], Icon(Icons.remove_red_eye, color: colorMetrics,)),
              metricButton(data['ups'], Icon(Icons.keyboard_arrow_up, color: (data['vote'] == 'up') ? Colors.green : colorMetrics, size: 30,), () {vote(true);}),
              metricButton(data['downs'], Icon(Icons.keyboard_arrow_down, color: (data['vote'] == 'down') ? Colors.red : colorMetrics, size: 30), () {vote(false);}),
            ],
          ),
        ),
      ],
    );
  }

  /// Favorites an Image or Album.
  /// Undoing a favorite is handled by the API.
  /// Modify the state for the Favorite Icon to be of the right type
  /// https://apidocs.imgur.com/?version=latest#31c72664-59c1-426f-98d7-ac7ad6547cc2
  /// https://apidocs.imgur.com/?version=latest#5dd1c471-a806-43cb-9067-f5e4fc8f28bd
  void favImage() async {
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

  /// Post vote on album to API
  /// If up or down, vote accordingly
  /// If undoing a vote, sends veto
  /// https://apidocs.imgur.com/?version=latest#23e5f110-318a-4872-9888-1bb1f864b360
  void vote(bool upvote) async {
    String lastVote = data['vote'];
    String vote = "up";
    if (!upvote) {
      vote = "down";
    }
    if (vote == data['vote']) {
      vote = "veto";
    }
    await http.post('https://api.imgur.com/3/gallery/${data['id']}/vote/$vote',
    headers: {HttpHeaders.authorizationHeader: 'Bearer $globalAccessToken'});
    setState(() {
      data['vote'] = vote;
      if (lastVote == "up")
        data['ups']--;
      if (lastVote == "down")
        data['downs']--;
      if (vote == "up")
        data['ups']++;
      if (vote == "down")
        data['downs']++;
    });
  }

  /// Finds title of image
  /// If not available gives description
  String getTitle() {
    if (data['title'] != null) {
      return data['title'];
    }
    if (data['description'] != null) {
      return data['description'];
    }
    return ' ';
  }

  /// Fetch Avatar of the uploader to show on header
  /// https://apidocs.imgur.com/?version=latest#6427d23d-2ad2-44e3-846d-65d7b042afbd
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

  /// Find image section if available
  String getSection() {
    if (data['section'] != null && data['section'] != '')
      return (' / ' + data['section']);
    else
      return '';
  }

  /// Find if is an album
  String getAlbum() {
    if (data['is_album'] != null) {
      return ' • Album';
    } else {
      return '';
    }
  }

  /// Widget for metrics with interaction (Used by Upvotes or Downvotes)
  Widget metricButton(int nb, Icon icon, function) {
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

  /// Widget for metrics
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

  ImageLoaderState createState() => ImageLoaderState();
}

/// Class for asynchronous Image or Video Loading
class ImageLoaderState extends State<ImageLoader> {
  Future<String> imgUrl;
  VideoPlayerController _videoController;
  bool _videoLoaded = false;
  var data = {};
  var isInit = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      data = widget.data;
      imgUrl = getImg();
      isInit = true;
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (_videoController != null) {
      _videoController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isInit && data['id'] != widget.data['id']) {
      setState(() {
        data = widget.data;
        imgUrl = getImg();
      });
    }
    return FutureBuilder(
      future: imgUrl,
      builder: imageBuilder
    );
  }

  /// ImageBuilder used in FutureBuilder
  /// When loading displays a CircularProgressIndicator
  /// Save needed height when loading to prevent list to list shift after loading
  /// Upon data loaded displays either
  /// * an Image using CachedNetworkImage
  /// * a Video using MyVideoPlayer
  Widget imageBuilder(context, snapshot) {
    var neededHeight = findNeededHeight();
    if (neededHeight == -1)
      return Text('');
    if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
      if (!snapshot.data.toString().endsWith('.mp4')) {
        return Container(
            height: neededHeight,
            child: CachedNetworkImage(
              filterQuality: FilterQuality.none,
              imageUrl: snapshot.data,
              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
            )
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
  }

  /// Finds neededHeight to save upon width and height
  /// If width is larger than phone width, calculate the ratio to apply for the needed height
  double findNeededHeight() {
    var width = widget.data['width'];
    var height = widget.data['height'];

    if (width == null || height == null) {
      width = widget.data['cover_width'];
      height = widget.data['cover_height'];
    }
    if (widget.data.isEmpty) {
      return -1;
    }
    var neededHeight = height / (width / MediaQuery.of(context).size.width);
    if (width < MediaQuery.of(context).size.width)
      neededHeight = height.toDouble();
    return neededHeight;
  }

  /// Finds the image or video link
  /// If not available search more info of Image on API
  /// https://apidocs.imgur.com/?version=latest#2078c7e0-c2b8-4bc8-a646-6e544b087d0f
  /// If a video sets up the videoController to be displayed by MyVideoPlayer
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
          var __videoController = new VideoPlayerController.network(link)..initialize();
          setState(() {
            _videoController = __videoController;
            _videoLoaded = true;
          });
          __videoController.setLooping(true);
          __videoController.setVolume(0);
        }
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

  VideoPlayerState createState() => VideoPlayerState();
}

/// Video Displayer with additional buttons for sound and play/pause
/// Video is loaded with VideoPlayer plugin
class VideoPlayerState extends State<MyVideoPlayer> {
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

  /// Sound button to mute the video
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

  /// Play button to stop or play the video
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

/// Displays a picture or video fullscreen
/// Closes with a gesture
class BigPicture extends StatelessWidget {
  const BigPicture({Key key, this.data}) : super(key: key);
  final data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragEnd: (data) { Navigator.of(context).pop();},
          child: Center(child: ImageLoader(data: data, index: 0)),
        ),
      )
    );
  }
}