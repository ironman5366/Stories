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
  Map<String, String> loadStatus = {};

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
    List<Widget> tiles = [];
    for (ServiceInterface service in selected){
      String status = "Loading...";
      if (this.loadStatus.keys.contains(service.name)) {
        status = this.loadStatus[service.name];
      }
      tiles.add(ListTile(
        leading: service.icon,
        title: Text(service.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(status)
      ));
    }
    return tiles;
  }

  List<Widget> getServiceTiles(List<ServiceInterface> services){
    List<Widget> tiles = [];
    Size size = MediaQuery.of(context).size;
    double tileWidth = size.width * 0.3;
    double tileHeight = size.height * 0.2;
    for (ServiceInterface service in services){
        // The decoration for the tile, will be a checkmark if selected
        BoxDecoration tileDec;
        Function onPressed;
        // .contains won't work for this, so use this test
        bool contained = selected.any((s) => s.name == service.name);
        if (contained) {
          tileDec = BoxDecoration(
            color: theme.splashColor,
            borderRadius: const BorderRadius.all(
                Radius.circular(8.0)
            ),
            border: Border.all(color: theme.splashColor)
          );
          onPressed = (){
            setState(() {
              // .remove doesn't work here either, so we iterate
              for (int i=0; i<selected.length; i++){
                if (selected[i].name == service.name){
                  selected.removeAt(i);
                  break;
                }
              }
              });
            };
        }
        else{
          tileDec = BoxDecoration(
            borderRadius: const BorderRadius.all(
                Radius.circular(8.0)
            ),
          );
          onPressed = (){
            service.loadStatus.stream.listen((String d){
              setState(() {
                this.loadStatus[service.name] = d;
              });
            });
            service.doOauth();
            setState((){
              selected.add(service);
            });
          };
          }
          tiles.add(GestureDetector(
            child: Card(child: Container(
                width: tileWidth,
                height: tileHeight,
                decoration: tileDec,
                  child: ListTile(
                    leading: Container(
                        child: service.icon,
                        width: size.width * 0.1,
                        height: size.width * 0.1
                    ),
                title: Text(service.name, style: TextStyle(fontWeight: FontWeight.bold))
            ))
          ),
            onTap: onPressed
        ));
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
