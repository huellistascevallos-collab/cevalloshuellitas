import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/veterinario_model.dart';
import '../../../domain/controllers/admin_controller.dart';
import '../../../presentation/widgets/safe_network_image.dart';

const _blue  = Color(0xFF1A73E8);
const _dark  = Color(0xFF1A1F36);
const _grey  = Color(0xFF8A9BB0);
const _bg    = Color(0xFFF4F6FB);
const _green = Color(0xFF0E9F6E);
const _red   = Color(0xFFE53935);

class AdminVeterinariosScreen extends StatefulWidget {
  const AdminVeterinariosScreen({super.key});

  @override
  State<AdminVeterinariosScreen> createState() =>
      _AdminVeterinariosScreenState();
}

class _AdminVeterinariosScreenState
    extends State<AdminVeterinariosScreen> {
  final _searchCtrl = TextEditingController();
  String _busqueda = '';
  String _filtroDisp = 'todos'; // todos | disponible | no_disponible

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().cargarVeterinarios();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<VeterinarioModel> _filtrar(List<VeterinarioModel> todos) {
    return todos.where((v) {
      final matchDisp = _filtroDisp == 'todos' ||
          (_filtroDisp == 'disponible' && v.disponible) ||
          (_filtroDisp == 'no_disponible' && !v.disponible);
      final q = _busqueda.toLowerCase();
      final matchBusqueda = q.isEmpty ||
          (v.nombre?.toLowerCase().contains(q) ?? false) ||
          (v.especialidad?.toLowerCase().contains(q) ?? false);
      return matchDisp && matchBusqueda;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _dark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Veterinarios',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _dark)),
        centerTitle: true,
        actions: [
          Consumer<AdminController>(
            builder: (_, ctrl, __) => IconButton(
              tooltip: 'Recargar',
              icon: const Icon(Icons.refresh_rounded, color: _green),
              onPressed: () => ctrl.cargarVeterinarios(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Buscador + filtros ────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _busqueda = v),
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o especialidad…',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: _green, size: 20),
                    suffixIcon: _busqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: _grey, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _busqueda = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: _bg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _chip('Todos', 'todos', _green),
                    const SizedBox(width: 8),
                    _chip('Disponibles', 'disponible', _green),
                    const SizedBox(width: 8),
                    _chip('No disponibles', 'no_disponible', _red),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Lista ─────────────────────────────────────────────────────
          Expanded(
            child: Consumer<AdminController>(
              builder: (ctx, ctrl, _) {
                if (ctrl.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator(color: _green));
                }
                final lista = _filtrar(ctrl.veterinarios);
                if (lista.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medical_services_outlined,
                            size: 56,
                            color: _grey.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('Sin resultados',
                            style: GoogleFonts.poppins(
                                color: _grey, fontSize: 15)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: _green,
                  onRefresh: () => ctrl.cargarVeterinarios(),
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _VetCard(vet: lista[i], ctrl: ctrl),
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
    final sel = _filtroDisp == valor;
    return GestureDetector(
      onTap: () => setState(() => _filtroDisp = valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? color : _bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? color : Colors.grey.shade300,
              width: sel ? 0 : 1),
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

// ── Tarjeta veterinario ───────────────────────────────────────────────────────

class _VetCard extends StatelessWidget {
  final VeterinarioModel vet;
  final AdminController ctrl;

  const _VetCard({required this.vet, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(
            color: vet.disponible ? _green : _red,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            SafeNetworkAvatar(
              url: vet.fotoUrl,
              size: 54,
              fallbackIcon: Icons.medical_services_rounded,
              fallbackColor: _green,
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vet.nombre ?? 'Sin nombre',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _dark)),
                  if (vet.especialidad != null &&
                      vet.especialidad!.isNotEmpty)
                    Text(vet.especialidad!,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: _grey)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    // Badge disponibilidad
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: vet.disponible
                            ? _green.withValues(alpha: 0.1)
                            : _red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          vet.disponible
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 11,
                          color: vet.disponible ? _green : _red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vet.disponible ? 'Disponible' : 'No disponible',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: vet.disponible ? _green : _red),
                        ),
                      ]),
                    ),
                    // Badge experiencia
                    if (vet.experiencia != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${vet.experiencia} años exp.',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _blue),
                        ),
                      ),
                    // Badge tarifa
                    if (vet.tarifa != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE58D57)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '\$${vet.tarifa!.toStringAsFixed(0)}/consulta',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE58D57)),
                        ),
                      ),
                  ]),
                ],
              ),
            ),
            // Menú de acciones
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: _grey, size: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (a) => _ejecutarAccion(context, a),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle_disp',
                  child: Row(children: [
                    Icon(
                      vet.disponible
                          ? Icons.toggle_off_rounded
                          : Icons.toggle_on_rounded,
                      size: 18,
                      color: vet.disponible ? _red : _green,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      vet.disponible
                          ? 'Marcar no disponible'
                          : 'Marcar disponible',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _dark,
                          fontWeight: FontWeight.w500),
                    ),
                  ]),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'eliminar',
                  child: Row(children: [
                    const Icon(Icons.delete_outline_rounded,
                        size: 18, color: _red),
                    const SizedBox(width: 10),
                    Text('Eliminar veterinario',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _dark,
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ejecutarAccion(BuildContext context, String accion) async {
    if (accion == 'toggle_disp') {
      final exito =
          await ctrl.toggleDisponibilidad(vet.id, !vet.disponible);
      if (!context.mounted) return;
      _snack(
          context,
          exito
              ? 'Disponibilidad actualizada'
              : (ctrl.errorMessage ?? 'Error'),
          exito ? _green : _red);
      return;
    }

    if (accion == 'eliminar') {
      final ok = await _confirmarEliminacion(context);
      if (!ok || !context.mounted) return;
      final exito =
          await ctrl.eliminarVeterinario(vet.id, vet.usuarioId);
      if (!context.mounted) return;
      _snack(
          context,
          exito
              ? 'Veterinario eliminado'
              : (ctrl.errorMessage ?? 'Error'),
          exito ? _green : _red);
    }
  }

  Future<bool> _confirmarEliminacion(BuildContext context) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar veterinario',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: _dark)),
        content: Text(
          '¿Eliminar a "${vet.nombre ?? 'este veterinario'}"? '
          'Su rol cambiará a usuario y perderá acceso al panel veterinario.',
          style: GoogleFonts.poppins(fontSize: 13, color: _grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(color: _grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Eliminar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  void _snack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
