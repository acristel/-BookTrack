import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/libro.dart';
import '../services/book_file_storage.dart';
import '../services/database_service.dart';
import '../services/epub_source.dart';

class LectorScreen extends StatefulWidget {
  const LectorScreen({super.key, required this.libro});

  final Libro libro;

  @override
  State<LectorScreen> createState() => _LectorScreenState();
}

class _LectorScreenState extends State<LectorScreen> {
  late final Future<Uint8List?> _contenidoLibro;
  final EpubController _controladorEpub = EpubController();
  Libro? _progresoPendiente;
  int? _ultimoProgresoEncolado;
  int? _ultimoTotalEncolado;
  int _paginaPdfActual = 1;
  int _totalPaginasPdf = 0;
  String? _errorCarga;
  bool _guardandoProgreso = false;

  @override
  void initState() {
    super.initState();
    _contenidoLibro = _cargarContenidoLibro();
    _paginaPdfActual = math.max(1, widget.libro.paginaActual);
    _totalPaginasPdf = widget.libro.totalPaginas;
    _ultimoProgresoEncolado = widget.libro.paginaActual;
    _ultimoTotalEncolado = widget.libro.totalPaginas;
  }

  void _guardarProgreso(int pagina, int totalPaginas) {
    if (widget.libro.id == null || totalPaginas <= 0) return;

    final paginaLimitada = pagina.clamp(0, totalPaginas).toInt();
    if (paginaLimitada == _ultimoProgresoEncolado &&
        totalPaginas == _ultimoTotalEncolado) {
      return;
    }

    _ultimoProgresoEncolado = paginaLimitada;
    _ultimoTotalEncolado = totalPaginas;
    _progresoPendiente = Libro(
      id: widget.libro.id,
      titulo: widget.libro.titulo,
      ruta: widget.libro.ruta,
      formato: widget.libro.formato,
      paginaActual: paginaLimitada,
      totalPaginas: totalPaginas,
      terminado: paginaLimitada >= totalPaginas,
    );

    if (!_guardandoProgreso) {
      unawaited(_procesarColaDeProgreso());
    }
  }

  Future<void> _procesarColaDeProgreso() async {
    _guardandoProgreso = true;
    try {
      while (_progresoPendiente != null) {
        final progreso = _progresoPendiente!;
        _progresoPendiente = null;
        try {
          await DatabaseService.actualizarLibro(progreso);
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No se pudo guardar el progreso: $error'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } finally {
      _guardandoProgreso = false;
    }
  }

  void _mostrarErrorCarga(String mensaje) {
    if (!mounted) return;
    setState(() {
      _errorCarga = mensaje;
    });
  }

  Future<Uint8List?> _cargarContenidoLibro() async {
    if (!await BookFileStorage.existe(widget.libro.ruta)) {
      throw StateError('No se encontró el archivo de este libro.');
    }
    return BookFileStorage.leer(widget.libro.ruta);
  }

  Widget _construirLector(Uint8List? contenido) {
    if (_errorCarga != null) {
      return _construirError(_errorCarga!);
    }

    if (widget.libro.formato.toUpperCase() == 'PDF') {
      final parametros = PdfViewerParams(
        onViewerReady: (document, controller) {
          _totalPaginasPdf = document.pages.length;
          _paginaPdfActual =
              controller.pageNumber ?? math.max(1, widget.libro.paginaActual);
          _guardarProgreso(_paginaPdfActual, _totalPaginasPdf);
        },
        onPageChanged: (pagina) {
          if (pagina == null) return;
          _paginaPdfActual = pagina;
          _guardarProgreso(pagina, _totalPaginasPdf);
        },
        onDocumentLoadFinished: (_, succeeded) {
          if (!succeeded) {
            _mostrarErrorCarga('No se pudo cargar el archivo PDF.');
          }
        },
      );
      if (kIsWeb) {
        if (contenido == null) {
          return _construirError('No se pudo leer el archivo PDF.');
        }
        return PdfViewer.data(
          contenido,
          sourceName: widget.libro.titulo,
          initialPageNumber: math.max(1, widget.libro.paginaActual),
          params: parametros,
        );
      }
      return PdfViewer.file(
        widget.libro.ruta,
        initialPageNumber: math.max(1, widget.libro.paginaActual),
        params: parametros,
      );
    }

    if (widget.libro.formato.toUpperCase() == 'EPUB') {
      return EpubViewer(
        epubController: _controladorEpub,
        epubSource: crearFuenteEpub(widget.libro.ruta, contenido),
        onLocationLoaded: () {
          if (widget.libro.totalPaginas > 0) {
            _controladorEpub.toProgressPercentage(widget.libro.progreso);
          }
        },
        onRelocated: (location) {
          final progreso = location.progress.clamp(0.0, 1.0);
          _guardarProgreso((progreso * 100).round(), 100);
        },
        onLoadError: (error) {
          _mostrarErrorCarga(
            'No se pudo cargar el archivo EPUB: ${error.message}',
          );
        },
      );
    }

    return _construirError(
      'El formato ${widget.libro.formato} no es compatible.',
    );
  }

  Widget _construirError(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.libro.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<Uint8List?>(
          future: _contenidoLibro,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _construirError('${snapshot.error}');
            }
            return _construirLector(snapshot.data);
          },
        ),
      ),
    );
  }
}
