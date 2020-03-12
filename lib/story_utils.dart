// Builtin imports
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:stories/service_utils.dart';
import 'dart:async';

// Internal imports
import 'package:stories/variables.dart';
import 'package:stories/spotify.dart';

// External imports
import 'package:uni_links/uni_links.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Page{
  final Map<ServiceInterface, ServicePoint> _points;

  Page(this._points);

  Widget render(BuildContext context){
    // Photo/Video widgets that should be at the top of the bundle
    List<Widget> pvWidgets = [];
    // Audio widgets that will be under visual widgets
    List<Widget> audioWidgets = [];
    // Text widgets that will share a grid
    List<Widget> textWidgets = [];
    // Events that should be triggered when the page is shown, such as audio play events
    List<Function> triggers = [];
    this._points.forEach((ServiceInterface service, ServicePoint point) {
      // The header of the widget card
      Widget cardHeader = Padding(
          padding: EdgeInsets.all(5.0),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                service.icon,
                Text(service.name, style: TextStyle(fontWeight: FontWeight.bold))
              ]
          )
      );
      Widget cardContent = point.render(context);
      // The footer of the card, dependent on the media type
      Widget cardFoot = Row();
      List appendTo;
      // If you implement a service with a new media type, this switch should be updated
      switch (point.mediaType){
        case MediaType.audio:
          appendTo = audioWidgets;
          break;
        case MediaType.photo:
          appendTo = pvWidgets;
          break;
        case MediaType.text:
          appendTo = textWidgets;
          break;
      }
      Widget combinedWidget = Padding(
        padding: EdgeInsets.all(5.0),
        child: Card(
          child: Column(
            children: [
              cardHeader,
              cardContent,
              cardFoot
            ]
          )
        )
      );
      appendTo.add(combinedWidget);
    });
    // Get the number of widgets that will go on the page
    int combinedLength = pvWidgets.length + audioWidgets.length + textWidgets.length;
    print("Rendering $combinedLength widgets");
    List<Widget> renderChildren = [];
    // Regardless of how many widgets we're rendering, pvWidgets will be on their own
    renderChildren.addAll(pvWidgets);
    // If we're rendering 3 or less total widgets, don't bother with a GridView, and just throw everything in a column
    if (combinedLength <= 3){
      renderChildren.addAll(audioWidgets);
      renderChildren.addAll(textWidgets);
    }
    else{
      List<Widget> audioText = [];
      audioText.addAll(audioWidgets);
      audioText.addAll(textWidgets);
      renderChildren.add(GridView.count(crossAxisCount: 2,
                                        children: audioText));
    }
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: ListView(
        children: renderChildren
      )
    );
  }
}

class Story{
  List<int> years;
  final List<ServiceInterface> services;

  Story({this.services});

  Iterable<Page> pages() sync*{
    for (int year in this.years){
      // Count the number of points for each service
      Map<ServiceInterface, ServicePoint> yearPoints = {};
      for (ServiceInterface service in this.services) {
        // Filter to find the first point that's valid
        yearPoints[service] = service.pointsInYear(year).firstWhere((point) =>
            service.pointIsValid(point));
      }
      yield Page(yearPoints);
    }
  }


  List<Widget> yearSelector() {
    List<int> serviceYears;
    for (ServiceInterface s in this.services) {
      if (serviceYears == null) {
        serviceYears = s.years;
      }
      else {
        List<int> temp = [];
        for (int y in s.years) {
          if (serviceYears.contains(y)) {
            temp.add(y);
          }
        }
        serviceYears = temp;
      }
    }
    serviceYears.sort();
    this.years = serviceYears;
    List<Widget> yearTiles = [];
    for (int y in serviceYears){
      yearTiles.add(
        Card(
          child:
            CheckboxListTile(
                checkColor: theme.splashColor,
                title: Text(y.toString(), style: TextStyle(fontWeight: FontWeight.bold)),
                value: true,
                onChanged: (bool b){
                  if (b){
                    if (!this.years.contains(y)){
                      this.years.add(y);
                    }
                  }
                  else{
                    this.years.remove(y);
                  }
                },
            )
        )
      );
    }
    return yearTiles;
  }
}