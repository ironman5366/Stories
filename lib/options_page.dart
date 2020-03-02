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


class OptionsStep extends StatelessWidget{
  final Story story;

  OptionsStep(this.story);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stories")
      ),
      body: Column(
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.settings_applications),
              title: Text("Step 2: Options", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Select different options, and configure your story")
            )
          ),
          this.story.yearSelector(),
          CupertinoButton(child: Text("Continue"),
                          color: theme.accentColor,
                          onPressed: (){
                            print("Next screen");
                          })
        ]
      )
    );
  }
}