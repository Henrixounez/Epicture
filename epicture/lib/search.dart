import 'dart:convert';
import 'dart:io';

import 'package:epicture/colors.dart';
import 'package:epicture/pictureList.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home.dart';

TextEditingController searchFilter = new TextEditingController();


class SearchPage extends StatefulWidget {
  @override
  SearchPageState createState() => SearchPageState();
}

/// Search for pictures on Imgur using name or tags
class SearchPageState extends State<SearchPage> {
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
    getTags();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: appBarSearch(),
      body: RefreshIndicator(
        color: colorBackground,
        onRefresh: search,
        child: CustomScrollView(
          cacheExtent: cacheLimit,
          controller: _scrollController,
          scrollDirection: Axis.vertical,
          slivers: <Widget>[
            tagsList(),
            sortingMenu(),
            PictureList(pictures: _images,),
          ]
        ),
      ),
    );
  }

  /// Search bar with input text
  /// Upon completion refreshes the current search
  Widget appBarSearch() {
    return AppBar(
      title: Container(
        child: TextField(
          focusNode: _focusNode,
          onEditingComplete: () async {
            FocusScope.of(context).unfocus();
            await _scrollController.animateTo(0.0, duration: Duration(milliseconds: 500), curve: Curves.easeOut);
            search();
          },
          style: TextStyle(color: colorText),
          controller: searchFilter,
          cursorColor: colorText,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: colorText,),
            hintText: 'Search...',
            hintStyle: TextStyle(color: colorText),
          ),
        ),
      ),
    );
  }

  /// List of popular tags on Imgur
  Widget tagsList() {
    return SliverToBoxAdapter(
        child: Container(
          height: 100.0,
          child: ListView.builder(
              cacheExtent: cacheLimit,
              addAutomaticKeepAlives: true,
              scrollDirection: Axis.horizontal,
              itemCount: _tags.length,
              itemBuilder: (BuildContext context, int index) {
                return tagCard(_tags[index]);
              }
          ),
        )
    );
  }

  /// Menu with dropdown for sorting search with type or time window
  Widget sortingMenu() {
    return SliverAppBar(
      title: Row(
        children: <Widget>[
          dropdown(0, ['top', 'time', 'viral']),
          VerticalDivider(),
          Opacity(
              opacity: _timeOpacity,
              child: dropdown(1, ['day', 'week', 'month', 'year', 'all'])
          ),
        ],
      ),
    );
  }

  /// Dropdown menus used by sortingMenu
  /// On click refreshes the current search
  Widget dropdown(int index, List<String> options) {
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
            search();
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

  /// Tag card used by tagsList
  /// Have a name and background images provided by Imgur
  /// On tap searches for selected tag
  Widget tagCard(tagData) {
    return InkWell(
      onTap: () { searchFilter.clear(); searchFilter.text = '#${tagData['name']}'; search(); },
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

  /// Search for current input
  /// If has a # searches for a tag
  /// https://apidocs.imgur.com/?version=latest#3c981acf-47aa-488f-b068-269f65aee3ce
  /// https://apidocs.imgur.com/?version=latest#0f89160b-8bb3-40c5-b17b-a02cc8a2f73d
  Future<Null> search() async {
    if (_values[0] == _lastSearch[0] &&
        _values[1] == _lastSearch[1] &&
        _values[2] == _lastSearch[2] &&
        searchFilter.text ==  _lastSearch[3])
      return;
    if (!searchFilter.text.startsWith('#')) {
      var response = await http.get(
        'https://api.imgur.com/3/gallery/search/${_values[0]}/${_values[1]}/${_values[2]}?q=${searchFilter.text}',
        headers: {HttpHeaders.authorizationHeader: "Bearer $globalAccessToken"}
      );
      var data = jsonDecode(response.body)['data'];
      setState(() {
        _lastSearch[0] = _values[0];
        _lastSearch[1] = _values[1];
        _lastSearch[2] = _values[2];
        _lastSearch[3] = searchFilter.text;
        _images = data;
      });
    } else {
      var search = searchFilter.text.substring(1);
      var response = await http.get(
          'https://api.imgur.com/3/gallery/t/$search/${_values[0]}/${_values[1]}/${_values[2]}',
          headers: {HttpHeaders.authorizationHeader: "Bearer $globalAccessToken"}
      );
      var data = jsonDecode(response.body)['data']['items'];
      setState(() {
        _lastSearch[0] = _values[0];
        _lastSearch[1] = _values[1];
        _lastSearch[2] = _values[2];
        _lastSearch[3] = searchFilter.text;
        _images = data;
      });
    }
  }

  /// Finds popular tags on Imgur
  /// https://apidocs.imgur.com/?version=latest#fbf4474f-5944-4535-80e8-c3219da0b643
  Future<Null> getTags() async {
    var response = await http.get(
        'https://api.imgur.com/3/tags',
        headers: {HttpHeaders.authorizationHeader: "Client-ID $globalClientId"}
    );
    var data = jsonDecode(response.body)['data'];
    if (mounted) {
      setState(() {
        _tags = data['tags'];
      });
    }
  }
}