// Builtin imports
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:stories/service_utils.dart';
import 'dart:async';

// Internal imports
import 'package:stories/variables.dart';
import 'package:stories/story_utils.dart';
import 'package:stories/story_page_screen.dart';

// External imports
import 'package:uni_links/uni_links.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class OptionsStep extends StatelessWidget{
  final Story story;

  OptionsStep(this.story);

  void startStory(BuildContext context) async{
    Iterator<Page> pageIt = this.story.pages().iterator;
    pageIt.moveNext();
    Navigator.push(context,
      new MaterialPageRoute(
        builder: (BuildContext context) => new StoryPageScreen(pageIt)
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> serviceOptions = [];
    for (ServiceInterface service in this.story.services){
      if (service.offersOptions){
        serviceOptions.add(
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(service.name, style:
                    TextStyle(fontWeight: FontWeight.bold)),
                  leading: service.icon
                ),
                service.options()
              ]
            )
          )
        );
      }
    }
    List<Widget> listChildren = [];
    listChildren.addAll(serviceOptions);
    listChildren.addAll(this.story.yearSelector());
    listChildren.add(
        CupertinoButton(child: Text("Continue"),
            color: theme.accentColor,
            onPressed: (){
              this.startStory(context);
            })
    );
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
          // TODO: get this to work without shrinkWrapping because in some cases there will be too many options
          ListView(
            shrinkWrap: true,
            children: listChildren
          )
        ]
      )
    );
  }
}