// Builtin imports
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:stories/service_utils.dart';
import 'dart:async';

// Internal imports
import 'package:stories/variables.dart';
import 'package:stories/spotify.dart';
import 'package:stories/story_utils.dart';

// External imports
import 'package:uni_links/uni_links.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class StoryPageScreen extends StatelessWidget{
  final Iterator<Page> _page;

  StoryPageScreen(this._page);

  @override
  Widget build(BuildContext context) {
    Page current = this._page.current;
    print("Got current");
    return Scaffold(
      appBar: AppBar(
        title: Text("Stories")
      ),
      body: this._page.current.render(context),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.arrow_forward),
        onPressed: (){
          if (this._page.moveNext()){
            Navigator.push(
              context,
              new MaterialPageRoute(
                builder: (BuildContext context) => StoryPageScreen(this._page)
              )
            );
          }
          else{
            print("Done");
          }
        },
      ),
    );
  }
}