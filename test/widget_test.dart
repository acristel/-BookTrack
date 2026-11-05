import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booktrack/main.dart';

void main() {
  testWidgets('BookTrack muestra sus pantallas', (WidgetTester tester) async {
    await tester.pumpWidget(const BookTrackApp());

    // Comprobar que aparece la pantalla inicial.
    expect(find.text('¡Hola, lector! 📚'), findsOneWidget);

    // Comprobar que existe la navegación.
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Estadísticas'), findsOneWidget);

    // Cambiar a la biblioteca.
    await tester.tap(find.byIcon(Icons.library_books_outlined));
    await tester.pumpAndSettle();

    // Verificar que se muestra la biblioteca.
    expect(find.text('Mi biblioteca'), findsOneWidget);
  });
}
