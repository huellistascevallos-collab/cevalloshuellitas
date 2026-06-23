import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../data/models/veterinario_model.dart';
import '../../../domain/controllers/veterinario_controller.dart';

class MapaVeterinariosScreen extends StatefulWidget {
  const MapaVeterinariosScreen({super.key});

  @override
  State<MapaVeterinariosScreen> createState() => _MapaVeterinariosScreenState();
}

class _MapaVeterinariosScreenState extends State<MapaVeterinariosScreen> {
  final MapController _mapController = MapController();
  VeterinarioModel? _seleccionado;
  bool _mapReady = false;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearchingLocation = false;
  LatLng? _direccionMarker;
  String? _direccionNombre;
  LatLng? _currentLocation;

  // Centro por defecto — Ecuador (ajustá a tu ciudad si querés)
  static const LatLng _centroInicial = LatLng(-1.8312, -78.1834);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VeterinarioController>().cargarTodosLosVeterinarios();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _seleccionarVet(VeterinarioModel vet) {
    setState(() => _seleccionado = vet);
    _mapController.move(LatLng(vet.latitud!, vet.longitud!), 15);
  }

  void _cerrarCard() => setState(() => _seleccionado = null);

  Future<void> _buscarDireccion(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearchingLocation = true);

    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1');
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'com.cevallos.huellitas/1.0.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            _searchResults = data;
          });
        }
      }
    } catch (e) {
      debugPrint('Error al buscar dirección: $e');
    } finally {
      setState(() => _isSearchingLocation = false);
    }
  }

  Future<void> _obtenerUbicacionActual() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, activa los servicios de ubicación.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado.')),
          );
        }
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Los permisos de ubicación están permanentemente denegados.')),
        );
      }
      return;
    } 

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = latLng;
      });
      _mapController.move(latLng, 16);
    } catch (e) {
      debugPrint('Error al obtener ubicación actual: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // ── Mapa ──
          Consumer<VeterinarioController>(
            builder: (context, ctrl, _) {
              final vetsConUbicacion = ctrl.todos
                  .where((v) => v.latitud != null && v.longitud != null)
                  .toList();

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: vetsConUbicacion.isNotEmpty
                      ? LatLng(vetsConUbicacion.first.latitud!,
                          vetsConUbicacion.first.longitud!)
                      : _centroInicial,
                  initialZoom: 13,
                  onTap: (_, _) => _cerrarCard(),
                  onPositionChanged: (camera, hasGesture) {
                    setState(() {
                      _mapReady = true;
                    });
                  },
                ),
                children: [
                  // Tiles de OpenStreetMap (gratuito, sin API key)
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.cevallos.huellitas',
                  ),
                  // Marcador de ubicación actual del usuario (GPS)
                  if (_currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation!,
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF5BBFBF),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF5BBFBF).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  // Marcador de dirección buscada (si existe)
                  if (_direccionMarker != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _direccionMarker!,
                          width: 80,
                          height: 70,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE58D57),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black12, blurRadius: 4)
                                  ],
                                ),
                                child: Text(
                                  _direccionNombre ?? 'Dirección',
                                  style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.location_on_rounded,
                                  color: Color(0xFFE58D57), size: 30),
                            ],
                          ),
                        ),
                      ],
                    ),
                  // Marcadores de veterinarios
                  MarkerLayer(
                    markers: vetsConUbicacion.map((vet) {
                      final isSelected = _seleccionado?.id == vet.id;
                      return Marker(
                        point: LatLng(vet.latitud!, vet.longitud!),
                        width: isSelected ? 56 : 46,
                        height: isSelected ? 56 : 46,
                        child: GestureDetector(
                          onTap: () => _seleccionarVet(vet),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF5BBFBF)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF5BBFBF),
                                width: isSelected ? 3 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF5BBFBF)
                                      .withValues(alpha: 0.4),
                                  blurRadius: isSelected ? 12 : 6,
                                  spreadRadius: isSelected ? 2 : 0,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: (vet.fotoUrl != null &&
                                      vet.fotoUrl!.isNotEmpty)
                                  ? Image.network(vet.fotoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Icon(
                                        Icons.medical_services_rounded,
                                        size: isSelected ? 28 : 22,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF5BBFBF),
                                      ))
                                  : Icon(
                                      Icons.medical_services_rounded,
                                      size: isSelected ? 28 : 22,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF5BBFBF),
                                    ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),

          // ── AppBar flotante y Buscador ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _glassButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
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
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              const Icon(Icons.search_rounded,
                                  color: Color(0xFF5BBFBF), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: GoogleFonts.poppins(fontSize: 14),
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: 'Buscar dirección...',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade400,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onSubmitted: (val) => _buscarDireccion(val),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty) ...[
                                if (_isSearchingLocation)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF5BBFBF),
                                    ),
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Icons.search_rounded,
                                        color: Color(0xFF5BBFBF), size: 18),
                                    onPressed: () =>
                                        _buscarDireccion(_searchController.text),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _direccionMarker = null;
                                      _direccionNombre = null;
                                    });
                                  },
                                ),
                              ],
                              const SizedBox(width: 6),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Lista de resultados flotante
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8, left: 54),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, index) =>
                            Divider(color: Colors.grey.shade100, height: 1),
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          final displayName = item['display_name'] ?? 'Dirección';
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_rounded,
                                color: Color(0xFF5BBFBF), size: 18),
                            title: Text(
                              displayName,
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: const Color(0xFF1A1A2E)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              final double? lat =
                                  double.tryParse(item['lat']?.toString() ?? '');
                              final double? lon =
                                  double.tryParse(item['lon']?.toString() ?? '');
                              if (lat != null && lon != null) {
                                setState(() {
                                  _direccionMarker = LatLng(lat, lon);
                                  final address = item['address'];
                                  _direccionNombre = address != null
                                      ? (address['road'] ??
                                          address['suburb'] ??
                                          address['city'] ??
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

          // ── Card del veterinario seleccionado ──
          if (_seleccionado != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _VetCard(
                vet: _seleccionado!,
                onCerrar: _cerrarCard,
              ),
            ),

          // ── Botones de control (GPS, Brújula, Zoom) ──
          Positioned(
            right: 16,
            bottom: _seleccionado != null ? 160 : 24,
            child: Column(
              children: [
                // Brújula (solo aparece si el mapa está rotado)
                _compassButton(),
                if (_mapReady && _mapController.camera.rotation.abs() >= 1.0) const SizedBox(height: 10),

                // Botón GPS
                _gpsButton(),
                const SizedBox(height: 10),

                // Botones de Zoom
                _zoomButton(
                  icon: Icons.add_rounded,
                  onTap: () {
                    if (!_mapReady) return;
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(
                        _mapController.camera.center, zoom + 1);
                  },
                ),
                const SizedBox(height: 8),
                _zoomButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    if (!_mapReady) return;
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(
                        _mapController.camera.center, zoom - 1);
                  },
                ),
              ],
            ),
          ),

          // ── Indicador de carga ──
          Consumer<VeterinarioController>(
            builder: (_, ctrl, _) => ctrl.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF5BBFBF),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Mensaje si no hay vets con ubicación ──
          Consumer<VeterinarioController>(
            builder: (_, ctrl, _) {
              if (ctrl.isLoading) return const SizedBox.shrink();
              final sinUbicacion =
                  ctrl.todos.every((v) => v.latitud == null);
              if (!sinUbicacion) return const SizedBox.shrink();
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_off_rounded,
                          size: 48, color: Color(0xFF5BBFBF)),
                      const SizedBox(height: 12),
                      Text(
                        'Sin ubicaciones aún',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Los veterinarios aún no han\nregistrado su ubicación.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
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
        child: Icon(icon, color: const Color(0xFF5BBFBF), size: 20),
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
        child: Icon(icon, color: const Color(0xFF5BBFBF), size: 24),
      ),
    );
  }

  Widget _gpsButton() {
    return GestureDetector(
      onTap: _obtenerUbicacionActual,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location_rounded,
          color: Color(0xFF5BBFBF),
          size: 22,
        ),
      ),
    );
  }

  Widget _compassButton() {
    if (!_mapReady) return const SizedBox.shrink();
    final rotation = _mapController.camera.rotation;
    if (rotation.abs() < 1.0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _mapController.rotate(0.0),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Transform.rotate(
            angle: -rotation * (3.141592653589793 / 180),
            child: const Icon(
              Icons.explore_rounded,
              color: Color(0xFFE58D57),
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// Card del veterinario seleccionado
// ────────────────────────────────────────────────
class _VetCard extends StatelessWidget {
  final VeterinarioModel vet;
  final VoidCallback onCerrar;

  const _VetCard({required this.vet, required this.onCerrar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEBF7FC),
              border: Border.all(
                  color: const Color(0xFF5BBFBF).withValues(alpha: 0.3),
                  width: 2),
            ),
            child: ClipOval(
              child: (vet.fotoUrl != null && vet.fotoUrl!.isNotEmpty)
                  ? Image.network(vet.fotoUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.medical_services_rounded,
                        color: Color(0xFF5BBFBF),
                        size: 32,
                      ))
                  : const Icon(Icons.medical_services_rounded,
                      color: Color(0xFF5BBFBF), size: 32),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Badge disponible
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: vet.disponible
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
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
                if (vet.especialidad != null && vet.especialidad!.isNotEmpty)
                  Text(
                    vet.especialidad!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF5BBFBF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (vet.direccion != null && vet.direccion!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: Color(0xFFF0954A)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          vet.direccion!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (vet.tarifa != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tarifa: \$${vet.tarifa!.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF43B89C),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Botón cerrar
          GestureDetector(
            onTap: onCerrar,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded,
                  size: 18, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}
