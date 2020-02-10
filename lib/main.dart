// Builtin imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'dart:async';



// Internal imports
import 'package:stories/variables.dart';
import 'package:stories/spotify.dart';

// External imports
import 'package:uni_links/uni_links.dart';


void main() => runApp(Stories());

class Stories extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stories',
      theme: theme,
      home: Home(title: 'Stories'),
    );
  }
}

class Home extends StatefulWidget {
  Home({Key key, this.title}) : super(key: key);


  final String title;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  StreamSubscription _sub;

  Future<Null> initUniLinks(Map serviceCallbacks) async {
    // ... check initialLink

    // Attach a listener to the stream
    _sub = getLinksStream().listen((String link) {
        print("Got link $link");
    }, onError: (err) {
      // Handle exception by warning the user their action did not succeed
    });

    _sub.onData((var data){
      for (String key in serviceCallbacks.keys){
        if (data.contains(key)){
          bool successful = serviceCallbacks[key].acknowledgeOauthKey(data);
          if (successful){
            // TODO: also change the widget state here
            // Start downloading the data for this widget
            serviceCallbacks[key].startDownloadingData();
          }
          else{
            print("Service error");
          }
        }
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    Spotify spotify = Spotify();
    Map authCallbacks = {
      "stories-oauth://spotify-callback": spotify
    };
    initUniLinks(authCallbacks);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Placeholder',
            ),
            RaisedButton(child: Text("Press me"), onPressed: ( ){
              spotify.doOauth();
            })
        ]
      ),
    )
    );
  }
}
