import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'database_service.dart';

Future<String> guardar(PlatformFile archivo, String extension) async {
  final contenido = await archivo.readAsBytes();

  final clave =
      'web:${DateTime.now().microsecondsSinceEpoch}:${archivo.name.hashCode}';
  await DatabaseService.guardarArchivo(clave, contenido);
  return clave;
}

Future<bool> existe(String ruta) async {
  return await DatabaseService.obtenerArchivo(ruta) != null;
}

Future<Uint8List?> leer(String ruta) => DatabaseService.obtenerArchivo(ruta);

Future<void> eliminar(String ruta) async {
  await DatabaseService.eliminarArchivo(ruta);
}
