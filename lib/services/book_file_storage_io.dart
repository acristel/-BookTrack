import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> guardar(PlatformFile archivo, String extension) async {
  final rutaOriginal = archivo.path;
  if (rutaOriginal == null) {
    throw StateError('No se pudo acceder al archivo seleccionado.');
  }

  final directorio = await getApplicationDocumentsDirectory();
  final carpetaLibros = Directory(p.join(directorio.path, 'libros'));
  if (!await carpetaLibros.exists()) {
    await carpetaLibros.create(recursive: true);
  }

  final nombreUnico = '${DateTime.now().microsecondsSinceEpoch}$extension';
  final rutaCopiada = p.join(carpetaLibros.path, nombreUnico);
  await File(rutaOriginal).copy(rutaCopiada);
  return rutaCopiada;
}

Future<bool> existe(String ruta) => File(ruta).exists();

Future<Uint8List?> leer(String ruta) async => null;

Future<void> eliminar(String ruta) async {
  final archivo = File(ruta);
  if (await archivo.exists()) {
    await archivo.delete();
  }
}
