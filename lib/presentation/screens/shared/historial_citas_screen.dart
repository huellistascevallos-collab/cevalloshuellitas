import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/cita_model.dart';
import '../../../data/models/calificacion_model.dart';
import '../../../data/services/calificacion_service.dart';
import '../../../domain/controllers/cita_controller.dart';

/// Modo: 'usuario' carga citasDelUsuario, 'veterinario' carga citasDelVeterinario
class HistorialCitasScreen extends StatefulWidget {
  final String modo;     // 'usuario' | 'veterinario'
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
  String _filtro = 'todos';
  final CalificacionService _calificacionService = CalificacionService();

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
                  _filtroChip(
                      'pendiente', 'Pendientes', Icons.schedule_rounded),
                  const SizedBox(width: 8),
                  _filtroChip(
                      'completada', 'Completadas', Icons.task_alt_rounded),
                  const SizedBox(width: 8),
                  _filtroChip(
                      'cancelada', 'Canceladas', Icons.cancel_outlined),
                ]),
              ),
              const SizedBox(height: 12),
              // Lista
              Expanded(
                child: Consumer<CitaController>(
                  builder: (ctx, ctrl, _) {
                    if (ctrl.isLoading) {
                      return const Center(
                          child: CircularProgressIndicator(
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
                                  fontSize: 14,
                                  color: Colors.grey.shade500)),
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

  // ── Widgets helpers ───────────────────────────────────────────────────────

  Widget _filtroChip(String key, String label, IconData icon) {
    final activo = _filtro == key;
    return GestureDetector(
      onTap: () => setState(() => _filtro = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo
              ? Colors.white
              : Colors.white.withValues(alpha: 0.2),
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
                  color:
                      activo ? const Color(0xFF126E82) : Colors.white)),
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

    final esModoUsuario = widget.modo == 'usuario';
    final esCompletada = cita.estado.toLowerCase() == 'completada';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: estadoColor, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Cabecera
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(estadoIcon, color: estadoColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              Text(cita.mascotaNombre,
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E))),
              Text(cita.motivo,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade500)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(cita.estado,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: estadoColor)),
            ),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          // Meta info
          Row(children: [
            _metaItem(
                Icons.calendar_today_outlined,
                cita.fecha.split('-').reversed.join('/'),
                Colors.grey.shade600),
            const SizedBox(width: 20),
            _metaItem(Icons.access_time_rounded, cita.hora,
                Colors.grey.shade600),
            if (!esModoUsuario &&
                cita.propietarioNombre.isNotEmpty) ...[
              const SizedBox(width: 20),
              Expanded(
                  child: _metaItem(
                      Icons.person_outline_rounded,
                      cita.propietarioNombre,
                      Colors.grey.shade600)),
            ],
          ]),
          // Botón calificar — solo usuario, cita completada con veteId
          if (esModoUsuario && esCompletada && cita.veteId != null) ...[
            const SizedBox(height: 12),
            _BotonCalificar(
              cita: cita,
              calificacionService: _calificacionService,
            ),
          ],
        ]),
      ),
    );
  }

  Widget _metaItem(IconData icon, String text, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(text,
          style: GoogleFonts.poppins(fontSize: 12, color: color)),
    ]);
  }
}

// ── Widget: Botón de calificación con estado propio ────────────────────────
class _BotonCalificar extends StatefulWidget {
  final CitaModel cita;
  final CalificacionService calificacionService;

  const _BotonCalificar({
    required this.cita,
    required this.calificacionService,
  });

  @override
  State<_BotonCalificar> createState() => _BotonCalificarState();
}

class _BotonCalificarState extends State<_BotonCalificar> {
  CalificacionModel? _calificacion;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final veteId = widget.cita.veteId;
    final usuaId = widget.cita.usuarioId;
    if (veteId == null || veteId.isEmpty || usuaId.isEmpty) {
      if (mounted) setState(() => _cargando = false);
      return;
    }
    final cal = await widget.calificacionService.obtenerCalificacion(
      usuaId: usuaId,
      veteId: veteId,
    );
    if (mounted) {
      setState(() {
        _calificacion = cal;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const SizedBox(
        height: 20,
        child: Center(
            child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFFB300)))),
      );
    }

    if (_calificacion != null) {
      // Ya calificó — mostrar estrellas
      return Row(children: [
        ...List.generate(
            5,
            (i) => Icon(
                  i < _calificacion!.puntuacion
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xFFFFB300),
                  size: 18,
                )),
        const SizedBox(width: 6),
        Text('Tu calificación',
            style: GoogleFonts.poppins(
                fontSize: 11, color: Colors.grey.shade500)),
      ]);
    }

    // No ha calificado — mostrar botón
    return GestureDetector(
      onTap: () => _mostrarDialogo(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFFFB300).withValues(alpha: 0.5),
              width: 1.2),
        ),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.star_outline_rounded,
              color: Color(0xFFFFB300), size: 20),
          const SizedBox(width: 8),
          Text('Calificar atención',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFB300))),
        ]),
      ),
    );
  }

  void _mostrarDialogo(BuildContext context) {
    int puntaje = 0;
    final comentarioCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Calificar atención',
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E))),
                const SizedBox(height: 6),
                Text('¿Cómo fue la atención del veterinario?',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade500)),
                const SizedBox(height: 20),
                // Estrellas
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () =>
                          setModal(() => puntaje = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6),
                        child: Icon(
                          i < puntaje
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFFFFB300),
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    puntaje == 0
                        ? 'Toca una estrella'
                        : [
                            '',
                            'Muy malo',
                            'Malo',
                            'Regular',
                            'Bueno',
                            'Excelente'
                          ][puntaje],
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFB300)),
                  ),
                ),
                const SizedBox(height: 18),
                // Comentario opcional
                TextField(
                  controller: comentarioCtrl,
                  maxLines: 3,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF2D2D2D)),
                  decoration: InputDecoration(
                    hintText: 'Comentario opcional…',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade400),
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFBBEBF0),
                            width: 1.2)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFFFB300), width: 2)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: puntaje == 0
                        ? null
                        : () async {
                            final cal = CalificacionModel(
                              id: '',
                              usuaId: widget.cita.usuarioId,
                              veteId: widget.cita.veteId!,
                              puntuacion: puntaje,
                              comentario: comentarioCtrl.text
                                      .trim()
                                      .isNotEmpty
                                  ? comentarioCtrl.text.trim()
                                  : null,
                            );
                            try {
                              final guardada = await widget
                                  .calificacionService
                                  .guardarCalificacion(cal);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                setState(
                                    () => _calificacion = guardada);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      '¡Gracias por tu calificación!',
                                      style: GoogleFonts.poppins(
                                          fontSize: 13)),
                                  backgroundColor:
                                      const Color(0xFF43B89C),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ));
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx)
                                    .showSnackBar(SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.redAccent,
                                ));
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Enviar calificación',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
