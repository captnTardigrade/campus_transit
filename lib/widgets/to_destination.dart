import 'package:campus_transit/utils/sheets_manager.dart';
import 'package:flutter/material.dart';

class ToDestination extends StatelessWidget {
  const ToDestination({
    super.key,
    required TransportScheduleRow? destination,
  }) : _destinationTwo = destination;

  final TransportScheduleRow? _destinationTwo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: -3.14 / 2,
        child: Container(
            margin: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              "To ${_destinationTwo!.destinationString}",
              style: Theme.of(context).textTheme.bodyMedium,
            )),
      ),
    );
  }
}
