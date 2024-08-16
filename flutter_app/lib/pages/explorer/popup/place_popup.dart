import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class ExamplePopup extends StatefulWidget {
  final Marker marker;
  List<List<double>> coordinates;
  List<dynamic> poiItinerary;
  int index;

  ExamplePopup(this.marker,
      {Key? key,
      required this.coordinates,
      required this.poiItinerary,
      required this.index})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ExamplePopupState();
}

class _ExamplePopupState extends State<ExamplePopup> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => print('Tapped on popup'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // const Padding(
            //   padding: EdgeInsets.only(left: 20, right: 10),
            //   child: Icon(Icons.star_border),
            // ),
            _cardDescription(context),
          ],
        ),
      ),
    );
  }

  Widget _cardDescription(BuildContext context) {
    return Stack(
      children: [
        // Content behind the popup
        // Add any content that should appear behind the popup here

        // Popup
        Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            constraints: const BoxConstraints(minWidth: 100, maxWidth: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Text(
                    'Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Place: ${widget.poiItinerary[widget.index]["Itinerary"]}',
                        style: const TextStyle(fontSize: 12.0),
                      ),
                      Text(
                        'Place Category:'
                        '${widget.poiItinerary[widget.index]["POICategories"]}',
                        style: const TextStyle(fontSize: 12.0),
                      ),
                      Text(
                        widget.index == 0 &&
                                widget.poiItinerary[widget.index]
                                        ["StartTimePOI"] !=
                                    null
                            ? 'StartTime: ${widget.poiItinerary[widget.index]["StartTimePOI"][0]}'
                            : 'ArrivalTime: ${widget.poiItinerary[widget.index]["ReachTimePOI"] != null ? widget.poiItinerary[widget.index]["ReachTimePOI"][0] : "N/A"}',
                        style: const TextStyle(fontSize: 12.0),
                      ),
                      Text(
                        widget.poiItinerary[widget.index]["LeaveTimePOI"] !=
                                    null &&
                                widget.poiItinerary[widget.index]
                                        ["LeaveTimePOI"][0] !=
                                    null
                            ? 'LeaveTime: ${widget.poiItinerary[widget.index]["LeaveTimePOI"][0]}'
                            : 'ArrivalTime: ${widget.poiItinerary[widget.index]["ReachTimePOI"] != null ? widget.poiItinerary[widget.index]["ReachTimePOI"][0] : "N/A"}',
                        style: const TextStyle(fontSize: 12.0),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
