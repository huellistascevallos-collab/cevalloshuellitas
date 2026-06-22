import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/cita_model.dart';
import '../../../domain/controllers/cita_controller.dart';

/// Modo: 'usuario' carga citasDelUsuario, 'veterinario' carga citasDelVeterinario
class HistorialCitasScreen extends StatefulWidget {
  final String modo; // 'usuario' | 'veterinario'
  final String entityId; // usuarioId o veteId

  const HistorialCitasScreen({
    super.key,
    required this.modo,
    required this.entityId,
  });

  @override
  State<HistorialCitasScreen> createState() => _HistorialCitasScreenState();
}

class _HistorialCitasScreenState extends State<HistorialCitasScreen> {
  String _filtro = 'todos'; // todos | pendiente | completada | cancelada

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<CitaController>();
      if (widget.modo == 'usuario') {
        ctrl.cargarCitasDeUsuario(widget.entityId);
      } else {
        ctrl.cargarCitasDeVeterinario(widget.entityId);
      }
    });
  }

  List<CitaModel> get _citas {
    final ctrl = context.read<CitaController>();
    final lista = widget.modo == 'usuario'
        ? ctrl.citasDelUsuario
        : ctrl.citasDelVeterinario;
    if (_filtro == 'todos') return lista;
    return lista.where((c) => c.estado.toLowerCase() == _filtro).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF126E82), Color(0xFF1CB5C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Column(children: [
                    const Icon(Icons.history_rounded,
                        color: Colors.white, size: 26),
                    Text('Historial de Citas',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ]),
                  const Spacer(),
                  const SizedBox(width: 48),
                ]),
              ),
              const SizedBox(height: 8),
              // Filtros
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _filtroChip('todos', 'Todos', Icons.list_rounded),
                  const SizedBox(width: 8),
                  _filtroChip('pendiente', 'Pendientes', Icons.schedule_rounded),
                  const SizedBox(width: 8),
                  _filtroChip('completada', 'Completadas', Icons.task_alt_rounded),
                  const SizedBox(width: 8),
                  _filtroChip('cancelada', 'Canceladas', Icons.cancel_outlined),
                ]),
              ),
              const SizedBox(height: 12),
              // Lista
              Expanded(
                child: Consumer<CitaController>(
                  builder: (ctx, ctrl, _) {
                    if (ctrl.isLoading) {
                      return const Center(child: CircularProgressIndicator(
                          color: Color(0xFF1CB5C9)));
                    }
                    final lista = _citas;
                    if (lista.isEmpty) {
                      return Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Icon(Icons.event_busy_rounded,
                              size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No hay citas en esta categoría',
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.grey.shade500)),
                        ]),
                      );
                    }
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      itemCount: lista.length,
                      itemBuilder: (ctx, i) => _citaCard(lista[i]),
                    );
                  },
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _filtroChip(String key, String label, IconData icon) {
    final activo = _filtro == key;
    return GestureDetector(
      onTap: () => setState(() => _filtro = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 14,
              color: activo ? const Color(0xFF126E82) : Colors.white),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: activo ? const Color(0xFF126E82) : Colors.white)),
        ]),
      ),
    );
  }

  Widget _citaCard(CitaModel cita) {
    Color estadoColor;
    IconData estadoIcon;
    switch (cita.estado.toLowerCase()) {
      case 'completada':
        estadoColor = const Color(0xFF43B89C);
        estadoIcon = Icons.task_alt_rounded;
        break;
      case 'cancelada':
        estadoColor = const Color(0xFFE53935);
        estadoIcon = Icons.cancel_outlined;
        break;
      default:
        estadoColor = const Color(0xFFE58D57);
        estadoIcon = Icons.schedule_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: estadoColor, width: 4)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(estadoIcon, color: estadoColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(cita.mascotaNombre,
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E))),
              Text(cita.motivo,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade500)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(cita.estado,
                  style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: estadoColor)),
            ),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          Row(children: [
            _metaItem(Icons.calendar_today_outlined,
                cita.fecha.split('-').reversed.join('/'),
                Colors.grey.shade600),
            const SizedBox(width: 20),
            _metaItem(Icons.access_time_rounded, cita.hora,
                Colors.grey.shade600),
            if (widget.modo == 'veterinario' &&
                cita.propietarioNombre.isNotEmpty) ...[
              const SizedBox(width: 20),
              Expanded(child: _metaItem(Icons.person_outline_rounded,
                  cita.propietarioNombre, Colors.grey.shade600)),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _metaItem(IconData icon, String text, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(text, style: GoogleFonts.poppins(fontSize: 12, color: color)),
    ]);
  }
}
