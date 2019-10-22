import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class IosStyleToast extends StatefulWidget {
  Color backgroundColor;
  Color iconColor;
  String text;

  IosStyleToast({this.backgroundColor, this.iconColor, this.text});

  @override
  _IosStyleToastState createState() => _IosStyleToastState();
}

/// Toast notifications IOS-like
/// Use with showOverlay((context, t) {return Opacity(opacity: t, child: IosStyleToast(),);});
class _IosStyleToastState extends State<IosStyleToast> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: widget.backgroundColor,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.check,
                      color: widget.iconColor,
                    ),
                    Text(widget.text)
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}