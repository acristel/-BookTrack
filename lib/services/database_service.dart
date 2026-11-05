import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/libro.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();

    _database = await openDatabase(
      join(dbPath, 'booktrack.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE libros (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo TEXT NOT NULL,
            ruta TEXT NOT NULL,
            formato TEXT NOT NULL,
            paginaActual INTEGER NOT NULL DEFAULT 0,
            totalPaginas INTEGER NOT NULL DEFAULT 0,
            terminado INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );

    return _database!;
  }

  static Future<int> agregarLibro(Libro libro) async {
    final db = await database;
    return db.insert('libros', libro.toMap());
  }

  static Future<List<Libro>> obtenerLibros() async {
    final db = await database;
    final resultado = await db.query('libros', orderBy: 'id DESC');

    return resultado.map((map) => Libro.fromMap(map)).toList();
  }

  static Future<int> actualizarLibro(Libro libro) async {
    final db = await database;

    return db.update(
      'libros',
      libro.toMap(),
      where: 'id = ?',
      whereArgs: [libro.id],
    );
  }

  static Future<int> eliminarLibro(int id) async {
    final db = await database;

    return db.delete('libros', where: 'id = ?', whereArgs: [id]);
  }
}
