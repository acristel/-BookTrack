import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/libro.dart';
import '../services/database_service.dart';

class BibliotecaScreen extends StatefulWidget {
  const BibliotecaScreen({super.key});

  @override
  State<BibliotecaScreen> createState() => _BibliotecaScreenState();
}

class _BibliotecaScreenState extends State<BibliotecaScreen> {
  List<Libro> libros = [];
  bool cargando = true;
  bool importando = false;

  @override
  void initState() {
    super.initState();
    cargarLibros();
  }

  // OBTENER LIBROS DESDE SQLITE
  Future<void> cargarLibros() async {
    try {
      final resultado = await DatabaseService.obtenerLibros();

      if (!mounted) return;

      setState(() {
        libros = resultado;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      mostrarMensaje('Error al cargar la biblioteca: $e');
    }
  }

  // MOSTRAR MENSAJES
  void mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }

  // IMPORTAR LIBROS PDF Y EPUB
  Future<void> importarLibro() async {
    if (importando) return;

    setState(() {
      importando = true;
    });

    String? rutaCopiada;

    try {
      // Abrir el selector de archivos.
      final resultado = await FilePicker.pickFiles();

      // El usuario canceló o no seleccionó archivos.
      if (resultado.isEmpty) return;

      // Obtener el primer archivo seleccionado.
      final archivo = resultado.first;
      final rutaOriginal = archivo.path;

      if (rutaOriginal == null) {
        mostrarMensaje('No se pudo acceder al archivo seleccionado.');
        return;
      }

      // Validar que sea PDF o EPUB.
      final formato = p.extension(archivo.name).toLowerCase();

      if (formato != '.pdf' && formato != '.epub') {
        mostrarMensaje('Solo se permiten archivos PDF y EPUB.');
        return;
      }

      // Obtener almacenamiento privado de BookTrack.
      final directorio = await getApplicationDocumentsDirectory();

      final carpetaLibros = Directory(p.join(directorio.path, 'libros'));

      // Crear carpeta si no existe.
      if (!await carpetaLibros.exists()) {
        await carpetaLibros.create(recursive: true);
      }

      // Generar nombre único.
      final nombreUnico = '${DateTime.now().microsecondsSinceEpoch}$formato';

      rutaCopiada = p.join(carpetaLibros.path, nombreUnico);

      // Copiar el archivo al almacenamiento de la aplicación.
      await File(rutaOriginal).copy(rutaCopiada);

      // Crear objeto Libro.
      final libro = Libro(
        titulo: p.basenameWithoutExtension(archivo.name),
        ruta: rutaCopiada,
        formato: formato.substring(1).toUpperCase(),
        paginaActual: 0,
        totalPaginas: 0,
        terminado: false,
      );

      // Registrar libro en SQLite.
      await DatabaseService.agregarLibro(libro);

      // La copia ya está registrada.
      rutaCopiada = null;

      // Actualizar biblioteca.
      await cargarLibros();

      mostrarMensaje('¡Libro agregado a tu biblioteca!');
    } catch (e) {
      // Eliminar la copia si ocurrió un error antes de guardarla.
      if (rutaCopiada != null) {
        try {
          final archivo = File(rutaCopiada);

          if (await archivo.exists()) {
            await archivo.delete();
          }
        } catch (_) {
          // Evitar que un error de limpieza oculte el original.
        }
      }

      mostrarMensaje('No se pudo importar el libro: $e');
    } finally {
      if (mounted) {
        setState(() {
          importando = false;
        });
      }
    }
  }

  // ELIMINAR LIBRO
  Future<void> eliminarLibro(Libro libro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar libro'),
        content: Text('¿Querés eliminar "${libro.titulo}" de tu biblioteca?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || libro.id == null) return;

    try {
      // Eliminar registro de SQLite.
      await DatabaseService.eliminarLibro(libro.id!);

      // Eliminar archivo del almacenamiento.
      final archivo = File(libro.ruta);

      if (await archivo.exists()) {
        await archivo.delete();
      }

      // Recargar la biblioteca.
      await cargarLibros();

      mostrarMensaje('Libro eliminado correctamente.');
    } catch (e) {
      mostrarMensaje('Error al eliminar el libro: $e');
    }
  }

  // CONSTRUIR TARJETA DE LIBRO
  Widget construirTarjeta(Libro libro) {
    final esPdf = libro.formato.toLowerCase() == 'pdf';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        // ICONO DEL LIBRO
        leading: Container(
          width: 55,
          height: 65,
          decoration: BoxDecoration(
            color: esPdf ? Colors.red.shade50 : Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            esPdf ? Icons.picture_as_pdf : Icons.menu_book,
            color: esPdf ? Colors.red : Colors.indigo,
            size: 32,
          ),
        ),

        // TÍTULO
        title: Text(
          libro.titulo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        // INFORMACIÓN Y PROGRESO
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Formato: ${libro.formato}'),

              const SizedBox(height: 8),

              LinearProgressIndicator(
                value: libro.progreso.clamp(0.0, 1.0),
                minHeight: 5,
                borderRadius: BorderRadius.circular(10),
              ),

              const SizedBox(height: 5),

              Text(
                '${(libro.progreso * 100).toStringAsFixed(0)}% leído',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),

        // MENÚ DE OPCIONES
        trailing: PopupMenuButton<String>(
          onSelected: (valor) {
            if (valor == 'eliminar') {
              eliminarLibro(libro);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar libro'),
                ],
              ),
            ),
          ],
        ),

        // ABRIR LIBRO (PENDIENTE)
        onTap: () {
          mostrarMensaje('Próximamente: lector de ${libro.formato}');
        },
      ),
    );
  }

  // INTERFAZ PRINCIPAL
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi biblioteca',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: cargando ? null : cargarLibros,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar biblioteca',
          ),
        ],
      ),

      // CONTENIDO
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : libros.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.library_books_outlined,
                      size: 90,
                      color: Colors.indigo,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Tu biblioteca está vacía',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Importá tu primer libro PDF o EPUB para comenzar.',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: importando ? null : importarLibro,
                      icon: const Icon(Icons.add),
                      label: const Text('Importar libro'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: libros.length,
              itemBuilder: (context, index) {
                return construirTarjeta(libros[index]);
              },
            ),

      // BOTÓN PARA AGREGAR LIBROS
      floatingActionButton: libros.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: importando ? null : importarLibro,
              icon: const Icon(Icons.add),
              label: Text(importando ? 'Importando...' : 'Agregar libro'),
            ),
    );
  }
}
