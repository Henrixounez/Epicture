import 'dart:async';

import 'package:camera/camera.dart';
import 'package:epicture/colors.dart';
import 'package:epicture/search.dart';
import 'package:flutter/material.dart';
import 'camera.dart';
import 'search.dart';
import 'home.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/src/messages/lookupmessages.dart';

class CustomMessages implements LookupMessages {
  String prefixAgo() => '';
  String prefixFromNow() => '';
  String suffixAgo() => '';
  String suffixFromNow() => '';
  String lessThanOneMinute(int seconds) => 'now';
  String aboutAMinute(int minutes) => '1min';
  String minutes(int minutes) => '${minutes}min';
  String aboutAnHour(int minutes) => '~1h';
  String hours(int hours) => '${hours}h';
  String aDay(int hours) => '~1d';
  String days(int days) => '${days}d';
  String aboutAMonth(int days) => '~1mo';
  String months(int months) => '$months mo';
  String aboutAYear(int year) => '~1y';
  String years(int years) => '${years}y';
  String wordSeparator() => ' ';
}


Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error');
  }
  timeago.setLocaleMessages('en_short', CustomMessages());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Epicture',
      theme: ThemeData(
        primarySwatch: materialcolorBackground,
        backgroundColor: materialcolorBackground,
        accentColor: Colors.white
      ),
        home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;

  PageController pageController = PageController(
    initialPage: 0,
    keepPage: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          pageChanged(index);
        },
        children: <Widget>[
          HomePage(),
          SearchPage(),
          CameraExampleHome(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colorBackground,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: selectedIndex,
        onTap: (index) {
          bottomTapped(index);
        },
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              title: Text('Home')
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.search),
              title: Text('Search')
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              title: Text('Picture')
          )
        ]
      ),
    );
  }

  void pageChanged(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void bottomTapped(int index) {
    setState(() {
      selectedIndex = index;
      pageController.animateToPage(
          index, duration: Duration(milliseconds: 500), curve: Curves.ease);
    });
  }
}