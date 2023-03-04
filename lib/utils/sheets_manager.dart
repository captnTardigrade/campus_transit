import 'package:campus_transit/utils/point.dart';
import 'package:gsheets/gsheets.dart';
import 'package:campus_transit/utils/_google_api_credentials.dart';
import 'package:intl/intl.dart';

class TransportScheduleRow {
  final Points source;
  final Points destination;
  final String vehicleId;
  final DateTime time;

  TransportScheduleRow({
    required this.source,
    required this.destination,
    required this.vehicleId,
    required this.time,
  });

  factory TransportScheduleRow.fromGsheets(Map<String, dynamic> json) {
    DateTime convertTime(String time) {
      final timeParts = time.split(":");
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      return DateTime(2020, 11, 20, hour, minute);
    }

    final val = TransportScheduleRow(
      source: stringToPoint[json["source"]]!,
      destination: stringToPoint[json["destination"]]!,
      vehicleId: json["vehicle_id"],
      time: convertTime(json["time"]),
    );

    return val;
  }

  String get sourceString => source.string;
  String get destinationString => destination.string;
  String get timeString => DateFormat.Hm().format(time);
}

class TransportScheduleSheetManager {
  final GSheets _gsheets = GSheets(googleAPICredentials);
  late Spreadsheet _spreadsheet;
  late Worksheet _worksheet;

  Future<void> init() async {
    _spreadsheet = await _gsheets.spreadsheet(spreadsheetId);
    final val = _spreadsheet.worksheetByTitle('main');

    if (val == null) {
      throw Exception('Worksheet not found');
    }

    _worksheet = val;
  }

  Future<List<TransportScheduleRow>> getAll() async {
    await init();
    final rows = await _worksheet.values.map.allRows();
    if (rows == null) {
      throw Exception('No rows found');
    }
    return rows.map((e) => TransportScheduleRow.fromGsheets(e)).toList();
  }

  DateTime _roundToNearestTen(DateTime time) {
    final minutes = time.minute;
    if (minutes % 10 == 0) {
      return DateTime(2020, 11, 20, time.hour, minutes);
    }
    final roundedMinutes = ((minutes / 10).floor() + 1) * 10;
    return DateTime(2020, 11, 20, time.hour, roundedMinutes);
  }

  Future<TransportScheduleRow> nextVehicleToDrop(
      Points boardingPoint, Points dropPoint, DateTime? time) async {
    final rows = await getAll();
    final filteredRows = rows
        .where((element) =>
            element.source == boardingPoint && element.destination == dropPoint)
        .toList();
    time ??= DateTime.now();
    final roundedTime = _roundToNearestTen(time);

    // check the time in the boardingPoint column and find the closest row
    TransportScheduleRow? closestRow;
    for (var row in filteredRows) {
      if (row.time.isAfter(roundedTime)) {
        if (closestRow == null) {
          closestRow = row;
          break;
        }
      }
    }

    if (closestRow == null) {
      throw Exception('No vehicle found');
    }

    return closestRow;
  }
}
