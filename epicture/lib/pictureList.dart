import 'package:epicture/image.dart';
import 'package:flutter/cupertino.dart';

class PictureList extends StatelessWidget {
  PictureList({Key key, this.pictures}) : super(key: key);
  var pictures = [];

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
          return ImgurImage(
            key: ValueKey(index),
            data: this.pictures[index],
          );
        },
        childCount: pictures.length,
        addAutomaticKeepAlives: true,
      ),
    );
  }
}