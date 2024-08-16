import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class InfoPopup extends StatefulWidget {
  final Marker marker;
  List<dynamic> routeInstructions;
  int infoIndex;
  String lastItem;

  InfoPopup(this.marker,
      {Key? key,
      required this.routeInstructions,
      required this.infoIndex,
      required this.lastItem})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _InfoPopupState();
}

class _InfoPopupState extends State<InfoPopup> {
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
            constraints: const BoxConstraints(minWidth: 100, maxWidth: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.lastItem,
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
