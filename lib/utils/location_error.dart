enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationError extends Error {
  LocationError(this.message, this.type);

  final String message;
  final LocationErrorType type;

  @override
  String toString() => message;
}
