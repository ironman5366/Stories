// Builtin/flutter imports
import 'dart:convert';

import 'package:flutter/material.dart';


// Internal imports
import 'package:stories/service_utils.dart';

// External imports
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sound/flutter_sound.dart';

const Color spotifyGreen = Color(0XFF1DB954);

class SpotifyTrack extends ServicePoint{
  int minDuration = 5;
  int maxDuration = 30;
  DateTime created;

  MediaType mediaType = MediaType.audio;

  Color color = spotifyGreen;

  String previewUrl;
  String externalUrl;
  String album;
  String artist;
  String name;
  String albumCoverUrl;
  int popularity;
  FlutterSound player = FlutterSound();

  SpotifyTrack(this.created, this.previewUrl, this.externalUrl,
                this.album, this.artist, this.name,
                this.albumCoverUrl, this.popularity);

  Widget render(BuildContext context){
    return ListTile(
      leading: Image(image: NetworkImage(this.albumCoverUrl)),
      title: Text(this.name, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("${this.artist}, ${this.album}"),
      trailing: IconButton(icon: Icon(Icons.open_in_new), onPressed: (){
        launchURL(this.externalUrl);
      })
    );
  }

  int compareTo(other){
    SpotifyTrack t = other;
    // Default: compare based on popularity
    return (this.popularity - t.popularity);
  }

  Future<void> startMedia() async{
    if (this.player.audioState == t_AUDIO_STATE.IS_PLAYING){
      await this.player.stopPlayer();
    }
    await this.player.startPlayer(this.previewUrl);
  }

  Future<void> stopMedia() async{
    await this.player.stopPlayer();
  }

  Map serialize(){
    /**
     * Export to a json serializable map
     */
    Map trackData ={
      "added": this.created.millisecondsSinceEpoch,
      "previewUrl": this.previewUrl,
      "externalUrl": this.externalUrl,
      "album": this.album,
      "artist": this.artist,
      "name": this.name,
      "albumCoverUrl": this.albumCoverUrl,
      "popularity": this.popularity
    };
    return trackData;
  }
}

class Spotify extends ServiceInterface {
  String name = "Spotify";
  Widget icon = Icon(FontAwesomeIcons.spotify, color: spotifyGreen);
  String description = "Songs from your spotify library";
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
      return this._tracks.keys.toList();
    }
    else{
      return [];
    }
  }

  void doAuth() async{
    if (!this.loaded && this._accessKey == null){
      this.loadStatus.add("Waiting for login...");
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
    else{
      if (!this.downloading){
        this.startDataDownload();
      }
      DateFormat cacheFormat = DateFormat.yMd();
      this.loadStatus.add("Last refreshed on ${cacheFormat.format(this.loadedAt)}");
    }
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
    if (this._tracks == null){
      this._tracks = {};
    }
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
        Map trackData = track["track"];
        String previewUrl = trackData["preview_url"];
        String externalUrl = trackData["external_urls"]["spotify"];
        String name = trackData["name"];
        String artist = trackData["artists"][0]["name"];
        String album = trackData["album"]["name"];
        String albumCoverUrl = trackData["album"]["images"][0]["url"];
        int popularity = trackData["popularity"];
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
    int reqNum = 0;
    this.loadStatus.add("0 songs processed");
    while (next != null){
      Response rep = await get(next, headers: {
        "Authorization": "Bearer ${this._accessKey}"
      });
      if (rep.statusCode == 200){
        var responseData = jsonDecode(rep.body);
        dataList.add(responseData);
        this.loadStatus.add("${(reqNum * 50)+
            responseData["items"].length} songs processed");
        reqNum++;
        next = responseData["next"];
      }
      else{
        print("Response error:");
        print(rep);
        this.loadStatus.add("Error");
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

