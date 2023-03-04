import 'package:campus_transit/utils/point.dart';
import 'package:campus_transit/utils/sheets_manager.dart';
import 'package:campus_transit/widgets/destination_block.dart';
import 'package:campus_transit/widgets/to_destination.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

final coordinates = {
  'Main Gate':
      Coordinate(latitude: 13.706253404147644, longitude: 79.59447771421611),
  'DB2': Coordinate(latitude: 13.715494310047804, longitude: 79.59168152695055),
  'G Block':
      Coordinate(latitude: 13.718071721024105, longitude: 79.58757120726337),
};

class GetLocation extends StatefulWidget {
  const GetLocation({super.key});

  @override
  State<GetLocation> createState() => _GetLocationState();
}

class _GetLocationState extends State<GetLocation> {
  Points _closestPoint = Points.mainGate;

  TransportScheduleRow? _destinationOne;
  TransportScheduleRow? _destinationTwo;

  final _sheetManager = TransportScheduleSheetManager();

  late Future<Position> _initLocation;

  @override
  void initState() {
    _initLocation = _initializeLocation();
    super.initState();
  }

  Future<Position> _initializeLocation() async {
    bool serviceEnabled = false;
    LocationPermission permission = LocationPermission.denied;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    final currLocation = await Geolocator.getCurrentPosition();

    final rows = await _getClosestPoint(currLocation);
    _destinationOne = rows[0];
    _destinationTwo = rows[1];

    return currLocation;
  }

  Future<List<TransportScheduleRow>> _getClosestPoint(Position position) async {
    final currentLocation =
        Coordinate(latitude: position.latitude, longitude: position.longitude);

    final distances = coordinates.map((key, value) {
      return MapEntry(key, value.distanceTo(currentLocation));
    });

    final closestPoint = distances.entries.reduce((value, element) {
      return value.value < element.value ? value : element;
    });

    _closestPoint = Points.values.firstWhere(
        (element) => element.string == closestPoint.key,
        orElse: () => Points.mainGate);

    final otherTwoPoints =
        Points.values.where((element) => element != _closestPoint).toList();
    final List<TransportScheduleRow> rows = [];

    for (final point in otherTwoPoints) {
      final row = await _sheetManager.nextVehicleToDrop(
          _closestPoint, point, DateTime.now());
      rows.add(row);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initLocation,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("${snapshot.error}"),
          );
        }

        if (snapshot.data == null) {
          return const Center(
            child: Text("No location data"),
          );
        }

        return RefreshIndicator(
            color: const Color(0xFF514C5E),
            onRefresh: () =>
                _getClosestPoint(snapshot.data!).then((value) => setState(() {
                      _destinationOne = value[0];
                      _destinationTwo = value[1];
                    })),
            child: Center(
                child: ListView(children: [
              DestinationBlock(
                vehicleId: _destinationTwo!.vehicleId,
                color: 0xFFA6A1C7,
                title: "Next bus is at ${_destinationTwo!.timeString}",
              ),
              ToDestination(destination: _destinationTwo),
              DestinationBlock(
                vehicleId: _closestPoint.string,
                color: 0xFF514C5E,
                title: "You are at",
              ),
              ToDestination(
                destination: _destinationOne,
              ),
              DestinationBlock(
                vehicleId: _destinationOne!.vehicleId,
                color: 0xFFA6A1C7,
                title: "Next bus is at ${_destinationOne!.timeString}",
              ),
            ])));
      },
    );
  }
}
