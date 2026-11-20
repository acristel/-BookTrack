import 'dart:typed_data';

import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

EpubSource crearFuenteEpub(String ruta, Uint8List? contenido) {
  if (contenido == null) {
    throw StateError('El archivo EPUB no está disponible en el navegador.');
  }
  return EpubSource.fromData(contenido);
}
