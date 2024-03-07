import 'database_provider.dart';
import 'location_model.dart';
import 'package:sqflite/sqflite.dart';

class LocationRepository {
  final dbProvider = DatabaseProvider.dbProvider;

  Future<int> insertLocation(LocationModel locationModel) async {
    final db = await dbProvider.database;
    var result = await db.insert('mytable', locationModel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return result;
  }

  Future<List<LocationModel>> getAllLocations() async {
    final db = await dbProvider.database;
    var result = await db.query('mytable');
    List<LocationModel> locations = result.isNotEmpty
        ? result.map((item) => LocationModel.fromMap(item)).toList()
        : [];
    return locations;
  }

  Future<void> deleteRecord({required String latitude, required String longitude, required String createdAt}) async {
    final db = await dbProvider.database;
    await db.delete(
      'mytable',
      where: 'latitude = ? AND longitude = ? AND created_at = ?',
      whereArgs: [latitude, longitude, createdAt],
    );
  }

  Future<void> insertRecord({required String latitude, required String longitude, required String createdAt}) async {
    LocationModel locationModel = LocationModel(
      latitude: double.parse(latitude),
      longitude: double.parse(longitude),
      createdAt: createdAt,
    );
    await insertLocation(locationModel);
  }
}
