// Builtin/flutter imports
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';

// Internal imports
import 'package:stories/service_utils.dart';

// External imports
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';

String _photoScope = "https://www.googleapis.com/auth/photoslibrary.readonly";
GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [_photoScope]
);

class PhotoRecord extends ServicePoint{
  int minDuration = 5;
  int maxDuration = 30;

  DateTime created;
  String baseUrl;
  String externalUrl;
  String mimeType;
  String filename;

  Map headers;

  MediaType mediaType = MediaType.photo;

  Map metadata;

  String get viewURL{
    if (this.mimeType.contains("video")){
      return "${this.baseUrl}=dv";
    }
    else{
      // Append width and height parameters to the image bytes
      return "${this.baseUrl}=w${this.metadata["width"]}-h${this.metadata["height"]}";
    }

  }

  bool get isScreenshot{
    /**
     * Try to determine whether or not this photo is a screenshot based on
     * aspect ratio and metadata
     */
    if (this.mediaType == MediaType.photo){
      if (this.metadata.containsKey("photo") &&
          this.metadata["photo"].length > 0){
        return false;
      }
      else{
        // The photo has no metadata on what camera it was taken with.
        // Check to see if the aspect ratio looks like a phone or computer
        int width = int.parse(this.metadata["width"]);
        int height = int.parse(this.metadata["height"]);
        int maxDim = max(width, height);
        int minDim = min(width, height);
        num aspectRatio = (maxDim / minDim);
        // Looks like a phone or desktop aspect ratio
        return (aspectRatio >= 1.5);
      }
    }
    else {
      return false;
    }
  }

  Widget render(BuildContext context){
    return Card(
      child: Column(
        children: [
          Container(
            child: Image(image: NetworkImage(this.viewURL, headers:
            this.headers.cast<String, String>()))
          ),
          ButtonBar(children: [
            IconButton(icon: Icon(Icons.open_in_new), onPressed: (){
              launchURL(this.baseUrl);
            })
          ])
        ]
      )
    );
  }

  Map serialize(){
    Map photoData = {
      "created": this.created.millisecondsSinceEpoch,
      "baseUrl": this.baseUrl,
      "externalUrl": this.externalUrl,
      "mimeType": this.mimeType,
      "filename": this.filename,
      "metadata": this.metadata,
      // TODO: cache these headers independently of all the photo items
      "headers": this.headers
    };
    return photoData;
  }

  PhotoRecord({this.created, this.baseUrl, this.externalUrl, this.mimeType,
              this.filename, this.metadata, this.headers});
}

class GooglePhotos extends ServiceInterface{
  String name="Google Photos";
  // Credit to https://stackoverflow.com/a/49168837 for this solution for maintaining color in an image icon
  Widget icon = new Image(
        image: new AssetImage("assets/google-photos-logo.png"),
        width: 24,
        height: 24,
        color: null,
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
      );
  String description = "Photos from your google photos library";
  GoogleSignInAccount _currentUser;
  bool offersOptions = true;
  Map<DateTime, PhotoRecord> _photos;

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  getPoint(DateTime time){
    try{
      return this._photos[time];
    }
    catch(e){
      return null;
    }
  }

  setPoint(DateTime time, data){
    if (this._photos == null){
      this._photos = {};
    }
    this._photos[time] = PhotoRecord(
      created: DateTime.fromMillisecondsSinceEpoch(data["created"]),
      mimeType: data["mimeType"],
      externalUrl: data["externalUrl"],
      baseUrl: data["baseUrl"],
      filename: data["filename"],
      metadata: data["metadata"],
      headers: data["headers"]
    );
  }

  bool pointIsValid(point){
    // If screenshots are excluded, check to make sure the point is not one
    if (!this.optionValues["include_screenshots"]){
      return !(point.isScreenshot);
    }
    else{
      return true;
    }
  }

  List<DateTime> get timeSeries{
    if (this._photos != null){
      return this._photos.keys.toList();
    }
    else {
      return [];
    }
  }

  Map<DateTime, PhotoRecord> _parseRecords(List responseData, Map headers){
    /**
     * Parse a list of google photos API responses into an internal usable track structure
     */
    Map<DateTime, PhotoRecord> photoAccumulator = {};
    for (Map photoData in responseData){
      Map metadata = photoData["mediaMetadata"];
      String rawCreated = metadata["creationTime"];
      // Parse the creation time into a datetime
      DateTime created = DateTime.parse(rawCreated);
      String filename = photoData["filename"];
      String mimeType = photoData["mimeType"];
      String baseUrl = photoData["baseUrl"];
      String productUrl = photoData["productUrl"];
      // Create the photo object, and associate it with it's creation time
      photoAccumulator[created] = PhotoRecord(created: created,
                                              metadata: metadata,
                                              filename: filename,
                                              mimeType: mimeType,
                                              baseUrl: baseUrl,
                                              externalUrl: productUrl,
                                              headers: headers);
    }
    return photoAccumulator;
  }

  Widget options(){
    this.optionValues["include_screenshots"] = false;
    return CheckboxListTile(
      title: Text("Include screenshots?"),
      value: this.optionValues["include_screenshots"],
      onChanged: (v){
        this.optionValues["include_screenshots"] = v;
      },
    );
  }

  Future<void> doDataDownload() async{
    // https://photoslibrary.googleapis.com/v1/mediaItems
    Map headers = await _currentUser.authHeaders;
    String initialEndpoint = "https://photoslibrary.googleapis.com/v1/mediaItems/?pageSize=100";
    String next = initialEndpoint;
    List dataList = [];
    int reqNum = 0;
    this.loadStatus.add("0 photos processed");
    while (next != null){
      // Request the next page of items
      Response rep = await get(next, headers: headers);
      reqNum++;
      if (rep.statusCode == 200){
        Map responseData = jsonDecode(rep.body);
        if (responseData.keys.contains("nextPageToken") &&
            responseData["nextPageToken"] != null){
           next = initialEndpoint+"&pageToken=${responseData["nextPageToken"]}";
        }
        else{
          next = null;
        }
        dataList += responseData["mediaItems"];
        this.loadStatus.add("${dataList.length} photos processed");
      }
      else{
        print(rep.body);
        this.loadStatus.add("Error");
        next = null;
      }
    }
    Map<DateTime, PhotoRecord> photos = _parseRecords(dataList, headers);
    print("Parsed ${photos.keys.length} photos in $reqNum requests");
    this.loadStatus.add("Done");
    this._photos = photos;
  }

  void doAuth() async{
    if (!this.loaded && _currentUser == null){
      this.loadStatus.add("Waiting for login...");
      _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
        print("Got sign in");
        _currentUser = account;
        this.startDataDownload();
      });
      _handleSignIn();
    }
    else{
      if (this.loaded){
        DateFormat cacheFormat = DateFormat.yMd();
        this.loadStatus.add("Last refreshed on ${cacheFormat.format(this.loadedAt)}");
      }
      else{
        this.startDataDownload();
      }
    }
  }
}