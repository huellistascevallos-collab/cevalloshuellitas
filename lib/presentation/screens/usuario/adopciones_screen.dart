import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../domain/controllers/auth_controller.dart';
import '../../../domain/controllers/mascota_controller.dart';
import '../../../domain/controllers/solicitud_adopcion_controller.dart';
import '../../../data/models/mascota_model.dart';
import '../../../presentation/widgets/safe_network_image.dart';

// ─── Paleta de colores Premium de la imagen ───────────────────────────────────
const _teal = Color(0xFF2FA3A3);       // Botones secundarios, "Ver Perfil" y tags
const _orange = Color(0xFFE58D57);     // Botón "¡Adoptar!", favoritos e información
const _headerBg = Color(0xFFBBE7EC);   // Fondo celeste pastel de la cabecera
const _bg = Color(0xFFF6FAFA);         // Fondo general de la app
const _dark = Color(0xFF262A2B);       // Títulos y textos principales
const _grey = Color(0xFF8A9BB0);       // Textos e íconos secundarios

class AdopcionesScreen extends StatefulWidget {
  const AdopcionesScreen({super.key});

  @override
  State<AdopcionesScreen> createState() => _AdopcionesScreenState();
}

class _AdopcionesScreenState extends State<AdopcionesScreen> {
  // ── Filtros ────────────────────────────────────────────────────────────────
  String? _filtroGenero;   // null = todos
  String? _filtroEspecie;  // null = todos
  String? _filtroAnio;     // null = todos

  // Opciones de filtro
  static const _generosOpciones  = ['Macho', 'Hembra'];
  static const _especiesOpciones = ['Perro', 'Gato', 'Ave', 'Conejo', 'Otro'];
  static const _aniosOpciones    = [
    '< 1 año', '1 año', '2 años', '3 años', '4 años',
    '5 años', '6 años', '7 años', '8+ años',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MascotaController>().cargarMascotasAdopcion();
      // Cargar solicitudes enviadas por el usuario actual
      final uid = context.read<AuthController>().currentUser?.id;
      if (uid != null) {
        context.read<SolicitudAdopcionController>().cargarMisSolicitudes(uid);
      }
    });
  }

  List<MascotaModel> _obtenerMascotasFiltradas(List<MascotaModel> todas) {
    return todas.where((m) {
      // Filtro género
      if (_filtroGenero != null) {
        if (!m.genero.toLowerCase().contains(_filtroGenero!.toLowerCase())) {
          return false;
        }
      }
      // Filtro especie
      if (_filtroEspecie != null) {
        final esp = m.especie.toLowerCase();
        final filtro = _filtroEspecie!.toLowerCase();
        if (filtro == 'otro') {
          final conocidas = ['perro', 'gato', 'ave', 'conejo'];
          if (conocidas.any((c) => esp.contains(c))) return false;
        } else {
          if (!esp.contains(filtro)) return false;
        }
      }
      // Filtro año (edad)
      if (_filtroAnio != null) {
        final anios = _extraerAnios(m.edad);
        switch (_filtroAnio) {
          case '< 1 año':  if (anios >= 1) return false;
          case '1 año':    if (anios.round() != 1) return false;
          case '2 años':   if (anios.round() != 2) return false;
          case '3 años':   if (anios.round() != 3) return false;
          case '4 años':   if (anios.round() != 4) return false;
          case '5 años':   if (anios.round() != 5) return false;
          case '6 años':   if (anios.round() != 6) return false;
          case '7 años':   if (anios.round() != 7) return false;
          case '8+ años':  if (anios < 8) return false;
        }
      }
      return true;
    }).toList();
  }

  /// Extrae el número de años de strings como "2 años", "6 meses", "1 año"
  double _extraerAnios(String edad) {
    final lower = edad.toLowerCase();
    final num = double.tryParse(
        RegExp(r'(\d+(\.\d+)?)').firstMatch(lower)?.group(1) ?? '') ?? 0;
    if (lower.contains('mes')) return num / 12;
    return num;
  }

  bool get _hayFiltros =>
      _filtroGenero != null || _filtroEspecie != null || _filtroAnio != null;

  void _limpiarFiltros() => setState(() {
        _filtroGenero = null;
        _filtroEspecie = null;
        _filtroAnio = null;
      });

  // ── Sheet de Mis Favoritos ────────────────────────────────────────────────
  void _showFavoritosSheet(BuildContext context) {
    final adopContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<MascotaController>(),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.92,
          minChildSize: 0.3,
          builder: (_, sc) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: Color(0xFFE53935), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Mis Favoritos',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _dark)),
                ]),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Consumer<MascotaController>(
                  builder: (sheetCtx, ctrl, _) {
                    final favs = ctrl.mascotasFavoritas;
                    if (favs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border_rounded,
                                size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No tienes mascotas favoritas aún.',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey.shade500,
                                    fontSize: 14)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: sc,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      itemCount: favs.length,
                      itemBuilder: (_, i) {
                        final m = favs[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFFFCDD2)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              // Foto
                              Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SafeNetworkImage(
                                  url: m.fotoUrl,
                                  borderRadius: BorderRadius.circular(12),
                                  fallbackIcon: Icons.pets_rounded,
                                  fallbackColor: _teal,
                                  fallbackIconSize: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.nombre,
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: _dark)),
                                    Text('${m.especie} · ${m.raza}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.grey.shade500)),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pop(sheetCtx);
                                        _showPerfilDialog(adopContext, m);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _teal.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                              color: _teal.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.visibility_outlined,
                                                color: _teal, size: 11),
                                            const SizedBox(width: 3),
                                            Text('Ver Perfil',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: _teal)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Quitar favorito
                              GestureDetector(
                                onTap: () => ctrl.toggleFavorito(m.id),
                                child: const Icon(Icons.favorite_rounded,
                                    color: Color(0xFFE53935), size: 24),
                              ),
                            ]),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Sheet de Mis Solicitudes ──────────────────────────────────────────────
  void _showMisSolicitudesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<SolicitudAdopcionController>()),
          ChangeNotifierProvider.value(value: context.read<AuthController>()),
        ],
        child: DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.92,
          minChildSize: 0.35,
          builder: (_, sc) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_rounded, color: _orange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Mis Solicitudes',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _dark)),
                ]),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Solicitudes enviadas — cancela si te equivocaste',
                  style: GoogleFonts.poppins(fontSize: 11, color: _grey),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Consumer<SolicitudAdopcionController>(
                  builder: (ctx, ctrl, _) {
                    final solicitudes = [...ctrl.misSolicitudes]
                      ..sort((a, b) => b.fecha.compareTo(a.fecha)); // más reciente primero
                    if (ctrl.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: _orange),
                      );
                    }
                    if (solicitudes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none_rounded,
                                size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No has enviado solicitudes aún.',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey.shade500, fontSize: 14)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: sc,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: solicitudes.length,
                      itemBuilder: (_, i) {
                        final s = solicitudes[i];
                        final estadoColor = _colorEstado(s.estado);
                        final estadoIcon = _iconEstado(s.estado);
                        final puedeCancel = s.estado == 'Pendiente';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: estadoColor.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: estadoColor.withValues(alpha: 0.25)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Foto mascota
                                Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F9FA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: estadoColor.withValues(alpha: 0.3)),
                                  ),
                                  child: SafeNetworkImage(
                                    url: s.mascotaFotoUrl,
                                    borderRadius: BorderRadius.circular(12),
                                    fallbackIcon: Icons.pets_rounded,
                                    fallbackColor: _teal,
                                    fallbackIconSize: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.mascotaNombre ?? 'Mascota',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14, color: _dark),
                                      ),
                                      if (s.mascotaEspecie != null)
                                        Text(
                                          '${s.mascotaEspecie}${s.mascotaRaza != null ? ' · ${s.mascotaRaza}' : ''}',
                                          style: GoogleFonts.poppins(
                                              fontSize: 11, color: _grey),
                                        ),
                                      const SizedBox(height: 6),
                                      // Badge de estado
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: estadoColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                              color: estadoColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(estadoIcon, size: 12, color: estadoColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              s.estado,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: estadoColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatFecha(s.fecha),
                                        style: GoogleFonts.poppins(
                                            fontSize: 10, color: _grey),
                                      ),
                                    ],
                                  ),
                                ),
                                // Botón cancelar (solo si Pendiente)
                                if (puedeCancel)
                                  GestureDetector(
                                    onTap: () async {
                                      final confirmar = await showDialog<bool>(
                                        context: ctx,
                                        builder: (_) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16)),
                                          title: Text('Cancelar solicitud',
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16)),
                                          content: Text(
                                            '¿Seguro que quieres cancelar la solicitud para ${s.mascotaNombre ?? 'esta mascota'}?',
                                            style: GoogleFonts.poppins(fontSize: 13),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: Text('No',
                                                  style: GoogleFonts.poppins(color: _grey)),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFE53935),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: Text('Sí, cancelar',
                                                  style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.w600)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmar == true) {
                                        await ctrl.cancelarSolicitud(s.id);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE53935).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: const Color(0xFFE53935).withValues(alpha: 0.2)),
                                      ),
                                      child: const Icon(Icons.close_rounded,
                                          size: 16, color: Color(0xFFE53935)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Pendiente':  return const Color(0xFFF59E0B);
      case 'Adoptado':   return const Color(0xFF10B981);
      case 'Rechazada':  return const Color(0xFFE53935);
      default:           return _grey;
    }
  }

  IconData _iconEstado(String estado) {
    switch (estado) {
      case 'Pendiente':  return Icons.schedule_rounded;
      case 'Adoptado':   return Icons.check_circle_rounded;
      case 'Rechazada':  return Icons.cancel_rounded;
      default:           return Icons.info_outline_rounded;
    }
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  void _showPerfilDialog(BuildContext context, MascotaModel mascota) {
    final uid = context.read<AuthController>().currentUser?.id;
    final esDuenio = uid != null && mascota.usuarioId == uid;
    showDialog(
      context: context,
      builder: (_) => Consumer<MascotaController>(
        builder: (ctx, controller, _) {
          final esFav = controller.esFavorito(mascota.id);
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: mascota.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SafeNetworkImage(
                          url: mascota.fotoUrl,
                          borderRadius: BorderRadius.circular(20),
                          fallbackIcon: mascota.icon,
                          fallbackColor: mascota.color,
                          fallbackIconSize: 80,
                        ),
                      ),
                      Positioned(
                        top: 8, right: 8,
                        child: GestureDetector(
                          onTap: () => controller.toggleFavorito(mascota.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 6)
                              ],
                            ),
                            child: Icon(
                              esFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: esFav ? const Color(0xFFE53935) : Colors.grey.shade400,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    mascota.nombre,
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: _dark),
                  ),
                  Text(
                    '${mascota.especie} · ${mascota.raza}',
                    style: GoogleFonts.poppins(fontSize: 13, color: _grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildChip(mascota.edad, Icons.cake_outlined, _orange),
                      const SizedBox(width: 8),
                      _buildChip(mascota.genero, Icons.transgender_rounded, _teal),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _teal.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      mascota.descripcion ?? 'Sin descripción disponible.',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // ── Datos del propietario ────────────────────────────────
                  if (mascota.propietarioNombre != null ||
                      mascota.propietarioTelefono != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _orange.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _orange.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.person_outline_rounded,
                                color: _orange, size: 15),
                            const SizedBox(width: 6),
                            Text('Propietario',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _orange)),
                          ]),
                          const SizedBox(height: 8),
                          // Foto + nombre + teléfono en fila
                          Row(crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                            // Avatar del propietario
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _orange.withValues(alpha: 0.12),
                                border: Border.all(
                                    color: _orange.withValues(alpha: 0.35),
                                    width: 2),
                              ),
                              child: ClipOval(
                                child: (mascota.propietarioFotoUrl != null &&
                                        mascota.propietarioFotoUrl!.isNotEmpty)
                                    ? Image.network(
                                        mascota.propietarioFotoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.person_rounded,
                                                size: 24, color: _orange))
                                    : const Icon(Icons.person_rounded,
                                        size: 24, color: _orange),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (mascota.propietarioNombre != null)
                                    Row(children: [
                                      const Icon(Icons.badge_outlined,
                                          size: 13, color: _grey),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                            mascota.propietarioNombre!,
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _dark)),
                                      ),
                                    ]),
                                  if (mascota.propietarioTelefono != null &&
                                      mascota.propietarioTelefono!
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      const Icon(Icons.phone_outlined,
                                          size: 13, color: _grey),
                                      const SizedBox(width: 5),
                                      Text(mascota.propietarioTelefono!,
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _dark)),
                                    ]),
                                  ],
                                ],
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _teal),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Cerrar',
                            style: GoogleFonts.poppins(color: _teal, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: esDuenio
                            ? OutlinedButton(
                                onPressed: null,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: _teal.withValues(alpha: 0.4)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  '🏠 Tu mascota',
                                  style: GoogleFonts.poppins(color: _teal, fontWeight: FontWeight.w600),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showAdoptarDialog(context, mascota);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _orange,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  '¡Adoptar!',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mascotaController = context.watch<MascotaController>();
    final isLoading = mascotaController.isLoadingAdopciones;
    final mascotasAdopcion = mascotaController.mascotasAdopcion;
    final mascotasFiltradas = _obtenerMascotasFiltradas(mascotasAdopcion);

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Cabecera celeste con curva convexa ──
          SliverToBoxAdapter(
            child: ClipPath(
              clipper: _HeaderWaveClipper(),
              child: Container(
                height: 180,
                color: _headerBg,
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            Text(
                              'Adopciones',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _dark,
                              ),
                            ),
                            const Spacer(),
                            // Botón mis solicitudes (notificaciones)
                            Consumer<SolicitudAdopcionController>(
                              builder: (_, ctrl, __) {
                                final pendientes = ctrl.misSolicitudes
                                    .where((s) => s.estado == 'Pendiente')
                                    .length;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.notifications_outlined, color: _dark, size: 24),
                                      tooltip: 'Mis solicitudes',
                                      onPressed: () => _showMisSolicitudesSheet(context),
                                    ),
                                    if (pendientes > 0)
                                      Positioned(
                                        top: 6, right: 6,
                                        child: Container(
                                          width: 16, height: 16,
                                          decoration: const BoxDecoration(
                                            color: _orange,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              pendientes > 9 ? '9+' : '$pendientes',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.favorite_border_rounded, color: _dark, size: 24),
                              tooltip: 'Mis favoritos',
                              onPressed: () => _showFavoritosSheet(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Encuentra a tu compañero ideal',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _dark.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Filtros por Género · Especie · Edad ──────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila: etiqueta + botón limpiar
                  Row(children: [
                    const Icon(Icons.tune_rounded, size: 16, color: _teal),
                    const SizedBox(width: 6),
                    Text('Filtros',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _dark)),
                    const Spacer(),
                    if (_hayFiltros)
                      GestureDetector(
                        onTap: _limpiarFiltros,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFFE53935).withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.close_rounded,
                                  size: 12, color: Color(0xFFE53935)),
                              const SizedBox(width: 4),
                              Text('Limpiar',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFE53935))),
                            ],
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 10),
                  // Tres dropdowns en fila
                  Row(children: [
                    Expanded(
                      child: _FiltroDropdown(
                        icono: Icons.transgender_rounded,
                        etiqueta: 'Género',
                        valor: _filtroGenero,
                        opciones: _generosOpciones,
                        onChanged: (v) => setState(() => _filtroGenero = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FiltroDropdown(
                        icono: Icons.pets_rounded,
                        etiqueta: 'Especie',
                        valor: _filtroEspecie,
                        opciones: _especiesOpciones,
                        onChanged: (v) => setState(() => _filtroEspecie = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FiltroDropdown(
                        icono: Icons.cake_rounded,
                        etiqueta: 'Año',
                        valor: _filtroAnio,
                        opciones: _aniosOpciones,
                        onChanged: (v) => setState(() => _filtroAnio = v),
                      ),
                    ),
                  ]),
                  // Chips de filtros activos
                  if (_hayFiltros) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (_filtroGenero != null)
                          _FiltroChipActivo(
                              label: _filtroGenero!,
                              onRemove: () =>
                                  setState(() => _filtroGenero = null)),
                        if (_filtroEspecie != null)
                          _FiltroChipActivo(
                              label: _filtroEspecie!,
                              onRemove: () =>
                                  setState(() => _filtroEspecie = null)),
                        if (_filtroAnio != null)
                          _FiltroChipActivo(
                              label: _filtroAnio!,
                              onRemove: () =>
                                  setState(() => _filtroAnio = null)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Contador de resultados
                  Text(
                    '${mascotasFiltradas.length} mascota${mascotasFiltradas.length != 1 ? "s" : ""} encontrada${mascotasFiltradas.length != 1 ? "s" : ""}',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: _grey,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          // ── Lista de adopciones (Feed Profesional) ──
          isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: _teal)),
                )
              : mascotasFiltradas.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pets_outlined, size: 60, color: _grey.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text(
                              'Sin mascotas en esta categoría',
                              style: GoogleFonts.poppins(color: _grey, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildAdopcionCard(mascotasFiltradas[index]);
                        },
                        childCount: mascotasFiltradas.length,
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildAdopcionCard(MascotaModel mascota) {
    // El estado 'para adoptar' es el único que llega aquí (filtra el servicio)
    final color = mascota.color;
    final descripcion = (mascota.descripcion != null && mascota.descripcion!.isNotEmpty)
        ? mascota.descripcion!
        : 'Mascota lista para encontrar un nuevo hogar lleno de amor. ¡Ven a conocerla!';

    return Consumer<MascotaController>(
      builder: (context, controller, _) {
        final esFav = controller.esFavorito(mascota.id);
        final uid = context.read<AuthController>().currentUser?.id;
        final esDuenio = uid != null && mascota.usuarioId == uid;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de la Tarjeta
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Icon(mascota.icon, size: 22, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                mascota.nombre,
                                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _dark),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                  mascota.especie,
                                  style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                                ),
                              ),
                              if (esDuenio) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: _teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Text(
                                    '🏠 Tuya',
                                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: _teal),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 12, color: _grey),
                              const SizedBox(width: 2),
                              Text('Ecuador',
                                  style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Área de Foto con Overlay de información estilizado
              Container(
                width: double.infinity,
                height: 280,
                color: color.withValues(alpha: 0.05),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (mascota.fotoUrl != null && mascota.fotoUrl!.isNotEmpty)
                      Positioned.fill(
                        child: ClipRect(
                          child: Image.network(
                            mascota.fotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(color, mascota.icon),
                          ),
                        ),
                      )
                    else
                      _buildPlaceholder(color, mascota.icon),
                    // Badges de información flotantes en la foto (Glassmorphism style)
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            _buildInfoBadge(mascota.raza, Icons.category_outlined),
                            const SizedBox(width: 8),
                            _buildInfoBadge(mascota.edad, Icons.cake_outlined),
                            const SizedBox(width: 8),
                            _buildInfoBadge(mascota.genero, Icons.transgender_rounded),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Fila de Acciones
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => controller.toggleFavorito(mascota.id),
                      child: Row(
                        children: [
                          Icon(
                            esFav ? Icons.favorite_rounded : Icons.favorite_outline,
                            color: const Color(0xFFE53935),
                            size: 26,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            esFav ? '1' : '0',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _dark),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showPerfilDialog(context, mascota),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: _teal),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Ver perfil',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _teal),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (esDuenio)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '🏠 Tu mascota',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _teal),
                        ),
                      )
                    else
                      Consumer<SolicitudAdopcionController>(
                        builder: (ctx, soli, _) {
                          // Verificar si ya envió solicitud para esta mascota
                          final solicitudExistente = soli.misSolicitudes
                              .where((s) => s.mascId == mascota.id)
                              .firstOrNull;
                          final yaEnvio = solicitudExistente != null;
                          final estadoSoli = solicitudExistente?.estado ?? '';

                          if (yaEnvio) {
                            final color = _colorEstado(estadoSoli);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: color.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_iconEstado(estadoSoli), size: 13, color: color),
                                  const SizedBox(width: 5),
                                  Text(
                                    estadoSoli == 'Pendiente' ? 'Solicitado' : estadoSoli,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: color),
                                  ),
                                ],
                              ),
                            );
                          }

                          return GestureDetector(
                            onTap: () => _showAdoptarDialog(context, mascota),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _orange,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _orange.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                '¡Adoptar!',
                                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              // Descripción del animal
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF2D2D2D)),
                    children: [
                      TextSpan(text: '${mascota.nombre} ', style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: descripcion),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF555555)),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF2D2D2D))),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(Color color, IconData icon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _PawPatternPainter(color: color.withValues(alpha: 0.05))),
        ),
        Icon(icon, size: 100, color: color.withValues(alpha: 0.4)),
      ],
    );
  }

  void _showAdoptarDialog(BuildContext context, MascotaModel mascota) {
    final uid = context.read<AuthController>().currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debes iniciar sesión para enviar una solicitud'),
      ));
      return;
    }

    // Bloquear al dueño de adoptar su propia mascota
    if (mascota.usuarioId == uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Esta mascota te pertenece, no puedes adoptarla.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
          ]),
          backgroundColor: _teal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.volunteer_activism_rounded,
                color: _orange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Adoptar a ${mascota.nombre}',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Al confirmar, se enviará una solicitud al dueño de la mascota.',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _orange.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: _orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El dueño revisará tu solicitud y te notificará su decisión.',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: _orange, height: 1.4),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(
                    color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          Consumer<SolicitudAdopcionController>(
            builder: (ctx, ctrl, _) => ElevatedButton(
              onPressed: ctrl.isLoading
                  ? null
                  : () async {
                      final ok = await ctrl.enviarSolicitud(
                        usuaId: uid,
                        mascId: mascota.id,
                      );
                      if (!context.mounted) return;
                      // Recargar solicitudes para actualizar el badge y los botones
                      ctrl.cargarMisSolicitudes(uid);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Row(children: [
                          Icon(
                            ok
                                ? Icons.check_circle_outline_rounded
                                : Icons.error_outline_rounded,
                            color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ok
                                  ? '¡Solicitud enviada! El dueño te contactará pronto.'
                                  : (ctrl.errorMessage ?? 'Error al enviar'),
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                        ]),
                        backgroundColor:
                            ok ? const Color(0xFF43B89C) : const Color(0xFFE53935),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ));
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: ctrl.isLoading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Enviar Solicitud',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dropdown de filtro ────────────────────────────────────────────────────────
class _FiltroDropdown extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String? valor;
  final List<String> opciones;
  final ValueChanged<String?> onChanged;

  const _FiltroDropdown({
    required this.icono, required this.etiqueta, required this.valor,
    required this.opciones, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final activo = valor != null;
    return GestureDetector(
      onTap: () => _mostrarOpciones(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFF2FA3A3) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activo ? const Color(0xFF2FA3A3) : Colors.grey.shade200,
            width: 1.2,
          ),
          boxShadow: [BoxShadow(
            color: activo
                ? const Color(0xFF2FA3A3).withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 6, offset: const Offset(0, 2),
          )],
        ),
        child: Row(children: [
          Icon(icono, size: 13,
              color: activo ? Colors.white : const Color(0xFF8A9BB0)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(valor ?? etiqueta,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: activo ? Colors.white : const Color(0xFF262A2B))),
          ),
          Icon(Icons.expand_more_rounded, size: 14,
              color: activo ? Colors.white : const Color(0xFF8A9BB0)),
        ]),
      ),
    );
  }

  void _mostrarOpciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            Icon(icono, color: const Color(0xFF2FA3A3), size: 18),
            const SizedBox(width: 8),
            Text(etiqueta, style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: const Color(0xFF262A2B))),
          ]),
          const SizedBox(height: 12),
          _OpcionItem(label: 'Todos', seleccionado: valor == null,
              onTap: () { Navigator.pop(context); onChanged(null); }),
          ...opciones.map((op) => _OpcionItem(
            label: op, seleccionado: valor == op,
            onTap: () { Navigator.pop(context); onChanged(op); },
          )),
        ]),
      ),
    );
  }
}

class _OpcionItem extends StatelessWidget {
  final String label;
  final bool seleccionado;
  final VoidCallback onTap;
  const _OpcionItem({required this.label, required this.seleccionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: seleccionado
              ? const Color(0xFF2FA3A3).withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: seleccionado
                ? const Color(0xFF2FA3A3).withValues(alpha: 0.3)
                : Colors.grey.shade100,
          ),
        ),
        child: Row(children: [
          Expanded(child: Text(label, style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
              color: seleccionado
                  ? const Color(0xFF2FA3A3)
                  : const Color(0xFF262A2B)))),
          if (seleccionado)
            const Icon(Icons.check_rounded, color: Color(0xFF2FA3A3), size: 18),
        ]),
      ),
    );
  }
}

// ── Chip de filtro activo ─────────────────────────────────────────────────────
class _FiltroChipActivo extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FiltroChipActivo({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2FA3A3).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2FA3A3).withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: const Color(0xFF2FA3A3))),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close_rounded, size: 13, color: Color(0xFF2FA3A3)),
        ),
      ]),
    );
  }
}

class _PawPatternPainter extends CustomPainter {
  final Color color;
  const _PawPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 4; j++) {
        canvas.drawCircle(
          Offset(size.width * (0.15 + i * 0.18), size.height * (0.15 + j * 0.24)),
          8, paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Cortador de cabecera en onda convexa ──
class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 15,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
