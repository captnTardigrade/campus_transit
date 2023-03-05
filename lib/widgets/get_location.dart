import 'package:campus_transit/widgets/error_button.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:campus_transit/utils/location_error.dart';
import 'package:campus_transit/utils/point.dart';
import 'package:campus_transit/utils/sheets_manager.dart';
import 'package:campus_transit/widgets/destination_block.dart';
import 'package:campus_transit/widgets/to_destination.dart';

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

class _GetLocationState extends State<GetLocation> with WidgetsBindingObserver {
  Points _closestPoint = Points.mainGate;

  TransportScheduleRow? _destinationOne;
  TransportScheduleRow? _destinationTwo;

  final _sheetManager = TransportScheduleSheetManager();

  late Future<Position> _initLocation;

  bool _openedSettings = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _initLocation = _initializeLocation();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _openedSettings) {
      setState(() {
        _initLocation = _initializeLocation();
      });
      _openedSettings = false;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<Position> _initializeLocation() async {
    bool serviceEnabled = false;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error(LocationError('Location services are disabled.',
          LocationErrorType.serviceDisabled));
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error(LocationError('Location permissions are denied',
            LocationErrorType.permissionDenied));
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(LocationError(
          'Location permissions are permanently denied, we cannot request permissions.',
          LocationErrorType.permissionDeniedForever));
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

  Future<void> _enableLocationServices() async {
    final openedSettings = await Geolocator.openLocationSettings();
    setState(() {
      _openedSettings = openedSettings;
    });
  }

  Future<void> _requestLocationPermission() async {
    await Geolocator.requestPermission();
    setState(() {
      _initLocation = _initializeLocation();
    });
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
          if (snapshot.error.toString().contains("No vehicle found")) {
            return const Center(
              child: Text("No vehicle found"),
            );
          }

          final errorData = snapshot.error as LocationError;

          if (errorData.type == LocationErrorType.serviceDisabled) {
            return ErrorButton(
              callBack: _enableLocationServices,
              buttonText: "Enable Location Services",
              error: "Location services are disabled",
            );
          }

          if (errorData.type == LocationErrorType.permissionDenied) {
            return ErrorButton(
              callBack: _requestLocationPermission,
              buttonText: "Grant Location Permission",
              error: "Location permissions are denied",
            );
          }

          if (errorData.type == LocationErrorType.permissionDeniedForever) {
            return ErrorButton(
              callBack: () =>
                  Geolocator.openAppSettings().then((value) => setState(() {
                        _openedSettings = value;
                      })),
              buttonText: "Enable Location Services",
              error:
                  "Please grant location permissions from settings to use this app",
            );
          }

          return Center(
            child: Text("${snapshot.error}"),
          );
        }

        if (snapshot.data == null) {
          return const Center(
            child: Text("No location data"),
          );
        }

        return LayoutBuilder(builder: (context, constraints) {
          return RefreshIndicator(
              onRefresh: () =>
                  _getClosestPoint(snapshot.data!).then((value) => setState(() {
                        _destinationOne = value[0];
                        _destinationTwo = value[1];
                      })),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DestinationBlock(
                          vehicleId: _destinationTwo!.vehicleId,
                          color: Theme.of(context).primaryColor,
                          title:
                              "Next bus is at ${_destinationTwo!.timeString}",
                        ),
                        ToDestination(destination: _destinationTwo),
                        DestinationBlock(
                          vehicleId: _closestPoint.string,
                          color: Theme.of(context).cardColor,
                          title: "You are at",
                        ),
                        ToDestination(
                          destination: _destinationOne,
                        ),
                        DestinationBlock(
                          vehicleId: _destinationOne!.vehicleId,
                          color: Theme.of(context).primaryColor,
                          title:
                              "Next bus is at ${_destinationOne!.timeString}",
                        ),
                      ]),
                ),
              ));
        });
      },
    );
  }
}
