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

  // Centro por defecto — Ecuador (ajustá a tu ciudad si querés)
  static const LatLng _centroInicial = LatLng(-1.8312, -78.1834);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VeterinarioController>().cargarTodosLosVeterinarios();
    });
  }

  void _seleccionarVet(VeterinarioModel vet) {
    setState(() => _seleccionado = vet);
    _mapController.move(LatLng(vet.latitud!, vet.longitud!), 15);
  }

  void _cerrarCard() => setState(() => _seleccionado = null);

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
                  onTap: (_, __) => _cerrarCard(),
                ),
                children: [
                  // Tiles de OpenStreetMap (gratuito, sin API key)
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.cevallos.huellitas',
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
                                  ? const Color(0xFF1CB5C9)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1CB5C9),
                                width: isSelected ? 3 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1CB5C9)
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
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.medical_services_rounded,
                                        size: isSelected ? 28 : 22,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF1CB5C9),
                                      ))
                                  : Icon(
                                      Icons.medical_services_rounded,
                                      size: isSelected ? 28 : 22,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF1CB5C9),
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

          // ── AppBar flotante ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              color: Color(0xFF1CB5C9), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Veterinarios cercanos',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
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

          // ── Botones de zoom ──
          Positioned(
            right: 16,
            bottom: _seleccionado != null ? 160 : 24,
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

          // ── Indicador de carga ──
          Consumer<VeterinarioController>(
            builder: (_, ctrl, __) => ctrl.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1CB5C9),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Mensaje si no hay vets con ubicación ──
          Consumer<VeterinarioController>(
            builder: (_, ctrl, __) {
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
                          size: 48, color: Color(0xFF1CB5C9)),
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
              color: const Color(0xFFE8F6F8),
              border: Border.all(
                  color: const Color(0xFF1CB5C9).withValues(alpha: 0.3),
                  width: 2),
            ),
            child: ClipOval(
              child: (vet.fotoUrl != null && vet.fotoUrl!.isNotEmpty)
                  ? Image.network(vet.fotoUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.medical_services_rounded,
                        color: Color(0xFF1CB5C9),
                        size: 32,
                      ))
                  : const Icon(Icons.medical_services_rounded,
                      color: Color(0xFF1CB5C9), size: 32),
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
                      color: const Color(0xFF1CB5C9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (vet.direccion != null && vet.direccion!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: Color(0xFFE58D57)),
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
