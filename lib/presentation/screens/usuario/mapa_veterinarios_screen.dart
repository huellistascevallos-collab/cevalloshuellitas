import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../../../data/models/veterinario_model.dart';
import '../../../domain/controllers/veterinario_controller.dart';

// ── Paleta ──────────────────────────────────────────────────────────────────
const _teal   = Color(0xFF2FA3A3);
const _orange = Color(0xFFE58D57);
const _dark   = Color(0xFF262A2B);
const _grey   = Color(0xFF8A9BB0);

class MapaVeterinariosScreen extends StatefulWidget {
  const MapaVeterinariosScreen({super.key});
  @override
  State<MapaVeterinariosScreen> createState() => _MapaVeterinariosScreenState();
}

class _MapaVeterinariosScreenState extends State<MapaVeterinariosScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  VeterinarioModel? _seleccionado;
  bool _mapReady = false;
  bool _locating = false;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearchingLocation = false;
  LatLng? _direccionMarker;
  String? _direccionNombre;
  LatLng? _currentLocation;

  late AnimationController _cardAnimCtrl;
  late Animation<Offset> _cardSlide;

  static const LatLng _centroInicial = LatLng(-1.8312, -78.1834);

  @override
  void initState() {
    super.initState();
    _cardAnimCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(parent: _cardAnimCtrl, curve: Curves.easeOutCubic));
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VeterinarioController>().cargarTodosLosVeterinarios();
    });
  }

  @override
  void dispose() {
    _cardAnimCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _seleccionarVet(VeterinarioModel vet) {
    setState(() => _seleccionado = vet);
    _cardAnimCtrl.forward(from: 0);
    _mapController.move(LatLng(vet.latitud!, vet.longitud!), 15);
  }

  void _cerrarCard() {
    _cardAnimCtrl.reverse().then((_) => setState(() => _seleccionado = null));
  }

  Future<void> _buscarDireccion(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearchingLocation = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1',
      );
      final response = await http.get(url,
          headers: {'User-Agent': 'com.cevallos.huellitas/1.0.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) setState(() => _searchResults = data);
      }
    } catch (e) {
      debugPrint('Error al buscar dirección: $e');
    } finally {
      setState(() => _isSearchingLocation = false);
    }
  }

  Future<void> _obtenerUbicacionActual() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack('Por favor, activa los servicios de ubicación.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _snack('Permiso de ubicación denegado.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _snack('Permisos denegados permanentemente. Actívalos en ajustes.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _currentLocation = latLng);
      _mapController.move(latLng, 16);
    } catch (e) {
      _snack('No se pudo obtener la ubicación.');
      debugPrint('GPS error: $e');
    } finally {
      setState(() => _locating = false);
    }
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
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // ── Mapa base ───────────────────────────────────────────────────
          Consumer<VeterinarioController>(
            builder: (context, ctrl, _) {
              final vets = ctrl.todos
                  .where((v) => v.latitud != null && v.longitud != null)
                  .toList();
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: vets.isNotEmpty
                      ? LatLng(vets.first.latitud!, vets.first.longitud!)
                      : _centroInicial,
                  initialZoom: 13,
                  onTap: (_, __) => _cerrarCard(),
                  onPositionChanged: (_, __) =>
                      setState(() => _mapReady = true),
                ),
                children: [
                  // Tiles OpenStreetMap
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.cevallos.huellitas',
                  ),
                  // Pulso de ubicación actual
                  if (_currentLocation != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: _currentLocation!,
                        width: 44,
                        height: 44,
                        child: _UserLocationMarker(),
                      ),
                    ]),
                  // Marcador de búsqueda
                  if (_direccionMarker != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: _direccionMarker!,
                        width: 120,
                        height: 72,
                        child: _SearchResultMarker(
                            label: _direccionNombre ?? 'Dirección'),
                      ),
                    ]),
                  // Marcadores de veterinarios
                  MarkerLayer(
                    markers: vets.map((vet) {
                      final selected = _seleccionado?.id == vet.id;
                      return Marker(
                        point: LatLng(vet.latitud!, vet.longitud!),
                        width: selected ? 64 : 52,
                        height: selected ? 64 : 52,
                        child: GestureDetector(
                          onTap: () => _seleccionarVet(vet),
                          child: _VetMarker(vet: vet, selected: selected),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),

          // ── Barra superior flotante ──────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Botón volver
                      _MapButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      // Buscador
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
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              const Icon(Icons.search_rounded,
                                  color: _teal, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, color: _dark),
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: 'Buscar dirección...',
                                    hintStyle: GoogleFonts.poppins(
                                        fontSize: 13, color: _grey),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onSubmitted: _buscarDireccion,
                                ),
                              ),
                              if (_searchController.text.isNotEmpty) ...[
                                _isSearchingLocation
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: _teal))
                                    : GestureDetector(
                                        onTap: () => _buscarDireccion(
                                            _searchController.text),
                                        child: const Icon(Icons.search_rounded,
                                            color: _teal, size: 18)),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _direccionMarker = null;
                                      _direccionNombre = null;
                                    });
                                    FocusScope.of(context).unfocus();
                                  },
                                  child: const Icon(Icons.close_rounded,
                                      size: 18, color: _grey),
                                ),
                              ],
                              const SizedBox(width: 10),
                            ],
                          ),
                        ),
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
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 230),
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
                                final addr = item['address'];
                                setState(() {
                                  _direccionMarker = LatLng(lat, lon);
                                  _direccionNombre = addr != null
                                      ? (addr['road'] ??
                                          addr['suburb'] ??
                                          addr['city'] ??
                                          'Dirección')
                                      : 'Dirección';
                                  _searchResults = [];
                                });
                                _mapController.move(LatLng(lat, lon), 15);
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

          // ── Controles laterales ──────────────────────────────────────────
          Positioned(
            right: 14,
            bottom: _seleccionado != null ? 280 : 30,
            child: Column(
              children: [
                // Brújula
                if (_mapReady && _mapController.camera.rotation.abs() >= 1.0)
                  ...[
                  GestureDetector(
                    onTap: () => _mapController.rotate(0.0),
                    child: _MapButton(
                      icon: Icons.explore_rounded,
                      iconColor: _orange,
                      rotate: -_mapController.camera.rotation *
                          (3.141592653589793 / 180),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                // GPS
                _MapButton(
                  icon: _locating
                      ? Icons.sync_rounded
                      : Icons.my_location_rounded,
                  iconColor: _currentLocation != null ? _teal : _grey,
                  onTap: _obtenerUbicacionActual,
                  loading: _locating,
                ),
                const SizedBox(height: 10),
                // Zoom +
                _MapButton(
                  icon: Icons.add_rounded,
                  onTap: () {
                    if (_mapReady) {
                      _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1);
                    }
                  },
                ),
                const SizedBox(height: 6),
                // Zoom -
                _MapButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    if (_mapReady) {
                      _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1);
                    }
                  },
                ),
              ],
            ),
          ),

          // ── Card animada del veterinario seleccionado ────────────────────
          if (_seleccionado != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _cardSlide,
                child: _VetDetailCard(
                  vet: _seleccionado!,
                  onCerrar: _cerrarCard,
                ),
              ),
            ),

          // ── Cargando ────────────────────────────────────────────────────
          Consumer<VeterinarioController>(
            builder: (_, ctrl, __) => ctrl.isLoading
                ? Container(
                    color: Colors.black.withValues(alpha: 0.15),
                    child: const Center(
                      child:
                          CircularProgressIndicator(color: _teal),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Sin veterinarios ─────────────────────────────────────────────
          Consumer<VeterinarioController>(
            builder: (_, ctrl, __) {
              if (ctrl.isLoading) return const SizedBox.shrink();
              if (ctrl.todos.any((v) => v.latitud != null)) {
                return const SizedBox.shrink();
              }
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 14)
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _teal.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_off_rounded,
                            size: 36, color: _teal),
                      ),
                      const SizedBox(height: 14),
                      Text('Sin ubicaciones aún',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _dark)),
                      const SizedBox(height: 6),
                      Text(
                        'Los veterinarios aún no han\nregistrado su clínica.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: _grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Marcador de ubicación del usuario ───────────────────────────────────────
class _UserLocationMarker extends StatefulWidget {
  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _scale = Tween(begin: 0.8, end: 1.4).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _scale,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: _teal,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: _teal.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1)
            ],
          ),
        ),
      ],
    );
  }
}

// ── Marcador de búsqueda ─────────────────────────────────────────────────────
class _SearchResultMarker extends StatelessWidget {
  final String label;
  const _SearchResultMarker({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: _orange,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
          ),
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        CustomPaint(
          painter: _TrianglePainter(color: _orange),
          size: const Size(12, 6),
        ),
        const Icon(Icons.location_on_rounded, color: _orange, size: 28),
      ],
    );
  }
}

// ── Marcador de veterinario ──────────────────────────────────────────────────
class _VetMarker extends StatelessWidget {
  final VeterinarioModel vet;
  final bool selected;
  const _VetMarker({required this.vet, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? _teal : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? _teal : _teal.withValues(alpha: 0.6),
          width: selected ? 3.5 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: selected ? 0.45 : 0.2),
            blurRadius: selected ? 16 : 8,
            spreadRadius: selected ? 3 : 0,
          ),
        ],
      ),
      child: ClipOval(
        child: vet.fotoUrl != null && vet.fotoUrl!.isNotEmpty
            ? Image.network(vet.fotoUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackIcon(selected))
            : _fallbackIcon(selected),
      ),
    );
  }

  Widget _fallbackIcon(bool sel) => Icon(
        Icons.medical_services_rounded,
        size: sel ? 30 : 24,
        color: sel ? Colors.white : _teal,
      );
}

// ── Botón de control del mapa ────────────────────────────────────────────────
class _MapButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final double? rotate;
  final bool loading;

  const _MapButton({
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
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _teal),
                ),
              )
            : rotate != null
                ? Transform.rotate(
                    angle: rotate!,
                    child: Icon(icon,
                        color: iconColor ?? _teal, size: 22),
                  )
                : Icon(icon, color: iconColor ?? _teal, size: 22),
      ),
    );
  }
}

// ── Card detalle del veterinario ─────────────────────────────────────────────
class _VetDetailCard extends StatelessWidget {
  final VeterinarioModel vet;
  final VoidCallback onCerrar;
  const _VetDetailCard({required this.vet, required this.onCerrar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _teal.withValues(alpha: 0.08),
                    border: Border.all(
                        color: _teal.withValues(alpha: 0.3), width: 2),
                  ),
                  child: ClipOval(
                    child: vet.fotoUrl != null && vet.fotoUrl!.isNotEmpty
                        ? Image.network(vet.fotoUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.medical_services_rounded,
                                    color: _teal, size: 32))
                        : const Icon(Icons.medical_services_rounded,
                            color: _teal, size: 32),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre + badge disponible
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vet.nombre ?? 'Veterinario',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _dark),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: vet.disponible
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: vet.disponible
                                        ? Colors.green.shade400
                                        : Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  vet.disponible ? 'Disponible' : 'Ocupado',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: vet.disponible
                                        ? Colors.green.shade600
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Especialidad
                      if (vet.especialidad != null &&
                          vet.especialidad!.isNotEmpty)
                        Text(vet.especialidad!,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: _teal,
                                fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                // Cerrar
                GestureDetector(
                  onTap: onCerrar,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Chips de info
            Row(
              children: [
                if (vet.experiencia != null)
                  _InfoChip(
                    icon: Icons.workspace_premium_rounded,
                    label: '${vet.experiencia} años exp.',
                    color: _teal,
                  ),
                if (vet.tarifa != null) ...[
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.attach_money_rounded,
                    label: '\$${vet.tarifa!.toStringAsFixed(2)}',
                    color: const Color(0xFF43B89C),
                  ),
                ],
              ],
            ),
            if (vet.direccion != null && vet.direccion!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 15, color: _orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      vet.direccion!,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: _grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            // Botón agendar cita
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/servicios'),
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: Text('Agendar cita',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
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
