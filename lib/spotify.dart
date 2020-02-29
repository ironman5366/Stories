// Builtin/flutter imports
import 'dart:convert';

import 'package:flutter/material.dart';


// Internal imports
import 'package:stories/service_utils.dart';

// External imports
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';

class SpotifyTrack extends ServicePoint{
  int minDuration = 5;
  int maxDuration = 30;

  DateTime added;
  String previewUrl;
  String externalUrl;
  String album;
  String artist;
  String name;
  String albumCoverUrl;
  int popularity;

  SpotifyTrack(this.added, this.previewUrl, this.externalUrl,
                this.album, this.artist, this.name,
                this.albumCoverUrl, this.popularity);

  Map serialize(){
    /**
     * Export to a json serializable map
     */
    return {
      "added": this.added.millisecondsSinceEpoch,
      "previewUrl": this.previewUrl,
      "externalUrl": this.externalUrl,
      "album": this.album,
      "artist": this.artist,
      "name": this.name,
      "albumCoverUrl": this.albumCoverUrl,
      "popularity": this.popularity
    };
  }
}

class Spotify extends ServiceInterface {
  String name = "Spotify";
  Icon icon = Icon(FontAwesomeIcons.spotify, color: Color(0XFF1DB954));
  String _redirect_uri = "stories-oauth://spotify-callback";
  // The required scopes to read a users library and playlists
  List<String> _scopes = [
    "user-library-read",
    "playlist-read-private"
  ];
  String _accessKey;
  Map<DateTime, SpotifyTrack> _tracks;

  List<DateTime> get timeSeries{
    if (this._tracks != null){
      return this._tracks.keys;
    }
    else{
      return [];
    }
  }

  void doOauth() async{
    Map spotifyCreds = await this.loadKey("spotify");
    String clientId = spotifyCreds["client_id"];
    Uri endpoint = Uri(scheme: "https",
                      host: "accounts.spotify.com",
                      path: "authorize",
                      queryParameters: {
                        "client_id": clientId,
                        "response_type": "token",
                        "redirect_uri": this._redirect_uri,
                        "scope": this._scopes.join(" ")
                      });
    print("Launching ${endpoint.toString()}");
    launchURL(endpoint.toString());
  }

  getPoint(DateTime time){
    // Use this structure instead of checking for key contain so that we don't
    // have to call contains every time, when it will be true most of the time
    try{
      return this._tracks[time];
    }
    catch (e){
      return null;
    }
  }

  setPoint(DateTime time, data){
    this._tracks[time] = SpotifyTrack(
        DateTime.fromMillisecondsSinceEpoch(data["added"]),
        data["previewUrl"],
        data["externalUrl"],
        data["album"], data["artist"],
        data["name"],
        data["albumCoverUrl"],
        data["popularity"]);
  }

  Map<DateTime, SpotifyTrack> _parseTracks(List responseData){
    /**
     * Parse a list of spotify API responses into an internal usable
     * track structure
     */
    Map<DateTime, SpotifyTrack> trackAccumulator = {};
    for (Map trackCollection in responseData){
      for (Map track in trackCollection["items"]){
        String rawAdded = track["added_at"];
        DateTime added = DateTime.parse(rawAdded);
        print(added);
        String previewUrl = track["preview_url"];
        String externalUrl = track["external_urls"]["spotify"];
        String name = track["name"];
        String artist = track["artists"][0]["name"];
        String album = track["album"]["name"];
        String albumCoverUrl = track["album"]["images"][0]["url"];
        int popularity = track["popularity"];
        trackAccumulator[added] = SpotifyTrack(added, previewUrl, externalUrl,
                      album, artist, name, albumCoverUrl, popularity);
      }
    }
    return trackAccumulator;
  }

  Future<void> doDataDownload() async{
    // Do this as a plain URL instead of the slightly easier URI
    // so the spotify next objects can be treated the same
    String next = "https://api.spotify.com/v1/me/tracks/?offset=0&limit=50";
    List dataList = [];
    int reqNum = 1;
    while (next != null){
      print("Request $reqNum, up to song ${reqNum*50}");
      Response rep = await get(next, headers: {
        "Authorization": "Bearer ${this._accessKey}"
      });
      if (rep.statusCode == 200){
        var responseData = jsonDecode(rep.body);
        dataList.add(responseData);
        reqNum++;
        next = responseData["next"];
        next = null;
      }
      else{
        print("Response error:");
        print(rep);
        next = null;
      }
    }
    Map<DateTime, SpotifyTrack> tracks = _parseTracks(dataList);
    this._tracks = tracks;
  }

  bool acknowledgeOauthKey(String initialLink){
    String accessToken = initialLink.split(
        "access_token=")[1].split("&token_type")[0];
    this._accessKey = accessToken;
    return true;
  }
}

