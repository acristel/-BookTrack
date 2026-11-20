import 'dart:typed_data';

import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

import 'epub_source_io.dart'
    if (dart.library.js_interop) 'epub_source_web.dart'
    as implementation;

EpubSource crearFuenteEpub(String ruta, Uint8List? contenido) {
  return implementation.crearFuenteEpub(ruta, contenido);
}
