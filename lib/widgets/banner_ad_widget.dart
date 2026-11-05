import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  int? _currentWidth;
  int _requestGeneration = 0;

  // ID real del banner de BookTrack.
  static const String realAdUnitId = 'ca-app-pub-9098157353616404/1999624051';

  // ID oficial de prueba de Google AdMob.
  static const String testAdUnitId = 'ca-app-pub-3940256099942544/9214589741';

  // Debug: anuncios de prueba.
  // Release: ID real de BookTrack.
  String get adUnitId => kReleaseMode ? realAdUnitId : testAdUnitId;

  Future<void> _loadBanner(int width, int generation) async {
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);

    if (!mounted || generation != _requestGeneration || size == null) {
      return;
    }

    late final BannerAd banner;

    banner = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || generation != _requestGeneration) {
            ad.dispose();
            return;
          }

          setState(() {
            _bannerAd = banner;
          });

          debugPrint('Banner de AdMob cargado correctamente.');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Error al cargar el banner: $error');
          ad.dispose();
        },
      ),
    );

    if (!mounted || generation != _requestGeneration) {
      banner.dispose();
      return;
    }

    await banner.load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final width = MediaQuery.sizeOf(context).width.floor();

    if (width <= 0 || width == _currentWidth) return;

    _currentWidth = width;
    final generation = ++_requestGeneration;

    final oldBanner = _bannerAd;
    _bannerAd = null;
    oldBanner?.dispose();

    _loadBanner(width, generation);
  }

  @override
  Widget build(BuildContext context) {
    final banner = _bannerAd;

    if (banner == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: banner.size.width.toDouble(),
      height: banner.size.height.toDouble(),
      child: AdWidget(ad: banner),
    );
  }

  @override
  void dispose() {
    ++_requestGeneration;
    _bannerAd?.dispose();
    super.dispose();
  }
}
