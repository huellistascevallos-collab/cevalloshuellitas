import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/cita_model.dart';
import '../../../domain/controllers/admin_controller.dart';

const _blue = Color(0xFF1A73E8);
const _dark = Color(0xFF1A1F36);
const _grey = Color(0xFF8A9BB0);
const _bg = Color(0xFFF4F6FB);
const _green = Color(0xFF0E9F6E);
const _red = Color(0xFFE53935);
const _purple = Color(0xFF7C6FCD);
const _orange = Color(0xFFE58D57);

class AdminCitasScreen extends StatefulWidget {
  const AdminCitasScreen({super.key});

  @override
  State<AdminCitasScreen> createState() => _AdminCitasScreenState();
}

class _AdminCitasScreenState extends State<AdminCitasScreen> {
  final _searchCtrl = TextEditingController();
  String _busqueda = '';
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().cargarCitas();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CitaModel> _filtrar(List<CitaModel> todas) {
    return todas.where((c) {
      final matchEstado =
          _filtroEstado == 'todos' || c.estado.toLowerCase() == _filtroEstado;
      final q = _busqueda.toLowerCase();
      final matchBusqueda = q.isEmpty ||
          c.mascotaNombre.toLowerCase().contains(q) ||
          c.propietarioNombre.toLowerCase().contains(q) ||
          c.motivo.toLowerCase().contains(q);
      return matchEstado && matchBusqueda;
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Citas',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700, color: _dark)),
        centerTitle: true,
        actions: [
          Consumer<AdminController>(
            builder: (_, ctrl, __) => IconButton(
              tooltip: 'Recargar',
              icon: const Icon(Icons.refresh_rounded, color: _purple),
              onPressed: () => ctrl.cargarCitas(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Buscador + filtros ──────────────────────────────────────────
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
                    hintText: 'Buscar por mascota, propietario o motivo…',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: _purple, size: 20),
                    suffixIcon: _busqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: _grey, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _busqueda = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: _bg,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('Todos', 'todos', _purple),
                      const SizedBox(width: 8),
                      _chip('Pendiente', 'pendiente', _orange),
                      const SizedBox(width: 8),
                      _chip('Confirmada', 'confirmada', _green),
                      const SizedBox(width: 8),
                      _chip('Completada', 'completada', _blue),
                      const SizedBox(width: 8),
                      _chip('Rechazada', 'rechazada', _red),
                    ],
                  ),
                ),
              ],
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
                final lista = _filtrar(ctrl.citas);
                if (lista.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_rounded,
                            size: 56, color: _grey.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('Sin resultados',
                            style: GoogleFonts.poppins(color: _grey, fontSize: 15)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: _purple,
                  onRefresh: () => ctrl.cargarCitas(),
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _CitaCard(cita: lista[i], ctrl: ctrl),
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

// ── Tarjeta de cita ───────────────────────────────────────────────────────────

class _CitaCard extends StatelessWidget {
  final CitaModel cita;
  final AdminController ctrl;
  const _CitaCard({required this.cita, required this.ctrl});

  Color get _estadoColor {
    switch (cita.estado.toLowerCase()) {
      case 'confirmada':
        return _green;
      case 'completada':
        return _blue;
      case 'rechazada':
        return _red;
      default:
        return _orange;
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: Row(
          children: [
            // Icono estado
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _estadoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.calendar_today_rounded,
                  color: _estadoColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Datos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cita.mascotaNombre,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _dark)),
                  if (cita.propietarioNombre.isNotEmpty)
                    Text('Propietario: ${cita.propietarioNombre}',
                        style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    _badge(
                        '${cita.fecha.split('-').reversed.join('/')}  ${cita.hora}',
                        _purple),
                    _badge(cita.estado, _estadoColor),
                    if (cita.motivo.isNotEmpty)
                      _badge(
                          cita.motivo.length > 30
                              ? '${cita.motivo.substring(0, 30)}…'
                              : cita.motivo,
                          _grey),
                  ]),
                ],
              ),
            ),
            // Acción eliminar
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: _red, size: 20),
              onPressed: () => _confirmarEliminar(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar cita',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _dark)),
        content: Text(
          '¿Eliminar la cita de "${cita.mascotaNombre}"? Esta acción no se puede deshacer.',
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
            child:
                Text('Eliminar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final exito = await ctrl.eliminarCita(cita.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(exito ? 'Cita eliminada' : (ctrl.errorMessage ?? 'Error'),
          style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: exito ? _green : _red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
