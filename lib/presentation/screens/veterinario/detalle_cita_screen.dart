import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/cita_model.dart';
import '../../../data/models/calificacion_model.dart';
import '../../../data/services/calificacion_service.dart';
import '../../../domain/controllers/auth_controller.dart';
import '../../../domain/controllers/cita_controller.dart';

class DetalleCitaScreen extends StatefulWidget {
  final CitaModel cita;
  const DetalleCitaScreen({super.key, required this.cita});

  @override
  State<DetalleCitaScreen> createState() => _DetalleCitaScreenState();
}

class _DetalleCitaScreenState extends State<DetalleCitaScreen> {
  late TextEditingController _descripcionCtrl;
  late TextEditingController _recetaCtrl;
  late String _estadoActual;
  final CalificacionService _calificacionService = CalificacionService();

  // Calificación existente (si ya fue calificada)
  CalificacionModel? _calificacionExistente;
  bool _cargandoCalificacion = true;

  @override
  void initState() {
    super.initState();
    _descripcionCtrl =
        TextEditingController(text: widget.cita.descripcion ?? '');
    _recetaCtrl = TextEditingController(text: widget.cita.receta ?? '');
    _estadoActual = widget.cita.estado;
    _cargarCalificacion();
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _recetaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarCalificacion() async {
    // Solo buscamos calificación si tenemos veteId y usuaId
    final veteId = widget.cita.veteId;
    final usuaId = widget.cita.usuarioId;
    if (veteId != null && veteId.isNotEmpty && usuaId.isNotEmpty) {
      final cal = await _calificacionService.obtenerCalificacion(
        usuaId: usuaId,
        veteId: veteId,
      );
      if (mounted) {
        setState(() {
          _calificacionExistente = cal;
          _cargandoCalificacion = false;
        });
      }
    } else {
      if (mounted) setState(() => _cargandoCalificacion = false);
    }
  }

  // ── Lógica de fecha/hora ──────────────────────────────────────────────────

  /// Combina fecha (yyyy-MM-dd) + hora (HH:mm) en DateTime
  DateTime get _fechaHoraCita {
    try {
      final parts = widget.cita.fecha.split('-');
      final timeParts = widget.cita.hora.split(':');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (_) {
      return DateTime.now().add(const Duration(days: 1));
    }
  }

  /// True cuando ya llegó la fecha y hora de la cita
  bool get _citaYaComenzo =>
      DateTime.now().isAfter(_fechaHoraCita) ||
      DateTime.now().isAtSameMomentAs(_fechaHoraCita);

  /// True cuando la cita ya fue completada
  bool get _citaCompletada =>
      _estadoActual.toLowerCase() == 'completada';

  /// True cuando se puede editar la consulta
  bool get _puedeEditar =>
      _citaYaComenzo && _estadoActual.toLowerCase() != 'cancelada';

  // ── Colores y estado ──────────────────────────────────────────────────────

  Color get _estadoColor {
    switch (_estadoActual.toLowerCase()) {
      case 'completada':
        return const Color(0xFF43B89C);
      case 'cancelada':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFFE58D57);
    }
  }

  IconData get _estadoIcon {
    switch (_estadoActual.toLowerCase()) {
      case 'completada':
        return Icons.task_alt_rounded;
      case 'cancelada':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule_rounded;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final yaComenzo = _citaYaComenzo;
    final estaCompletada = _citaCompletada;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF0D5C70), _estadoColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
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
                      Icon(_estadoIcon, color: Colors.white, size: 26),
                      const SizedBox(height: 2),
                      Text('Detalle de Cita',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ]),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ]),
                ),
                // Badge estado
                const SizedBox(height: 4),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(_estadoActual.toUpperCase(),
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                // Contenido
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(children: [
                      // Fecha/hora/estado
                      _quickStatsCard(),
                      const SizedBox(height: 14),

                      // Banner si la cita aún no ha llegado
                      if (!yaComenzo) ...[
                        _bannerEspera(),
                        const SizedBox(height: 14),
                      ],

                      // Datos del paciente (siempre visible)
                      _infoCard(
                        title: 'Paciente',
                        icon: Icons.pets_rounded,
                        color: const Color(0xFF1CB5C9),
                        children: [
                          _infoRow(Icons.badge_outlined, 'Nombre',
                              widget.cita.mascotaNombre),
                          _infoRow(Icons.notes_rounded, 'Motivo',
                              widget.cita.motivo.isNotEmpty
                                  ? widget.cita.motivo
                                  : '—'),
                          if (widget.cita.direccion != null &&
                              widget.cita.direccion!.isNotEmpty)
                            _infoRow(Icons.location_on_outlined, 'Dirección',
                                widget.cita.direccion!),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Datos del propietario (siempre visible)
                      _infoCard(
                        title: 'Propietario',
                        icon: Icons.person_outline_rounded,
                        color: const Color(0xFFE58D57),
                        children: [
                          _infoRow(Icons.person_rounded, 'Nombre',
                              widget.cita.propietarioNombre.isNotEmpty
                                  ? widget.cita.propietarioNombre
                                  : '—'),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Sección de consulta — solo si ya comenzó
                      if (yaComenzo) ...[
                        _editableCard(
                          title: 'Notas de la consulta',
                          icon: Icons.description_outlined,
                          color: const Color(0xFF7C6FCD),
                          controller: _descripcionCtrl,
                          hint:
                              'Describe síntomas, diagnóstico y observaciones…',
                          maxLines: 5,
                          enabled: _puedeEditar,
                        ),
                        const SizedBox(height: 14),
                        _editableCard(
                          title: 'Receta / Prescripción',
                          icon: Icons.medication_outlined,
                          color: const Color(0xFF43B89C),
                          controller: _recetaCtrl,
                          hint: 'Medicamentos, dosis, indicaciones…',
                          maxLines: 4,
                          enabled: _puedeEditar,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Cambiar estado — solo si ya comenzó y no cancelada
                      if (yaComenzo &&
                          _estadoActual.toLowerCase() != 'cancelada') ...[
                        _infoCard(
                          title: 'Cambiar Estado',
                          icon: Icons.swap_horiz_rounded,
                          color: const Color(0xFF126E82),
                          children: [
                            _estadoSelector('pendiente',
                                Icons.schedule_rounded,
                                const Color(0xFFE58D57)),
                            _estadoSelector('completada',
                                Icons.task_alt_rounded,
                                const Color(0xFF43B89C)),
                            _estadoSelector('cancelada',
                                Icons.cancel_outlined,
                                const Color(0xFFE53935)),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Calificación recibida — solo si está completada
                      if (estaCompletada) ...[
                        _cargandoCalificacion
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF1CB5C9)))
                            : _calificacionWidget(),
                        const SizedBox(height: 14),
                      ],

                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Botón guardar — solo si ya comenzó y no está cancelada
          if (yaComenzo && _estadoActual.toLowerCase() != 'cancelada')
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -4))
                  ],
                ),
                child: Consumer<CitaController>(
                  builder: (ctx, ctrl, _) => SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: ctrl.isLoading ? null : _guardar,
                      icon: ctrl.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text('Guardar Consulta',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _estadoColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _bannerEspera() {
    final ahora = DateTime.now();
    final diff = _fechaHoraCita.difference(ahora);
    final horas = diff.inHours;
    final minutos = diff.inMinutes % 60;

    String tiempoRestante;
    if (diff.inDays > 0) {
      tiempoRestante = '${diff.inDays} día(s) y $horas hora(s)';
    } else if (horas > 0) {
      tiempoRestante = '$horas h $minutos min';
    } else {
      tiempoRestante = '$minutos min';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFE58D57).withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE58D57).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_clock_rounded,
              color: Color(0xFFE58D57), size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cita aún no disponible',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E))),
            Text(
              'Podrás atender esta cita en:\n$tiempoRestante',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey.shade600, height: 1.4),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _calificacionWidget() {
    if (_calificacionExistente != null) {
      // Mostrar calificación recibida
      return _infoCard(
        title: 'Calificación recibida',
        icon: Icons.star_rounded,
        color: const Color(0xFFFFB300),
        children: [
          Row(children: [
            ...List.generate(5, (i) {
              return Icon(
                i < _calificacionExistente!.puntuacion
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: const Color(0xFFFFB300),
                size: 28,
              );
            }),
            const SizedBox(width: 10),
            Text('${_calificacionExistente!.puntuacion}/5',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A2E))),
          ]),
          if (_calificacionExistente!.comentario != null &&
              _calificacionExistente!.comentario!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDE7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded,
                      color: Color(0xFFFFB300), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _calificacionExistente!.comentario!,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    // Sin calificación aún
    return _infoCard(
      title: 'Calificación',
      icon: Icons.star_outline_rounded,
      color: const Color(0xFFFFB300),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            const Icon(Icons.hourglass_empty_rounded,
                color: Color(0xFFFFB300), size: 20),
            const SizedBox(width: 10),
            Text('El propietario aún no ha calificado esta atención.',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade500)),
          ]),
        ),
      ],
    );
  }

  Widget _quickStatsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickStat(Icons.calendar_today_rounded,
              widget.cita.fecha.split('-').reversed.join('/'),
              'Fecha', const Color(0xFF7C6FCD)),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _quickStat(Icons.access_time_rounded, widget.cita.hora, 'Hora',
              _estadoColor),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _quickStat(_estadoIcon, _estadoActual, 'Estado', _estadoColor),
        ],
      ),
    );
  }

  Widget _quickStat(
      IconData icon, String value, String label, Color color) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E))),
      Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10, color: Colors.grey.shade500)),
    ]);
  }

  Widget _infoCard(
      {required String title,
      required IconData icon,
      required Color color,
      required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E))),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        const SizedBox(height: 8),
        ...children,
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF1CB5C9)),
        const SizedBox(width: 10),
        SizedBox(
            width: 90,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade500))),
        Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E)))),
      ]),
    );
  }

  Widget _editableCard(
      {required String title,
      required IconData icon,
      required Color color,
      required TextEditingController controller,
      required String hint,
      int maxLines = 3,
      bool enabled = true}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E))),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          style: GoogleFonts.poppins(
              fontSize: 13, color: const Color(0xFF2D2D2D)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
            filled: true,
            fillColor:
                enabled ? const Color(0xFFF5F6FA) : Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: color.withValues(alpha: 0.25), width: 1.2)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color, width: 2)),
          ),
        ),
      ]),
    );
  }

  Widget _estadoSelector(
      String estado, IconData icon, Color color) {
    final sel = _estadoActual.toLowerCase() == estado;
    return GestureDetector(
      onTap: () => setState(() => _estadoActual = estado),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              sel ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: sel ? color : Colors.grey.shade200,
              width: sel ? 1.5 : 1),
        ),
        child: Row(children: [
          Icon(icon,
              color: sel ? color : Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
          Text(estado[0].toUpperCase() + estado.substring(1),
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight:
                      sel ? FontWeight.w700 : FontWeight.w500,
                  color:
                      sel ? color : Colors.grey.shade600)),
          const Spacer(),
          if (sel)
            Icon(Icons.check_circle_rounded, color: color, size: 18),
        ]),
      ),
    );
  }

  // ── Guardar ───────────────────────────────────────────────────────────────

  Future<void> _guardar() async {
    final ctrl = context.read<CitaController>();
    final ok = await ctrl.guardarConsulta(
      citaId: widget.cita.id,
      estado: _estadoActual,
      descripcion: _descripcionCtrl.text.trim().isNotEmpty
          ? _descripcionCtrl.text.trim()
          : null,
      receta: _recetaCtrl.text.trim().isNotEmpty
          ? _recetaCtrl.text.trim()
          : null,
      mascotaId: widget.cita.mascotaId,
      veteId: widget.cita.veteId,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text('Consulta guardada correctamente',
              style: GoogleFonts.poppins(fontSize: 13)),
        ]),
        backgroundColor: const Color(0xFF43B89C),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ctrl.errorMessage ?? 'Error al guardar'),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }
}
