// Builtin/flutter imports
import 'package:flutter/material.dart';

// Internal imports
import 'package:stories/service_utils.dart';

// External imports
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class Spotify extends ServiceInterface {
  String name = "Spotify";
  Icon icon = Icon(FontAwesomeIcons.spotify, color: Color(0XFF1DB954));

  bool doOauth(){

  }
}