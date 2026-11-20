import 'dart:typed_data';

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
      version: 2,
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
        await db.execute('''
          CREATE TABLE libro_archivos (
            clave TEXT PRIMARY KEY NOT NULL,
            contenido BLOB NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE libro_archivos (
              clave TEXT PRIMARY KEY NOT NULL,
              contenido BLOB NOT NULL
            )
          ''');
        }
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

  static Future<void> guardarArchivo(String clave, Uint8List contenido) async {
    final db = await database;
    await db.insert('libro_archivos', {
      'clave': clave,
      'contenido': contenido,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Uint8List?> obtenerArchivo(String clave) async {
    final db = await database;
    final resultado = await db.query(
      'libro_archivos',
      columns: ['contenido'],
      where: 'clave = ?',
      whereArgs: [clave],
      limit: 1,
    );

    return resultado.isEmpty
        ? null
        : resultado.first['contenido'] as Uint8List?;
  }

  static Future<int> eliminarArchivo(String clave) async {
    final db = await database;
    return db.delete('libro_archivos', where: 'clave = ?', whereArgs: [clave]);
  }
}
