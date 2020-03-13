// Builtin imports
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:intl/intl.dart';
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
      Widget cardFoot = Row(
        children: [
          Padding(padding: EdgeInsets.all(10), child:
            Text(DateFormat.yMMMMd("en_us").format(point.created),
                 style: TextStyle(color: Colors.grey)))
        ]
      );
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

  void startPageMedia() async{
    for (ServicePoint point in this._points.values){
      await point.startMedia();
    }
  }

  void stopPageMedia() async{
    for (ServicePoint point in this._points.values){
      await point.stopMedia();
    }
  }
}

class Story{
  List<int> years;
  final List<ServiceInterface> services;

  Story({this.services});

  /// Try to match peaks of services
  Map<ServiceInterface, ServicePoint> _isolatePoints(Map<ServiceInterface,
      List<ServicePoint>> points){
    Map<ServiceInterface, ServicePoint> chosenPoints = {};
    for (ServiceInterface service in points.keys){
      List<ServicePoint> pOps = points[service];
      // Short circuit if there's only 1 point
      if (pOps.length == 1){
        chosenPoints[service] = pOps[0];
        continue;
      }
      // Sort the points by their date
      pOps.sort((ServicePoint o, ServicePoint p) =>
          o.created.compareTo(p.created));
      DateTime firstPoint = pOps.first.created;
      DateTime lastPoint = pOps.last.created;
      Duration pointDiff = lastPoint.difference(firstPoint);
      // Break the duration of the difference of the points into equal sized chunks, and identify the largest
      int microChunks = pointDiff.inMicroseconds ~/ pOps.length;
      int peakLen = 0;
      List<ServicePoint> peak;
      // Iterate through the chunks that are defined, and pick the chunk which has the most points, the peak
      Duration chunkDur = Duration(microseconds: microChunks);
      DateTime chunkEnd = firstPoint.add(chunkDur);
      int idx = 0;
      while (chunkEnd.isBefore(lastPoint) ||
          chunkEnd.isAtSameMomentAs(lastPoint)){
        int chunkIdx = pOps.lastIndexWhere((element) =>
          (element.created.isBefore(chunkEnd) ||
              element.created.isAtSameMomentAs(chunkEnd)));
        List<ServicePoint> currChunk = pOps.sublist(idx, chunkIdx);
        idx = chunkIdx;
        if (currChunk.length > peakLen){
          peakLen = currChunk.length;
          peak = currChunk;
        }
        // Update what datetime this current chunk is
        chunkEnd = chunkEnd.add(chunkDur);
      }
      // Sort the points in the peak by their compareTo functions
      peak.sort((ServicePoint s, ServicePoint o) => s.compareTo(o));
      // Choose the first sorted point in the pak
      chosenPoints[service] = peak.last;
    }
    return chosenPoints;
  }

  Future<List<Page>> pages() async{
    List<Page> builtPages = [];
    for (int year in this.years){
      // Iterate through the months in the year
      for (int m=1; m<=12; m++){
        print("$year, $m");
        // Determine when to start and end for the month range
        DateTime monthStart = DateTime(year, m).subtract(Duration(microseconds: 1));
        DateTime monthEnd;
        if (m == 12){
          monthEnd = DateTime(year+1, 1);
        }
        else{
          monthEnd = DateTime(year, m+1);
        }
        // Determine if all services have points in this month
        Map<ServiceInterface, List<ServicePoint>> found = {};
        bool serviceExcluded = false;
        for (ServiceInterface service in this.services){
          List<ServicePoint> monthPoints = service.pointsInRange(monthStart,
              monthEnd);
          if (monthPoints.length == 0){
            serviceExcluded = true;
            break;
          }
          else{
            found[service] = monthPoints;
          }
        }
        if (!serviceExcluded){
          // If they do, pick which points to display
          Map<ServiceInterface, ServicePoint> pagePoints = _isolatePoints(found);
          print(pagePoints.length);
          // Do prerender operations on the chosen points
          for (ServicePoint p in pagePoints.values){
            await p.preRender();
          }
          Page builtPage = new Page(pagePoints);
          builtPages.add(builtPage);
        }
      }
    }
    return builtPages;
  }


  List<Widget> yearSelector(Function callback) {
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
    if (this.years == null){
      this.years = serviceYears;
    }
    List<Widget> yearTiles = [];
    for (int y in serviceYears){
      bool v = (this.years.contains(y));
      yearTiles.add(
        Card(
          child:
            CheckboxListTile(
                checkColor: theme.splashColor,
                title: Text(y.toString(), style: TextStyle(fontWeight: FontWeight.bold)),
                value: v,
                onChanged: (bool b){
                  if (b){
                    if (!this.years.contains(y)){
                      this.years.add(y);
                      callback();
                    }
                  }
                  else{
                    this.years.remove(y);
                    callback();
                  }
                },
            )
        )
      );
    }
    return yearTiles;
  }
}