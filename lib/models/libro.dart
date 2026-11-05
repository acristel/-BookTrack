class Libro {
  final int? id;
  final String titulo;
  final String ruta;
  final String formato;
  final int paginaActual;
  final int totalPaginas;
  final bool terminado;

  const Libro({
    this.id,
    required this.titulo,
    required this.ruta,
    required this.formato,
    this.paginaActual = 0,
    this.totalPaginas = 0,
    this.terminado = false,
  });

  double get progreso {
    if (totalPaginas <= 0) return 0;
    return (paginaActual / totalPaginas).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'ruta': ruta,
      'formato': formato,
      'paginaActual': paginaActual,
      'totalPaginas': totalPaginas,
      'terminado': terminado ? 1 : 0,
    };
  }

  factory Libro.fromMap(Map<String, dynamic> map) {
    return Libro(
      id: map['id'] as int?,
      titulo: map['titulo'] as String,
      ruta: map['ruta'] as String,
      formato: map['formato'] as String,
      paginaActual: map['paginaActual'] as int,
      totalPaginas: map['totalPaginas'] as int,
      terminado: (map['terminado'] as int) == 1,
    );
  }
}
