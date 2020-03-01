// Builtin imports
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:stories/googlephotos.dart';
import 'package:stories/service_utils.dart';
import 'dart:async';



// Internal imports
import 'package:stories/variables.dart';
import 'package:stories/spotify.dart';

// External imports
import 'package:uni_links/uni_links.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


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
  List<ServiceInterface> selected = [];

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
            serviceCallbacks[key].startDataDownload();
          }
          else{
            print("Service error");
          }
        }
      }
    });
  }

  List<Widget> get selectedServices{
    return [];
  }

  List<Widget> getServiceTiles(List<ServiceInterface> services){
    List<Widget> tiles = [];
    for (ServiceInterface service in services){
      if (!selected.contains(service)){
          tiles.add(GestureDetector(
          child: Card(
            child: ListTile(
              leading: service.icon,
              title: Text(service.name, style: TextStyle(fontWeight: FontWeight.bold))
            )
          )
        ));
      }
    }
    return tiles;
  }

  Widget getContinueButton(){
    bool enabled = false;
    String buttonText = "Select at least 2 services";
    if (this.selected.length >= 2){
      bool allDone = true;
      for (ServiceInterface s in this.selected){
        if (!s.loaded){
          allDone = false;
          break;
        }
      }
      enabled = allDone;
      if (allDone){
        buttonText = "Continue";
      }
      else{
        buttonText = "Waiting for services to load...";
      }
    }
    if (enabled){
      return CupertinoButton(child: Text(buttonText), onPressed: (){
        print("Continue!");
      }, color: theme.accentColor);
    }
    else{
      return CupertinoButton(child: Text(buttonText));
    }
  }

  @override
  Widget build(BuildContext context) {
    Spotify spotify = Spotify();
    GooglePhotos googlePhotos = GooglePhotos();
    Map authCallbacks = {
      "stories-oauth://spotify-callback": spotify,
      "stories-oauth://googlephotos-callback": googlePhotos
    };
    List<ServiceInterface> services = [spotify, googlePhotos];
    initUniLinks(authCallbacks);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body:
        Column(
          children: <Widget>[
            Card(
              child: ListTile(
                leading: Icon(FontAwesomeIcons.clipboardCheck),
                title: Text("Step 1: Choose your services", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Choose at least 2 of the services listed below")
              )
            ),
            Card(
              child: Column(
                children: selectedServices
              )
            ),
            GridView.count(padding: EdgeInsets.all(5.0),
                    crossAxisCount: 2,
                    children: getServiceTiles(services),
                    shrinkWrap: true,
                    ),
            getContinueButton()
        ]
    )
    );
  }
}
