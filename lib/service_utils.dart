// Builtin/Flutter imports
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:convert/convert.dart';


// External imports
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceWidget{
}

launchURL(String url) async {
  try{
    launch(url);
  }
  catch (e){
    print("Error launching url ${url}");
    print(e);
  }
}

class ServicePoint{
  int minDuration;
  int maxDuration;

  serialize(){
    throw UnimplementedError();
  }
}

class ServiceInterface{
  String name;
  Widget icon;
  SharedPreferences _prefs;
  Map _keys;
  DateTime loadedAt;
  bool loaded;
  bool downloading = false;
  String loadStatus = "Loading...";

  Map shapeData(){
    /**
     * The function that shapes data from the service into a usable timeseries
     */
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

  List<Map<DateTime, ServiceWidget>> parseSeries(Map<num, Map> rawData){
    /**
     * The function that loads cached data back into a usable format
     */
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
  }

  void doCache() async{
    Map cacheData = {"loadedAt": this.loadedAt.millisecondsSinceEpoch,
    "data": {}};
    for (DateTime time in this.timeSeries){
      cacheData["data"][time.millisecondsSinceEpoch] = getPoint(time).serialize();
    }
    print("Caching ${cacheData.length} datapoints under key ${this._cacheName}");
    _writeCache(cacheData);
  }

  Future<void> doDataDownload() async{
    throw UnimplementedError();
  }

  void startDataDownload() async{
    /**
     * Download the data. Cache should likely be called when this is done
     */
    // Set downloading = true to prevent multiple downloads
    if (!this.downloading){
      this.downloading = true;
      print("Starting ${this.name} download");
      DateTime startTime = DateTime.now();
      await this.doDataDownload();
      DateTime endTime = DateTime.now();
      this.downloading = false;
      // Use inMilliseconds instead of inSeconds because we're interested in fractional seconds
      double secondsTaken = (endTime.difference(startTime).inMilliseconds / 1000);
      print("Finished ${this.name} download, took $secondsTaken seconds");
      // TODO: call cache here
    }
  }

  String get _cacheName{
    return "${this.name}_service_cache";
  }

  bool get _isCached{
    return (this._prefs.get(this._cacheName) != null);
  }

  void doOauth(){
    throw UnimplementedError();
  }

  // TODO: from and to JSON serializers

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
    // Process the raw data
    for (num timestamp in cacheData["data"].keys){
      setPoint(cachedAt,
              cacheData[timestamp]);
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
    this._initializeCache();
  }
}