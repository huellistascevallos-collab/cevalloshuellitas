import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/solicitud_adopcion_model.dart';
import '../../../domain/controllers/auth_controller.dart';
import '../../../domain/controllers/solicitud_adopcion_controller.dart';

const _teal = Color(0xFF2FA3A3);
const _orange = Color(0xFFE58D57);
const _headerBg = Color(0xFFBBE7EC);
const _bg = Color(0xFFF6FAFA);
const _dark = Color(0xFF262A2B);
const _grey = Color(0xFF8A9BB0);

/// Pantalla con dos tabs:
///  - "Mis Solicitudes": solicitudes que el usuario envió.
///  - "Recibidas": solicitudes recibidas para sus mascotas.
class SolicitudesAdopcionScreen extends StatefulWidget {
  const SolicitudesAdopcionScreen({super.key});

  @override
  State<SolicitudesAdopcionScreen> createState() =>
      _SolicitudesAdopcionScreenState();
}

class _SolicitudesAdopcionScreenState extends State<SolicitudesAdopcionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthController>().currentUser?.id;
      if (uid != null) {
        context.read<SolicitudAdopcionController>().cargarMisSolicitudes(uid);
        context.read<SolicitudAdopcionController>().cargarSolicitudesRecibidas(uid);
        // Suscribir a notificaciones realtime para este dueño
        context.read<SolicitudAdopcionController>().suscribirNotificaciones(uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Cabecera ──
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              color: _headerBg,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: _dark, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Text('Solicitudes de Adopción',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _dark)),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Text('Gestiona tus solicitudes',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _dark.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 14),
                    // Tabs
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                            color: _teal,
                            borderRadius: BorderRadius.circular(10)),
                        labelColor: Colors.white,
                        unselectedLabelColor: _dark,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600),
                        tabs: [
                          const Tab(text: 'Mis Solicitudes'),
                          Tab(
                            child: Consumer<SolicitudAdopcionController>(
                              builder: (ctx, ctrl, _) {
                                final pending = ctrl.pendientesRecibidas;
                                final notifs = ctrl.totalNotificaciones;
                                final badge = notifs > 0 ? notifs : pending;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Recibidas'),
                                    if (badge > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: notifs > 0 ? const Color(0xFFE53935) : _orange,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text('$badge',
                                            style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white)),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),

          // ── Banner de notificaciones nuevas ──
          Consumer<SolicitudAdopcionController>(
            builder: (ctx, ctrl, _) {
              if (ctrl.totalNotificaciones == 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.notifications_active_rounded,
                      color: Color(0xFFE53935), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${ctrl.totalNotificaciones} nueva${ctrl.totalNotificaciones > 1 ? 's' : ''} solicitud${ctrl.totalNotificaciones > 1 ? 'es' : ''} de adopción recibida${ctrl.totalNotificaciones > 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE53935)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ctrl.limpiarNotificaciones();
                      _tabController.animateTo(1);
                    },
                    child: Text('Ver',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE53935),
                            decoration: TextDecoration.underline)),
                  ),
                ]),
              );
            },
          ),

          // ── Contenido ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MisSolicitudesTab(),
                _RecibidasTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab: Mis Solicitudes ─────────────────────────────────────────────────────
class _MisSolicitudesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SolicitudAdopcionController>(
      builder: (ctx, ctrl, _) {
        if (ctrl.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: _teal));
        }
        if (ctrl.misSolicitudes.isEmpty) {
          return _emptyState(
            icon: Icons.volunteer_activism_outlined,
            title: 'Sin solicitudes enviadas',
            subtitle: 'Explora la sección de Adopciones y\nenvía tu primera solicitud.',
          );
        }
        return RefreshIndicator(
          color: _teal,
          onRefresh: () async {
            final uid = context.read<AuthController>().currentUser?.id;
            if (uid != null) {
              await ctrl.cargarMisSolicitudes(uid);
            }
          },
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            itemCount: ctrl.misSolicitudes.length,
            itemBuilder: (_, i) =>
                _MiSolicitudCard(solicitud: ctrl.misSolicitudes[i]),
          ),
        );
      },
    );
  }
}

// ── Tarjeta: solicitud enviada por el usuario ────────────────────────────────
class _MiSolicitudCard extends StatelessWidget {
  final SolicitudAdopcionModel solicitud;
  const _MiSolicitudCard({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final color = _estadoColor(solicitud.estado);
    final icon = _estadoIcon(solicitud.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // Foto mascota
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: (solicitud.mascotaFotoUrl != null &&
                    solicitud.mascotaFotoUrl!.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(solicitud.mascotaFotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            Icon(Icons.pets_rounded, color: color, size: 28)))
                : Icon(Icons.pets_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(solicitud.mascotaNombre ?? 'Mascota',
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _dark)),
                Text(
                  '${solicitud.mascotaEspecie ?? ''} · ${solicitud.mascotaRaza ?? ''}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: _grey),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(solicitud.estado,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatFecha(solicitud.fecha),
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: _grey),
                  ),
                ]),
              ],
            ),
          ),
          // Botón cancelar si está pendiente
          if (solicitud.estado == 'Pendiente')
            GestureDetector(
              onTap: () => _confirmarCancelar(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.close_rounded,
                    color: Color(0xFFE53935), size: 18),
              ),
            ),
        ]),
      ),
    );
  }

  void _confirmarCancelar(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancelar solicitud',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w700, color: _dark)),
        content: Text(
          '¿Deseas cancelar la solicitud para adoptar a "${solicitud.mascotaNombre}"?',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('No',
                style: GoogleFonts.poppins(
                    color: _grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context
                  .read<SolicitudAdopcionController>()
                  .cancelarSolicitud(solicitud.id);
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(ok
                    ? 'Solicitud cancelada'
                    : 'Error al cancelar'),
                backgroundColor:
                    ok ? _teal : const Color(0xFFE53935),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Sí, cancelar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Tab: Solicitudes Recibidas (dueño de mascotas) ───────────────────────────
class _RecibidasTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SolicitudAdopcionController>(
      builder: (ctx, ctrl, _) {
        if (ctrl.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: _teal));
        }
        if (ctrl.solicitudesRecibidas.isEmpty) {
          return _emptyState(
            icon: Icons.inbox_outlined,
            title: 'Sin solicitudes recibidas',
            subtitle: 'Cuando alguien quiera adoptar\nuna de tus mascotas, aparecerá aquí.',
          );
        }
        return RefreshIndicator(
          color: _teal,
          onRefresh: () async {
            final uid = context.read<AuthController>().currentUser?.id;
            if (uid != null) {
              await ctrl.cargarSolicitudesRecibidas(uid);
            }
          },
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            itemCount: ctrl.solicitudesRecibidas.length,
            itemBuilder: (_, i) =>
                _SolicitudRecibidaCard(solicitud: ctrl.solicitudesRecibidas[i]),
          ),
        );
      },
    );
  }
}

// ── Tarjeta: solicitud recibida para confirmar adopción ─────────────────────
class _SolicitudRecibidaCard extends StatelessWidget {
  final SolicitudAdopcionModel solicitud;
  const _SolicitudRecibidaCard({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final color = _estadoColor(solicitud.estado);
    final esPendiente = solicitud.estado == 'Pendiente';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: foto mascota + info
            Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: (solicitud.mascotaFotoUrl != null &&
                        solicitud.mascotaFotoUrl!.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(solicitud.mascotaFotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(
                                Icons.pets_rounded, color: _teal, size: 26)))
                    : const Icon(Icons.pets_rounded, color: _teal, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(solicitud.mascotaNombre ?? 'Mascota',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _dark)),
                    Text(
                        '${solicitud.mascotaEspecie ?? ''} · ${solicitud.mascotaRaza ?? ''}',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: _grey)),
                  ],
                ),
              ),
              // Badge estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(solicitud.estado,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ]),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),

            // Datos del solicitante
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FAFB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_outline_rounded,
                    color: _teal, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(solicitud.usuarioNombre ?? 'Usuario',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _dark)),
                    Text(solicitud.usuarioCorreo ?? '',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: _grey)),
                  ],
                ),
              ),
              Text(_formatFecha(solicitud.fecha),
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: _grey)),
            ]),

            // Botones solo si está pendiente
            if (esPendiente) ...[
              const SizedBox(height: 14),
              Consumer<SolicitudAdopcionController>(
                builder: (ctx, ctrl, _) => Row(children: [
                  // Rechazar
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: ctrl.isLoading
                          ? null
                          : () => _rechazar(context, ctrl),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text('Rechazar',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE53935),
                        side: const BorderSide(color: Color(0xFFE53935)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Adoptado
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: ctrl.isLoading
                          ? null
                          : () => _confirmarAdopcion(context, ctrl),
                      icon: ctrl.isLoading
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.favorite_rounded, size: 16),
                      label: Text('Adoptado',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43B89C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ]),
              ),
            ],

            // Mensaje cuando ya está adoptado
            if (solicitud.estado == 'Adoptado') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF43B89C).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.home_rounded,
                      color: Color(0xFF43B89C), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${solicitud.mascotaNombre ?? 'La mascota'} ya tiene un nuevo hogar con ${solicitud.usuarioNombre ?? 'este usuario'} ❤️',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF43B89C),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarAdopcion(
      BuildContext context, SolicitudAdopcionController ctrl) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF43B89C).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.favorite_rounded,
                color: Color(0xFF43B89C), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Confirmar adopción',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _dark)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Confirmas que ${solicitud.usuarioNombre ?? 'este usuario'} adoptó a ${solicitud.mascotaNombre ?? 'la mascota'}?',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF43B89C).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF43B89C).withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF43B89C), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La mascota pasará a ser propiedad de ${solicitud.usuarioNombre ?? 'este usuario'} y saldrá de la lista de adopciones.',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF43B89C),
                        height: 1.4),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(
                    color: _grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43B89C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Sí, adoptado',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (!context.mounted) return;

    final ok = await ctrl.confirmarAdopcion(solicitud);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          ok ? Icons.home_rounded : Icons.error_outline_rounded,
          color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            ok
                ? '¡Adopción confirmada! ${solicitud.mascotaNombre ?? 'La mascota'} tiene nuevo hogar 🏠'
                : (ctrl.errorMessage ?? 'Error al confirmar'),
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
      ]),
      backgroundColor: ok ? const Color(0xFF43B89C) : const Color(0xFFE53935),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _rechazar(
      BuildContext context, SolicitudAdopcionController ctrl) async {
    final ok = await ctrl.rechazarSolicitud(solicitud.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          ok ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
          color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(
          ok ? 'Solicitud rechazada' : (ctrl.errorMessage ?? 'Error'),
          style: GoogleFonts.poppins(fontSize: 13),
        ),
      ]),
      backgroundColor:
          ok ? const Color(0xFFE53935) : Colors.grey.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Color _estadoColor(String estado) {
  switch (estado) {
    case 'Adoptado':
      return const Color(0xFF43B89C);
    case 'Rechazada':
      return const Color(0xFFE53935);
    default:
      return _orange; // Pendiente
  }
}

IconData _estadoIcon(String estado) {
  switch (estado) {
    case 'Adoptado':
      return Icons.home_rounded;
    case 'Rechazada':
      return Icons.cancel_outlined;
    default:
      return Icons.schedule_rounded;
  }
}

String _formatFecha(DateTime fecha) {
  return '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/'
      '${fecha.year}';
}

Widget _emptyState({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: _grey.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
        const SizedBox(height: 8),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 13, color: _grey, height: 1.5)),
      ],
    ),
  );
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
        size.width / 2, size.height + 10, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
