// Builtin/Flutter imports
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:convert/convert.dart';

// Internal imports
import 'package:stories/variables.dart';

// External imports
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';



launchURL(String url) async {
  try{
    launch(url);
  }
  catch (e){
    print("Error launching url ${url}");
    print(e);
  }
}

enum MediaType{
  photo,
  audio,
  text
}

class ServicePoint{
  int minDuration;
  int maxDuration;
  ServiceInterface service;

  // If the service has a signature color (for example Spotify green), add it here
  Color color = theme.accentColor;

  MediaType mediaType;

  Widget render(BuildContext context){
    throw UnimplementedError();
  }

  serialize(){
    throw UnimplementedError();
  }
}

class ServiceInterface{
  String name;
  Widget icon;
  String description;
  SharedPreferences _prefs;
  Map _keys;
  DateTime loadedAt;
  bool loaded;
  bool downloading = false;
  StreamController<String> loadStatus;
  Map optionValues = {};
  bool offersOptions = false;

  Map shapeData(){
    /**
     * The function that shapes data from the service into a usable timeseries
     */
    throw UnimplementedError();
  }

  Widget options(){
    throw UnimplementedError();
  }

  Future _loadCredentials() async{
    await rootBundle.loadStructuredData("assets/credentials.json",
            (jsonStr) async{
          Map credentials = jsonDecode(jsonStr);
          this._keys = credentials;
        });
  }

  Future loadKey(String key) async{
    if (this._keys == null){
      await this._loadCredentials();
    }
    return this._keys[key];
  }

  List<DateTime> get timeSeries{
    throw UnimplementedError();
  }

  bool acknowledgeOauthKey(String initialLink){
    throw UnimplementedError();
  }

  getPoint(DateTime time){
    /**
     * A method that should return an event associated with a specific time,
     * or null. There is no specification of what type the returned event is,
     * but it should contain a serialize() method that returns JSON serializable
     * data
     */
    throw UnimplementedError();
  }

  setPoint(DateTime time, data){
    /**
     * A method that should set the internal event within a service to a value,
     * where data is JSON serializable
     */
    throw UnimplementedError();
  }

  bool pointIsValid(point){
    /**
     * A method to check if a given point matches the criterion for the fucntion
     */
    return true;
  }

  List<int> get years{
    /**
     * Return the years that this service has data for
     */
    // Sort the time series
    List<DateTime> times = this.timeSeries;
    List<int> currYears = [];
    for (DateTime t in times){
      if (!currYears.contains(t.year)){
        currYears.add(t.year);
      }
    }
    return currYears;
  }

  List<ServicePoint> pointsInRange(DateTime start, DateTime end){
    /**
     * Get all the points that fall between start and end. End must be after
     * start
     */
    assert(end.isAfter(start));
    List<DateTime> times = this.timeSeries;
    List<ServicePoint> p = [];
    for (DateTime t in times){
      if (t.isAfter(start) && t.isBefore(end)){
        p.add(this.getPoint(t));
      }
    }
    return p;
  }

  List<ServicePoint> pointsInYear(int year){
    /**
     * A helper function to call pointsInRange for a certain year.
     * Start from one microsecond from the beginning of the year, end right
     * after the year ends
     */
    DateTime yearStart = DateTime(year).subtract(Duration(microseconds: 1));
    DateTime yearEnd = DateTime(year+1);
    return pointsInRange(yearStart, yearEnd);
  }

  void doCache() async{
    Map cacheData = {"loadedAt": this.loadedAt.millisecondsSinceEpoch,
    "data": {}};
    for (DateTime time in this.timeSeries){
      // JSON encoded maps must have string keys
      cacheData["data"][time.millisecondsSinceEpoch.toString()] = getPoint(time).serialize();
    }
    print("Caching ${cacheData['data'].length} datapoints under key ${this._cacheName}");
    _writeCache(cacheData);
  }

  Future<void> doDataDownload() async{
    throw UnimplementedError();
  }

  void refresh(){
    this.loaded = false;
    this.doAuth();
  }

  void startDataDownload() async{
    /**
     * Download the data. Cache should likely be called when this is done
     */
    // Set downloading = true to prevent multiple downloads
    if (!this.downloading && !this.loaded){
      print("Starting ${this.name} download");
      DateTime startTime = DateTime.now();
      await this.doDataDownload();
      DateTime endTime = DateTime.now();
      this.downloading = false;
      // Use inMilliseconds instead of inSeconds because we're interested in fractional seconds
      double secondsTaken = (endTime.difference(startTime).inMilliseconds / 1000);
      print("Finished ${this.name} download, took $secondsTaken seconds");
      this.loadedAt = startTime;
      this.loadStatus.add("Caching...");
      this.doCache();
      this.loaded = true;
      this.loadStatus.add("Done");
      // Close the load status subscription
      this.loadStatus.close();
    }
  }

  String get _cacheName{
    return "${this.name}_service_cache";
  }

  bool get _isCached{
    return (this._prefs.get(this._cacheName) != null);
  }

  void doAuth(){
    throw UnimplementedError();
  }

  void _writeCache(data){
    /**
     * data must be JSON serializable
     */
    String jsonData = jsonEncode(data);
    this._prefs.setString(this._cacheName, jsonData);
  }


  void _loadCache(){
    // This function assumes that in protected usage _isCached has been
    // checked each time
    String rawCache = this._prefs.getString(this._cacheName);
    // Decode the cache
    Map cacheData = jsonDecode(rawCache);
    // Check the cache time
    num cachedAtStamp = cacheData["loadedAt"];
    DateTime cachedAt = DateTime.fromMillisecondsSinceEpoch(
        (cachedAtStamp)
    );
    this.loadedAt = cachedAt;
    // Process the raw data
    for (String timestamp in cacheData["data"].keys){
      setPoint(DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)),
              cacheData["data"][timestamp]);
    }
  }

  Future data({bool cacheOverride: false}){
    if (!cacheOverride && this._isCached){

    }
  }


  void _initializeCache() async{
    this._prefs = await SharedPreferences.getInstance();
    // Check to see if the data is already cached
    if (this._prefs.containsKey(this._cacheName)){
      this._loadCache();
      this.loaded = true;
    }
  }

  ServiceInterface(){
    this.loaded = false;
    loadStatus = new StreamController.broadcast();
    this._initializeCache();
  }
}