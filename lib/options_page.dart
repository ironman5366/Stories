// Builtin imports
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:stories/service_utils.dart';
import 'dart:async';
import 'package:async/async.dart';

// Internal imports
import 'package:stories/variables.dart';
import 'package:stories/story_utils.dart';
import 'package:stories/story_page_screen.dart';

// External imports
import 'package:uni_links/uni_links.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoadingStep extends StatelessWidget{
  final Future<List<StoryPage>> pageFuture;

  LoadingStep(this.pageFuture);


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
                leading: Icon(Icons.hourglass_empty),
                title: Text("Step 3: Loading", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Building your story, please wait...")
            )
        ),
        FutureBuilder(
          initialData: SpinKitChasingDots(color: theme.accentColor),
          future: this.pageFuture,
          builder: (BuildContext context, AsyncSnapshot snapshot){
            if (snapshot.connectionState == ConnectionState.done){
              List<StoryPage> data = snapshot.data;
              return CupertinoButton(
                child: Text("Start story"),
                color: theme.accentColor,
                onPressed: (){
                  Navigator.push(context,
                      new MaterialPageRoute(
                          builder: (BuildContext context) => new StoryPageScreen(data)
                      )
                  );
                }
              );
            }
            else{
              return SpinKitChasingDots(color: theme.accentColor);
            }
          }
        )
      ]
      )
    );
  }
}


class OptionsStep extends StatefulWidget {
  final Story story;

  OptionsStep(this.story);

  @override
  _OptionsState createState() => new _OptionsState();
}

class _OptionsState extends State<OptionsStep>{
  List<Widget> yearOps;

  void startStory(BuildContext context) async{
    Future<List<StoryPage>> pages = this.widget.story.pages();
    Navigator.push(context,
        new MaterialPageRoute(
            builder: (BuildContext context) => new LoadingStep(pages)
        )
    );
  }

  void buildYears(){
    print("Changing state...");
    setState(() {
      this.yearOps = widget.story.yearSelector(this.buildYears);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (this.yearOps == null){
      this.yearOps = widget.story.yearSelector(this.buildYears);
    }
    List<Widget> serviceOptions = [];
    for (ServiceInterface service in widget.story.services){
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
    listChildren.addAll(yearOps);
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