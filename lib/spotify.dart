// Builtin/flutter imports
import 'package:flutter/material.dart';


// Internal imports
import 'package:stories/service_utils.dart';

// External imports
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';



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

  void startDataDownload() async{
    // Do this as a plain URL instead of the slightly easier URI
    // so the spotify next objects can be treated the same
    String next = "https://api.spotify.com/v1/me/tracks/?offset=0&limit=50";
    Map headers = {
      "Authorization": "Bearer ${this._accessKey}"
    };
    while (next != null){
      Response rep = await get(next, headers: headers);
      print(rep);
    }
  }

  bool acknowledgeOauthKey(String initialLink){
    String accessToken = initialLink.split(
        "access_token=")[1].split("&token_type")[0];
    this._accessKey = accessToken;
    return true;
  }
}

