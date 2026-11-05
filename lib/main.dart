import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'screens/home_screen.dart';
import 'screens/biblioteca_screen.dart';
import 'screens/estadisticas_screen.dart';
import 'widgets/banner_ad_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Google AdMob.
  await MobileAds.instance.initialize();

  runApp(const BookTrackApp());
}

class BookTrackApp extends StatelessWidget {
  const BookTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5265D8)),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      ),
      home: const BookTrackNavigation(),
    );
  }
}

class BookTrackNavigation extends StatefulWidget {
  const BookTrackNavigation({super.key});

  @override
  State<BookTrackNavigation> createState() => _BookTrackNavigationState();
}

class _BookTrackNavigationState extends State<BookTrackNavigation> {
  int selectedIndex = 0;

  static const List<Widget> screens = [
    HomeScreen(),
    BibliotecaScreen(),
    EstadisticasScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: screens),

      // Banner adaptable encima de la navegación.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),

          NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_books_outlined),
                selectedIcon: Icon(Icons.library_books),
                label: 'Biblioteca',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Estadísticas',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
