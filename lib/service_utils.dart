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



class ServiceData{
  final DateTime loadedAt;
  final List<Map<DateTime, ServiceWidget>> series;

  ServiceData({@required this.loadedAt, @required this.series});
}

class ServiceInterface{
  String name;
  Icon icon;
  SharedPreferences _prefs;
  Map _keys;

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

  List<Map<DateTime, ServiceWidget>> parseSeries(Map<num, Map> rawData){
    /**
     * The function that loads cached data back into a usable format
     */
    throw UnimplementedError();
  }

  bool acknowledgeOauthKey(String initialLink){
    throw UnimplementedError;
  }

  void startDataDownload() async{
    throw UnimplementedError();
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


  Map get _loadCache{
    // This function assumes that in protected usage _isCached has been
    // checked each time
    String rawCache = this._prefs.getString(this._cacheName);
    // Decode the cache
    Map cacheData = jsonDecode(rawCache);
    // Check the cache time
    num cachedAtStamp = cacheData["timestamp"];
    DateTime cachedAt = DateTime.fromMillisecondsSinceEpoch(
        (cachedAtStamp*1000)
    );
    // Process the raw data

  }

  Future data({bool cacheOverride: false}){
    if (!cacheOverride && this._isCached){

    }
  }


  void _initializeCache() async{
    this._prefs = await SharedPreferences.getInstance();
  }

  ServiceInterface(){
    this._initializeCache();
  }
}