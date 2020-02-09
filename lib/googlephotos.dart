// Builtin/flutter imports
import 'package:flutter/material.dart';

// Internal imports
import 'package:stories/service_utils.dart';

// External imports
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

String readOnlySCope = "https://www.googleapis.com/auth/photoslibrary.readonly";

class GooglePhotos extends ServiceInterface{
  String name="Google Photos";
  Icon icon = Icon(FontAwesomeIcons.google);


}