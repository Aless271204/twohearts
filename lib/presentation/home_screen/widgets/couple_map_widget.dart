import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';

class CoupleMapWidget extends StatefulWidget {
  final String myCity;
  final String partnerCity;
  final List<String> travelCities;
  final bool realtimeEnabled;
  final ValueChanged<bool>? onRealtimeToggle;

  const CoupleMapWidget({
    super.key,
    required this.myCity,
    required this.partnerCity,
    this.travelCities = const [],
    this.realtimeEnabled = false,
    this.onRealtimeToggle,
  });

  @override
  State<CoupleMapWidget> createState() => _CoupleMapWidgetState();
}

class _CoupleMapWidgetState extends State<CoupleMapWidget> {
  // Real GPS coordinates (lat, lon) — set when real-time is ON
  double? _myLat;
  double? _myLon;
  bool _locating = false;
  String? _locationError;

  // Approximate normalized positions for cities on a world map image
  static const Map<String, Offset> _cityPositions = {
    'Madrid': Offset(0.46, 0.35),
    'Barcelona': Offset(0.48, 0.33),
    'Quito': Offset(0.26, 0.58),
    'Salinas': Offset(0.25, 0.59),
    'Lima': Offset(0.27, 0.62),
    'Bogotá': Offset(0.27, 0.55),
    'Buenos Aires': Offset(0.30, 0.75),
    'Ciudad de México': Offset(0.20, 0.47),
    'New York': Offset(0.25, 0.38),
    'London': Offset(0.46, 0.28),
    'Paris': Offset(0.47, 0.30),
    'Tokyo': Offset(0.80, 0.37),
    'Sydney': Offset(0.84, 0.72),
    'Dubai': Offset(0.60, 0.43),
    'Rome': Offset(0.50, 0.34),
    'Amsterdam': Offset(0.48, 0.27),
    'Berlin': Offset(0.50, 0.27),
    'default_left': Offset(0.25, 0.50),
    'default_right': Offset(0.70, 0.40),
  };

  @override
  void didUpdateWidget(CoupleMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.realtimeEnabled && !oldWidget.realtimeEnabled) {
      _requestAndFetchLocation();
    }
    if (!widget.realtimeEnabled && oldWidget.realtimeEnabled) {
      setState(() {
        _myLat = null;
        _myLon = null;
        _locationError = null;
      });
    }
  }

  Future<void> _requestAndFetchLocation() async {
    if (kIsWeb) {
      // Web: use browser geolocation via geolocator
      setState(() => _locating = true);
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            _locationError = 'Activa la ubicación en tu dispositivo';
            _locating = false;
          });
          return;
        }
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Permiso de ubicación denegado';
            _locating = false;
          });
          return;
        }
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
        setState(() {
          _myLat = pos.latitude;
          _myLon = pos.longitude;
          _locating = false;
          _locationError = null;
        });
      } catch (e) {
        setState(() {
          _locationError = 'No se pudo obtener la ubicación';
          _locating = false;
        });
      }
      return;
    }

    // Mobile: request permission then get location
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Activa el GPS en tu dispositivo';
          _locating = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Permiso de ubicación denegado';
            _locating = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Permiso denegado permanentemente. Actívalo en Ajustes.';
          _locating = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      setState(() {
        _myLat = pos.latitude;
        _myLon = pos.longitude;
        _locating = false;
        _locationError = null;
      });
    } catch (e) {
      setState(() {
        _locationError = 'No se pudo obtener la ubicación';
        _locating = false;
      });
    }
  }

  /// Convert GPS lat/lon to normalized map position (0..1)
  Offset _gpsToMapOffset(double lat, double lon) {
    // Simple equirectangular projection for the world map image
    // Map spans roughly -90 to 90 lat, -180 to 180 lon
    final x = ((lon + 180) / 360).clamp(0.0, 1.0);
    final y = ((90 - lat) / 180).clamp(0.0, 1.0);
    return Offset(x, y);
  }

  Offset _getCityPosition(String city, bool isLeft) {
    final key = city.split(',').first.trim();
    if (_cityPositions.containsKey(key)) return _cityPositions[key]!;
    return isLeft
        ? _cityPositions['default_left']!
        : _cityPositions['default_right']!;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Real-time toggle
          Row(
            children: [
              const Text('📍', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'Distancia en tiempo real',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: const Color(0xFF5A5A5A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_locating)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              const SizedBox(width: 6),
              Row(
                children: [
                  Text(
                    widget.realtimeEnabled ? 'ON' : 'OFF',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.realtimeEnabled
                          ? AppTheme.primary
                          : const Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Switch(
                    value: widget.realtimeEnabled,
                    onChanged: widget.onRealtimeToggle,
                    activeThumbColor: AppTheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
          if (_locationError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '⚠️ $_locationError',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          if (widget.realtimeEnabled && _myLat != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '✅ Ubicación real: ${_myLat!.toStringAsFixed(4)}, ${_myLon!.toStringAsFixed(4)}',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  const h = 200.0;

                  // Use real GPS if available, otherwise city-based
                  final Offset myPos =
                      (widget.realtimeEnabled && _myLat != null)
                      ? _gpsToMapOffset(_myLat!, _myLon!)
                      : _getCityPosition(widget.myCity, true);
                  final partnerPos = _getCityPosition(
                    widget.partnerCity,
                    false,
                  );

                  return Stack(
                    children: [
                      // Map background
                      SizedBox(
                        height: h,
                        width: w,
                        child: CustomImageWidget(
                          imageUrl:
                              'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800',
                          width: w,
                          height: h,
                          fit: BoxFit.cover,
                          semanticLabel:
                              'World map showing continents and oceans from above',
                        ),
                      ),
                      // Dark overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withAlpha(26),
                                Colors.black.withAlpha(102),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Travel city pins
                      ...widget.travelCities.map((city) {
                        final pos = _getCityPosition(city, true);
                        return Positioned(
                          left: pos.dx * w - 12,
                          top: pos.dy * h - 12,
                          child: _TravelPin(city: city.split(',').first.trim()),
                        );
                      }),
                      // Dotted line
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _DottedLinePainter(
                            from: Offset(myPos.dx * w, myPos.dy * h),
                            to: Offset(partnerPos.dx * w, partnerPos.dy * h),
                          ),
                        ),
                      ),
                      // My pin
                      Positioned(
                        left: myPos.dx * w - 30,
                        top: myPos.dy * h - 44,
                        child: _LocationPin(
                          city: widget.realtimeEnabled && _myLat != null
                              ? 'Mi ubicación'
                              : widget.myCity,
                          emoji: '💕',
                          isMe: true,
                        ),
                      ),
                      // Partner pin
                      Positioned(
                        left: partnerPos.dx * w - 30,
                        top: partnerPos.dy * h - 44,
                        child: _LocationPin(
                          city: widget.partnerCity,
                          emoji: '💙',
                          isMe: false,
                        ),
                      ),
                      // Bottom bar
                      Positioned(
                        bottom: 12,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(230),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '✈️',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.travelCities.isEmpty
                                        ? 'Mapa de su historia'
                                        : '${widget.travelCities.length} lugares visitados',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (widget.realtimeEnabled)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(230),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.gps_fixed,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _myLat != null
                                          ? 'GPS activo'
                                          : 'Obteniendo...',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Travel Pin ───────────────────────────────────────────────────────────────

class _TravelPin extends StatelessWidget {
  final String city;
  const _TravelPin({required this.city});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB347),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            city.length > 8 ? '${city.substring(0, 7)}…' : city,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFFFB347),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

// ── Location Pin ─────────────────────────────────────────────────────────────

class _LocationPin extends StatelessWidget {
  final String city;
  final String emoji;
  final bool isMe;

  const _LocationPin({
    required this.city,
    required this.emoji,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final label = city.split(',').first.trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primary : const Color(0xFF5B8DEF),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 10)),
              const SizedBox(width: 3),
              Text(
                label.length > 10 ? '${label.substring(0, 9)}…' : label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primary : const Color(0xFF5B8DEF),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

// ── Dotted Line Painter ───────────────────────────────────────────────────────

class _DottedLinePainter extends CustomPainter {
  final Offset from;
  final Offset to;

  const _DottedLinePainter({required this.from, required this.to});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(180)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashLen = 6.0;
    const gapLen = 4.0;
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = (dx * dx + dy * dy).abs() > 0
        ? (dx * dx + dy * dy).abs().toDouble()
        : 1.0;
    final length = dist > 0 ? dist.toDouble() : 1.0;
    final totalLen = length > 0 ? length : 1.0;
    // Use sqrt approximation
    final steps = (totalLen / (dashLen + gapLen)).ceil();
    if (steps <= 0) return;

    final path = Path();
    double traveled = 0;
    bool drawing = true;
    final normX = dx / (totalLen > 0 ? totalLen : 1);
    final normY = dy / (totalLen > 0 ? totalLen : 1);

    // Compute actual distance
    final actualDist = ((dx * dx + dy * dy) > 0) ? (dx * dx + dy * dy) : 1.0;

    // Simple dotted line using path
    final totalDistance = ((to - from).distance);
    if (totalDistance < 1) return;
    final unitX = dx / totalDistance;
    final unitY = dy / totalDistance;

    double d = 0;
    bool dash = true;
    while (d < totalDistance) {
      final segLen = dash ? dashLen : gapLen;
      final end = (d + segLen).clamp(0.0, totalDistance);
      if (dash) {
        path.moveTo(from.dx + unitX * d, from.dy + unitY * d);
        path.lineTo(from.dx + unitX * end, from.dy + unitY * end);
      }
      d += segLen;
      dash = !dash;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DottedLinePainter oldDelegate) =>
      oldDelegate.from != from || oldDelegate.to != to;
}
