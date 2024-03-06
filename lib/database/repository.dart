import 'database_provider.dart';
import 'location_model.dart';
import 'package:sqflite/sqflite.dart';

class LocationRepository {
  final dbProvider = DatabaseProvider.dbProvider;

  Future<int> insertLocation(LocationModel locationModel) async {
    final db = await dbProvider.database;
    var result = db.insert('mytable', locationModel.toMap(),
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
}
