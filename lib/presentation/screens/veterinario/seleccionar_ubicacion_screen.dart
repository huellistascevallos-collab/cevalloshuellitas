import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../../../domain/controllers/veterinario_controller.dart';

// ── Paleta ──────────────────────────────────────────────────────────────────
const _teal   = Color(0xFF1CB5C9);
const _orange = Color(0xFFE58D57);
const _dark   = Color(0xFF262A2B);
const _grey   = Color(0xFF8A9BB0);

class SeleccionarUbicacionScreen extends StatefulWidget {
  const SeleccionarUbicacionScreen({super.key});
  @override
  State<SeleccionarUbicacionScreen> createState() =>
      _SeleccionarUbicacionScreenState();
}

class _SeleccionarUbicacionScreenState
    extends State<SeleccionarUbicacionScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  LatLng? _pinActual;
  String? _direccionActual;
  bool _buscandoDireccion = false;
  bool _guardando = false;
  bool _locating = false;
  bool _mapReady = false;

  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  static const LatLng _centroInicial = LatLng(-1.8312, -78.1834);

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _obtenerDireccion(LatLng punto) async {
    setState(() => _buscandoDireccion = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${punto.latitude}&lon=${punto.longitude}'
        '&format=json&accept-language=es',
      );
      final resp = await http.get(
          url, headers: {'User-Agent': 'HuellitasCevallos/1.0'});
      if (resp.statusCode == 200) {
        final data = convert.json.decode(resp.body);
        setState(() => _direccionActual = data['display_name'] as String?);
      }
    } catch (_) {
      setState(() => _direccionActual = null);
    } finally {
      setState(() => _buscandoDireccion = false);
    }
  }

  void _alTocarMapa(TapPosition _, LatLng punto) {
    setState(() => _pinActual = punto);
    _obtenerDireccion(punto);
  }

  Future<void> _buscarDireccion(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1',
      );
      final response = await http.get(
          url, headers: {'User-Agent': 'HuellitasCevallos/1.0'});
      if (response.statusCode == 200) {
        final data = convert.json.decode(response.body);
        if (data is List) setState(() => _searchResults = data);
      }
    } catch (e) {
      debugPrint('Error búsqueda: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _obtenerUbicacionActual() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) { _snack('Activa los servicios de ubicación.'); return; }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _snack('Permiso denegado.'); return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _snack('Permisos denegados permanentemente.'); return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _pinActual = latLng);
      _mapController.move(latLng, 16);
      _obtenerDireccion(latLng);
    } catch (e) {
      _snack('No se pudo obtener la ubicación.');
    } finally {
      setState(() => _locating = false);
    }
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
    _snack(ok ? '¡Ubicación guardada!' : (ctrl.errorMessage ?? 'Error al guardar'));
    if (ok) Navigator.pop(context);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: _dark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Mapa ────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centroInicial,
              initialZoom: 6,
              onTap: _alTocarMapa,
              onPositionChanged: (_, __) => setState(() => _mapReady = true),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.cevallos.huellitas',
              ),
              if (_pinActual != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _pinActual!,
                    width: 56,
                    height: 70,
                    child: const _ClinicaPin(),
                  ),
                ]),
            ],
          ),

          // ── AppBar flotante + Buscador ──────────────────────────────────
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Volver
                      _MapBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      // Buscador de dirección
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Row(children: [
                            const SizedBox(width: 14),
                            const Icon(Icons.search_rounded,
                                color: _teal, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: _dark),
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: 'Buscar tu dirección...',
                                  hintStyle: GoogleFonts.poppins(
                                      fontSize: 13, color: _grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                                onSubmitted: _buscarDireccion,
                              ),
                            ),
                            if (_searchCtrl.text.isNotEmpty) ...[
                              _isSearching
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: _teal))
                                  : GestureDetector(
                                      onTap: () => _buscarDireccion(
                                          _searchCtrl.text),
                                      child: const Icon(Icons.search_rounded,
                                          color: _teal, size: 18)),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchResults = []);
                                  FocusScope.of(context).unfocus();
                                },
                                child: const Icon(Icons.close_rounded,
                                    size: 18, color: _grey),
                              ),
                            ],
                            const SizedBox(width: 10),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // GPS
                      _MapBtn(
                        icon: _locating
                            ? Icons.sync_rounded
                            : Icons.my_location_rounded,
                        iconColor: _pinActual != null ? _teal : _grey,
                        loading: _locating,
                        onTap: _obtenerUbicacionActual,
                      ),
                    ],
                  ),
                  // Resultados de búsqueda
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8, left: 52),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: Colors.grey.shade100, height: 1),
                        itemBuilder: (context, i) {
                          final item = _searchResults[i];
                          return ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _teal.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on_rounded,
                                  color: _teal, size: 14),
                            ),
                            title: Text(
                              item['display_name'] ?? '',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: _dark),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              final lat = double.tryParse(
                                  item['lat']?.toString() ?? '');
                              final lon = double.tryParse(
                                  item['lon']?.toString() ?? '');
                              if (lat != null && lon != null) {
                                final latlng = LatLng(lat, lon);
                                setState(() {
                                  _pinActual = latlng;
                                  _searchResults = [];
                                });
                                _mapController.move(latlng, 15);
                                _obtenerDireccion(latlng);
                                FocusScope.of(context).unfocus();
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Controles laterales de zoom ──────────────────────────────────
          Positioned(
            right: 14,
            bottom: 240,
            child: Column(
              children: [
                if (_mapReady &&
                    _mapController.camera.rotation.abs() >= 1.0) ...[
                  GestureDetector(
                    onTap: () => _mapController.rotate(0.0),
                    child: _MapBtn(
                      icon: Icons.explore_rounded,
                      iconColor: _orange,
                      rotate: -_mapController.camera.rotation *
                          (3.141592653589793 / 180),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _MapBtn(
                  icon: Icons.add_rounded,
                  onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1),
                ),
                const SizedBox(height: 6),
                _MapBtn(
                  icon: Icons.remove_rounded,
                  onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1),
                ),
              ],
            ),
          ),

          // ── Panel inferior ───────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
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
                      width: 38, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  if (_pinActual == null) ...[
                    // Estado vacío
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _teal.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _teal.withValues(alpha: 0.15)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.touch_app_rounded,
                            color: _teal, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Toca el mapa o busca tu dirección\npara marcar la clínica',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: _grey, height: 1.4),
                          ),
                        ),
                      ]),
                    ),
                  ] else ...[
                    // Dirección seleccionada
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded,
                              color: _orange, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buscandoDireccion
                              ? Row(children: [
                                  SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.grey.shade400),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Obteniendo dirección...',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12, color: _grey)),
                                ])
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _direccionActual ?? 'Ubicación seleccionada',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: _dark,
                                          fontWeight: FontWeight.w500),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Lat: ${_pinActual!.latitude.toStringAsFixed(5)}'
                                      '  Lng: ${_pinActual!.longitude.toStringAsFixed(5)}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 10, color: _grey),
                                    ),
                                  ],
                                ),
                        ),
                        // Botón borrar pin
                        GestureDetector(
                          onTap: () => setState(() {
                            _pinActual = null;
                            _direccionActual = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close_rounded,
                                size: 14, color: Colors.grey.shade500),
                          ),
                        ),
                      ],
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
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade100,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _guardando
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text('Guardar ubicación',
                                    style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ],
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
}

// ── Pin de clínica ───────────────────────────────────────────────────────────
class _ClinicaPin extends StatelessWidget {
  const _ClinicaPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _teal,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: _teal.withValues(alpha: 0.45),
                blurRadius: 14,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        CustomPaint(
          painter: _TrianglePainter(color: _teal),
          size: const Size(16, 8),
        ),
      ],
    );
  }
}

// ── Botón de control del mapa ────────────────────────────────────────────────
class _MapBtn extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final double? rotate;
  final bool loading;

  const _MapBtn({
    required this.icon,
    this.iconColor,
    this.onTap,
    this.rotate,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
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
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _teal),
                ))
            : rotate != null
                ? Transform.rotate(
                    angle: rotate!,
                    child: Icon(icon, color: iconColor ?? _teal, size: 22))
                : Icon(icon, color: iconColor ?? _teal, size: 22),
      ),
    );
  }
}

// ── Triangle painter ─────────────────────────────────────────────────────────
class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
