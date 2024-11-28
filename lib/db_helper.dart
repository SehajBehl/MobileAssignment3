import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('food_orders.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cost REAL NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        food_items TEXT NOT NULL,
        target_cost REAL NOT NULL
      );
    ''');

    // Insert initial foods
    await insertInitialFoods(db);
  }

  // Modify insertInitialFoods to accept the db parameter
  Future<void> insertInitialFoods(Database db) async {
    final List<Map<String, dynamic>> initialFoods = [
      {'name': 'Pizza', 'cost': 10.0},
      {'name': 'Burger', 'cost': 5.0},
      {'name': 'Pasta', 'cost': 8.0},
      {'name': 'Sushi', 'cost': 12.0},
      {'name': 'Salad', 'cost': 6.0},
      {'name': 'Sandwich', 'cost': 4.0},
      {'name': 'Fried Rice', 'cost': 7.0},
      {'name': 'Chicken Curry', 'cost': 9.0},
      {'name': 'Ice Cream', 'cost': 3.0},
      {'name': 'Steak', 'cost': 15.0},
      {'name': 'Tacos', 'cost': 6.0},
      {'name': 'Fries', 'cost': 2.5},
      {'name': 'Donut', 'cost': 1.5},
      {'name': 'Soup', 'cost': 4.0},
      {'name': 'Hot Dog', 'cost': 3.5},
      {'name': 'Noodles', 'cost': 5.5},
      {'name': 'Grilled Cheese', 'cost': 4.5},
      {'name': 'Pancakes', 'cost': 6.5},
      {'name': 'Waffles', 'cost': 6.5},
      {'name': 'Brownie', 'cost': 3.0},
    ];

    for (var food in initialFoods) {
      await db.insert('foods', food, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // Method to query an order by date
  Future<Map<String, dynamic>?> getOrderByDate(String date) async {
    final db = await instance.database;
    final result = await db.query('orders', where: 'date = ?', whereArgs: [date]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> addFood(String name, double cost) async {
    final db = await DBHelper.instance.database;
    await db.insert('foods', {'name': name, 'cost': cost});
  }

  Future<void> updateFood(int id, String name, double cost) async {
    final db = await DBHelper.instance.database;
    await db.update('foods', {'name': name, 'cost': cost}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteFood(int id) async {
    final db = await DBHelper.instance.database;
    await db.delete('foods', where: 'id = ?', whereArgs: [id]);
  }
}
