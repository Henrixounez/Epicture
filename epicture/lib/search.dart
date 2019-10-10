import 'dart:convert';
import 'dart:io';

import 'package:epicture/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:epicture/image.dart';
import 'package:http/http.dart' as http;
import 'home.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPage createState() => _SearchPage();
}

class _SearchPage extends State<SearchPage> {
  final TextEditingController _filter = new TextEditingController();
  bool seaching = false;
  IconButton _leadingIcon = null;
  IconButton _endIcon = null;
  Widget _appBarTitle = Text('Search on Imgur');
  var _images = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      this._endIcon = IconButton(
        icon: Icon(Icons.search),
        onPressed: _searchPressed,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        leading: _leadingIcon,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: _endIcon
          )
        ],
        title: _appBarTitle,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
              child: RefreshIndicator(
                  child: ListView.builder(
                    itemCount: _images.length,
                    itemBuilder: (BuildContext ctx, int index) {
                      return ImgurImage(key: ValueKey(index),data: _images[index]);
                    },
                    addAutomaticKeepAlives: true,
                  ),
                  onRefresh: (){},
//                  onRefresh: _refresh
              )
          )
        ],
      ),
    );
  }

  void _searchPressed() {
    setState(() {
      if (!seaching) {
        seaching = true;
        this._leadingIcon = IconButton(
            icon: Icon(Icons.search),
            onPressed: _search
        );
        this._endIcon = IconButton(
          icon: Icon(Icons.close),
          onPressed: _searchPressed,
        );
        this._appBarTitle = TextField(
          style: TextStyle(color: Colors.white),
          controller: _filter,
          cursorColor: Colors.white,
          decoration: InputDecoration(
            prefixIcon: null,
            hintText: 'Search...',
            hintStyle: TextStyle(color: Colors.white),
          ),
        );
      } else {
        seaching = false;
        this._leadingIcon = null;
        this._endIcon = IconButton(
          icon: Icon(Icons.search),
          onPressed: _searchPressed,
        );
        this._appBarTitle = Text('Search on Imgur !');
        _filter.clear();
      }
    });
  }

  void _search() async {
    var sort = 'time';
    var window = 'month';
    var page = '1';
    var response = await http.get(
      'https://api.imgur.com/3/gallery/search/$sort/$window/$page?q=${_filter.text}',
      headers: {HttpHeaders.authorizationHeader: "Client-ID $global_client_id"}
    );
    var data = jsonDecode(response.body)['data'];
    print(response.body);
    print(data);
    setState(() {
      _images = data;
    });
  }
}