import 'dart:convert';
import 'dart:io';

import 'package:epicture/colors.dart';
import 'package:epicture/pictureList.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPage createState() => _SearchPage();
}

class _SearchPage extends State<SearchPage> {
  final TextEditingController _filter = new TextEditingController();
  FocusNode _focusNode;
  ScrollController _scrollController;
  var _timeOpacity = 1.0;
  var _images = [];
  var _tags = [];
  var _values = ['top', 'week', '0'];
  var _lastSearch = ['top', 'week', '0', ''];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _getTags();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: Container(
            child: TextField(
              focusNode: _focusNode,
              onEditingComplete: () async {
                FocusScope.of(context).unfocus();
                await _scrollController.animateTo(0.0, duration: Duration(milliseconds: 500), curve: Curves.easeOut);
                _search();
              },
              style: TextStyle(color: colorText),
              controller: _filter,
              cursorColor: colorText,
              decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: colorText,),
                hintText: 'Search...',
                hintStyle: TextStyle(color: colorText),
              ),
            ),
          ),
      ),
      body: RefreshIndicator(
        color: colorBackground,
        onRefresh: _search,
        child: CustomScrollView(
          cacheExtent: cacheLimit,
          controller: _scrollController,
          scrollDirection: Axis.vertical,
          slivers: <Widget>[
            SliverToBoxAdapter(
                child: Container(
                  height: 100.0,
                  child: ListView.builder(
                      cacheExtent: cacheLimit,
                      addAutomaticKeepAlives: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: _tags.length,
                      itemBuilder: (BuildContext context, int index) {
                        return _tag(_tags[index]);
                      }
                  ),
                )
            ),
            SliverAppBar(
              title: Row(
                children: <Widget>[
                  _dropdown(0, ['top', 'time', 'viral']),
                  VerticalDivider(),
                  Opacity(
                    opacity: _timeOpacity,
                    child: _dropdown(1, ['day', 'week', 'month', 'year', 'all'])
                  ),
                ],
              ),
            ),
            PictureList(pictures: _images,),
          ]
        ),
      ),
    );
  }

  Widget _dropdown(int index, List<String> options) {
    return Theme(
        data: ThemeData(canvasColor: colorBackground),
        child: DropdownButton<String>(
          value: _values[index],
          icon: Icon(Icons.arrow_downward),
          style: TextStyle(
              color: colorText,
              fontSize: 15
          ),
          onChanged: (String newValue) {
            setState(() {
              _values[index] = newValue;
              if (index == 0) {
                if (newValue == "top") {
                  _timeOpacity = 1.0;
                } else {
                  _timeOpacity = 0.0;
                }
              }
            });
            _search();
          },
          items: options
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
                value: value,
                child: Text(value)
            );
          }).toList(),
        )
    );
  }

  Widget _tag(tagData) {
    return InkWell(
      onTap: () { _filter.clear(); _filter.text = '#${tagData['name']}'; _search(); },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
                image: NetworkImage('https://i.imgur.com/${tagData['background_hash']}.png'),
                fit: BoxFit.fitHeight
            )
        ),
        width: 150,
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
              child: Text(tagData['display_name'], style: TextStyle(color: colorText, fontWeight: FontWeight.bold, fontSize: 20))
            ),
          ]
        ),
      )
    );
  }

  Future<Null> _search() async {
    if (_values[0] == _lastSearch[0] &&
        _values[1] == _lastSearch[1] &&
        _values[2] == _lastSearch[2] &&
        _filter.text ==  _lastSearch[3])
      return;
    if (!_filter.text.startsWith('#')) {
      var response = await http.get(
        'https://api.imgur.com/3/gallery/search/${_values[0]}/${_values[1]}/${_values[2]}?q=${_filter.text}',
        headers: {HttpHeaders.authorizationHeader: "Bearer $globalAccessToken"}
      );
      var data = jsonDecode(response.body)['data'];
      setState(() {
        _lastSearch[0] = _values[0];
        _lastSearch[1] = _values[1];
        _lastSearch[2] = _values[2];
        _lastSearch[3] = _filter.text;
        _images = data;
      });
    } else {
      var search = _filter.text.substring(1);
      var response = await http.get(
          'https://api.imgur.com/3/gallery/t/$search',
          headers: {HttpHeaders.authorizationHeader: "Bearer $globalAccessToken"}
      );
      var data = jsonDecode(response.body)['data']['items'];
      setState(() {
        _lastSearch[0] = _values[0];
        _lastSearch[1] = _values[1];
        _lastSearch[2] = _values[2];
        _lastSearch[3] = _filter.text;
        _images = data;
      });
    }
  }

  Future<Null> _getTags() async {
    var response = await http.get(
        'https://api.imgur.com/3/tags',
        headers: {HttpHeaders.authorizationHeader: "Client-ID $globalClientId"}
    );
    var data = jsonDecode(response.body)['data'];
    setState(() {
      _tags = data['tags'];
    });
  }
}