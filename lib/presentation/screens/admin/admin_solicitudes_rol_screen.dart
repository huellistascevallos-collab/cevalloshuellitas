import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/solicitud_rol_model.dart';
import '../../../domain/controllers/admin_controller.dart';
import '../../../presentation/widgets/safe_network_image.dart';

const _dark = Color(0xFF1A1F36);
const _grey = Color(0xFF8A9BB0);
const _bg = Color(0xFFF4F6FB);
const _green = Color(0xFF0E9F6E);
const _red = Color(0xFFE53935);
const _orange = Color(0xFFE58D57);
const _purple = Color(0xFF7C6FCD);

class AdminSolicitudesRolScreen extends StatefulWidget {
  const AdminSolicitudesRolScreen({super.key});

  @override
  State<AdminSolicitudesRolScreen> createState() =>
      _AdminSolicitudesRolScreenState();
}

class _AdminSolicitudesRolScreenState
    extends State<AdminSolicitudesRolScreen> {
  String _filtroEstado = 'pendiente';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().cargarSolicitudesRol();
    });
  }

  List<SolicitudRolModel> _filtrar(List<SolicitudRolModel> todas) {
    if (_filtroEstado == 'todos') return todas;
    return todas.where((s) => s.estado == _filtroEstado).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Solicitudes de Veterinario',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
        centerTitle: true,
        actions: [
          Consumer<AdminController>(
            builder: (_, ctrl, __) => IconButton(
              tooltip: 'Recargar',
              icon: const Icon(Icons.refresh_rounded, color: _purple),
              onPressed: () => ctrl.cargarSolicitudesRol(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filtros ─────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('Pendientes', 'pendiente', _orange),
                  const SizedBox(width: 8),
                  _chip('Todos', 'todos', _purple),
                  const SizedBox(width: 8),
                  _chip('Aprobadas', 'aprobada', _green),
                  const SizedBox(width: 8),
                  _chip('Rechazadas', 'rechazada', _red),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // ── Lista ───────────────────────────────────────────────────────
          Expanded(
            child: Consumer<AdminController>(
              builder: (ctx, ctrl, _) {
                if (ctrl.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator(color: _purple));
                }
                final lista = _filtrar(ctrl.solicitudesRol);
                if (lista.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medical_services_outlined,
                            size: 56, color: _grey.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          _filtroEstado == 'pendiente'
                              ? 'No hay solicitudes pendientes'
                              : 'Sin resultados',
                          style: GoogleFonts.poppins(color: _grey, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: _purple,
                  onRefresh: () => ctrl.cargarSolicitudesRol(),
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _SolicitudRolCard(solicitud: lista[i], ctrl: ctrl),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String valor, Color color) {
    final sel = _filtroEstado == valor;
    return GestureDetector(
      onTap: () => setState(() => _filtroEstado = valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? color : _bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? color : Colors.grey.shade300, width: sel ? 0 : 1),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : _grey)),
      ),
    );
  }
}

// ── Tarjeta de solicitud de rol ───────────────────────────────────────────────

class _SolicitudRolCard extends StatelessWidget {
  final SolicitudRolModel solicitud;
  final AdminController ctrl;
  const _SolicitudRolCard({required this.solicitud, required this.ctrl});

  Color get _estadoColor {
    switch (solicitud.estado) {
      case 'aprobada':
        return _green;
      case 'rechazada':
        return _red;
      default:
        return _orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPendiente = solicitud.estado == 'pendiente';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: _estadoColor, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                SafeNetworkAvatar(
                  url: solicitud.usuarioFotoUrl,
                  size: 48,
                  fallbackIcon: Icons.person_rounded,
                  fallbackColor: _purple,
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(solicitud.usuarioNombre ?? 'Usuario',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _dark)),
                      if (solicitud.usuarioCorreo?.isNotEmpty == true)
                        Text(solicitud.usuarioCorreo!,
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: _grey)),
                      if (solicitud.usuarioTelefono?.isNotEmpty == true)
                        Text(solicitud.usuarioTelefono!,
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: _grey)),
                    ],
                  ),
                ),
                // Badge estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _estadoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(solicitud.estado,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _estadoColor)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Solicita ser Veterinario · '
              '${solicitud.fecha.day.toString().padLeft(2, '0')}/'
              '${solicitud.fecha.month.toString().padLeft(2, '0')}/'
              '${solicitud.fecha.year}',
              style: GoogleFonts.poppins(fontSize: 11, color: _grey),
            ),
            // Botones de acción (solo si está pendiente)
            if (esPendiente) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  // Aprobar
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _aprobar(context),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text('Aprobar',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Rechazar
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rechazar(context),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text('Rechazar',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _red,
                        side: const BorderSide(color: _red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Para solicitudes resueltas: solo botón eliminar
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _eliminar(context),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: _red, size: 16),
                  label: Text('Eliminar',
                      style: GoogleFonts.poppins(color: _red, fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _aprobar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Aprobar solicitud',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _dark)),
        content: Text(
          '${solicitud.usuarioNombre ?? 'El usuario'} pasará a tener el rol de Veterinario. '
          'Quedará inactivo hasta que lo actives manualmente.',
          style: GoogleFonts.poppins(fontSize: 13, color: _grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: _grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Aprobar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final exito = await ctrl.aprobarSolicitudRol(solicitud);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          exito ? '✅ Solicitud aprobada. Usuario ahora es veterinario.' : (ctrl.errorMessage ?? 'Error'),
          style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: exito ? _green : _red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _rechazar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rechazar solicitud',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _dark)),
        content: Text(
          '${solicitud.usuarioNombre ?? 'El usuario'} permanecerá como usuario normal.',
          style: GoogleFonts.poppins(fontSize: 13, color: _grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: _grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Rechazar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final exito = await ctrl.rechazarSolicitudRol(solicitud.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(exito ? 'Solicitud rechazada' : (ctrl.errorMessage ?? 'Error'),
          style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: exito ? _green : _red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _eliminar(BuildContext context) async {
    final exito = await ctrl.eliminarSolicitudRol(solicitud.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(exito ? 'Solicitud eliminada' : (ctrl.errorMessage ?? 'Error'),
          style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: exito ? _green : _red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
