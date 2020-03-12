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
  final StreamQueue<Page> _page;
  Function stopMedia;

  StoryPageScreen(this._page);

  void nextPage(BuildContext context) async{
    if (this.stopMedia == null){
      print("Warning: stopMedia undefined");
    }
    else{
      await stopMedia();
    }
    bool hasNext = await this._page.hasNext;
    if (hasNext) {
      this._page.next;
      Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (BuildContext context) => new StoryPageScreen(this._page)
        )
      );
    }
    else{
      print("Show story end here");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stories")
      ),
      body: FutureBuilder(
        future: this._page.next,
        initialData: SpinKitChasingDots(color: theme.accentColor),
        builder: (BuildContext context, AsyncSnapshot snapshot){
          if (snapshot.connectionState == ConnectionState.done){
            Page data = snapshot.data;
            if (data == null){
              return Column(
                children: [
                  Card(
                    child: ListTile(
                      title: Text("Story finished", style:
                        TextStyle(fontWeight: FontWeight.bold))
                    )
                  )
                ]
              );
            }
            else{
              data.startPageMedia();
              this.stopMedia = data.stopPageMedia;
              return data.render(context);
            }
          }
          else{
            return SpinKitChasingDots(color: theme.accentColor);
          }
        }
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.arrow_forward),
        onPressed: (){
          this.nextPage(context);
        },
      ),
    );
  }
}