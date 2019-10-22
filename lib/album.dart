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
  AlbumState createState() => AlbumState();
}

/// Album Page
/// * Displays all album pictures and descriptions
/// * Tags and Comments of the album are available below the image list
class AlbumState extends State<Album> {
  ScrollController _scrollController;
  var _comments = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    getComments();
  }

  /// Fetch comments from API with album ID
  /// https://apidocs.imgur.com/?version=latest#b95843d0-0036-4486-8e64-152338f88872
  void getComments() async {
    var response = await http.get(
      'https://api.imgur.com/3/gallery/${widget.images['id']}/comments/best',
      headers: {HttpHeaders.authorizationHeader: "Client-ID $globalClientId"}
    );
    if (mounted) {
      setState(() {
        if (response.statusCode == 200)
          _comments = jsonDecode(response.body)['data'];
        else
          _comments = [];
      });
    }
  }

  /// Post vote on album to API
  /// If up or down, vote accordingly
  /// If undoing a vote, sends veto
  /// https://apidocs.imgur.com/?version=latest#23e5f110-318a-4872-9888-1bb1f864b360
  void vote(bool upvote) async {
    String lastVote = widget.images['vote'];
    String vote = "up";
    if (!upvote) {
      vote = "down";
    }
    if (vote == widget.images['vote']) {
      vote = "veto";
    }
    await http.post('https://api.imgur.com/3/gallery/${widget.images['id']}/vote/$vote',
        headers: {HttpHeaders.authorizationHeader: 'Bearer $globalAccessToken'});
    setState(() {
      widget.images['vote'] = vote;
      if (lastVote == "up")
        widget.images['ups']--;
      if (lastVote == "down")
        widget.images['downs']--;
      if (vote == "up")
        widget.images['ups']++;
      if (vote == "down")
        widget.images['downs']++;
    });
  }

  /// Favorites an Image or Album.
  /// Undoing a favorite is handled by the API.
  /// Modify the state for the Favorite Icon to be of the right type
  /// https://apidocs.imgur.com/?version=latest#31c72664-59c1-426f-98d7-ac7ad6547cc2
  /// https://apidocs.imgur.com/?version=latest#5dd1c471-a806-43cb-9067-f5e4fc8f28bd
  void favImage() async {
    if (widget.images['is_album']) {
      await http.post('https://api.imgur.com/3/album/${widget.images['id']}/favorite',
          headers: {HttpHeaders.authorizationHeader: 'Bearer $globalAccessToken'});
    } else {
      await http.post('https://api.imgur.com/3/image/${widget.images['cover']}/favorite',
          headers: {HttpHeaders.authorizationHeader: 'Bearer $globalAccessToken'});
    }
    setState(() {
      widget.images['favorite'] = !widget.images['favorite'];
    });
  }

  /// AppBar has action buttons for Voting or Favorite
  /// ScrollView with in order :
  ///    Album title, description, poster username and date of post
  ///    Picture list (AlbumPicture)
  ///    Tags List
  ///    Comments (AlbumComments)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBottomAppBar,
        actions: <Widget>[
          MaterialButton(minWidth: 0, onPressed: () {vote(true); }, child: Icon(Icons.keyboard_arrow_up, color: (widget.images['vote'] == 'up') ? Colors.green : colorMetrics, size: 30,)),
          MaterialButton(minWidth: 0, onPressed: () {vote(false);}, child: Icon(Icons.keyboard_arrow_down, color: (widget.images['vote'] == 'down') ? Colors.red : colorMetrics, size: 30)),
          MaterialButton(minWidth: 0, onPressed: () {favImage(); }, child: widget.images['favorite'] ? Icon(Icons.favorite, color: colorFavorite,) : Icon(Icons.favorite_border, color: colorMetrics,)),
        ],
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
                      (widget.images['account_url'] != null ? widget.images['account_url'] : 'unknown') + ' • ' + getTimeago(widget.images['datetime']),
                      style: TextStyle(color: colorFadedText),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ),
            AlbumPicture(data: widget.images),
            SliverToBoxAdapter(
              child: widget.images['tags'] != null ? (Wrap(
                children: widget.images['tags'].map<Widget>((tag) { return tagCard(tag); }).toList()
              )) : Text('')
            ),
            SliverToBoxAdapter(
              child: Divider(height: 30,),
            ),
            AlbumComments(comments: _comments, depth: 0,),
          ],
        ),
    );
  }

  /// Creates a Tag card with background and name
  Widget tagCard(tagData) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
              image: NetworkImage('https://i.imgur.com/${tagData['background_hash']}.png'),
              fit: BoxFit.fitHeight
          )
      ),
      width: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Color.fromRGBO(0, 0, 0, 100)
              ),
              child: Text(tagData['display_name'], style: TextStyle(color: colorText, fontWeight: FontWeight.bold, fontSize: 10))
          ),
        ]
      ),
    );
  }
}

class AlbumPicture extends StatefulWidget {
  const AlbumPicture({Key key, this.data}) : super(key: key);
  final data;

  AlbumPictureState createState() => AlbumPictureState();
}

/// Pictures for Album
/// * Creates a list of Pictures to be used in Album Class
class AlbumPictureState extends State<AlbumPicture> {
  var _data = {};

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  /// Fetch album images data from API
  /// https://apidocs.imgur.com/?version=latest#5369b915-ad8b-47b1-b44b-8e2561e41cee
  void fetchData() async {
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

  /// Creates a list of Images using ImageLoader (image.dart)
  /// Additional info in list with image title and description
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

  AlbumCommentsState createState() => AlbumCommentsState();
}

/// Comments for Album
/// * Creates a list of Comments to be used in Album Class or in an other AlbumComments Class
/// * Recursively called when comments replies are expanded
class AlbumCommentsState extends State<AlbumComments> {
  List<bool> showChildren;

  @override
  void initState() {
    super.initState();
  }

  /// Creates a list of Comments for comments list in data
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
                  header(index),
                  Divider(height: 3,),
                  Text(widget.comments[index]['comment'], style: TextStyle(color: colorText, fontSize: 14),),
                  Divider(height: 5,),
                  showChildren[index] ? (
                    children(index)
                  ) : (
                    (widget.comments[index]['children'] != null && widget.comments[index]['children'].length > 0) ? (
                    showButton(index)
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

  /// Header of comment with author username, date of post and points
  Widget header(index) {
    return Wrap(
      children: <Widget>[
        Text(widget.comments[index]['author'], style: TextStyle(color: colorText, fontSize: 15, fontWeight: FontWeight.bold),),
        VerticalDivider(),
        Text(getTimeago(widget.comments[index]['datetime']), style: TextStyle(color: colorFadedText, fontSize: 14),),
        VerticalDivider(),
        Text('${widget.comments[index]['points']} pts', style: TextStyle(color: colorFadedText, fontSize: 14),),
      ],
    );
  }

  /// Displaying of comments children by calling recursively AlbumComments class
  /// Have a close button to hide children
  Widget children(index) {
    return Column(
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
          onTap: () {
            setState(() {
              if (widget.comments[index]['children'] != null && widget.comments[index]['children'].length > 0)
                showChildren[index] = !showChildren[index];
            });
          },
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
    );
  }

  /// If comment have children, display a button with number of replies
  /// When button is tapped, displays comment children
  Widget showButton(index) {
    return InkWell(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        child: Text('${widget.comments[index]['children'].length} replies', style: TextStyle(color: colorMetrics, fontSize: 14)),
        decoration: BoxDecoration(
          color: colorMiddle,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      onTap: () {
        setState(() {
          if (widget.comments[index]['children'] != null && widget.comments[index]['children'].length > 0)
            showChildren[index] = !showChildren[index];
        });
      },
    );
  }
}