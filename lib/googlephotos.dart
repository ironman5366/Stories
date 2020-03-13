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
  String externalUrl;
  String mimeType;
  String filename;
  String id;
  Map headers;
  String baseUrl;
  NetworkImage _renderedImage;

  MediaType mediaType = MediaType.photo;

  Map metadata;

  Future<void> preRender() async{
    Response rep = await
      get("https://photoslibrary.googleapis.com/v1/mediaItems/${this.id}",
        headers: this.headers.cast<String, String>());
    Map photoData = jsonDecode(rep.body);
    this.baseUrl = photoData["baseUrl"];
    // Also start loading the image ahead of time
    this._renderedImage = NetworkImage(this.viewURL);
  }

  String get viewURL{
    // Scale the image
    int width = int.parse(this.metadata["width"]);
    int height = int.parse(this.metadata["height"]);
    int optimalHeight = 600;
    int newHeight;
    int newWidth;
    if (height <= optimalHeight){
      newHeight = height;
      newWidth = width;
    }
    else{
      newHeight = optimalHeight;
      newWidth = (optimalHeight * (width / height)).toInt();
    }
    if (this.mimeType.contains("video")){
      return "${this.baseUrl}=dv";
    }
    else{
      // Append width and height parameters to the image bytes
      return "${this.baseUrl}=w$newWidth-h$newHeight";
    }
  }

  bool get isLandscape{
    return int.parse(this.metadata["width"]) >=
        int.parse(this.metadata["height"]);
  }

  int compareTo(p){
    PhotoRecord photo = p;
    bool isLandscape = this.isLandscape;
    bool photoIsLandscape = photo.isLandscape;
    // Prefer landscape photos,
    if (isLandscape || photoIsLandscape){
      if (isLandscape){
        if (!photoIsLandscape){
          return 1;
        }
      }
      else{
        return -1;
      }
    }
    // If neither or both is landscape, compare datetimes
    return this.created.compareTo(photo.created);
  }

  ///
  /// Try to determine whether or not this photo is a screenshot based on
  /// aspect ratio and metadata
  bool get isScreenshot{
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
            child: Image(image: this._renderedImage)
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
      "externalUrl": this.externalUrl,
      "mimeType": this.mimeType,
      "filename": this.filename,
      "metadata": this.metadata,
      "id": this.id
    };
    return photoData;
  }

  PhotoRecord({this.created, this.baseUrl, this.externalUrl, this.mimeType,
              this.filename, this.metadata, this.id, this.headers});
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
  Map _headers;

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
        filename: data["filename"],
        metadata: data["metadata"],
        headers: this._headers,
        id: data["id"]
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

  Future<void> onStart() async{
    if (this._currentUser == null){
      GoogleSignInAccount account = await _googleSignIn.signInSilently();
      // If this account is null, cache won't be loaded anyway because user hasn't signed in before.
      if (account != null){
        this._currentUser = account;
        this._headers = await account.authHeaders;
      }
    }
  }

  Map<DateTime, PhotoRecord> _parseRecords(List responseData, Map headers){
    /**
     * Parse a list of google photos API responses into an internal usable track structure
     */
    List<String> processedIds = [];
    Map<DateTime, PhotoRecord> photoAccumulator = {};
    for (Map photoData in responseData){
      Map metadata = photoData["mediaMetadata"];
      String rawCreated = metadata["creationTime"];
      if (!metadata.containsKey("photo") || metadata["photo"].keys.length == 0){
        continue;
      }
      // Parse the creation time into a datetime
      DateTime created = DateTime.parse(rawCreated);
      String filename = photoData["filename"];
      String mimeType = photoData["mimeType"];
      String productUrl = photoData["productUrl"];
      String id = photoData["id"];
      // Don't add the same photo twice
      if (processedIds.contains(id)){
        continue;
      }
      // Create the photo object, and associate it with it's creation time
      photoAccumulator[created] = PhotoRecord(created: created,
                                              metadata: metadata,
                                              filename: filename,
                                              mimeType: mimeType,
                                              externalUrl: productUrl,
                                              headers: headers,
                                              id: id
                                            );
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

  Future<List> _doPhotosDownload(String initialEndpoint, Map next, {int initNum: 0}) async{
    List dataList = [];
    this.loadStatus.add("$initNum photos processed");
    while (next != null){
      // Request the next page of items
      Response rep = await post(initialEndpoint, headers: this._headers,
          body: jsonEncode(next));
      if (rep.statusCode == 200){
        Map responseData = jsonDecode(rep.body);
        if (responseData.keys.contains("nextPageToken") &&
            responseData["nextPageToken"] != null){
          next["pageToken"] = responseData["nextPageToken"];
        }
        else{
          next = null;
        }
        dataList += responseData["mediaItems"];
        this.loadStatus.add("${dataList.length+initNum} photos processed");
      }
      else{
        print(rep.body);
        this.loadStatus.add("Error");
        next = null;
      }
    }
    return dataList;
  }

  Future<void> doDataDownload() async{
    // https://photoslibrary.googleapis.com/v1/mediaItems:search
    Map headers = this._headers;
    String initialEndpoint = "https://photoslibrary.googleapis.com/v1/mediaItems:search";
    // Try not to include any photos that could have sensitive information,
    // like documents, or any pictures that would likely be
    // less nostalgic
    Map reqData = {
      "filters": {
        "contentFilter": {
          "includedContentCategories": [
            "PEOPLE",
            "WEDDINGS",
            "BIRTHDAYS",
            "TRAVEL",
            "PERFORMANCES",
            "CITYSCAPES",
            "LANDMARKS",
          ],
          "excludedContentCategories": [
            "HOUSES",
            "DOCUMENTS",
            "RECEIPTS",
            "SELFIES",
            "FOOD"
          ]
        },
        "mediaTypeFilter": {
          "mediaTypes": [
            "PHOTO"
          ]
        }
      },
      "pageSize": 100
    };
    List dataList = [];
    dataList.addAll(await _doPhotosDownload(initialEndpoint, reqData));
    Map featureData = {
        "filters": {
          "featureFilter": {
            "includedFeatures": [
              "FAVORITES"
            ]
          },
          "mediaTypeFilter": {
            "mediaTypes": [
              "PHOTO"
            ]
          }
      },
      "pageSize": 100
    };
    this.loadStatus.add("Processing favorites...");
    dataList.addAll(await _doPhotosDownload(initialEndpoint, featureData,
        initNum: dataList.length));
    // After processing normal pictures, process favorites
    Map<DateTime, PhotoRecord> photos = _parseRecords(dataList, headers);
    print("Parsed ${photos.keys.length} photos");
    this.loadStatus.add("Done");
    this._photos = photos;
    this.downloading = false;
  }

  /// Log in to google, set headers, and optionally call callback
  Future<void> doLoginSequence({Function callback}) async{
    void setHeaders() async{
      this._headers = await _currentUser.authHeaders;
    }
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      print("Got sign in ${account.displayName}");
      _currentUser = account;
      setHeaders();
      if (callback != null){
        callback();
      }
    });
    await _handleSignIn();
  }

  void doAuth() async{
    if (!this.loaded && _currentUser == null){
      doLoginSequence(callback: this.startDataDownload);
    }
    else{
      // Sign in has to happen regardless for fresh headers for photo get, so do this as well
      void doLoad(){
        if (this.loaded){
          DateFormat cacheFormat = DateFormat.yMd();
          this.loadStatus.add("Last refreshed on ${cacheFormat.format(this.loadedAt)}");
        }
        else{
          this.startDataDownload();
        }
      }
      if (_currentUser == null){
        doLoginSequence(callback: doLoad);
      }
      else{
        doLoad();
      }
    }
  }
}