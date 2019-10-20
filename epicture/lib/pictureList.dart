import 'package:epicture/image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Creates a list of pictures using ImgurImage (image.dart)
class PictureList extends StatelessWidget {
  PictureList({Key key, this.pictures}) : super(key: key);
  final pictures;

  @override
  Widget build(BuildContext context) {
    if (pictures == null) {
      return SliverToBoxAdapter(
        child: Container(),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return new ImgurImage(
            key: ValueKey(index),
            data: this.pictures[index],
          );
        },
        childCount: pictures.length,
      ),
    );
  }
}