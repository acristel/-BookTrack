import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

EpubSource crearFuenteEpub(String ruta, Uint8List? contenido) {
  return EpubSource.fromFile(File(ruta));
}
