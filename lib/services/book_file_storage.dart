import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'book_file_storage_io.dart'
    if (dart.library.js_interop) 'book_file_storage_web.dart'
    as implementation;

abstract final class BookFileStorage {
  static Future<String> guardar(PlatformFile archivo, String extension) {
    return implementation.guardar(archivo, extension);
  }

  static Future<bool> existe(String ruta) => implementation.existe(ruta);

  static Future<Uint8List?> leer(String ruta) => implementation.leer(ruta);

  static Future<void> eliminar(String ruta) => implementation.eliminar(ruta);
}
