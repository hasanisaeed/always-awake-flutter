class LocationModel {
  final double latitude;
  final double longitude;
  final String
      createdAt; // Consider using DateTime and converting to String for storage, the format of datetime is: YYYY-MM-DD hh:mm:ss

  LocationModel(
      {required this.latitude,
      required this.longitude,
      required this.createdAt});

  factory LocationModel.fromMap(Map<String, dynamic> json) => LocationModel(
        latitude: json['latitude'],
        longitude: json['longitude'],
        createdAt: json['created_at'],
      );

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt,
    };
  }
}
