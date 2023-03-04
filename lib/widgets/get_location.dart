import 'package:campus_transit/utils/point.dart';
import 'package:campus_transit/utils/sheets_manager.dart';
import 'package:campus_transit/widgets/destination_block.dart';
import 'package:campus_transit/widgets/to_destination.dart';
import 'package:location/location.dart';

import 'package:flutter/material.dart';

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
  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;

  final _location = Location();
  Points _closestPoint = Points.mainGate;

  TransportScheduleRow? _destinationOne;
  TransportScheduleRow? _destinationTwo;

  final _sheetManager = TransportScheduleSheetManager();
  late Future<void> _init;
  // bool _isLoaded = false;

  @override
  void initState() {
    _init = initializeLocation();
    super.initState();
  }

  Future<void> initializeLocation() async {
    final isServiceEnabled = await _location.serviceEnabled();

    final hasPermission = await _location.hasPermission();

    final rows = await _getClosestPoint();

    _serviceEnabled = isServiceEnabled;
    _permissionGranted = hasPermission;
    _destinationOne = rows[0];
    _destinationTwo = rows[1];
  }

  Future<void> _enableLocation() async {
    await _location.requestService().then((value) => setState(() {
          _serviceEnabled = value;
        }));
  }

  Future<PermissionStatus> _getPermission() async {
    PermissionStatus status = await _location.hasPermission();
    if (status == PermissionStatus.denied) {
      status = await _location.requestPermission();
      if (status != PermissionStatus.granted) {
        return status;
      }
    }
    return status;
  }

  Future<List<TransportScheduleRow>> _getClosestPoint() async {
    final location = await _location.getLocation();
    final currentCoordinate = Coordinate(
        latitude: location.latitude!, longitude: location.longitude!);
    final distances = coordinates.map((key, value) {
      return MapEntry(key, value.distanceTo(currentCoordinate));
    });
    final minDistPoint = distances.entries.reduce((a, b) {
      return a.value < b.value ? a : b;
    });
    final source = stringToPoint[minDistPoint.key]!;
    setState(() {
      _closestPoint = source;
    });
    final otherTwoPoints =
        Points.values.where((element) => element != source).toList();

    List<TransportScheduleRow> rows = [];
    for (final point in otherTwoPoints) {
      TransportScheduleRow? destination;
      destination =
          await _sheetManager.nextVehicleToDrop(source, point, DateTime.now());
      rows.add(destination);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    if (!_serviceEnabled) {
      return Center(
        child: Column(
          children: [
            const Text("Please enable location services to use"),
            ElevatedButton(
              onPressed: _enableLocation,
              child: const Text("Enable Location"),
            )
          ],
        ),
      );
    }

    if (_permissionGranted == PermissionStatus.denied) {
      return Center(
        child: Column(
          children: [
            const Text("Please grant location permsission to use"),
            ElevatedButton(
              onPressed: () async {
                final status = await _getPermission();
                setState(() {
                  _permissionGranted = status;
                });
              },
              child: const Text("Request Permission"),
            )
          ],
        ),
      );
    }

    if (_permissionGranted == PermissionStatus.deniedForever) {
      return const Center(
        child: Text("Please grant location permsission to use"),
      );
    }

    return FutureBuilder(
      future: _init,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return RefreshIndicator(
            color: const Color(0xFF514C5E),
            onRefresh: () => _getClosestPoint().then((value) => setState(() {
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
