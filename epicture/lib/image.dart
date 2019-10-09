import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ImgurImage extends StatelessWidget {
  var data = {};

  ImgurImage({@required this.data});

  @override
  Widget build(BuildContext context) {
    var title = getTitle();
    if (data['link'] == null) {
      return Text('Loading');
    }
    print(data);
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
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Divider(color: Colors.transparent, height: 5,),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Text(
                        data['account_url'],
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            )
          ),
          Image.network(data['link']),
          Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  metric(data['views'], Icons.remove_red_eye),
                ],
              )
            ],
          ),
          Divider(),
        ],
      )
    );
  }

  String getTitle() {
    if (data['description'] != null) {
      return data['description'];
    }
    if (data['title'] != null) {
      return data['title'];
    }
    return 'title';
  }

  Widget metric(int nb, IconData icon) {
    return Container(
      child: Row(
        children: <Widget>[
          Icon(icon, color: Colors.white,),
          Text('$nb', style: TextStyle(color: Colors.white),)
        ],
      ),
    );
  }
}