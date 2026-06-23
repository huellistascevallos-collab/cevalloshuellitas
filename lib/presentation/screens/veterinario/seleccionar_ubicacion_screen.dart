import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../../../domain/controllers/veterinario_controller.dart';

class SeleccionarUbicacionScreen extends StatefulWidget {
  const SeleccionarUbicacionScreen({super.key});

  @override
  State<SeleccionarUbicacionScreen> createState() =>
      _SeleccionarUbicacionScreenState();
}

class _SeleccionarUbicacionScreenState
    extends State<SeleccionarUbicacionScreen> {
  final MapController _mapController = MapController();

  // Coordenadas del pin actual
  LatLng? _pinActual;
  String? _direccionActual;
  bool _buscandoDireccion = false;
  bool _guardando = false;

  // Centro inicial — Ecuador
  static const LatLng _centroInicial = LatLng(-1.8312, -78.1834);

  @override
  void initState() {
    super.initState();
    // Si el vet ya tiene ubicación, centra el mapa ahí
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final perfil = context.read<VeterinarioController>().perfil;
      if (perfil?.latitud != null && perfil?.longitud != null) {
        final pos = LatLng(perfil!.latitud!, perfil.longitud!);
        setState(() {
          _pinActual = pos;
          _direccionActual = perfil.direccion;
        });
        _mapController.move(pos, 15);
      }
    });
  }

  /// Obtiene la dirección aproximada de las coordenadas usando
  /// Nominatim (OpenStreetMap) — completamente gratuito.
  Future<void> _obtenerDireccion(LatLng punto) async {
    setState(() => _buscandoDireccion = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${punto.latitude}&lon=${punto.longitude}'
        '&format=json&accept-language=es',
      );
      final resp = await http.get(url, headers: {
        'User-Agent': 'HuellitasCevallos/1.0',
      });
      if (resp.statusCode == 200) {
        final data = convert.json.decode(resp.body);
        setState(() {
          _direccionActual = data['display_name'] as String?;
        });
      }
    } catch (_) {
      // Si falla el reverse geocoding igual guardamos las coordenadas
      setState(() => _direccionActual = null);
    } finally {
      setState(() => _buscandoDireccion = false);
    }
  }

  void _alTocarMapa(TapPosition _, LatLng punto) {
    setState(() => _pinActual = punto);
    _obtenerDireccion(punto);
  }

  Future<void> _guardarUbicacion() async {
    if (_pinActual == null) return;
    setState(() => _guardando = true);

    final ctrl = context.read<VeterinarioController>();
    final ok = await ctrl.guardarUbicacion(
      latitud: _pinActual!.latitude,
      longitud: _pinActual!.longitude,
      direccion: _direccionActual,
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Ubicación guardada correctamente'
            : (ctrl.errorMessage ?? 'Error al guardar')),
        backgroundColor: ok ? const Color(0xFF1CB5C9) : Colors.redAccent,
      ),
    );

    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Mapa ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centroInicial,
              initialZoom: 6,
              onTap: _alTocarMapa,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.cevallos.huellitas',
              ),
              if (_pinActual != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pinActual!,
                      width: 60,
                      height: 60,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1CB5C9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1CB5C9)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.medical_services_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          // Triángulo del pin
                          CustomPaint(
                            painter: _PinTriangle(),
                            size: const Size(16, 8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── AppBar flotante ──
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _glassButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        'Toca el mapa para marcar tu clínica',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Botones de zoom ──
          Positioned(
            right: 16,
            bottom: 220,
            child: Column(
              children: [
                _zoomButton(
                  icon: Icons.add_rounded,
                  onTap: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(
                        _mapController.camera.center, zoom + 1);
                  },
                ),
                const SizedBox(height: 8),
                _zoomButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(
                        _mapController.camera.center, zoom - 1);
                  },
                ),
              ],
            ),
          ),

          // ── Panel inferior con dirección y botón guardar ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_pinActual == null) ...[
                    Row(
                      children: [
                        const Icon(Icons.touch_app_rounded,
                            color: Color(0xFF1CB5C9), size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Toca el mapa para seleccionar\ntu ubicación',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: Color(0xFFE58D57), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buscandoDireccion
                              ? Row(children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Obteniendo dirección...',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey.shade400)),
                                ])
                              : Text(
                                  _direccionActual ??
                                      'Lat: ${_pinActual!.latitude.toStringAsFixed(5)}'
                                          ', Lng: ${_pinActual!.longitude.toStringAsFixed(5)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Text(
                        'Lat: ${_pinActual!.latitude.toStringAsFixed(5)}'
                        '  Lng: ${_pinActual!.longitude.toStringAsFixed(5)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_pinActual == null || _guardando)
                          ? null
                          : _guardarUbicacion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1CB5C9),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade200,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _guardando
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Guardar ubicación',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF1CB5C9), size: 20),
      ),
    );
  }

  Widget _zoomButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF1CB5C9), size: 24),
      ),
    );
  }
}

// Triángulo del pin del mapa
class _PinTriangle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1CB5C9)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
