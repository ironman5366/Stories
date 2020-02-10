// Builtin/flutter imports
import 'dart:convert';

import 'package:flutter/material.dart';


// Internal imports
import 'package:stories/service_utils.dart';

// External imports
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';

class SpotifyTrack{
  DateTime added;
  String previewUrl;
  String externalUrl;
  String album;
  String artist;
  String name;
  String albumCoverUrl;

  SpotifyTrack(this.added, this.previewUrl, this.externalUrl,
                this.album, this.artist, this.name,
                this.albumCoverUrl);

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
      "albumCoverUrl": this.albumCoverUrl
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

  List<SpotifyTrack> parseTracks(List responseData){
    /**
     * Parse a list of spotify API responses into an internal usable
     * track structure
     */
    List<SpotifyTrack> trackAccumulator = [];
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
        trackAccumulator.add(
          SpotifyTrack(added, previewUrl, externalUrl,
                      album, artist, name, albumCoverUrl)
        );
      }
    }
    return trackAccumulator;
  }

  void startDataDownload() async{
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
        //next = responseData["next"];
        next = null;
      }
      else{
        print("Response error:");
        print(rep);
        next = null;
      }
    }
    List<SpotifyTrack> tracks = parseTracks(dataList);

  }

  bool acknowledgeOauthKey(String initialLink){
    String accessToken = initialLink.split(
        "access_token=")[1].split("&token_type")[0];
    this._accessKey = accessToken;
    return true;
  }
}

