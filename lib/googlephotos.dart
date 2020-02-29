// Builtin/flutter imports
import 'package:flutter/material.dart';
import 'dart:convert';

// Internal imports
import 'package:stories/service_utils.dart';

// External imports
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';

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

  PhotoRecord({this.created, this.baseUrl, this.externalUrl, this.mimeType,
              this.filename, this.metadata});
}

class GooglePhotos extends ServiceInterface{
  String name="Google Photos";
  Icon icon = Icon(FontAwesomeIcons.google);
  GoogleSignInAccount _currentUser;

  Map<DateTime, PhotoRecord> _photos;

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Map<DateTime, PhotoRecord> _parseRecords(List responseData){
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
                                              externalUrl: productUrl);
    }
    return photoAccumulator;
  }

  Future<void> doDataDownload() async{
    // https://photoslibrary.googleapis.com/v1/mediaItems
    Map headers = await _currentUser.authHeaders;
    String initialEndpoint = "https://photoslibrary.googleapis.com/v1/mediaItems/?pageSize=100";
    String next = initialEndpoint;
    List dataList = [];
    int reqNum = 0;
    while (next != null){
      // Request the next page of items
      Response rep = await get(next, headers: headers);
      reqNum++;
      print("$reqNum, ${dataList.length}");
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
      }
      else{
        print(rep.body);
        next = null;
      }
    }
    Map<DateTime, PhotoRecord> photos = _parseRecords(dataList);
    print("Parsed ${photos.keys.length} photos in $reqNum requests");
    this._photos = photos;
  }

  void doOauth() async{
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
        print("Got sign in");
        _currentUser = account;
        this.startDataDownload();
    });
    _handleSignIn();
  }
}