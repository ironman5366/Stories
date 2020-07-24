// Builtin imports
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:stories/service_utils.dart';
import 'dart:async';
import 'package:async/async.dart';

// Internal imports
import 'package:stories/variables.dart';
import 'package:stories/spotify.dart';
import 'package:stories/story_utils.dart';

// External imports
import 'package:uni_links/uni_links.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class StoryPageScreen extends StatelessWidget{
  final List<StoryPage> _page;
  Function stopMedia;

  StoryPageScreen(this._page);

  void nextPage(BuildContext context) async{
    if (this.stopMedia == null){
      print("Warning: stopMedia undefined");
    }
    else{
      await stopMedia();
    }
    if (this._page.length == 0) {
      print("Show end here");
    }
    else{
      Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (BuildContext context) => new StoryPageScreen(this._page)
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    StoryPage currPage = this._page.removeAt(0);
    currPage.startPageMedia();
    this.stopMedia = currPage.stopPageMedia;
    return Scaffold(
      appBar: AppBar(
        title: Text("Stories")
      ),
      body: currPage.render(context),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.arrow_forward),
        onPressed: (){
          this.nextPage(context);
        },
      ),
    );
  }
}