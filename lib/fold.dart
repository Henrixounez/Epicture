import 'package:epicture/uploader.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:folding_cell/folding_cell.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';

import 'colors.dart';
import 'uploader.dart';

class FoldingCellSimpleDemo extends StatefulWidget {
  bool loading;
  int response;
  String title;

  FoldingCellSimpleDemo({this.response, this.loading, this.title});

  @override
  FoldingCellSimpleDemoState createState() => FoldingCellSimpleDemoState();
}

/// A animation class that creates three panels that fold to each other
class FoldingCellSimpleDemoState extends State<FoldingCellSimpleDemo> {
  final _foldingCellKey = GlobalKey<SimpleFoldingCellState>();

  Color colorTile;
  String messageFolded;

  /// Setup the folding animation to open the folder by default
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _foldingCellKey?.currentState?.toggleFold();
    });
    colorTile = colorGreen;
    messageFolded = "${widget.title} is uploaded !";
  }

  /// When the widget is updated, check the parent response and act accordingly
  /// If content was uploaded, close the folder and setup a quit timer
  /// If error has occured, changes folder colors, close it and go back to uploader
  @override
  void didUpdateWidget(FoldingCellSimpleDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.response == 200) {
      Timer(Duration(seconds: 2), () {
        Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
      });
    } else {
      setState(() {
        colorTile = colorFavorite;
        messageFolded = "Failed to upvote.";
      });
      Timer(Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    }
    _foldingCellKey?.currentState?.toggleFold();
  }

  /// Builds the folder
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF2e282a),
      alignment: Alignment.topCenter,
      child: SimpleFoldingCell(
          key: _foldingCellKey,
          frontWidget: _buildFrontWidget(),
          innerTopWidget: _buildInnerTopWidget(),
          innerBottomWidget: _buildInnerBottomWidget(),
          cellSize: Size(MediaQuery.of(context).size.width, 125),
          padding: EdgeInsets.all(15),
          animationDuration: Duration(milliseconds: 300),
          borderRadius: 10,
          onOpen: () => print('cell opened'),
          onClose: () => print('cell closed')),
    );
  }

  /// Front folder. Its what you see when folder is closed
  Widget _buildFrontWidget() {
    return Container(
        color: colorTile,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(messageFolded,
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                    fontSize: 20.0,
                    fontWeight: FontWeight.w800)),
          ],
        ));
  }

  /// Top folder. Its what you see during loading
  Widget _buildInnerTopWidget() {
    return Container(
        color: colorFavorite,
        alignment: Alignment.center,
        child: Text("${widget.title}",
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'OpenSans',
                fontSize: 20.0,
                fontWeight: FontWeight.w800)
        ));
  }

  /// Bottom folder. Its where you look at the loading animation
  Widget _buildInnerBottomWidget() {
    return Container(
      color: colorMiddle,
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Row(
          children: <Widget>[
            VerticalDivider(
              width: 20.0,
            ),
            Text("Uploading your content ...",
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                    fontSize: 20.0,
                    fontWeight: FontWeight.w800)
            ),
            VerticalDivider(
              width: 20.0,
            ),
            SpinKitFoldingCube(
              color: Colors.white,
              size: 50.0,
            )
          ],
        )
      ),
    );
  }
}

/// Route that defines a fading animation
class TestRoute extends CupertinoPageRoute {
  TestRoute()
      : super(builder: (BuildContext context) => Test());


  // OPTIONAL IF YOU WISH TO HAVE SOME EXTRA ANIMATION WHILE ROUTING
  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return new FadeTransition(opacity: animation, child: Test());
  }
}

class Test extends StatefulWidget {
  Test({Key key, this.parent, this.title}) : super(key: key);
  UploadFlutterState parent;
  String title;


  @override
  TestState createState() => TestState();
}

/// Contains the folding animation.
/// Interface it with it parents and handle the update logic
class TestState extends State<Test> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: colorBackground,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FoldingCellSimpleDemo(
              response: widget.parent.responseUpload,
              loading: widget.parent.loading,
              title: widget.title
            ),
          ],
        ),

      ),
    );
  }
}