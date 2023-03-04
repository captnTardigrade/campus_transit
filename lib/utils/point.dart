import 'dart:math';

enum Points { mainGate, dB2, gBlock }

final stringToPoint = <String, Points>{
  "Main Gate": Points.mainGate,
  "DB2": Points.dB2,
  "G Block": Points.gBlock,
};

extension PointsToString on Points {
  String get string {
    switch (this) {
      case Points.mainGate:
        return "Main Gate";
      case Points.dB2:
        return "DB2";
      case Points.gBlock:
        return "G Block";
    }
  }
}

class Coordinate {
  final double latitude;
  final double longitude;

  Coordinate({required this.latitude, required this.longitude});

  double distanceTo(Coordinate other) {
    return sqrt(pow(latitude - other.latitude, 2) +
        pow(longitude - other.longitude, 2));
  }
}
