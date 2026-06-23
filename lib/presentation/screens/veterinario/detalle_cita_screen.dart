import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/cita_model.dart';
import '../../../data/models/calificacion_model.dart';
import '../../../data/services/calificacion_service.dart';
import '../../../domain/controllers/cita_controller.dart';

class DetalleCitaScreen extends StatefulWidget {
  final CitaModel cita;
  const DetalleCitaScreen({super.key, required this.cita});

  @override
  State<DetalleCitaScreen> createState() => _DetalleCitaScreenState();
}

class _DetalleCitaScreenState extends State<DetalleCitaScreen> {
  late TextEditingController _diagnosticoCtrl;
  late TextEditingController _observacionesCtrl;
  late TextEditingController _tratamientoCtrl;
  late TextEditingController _recetaCtrl;
  late TextEditingController _recomendacionesCtrl;
  late String _estadoActual;
  final CalificacionService _calificacionService = CalificacionService();

  // Calificación existente (si ya fue calificada)
  CalificacionModel? _calificacionExistente;
  bool _cargandoCalificacion = true;

  @override
  void initState() {
    super.initState();
    
    // Parsear descripción (Diagnóstico + Observaciones)
    String diagnostico = '';
    String observaciones = '';
    final desc = widget.cita.descripcion ?? '';
    if (desc.contains('Observaciones:')) {
      final parts = desc.split('Observaciones:');
      diagnostico = parts[0].replaceAll('Diagnóstico:', '').trim();
      observaciones = parts[1].trim();
    } else {
      diagnostico = desc;
    }

    // Parsear receta (Tratamiento + Medicamentos + Recomendaciones)
    String tratamiento = '';
    String medicamentos = '';
    String recomendaciones = '';
    final rec = widget.cita.receta ?? '';
    
    if (rec.contains('Tratamiento:') || rec.contains('Medicamentos:') || rec.contains('Recomendaciones:')) {
      final tIndex = rec.indexOf('Tratamiento:');
      final mIndex = rec.indexOf('Medicamentos:');
      final rIndex = rec.indexOf('Recomendaciones:');
      
      int tStart = tIndex != -1 ? tIndex + 'Tratamiento:'.length : -1;
      int mStart = mIndex != -1 ? mIndex + 'Medicamentos:'.length : -1;
      int rStart = rIndex != -1 ? rIndex + 'Recomendaciones:'.length : -1;
      
      int tEnd = mIndex != -1 ? mIndex : (rIndex != -1 ? rIndex : rec.length);
      int mEnd = rIndex != -1 ? rIndex : rec.length;
      int rEnd = rec.length;
      
      if (tIndex != -1) {
        tratamiento = rec.substring(tStart, tEnd).trim();
      }
      if (mIndex != -1) {
        medicamentos = rec.substring(mStart, mEnd).trim();
      }
      if (rIndex != -1) {
        recomendaciones = rec.substring(rStart, rEnd).trim();
      }
    } else {
      medicamentos = rec;
    }

    _diagnosticoCtrl = TextEditingController(text: diagnostico);
    _observacionesCtrl = TextEditingController(text: observaciones);
    _tratamientoCtrl = TextEditingController(text: tratamiento);
    _recetaCtrl = TextEditingController(text: medicamentos);
    _recomendacionesCtrl = TextEditingController(text: recomendaciones);
    
    _estadoActual = widget.cita.estado;
    _cargarCalificacion();
  }

  @override
  void dispose() {
    _diagnosticoCtrl.dispose();
    _observacionesCtrl.dispose();
    _tratamientoCtrl.dispose();
    _recetaCtrl.dispose();
    _recomendacionesCtrl.dispose();
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

  /// True cuando la cita ya fue completada o finalizada
  bool get _citaCompletada =>
      _estadoActual.toLowerCase() == 'completada' ||
      _estadoActual.toLowerCase() == 'finalizada';

  /// True cuando se puede editar la consulta (solo en estado "en atención")
  bool get _puedeEditar =>
      _estadoActual.toLowerCase() == 'en atención';

  // ── Colores y estado ──────────────────────────────────────────────────────

  Color get _estadoColor {
    switch (_estadoActual.toLowerCase()) {
      case 'completada':
      case 'finalizada':
        return const Color(0xFF43B89C);
      case 'en atención':
        return const Color(0xFF7C6FCD);
      case 'confirmada':
        return const Color(0xFF1CB5C9);
      case 'cancelada':
      case 'rechazada':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFFE58D57);
    }
  }

  IconData get _estadoIcon {
    switch (_estadoActual.toLowerCase()) {
      case 'completada':
      case 'finalizada':
        return Icons.task_alt_rounded;
      case 'en atención':
        return Icons.play_circle_outline_rounded;
      case 'confirmada':
        return Icons.check_circle_outline_rounded;
      case 'cancelada':
      case 'rechazada':
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

                      // Sección de consulta — si está en atención o ya completada/finalizada
                      if (_estadoActual.toLowerCase() == 'en atención' || _citaCompletada) ...[
                        _editableCard(
                          title: 'Observaciones médicas',
                          icon: Icons.notes_outlined,
                          color: const Color(0xFF7C6FCD),
                          controller: _observacionesCtrl,
                          hint: 'Comportamiento de la mascota, síntomas observados...',
                          maxLines: 3,
                          enabled: _puedeEditar,
                        ),
                        const SizedBox(height: 14),
                        _editableCard(
                          title: 'Diagnóstico',
                          icon: Icons.description_outlined,
                          color: const Color(0xFF1CB5C9),
                          controller: _diagnosticoCtrl,
                          hint: 'Escribe el diagnóstico médico (Requerido)...',
                          maxLines: 3,
                          enabled: _puedeEditar,
                        ),
                        const SizedBox(height: 14),
                        _editableCard(
                          title: 'Tratamiento',
                          icon: Icons.healing_outlined,
                          color: const Color(0xFFF0954A),
                          controller: _tratamientoCtrl,
                          hint: 'Plan de cuidado y tratamiento a seguir...',
                          maxLines: 3,
                          enabled: _puedeEditar,
                        ),
                        const SizedBox(height: 14),
                        _editableCard(
                          title: 'Medicamentos recetados (Receta)',
                          icon: Icons.medication_outlined,
                          color: const Color(0xFF43B89C),
                          controller: _recetaCtrl,
                          hint: 'Fórmulas, dosis e indicaciones médicas...',
                          maxLines: 3,
                          enabled: _puedeEditar,
                        ),
                        const SizedBox(height: 14),
                        _editableCard(
                          title: 'Recomendaciones',
                          icon: Icons.info_outline_rounded,
                          color: const Color(0xFFFFB300),
                          controller: _recomendacionesCtrl,
                          hint: 'Recomendaciones alimentarias, de aseo u otras...',
                          maxLines: 3,
                          enabled: _puedeEditar,
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

                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Botones de acción inferior basados en el estado actual
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
                builder: (ctx, ctrl, _) {
                  final estadoLower = _estadoActual.toLowerCase();
                  
                  if (estadoLower == 'pendiente') {
                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: ctrl.isLoading ? null : _rechazarCitaDialog,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE53935),
                              side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Rechazar', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: ctrl.isLoading ? null : _aceptarCita,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF43B89C),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Aceptar Cita', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    );
                  } else if (estadoLower == 'confirmada') {
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: ctrl.isLoading ? null : _iniciarAtencion,
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                        label: Text('Iniciar Atención', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C6FCD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    );
                  } else if (estadoLower == 'en atención') {
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: ctrl.isLoading ? null : _guardarConsultaFinal,
                        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                        label: Text('Finalizar Consulta', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43B89C),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
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

  // ── Acciones de Estado ───────────────────────────────────────────────────

  Future<void> _aceptarCita() async {
    final ctrl = context.read<CitaController>();
    final ok = await ctrl.actualizarEstado(widget.cita.id, 'confirmada');
    if (!mounted) return;
    if (ok) {
      setState(() => _estadoActual = 'confirmada');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Cita aceptada y confirmada exitosamente.', style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: const Color(0xFF1CB5C9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ctrl.errorMessage ?? 'Error al aceptar cita'),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _rechazarCitaDialog() {
    final motivoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Rechazar Cita', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Por favor ingresa el motivo del rechazo para informar al propietario:',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl,
              maxLines: 3,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ej. No atiendo a esa hora / Médico de vacaciones / Emergencia...',
                hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final motivo = motivoCtrl.text.trim();
              if (motivo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('El motivo de rechazo es obligatorio.'),
                  backgroundColor: Color(0xFFE53935),
                ));
                return;
              }
              Navigator.pop(ctx);
              await _rechazarCita(motivo);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirmar Rechazo', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _rechazarCita(String motivo) async {
    final ctrl = context.read<CitaController>();
    final ok = await ctrl.guardarConsulta(
      citaId: widget.cita.id,
      estado: 'rechazada',
      descripcion: 'Cita rechazada. Motivo: $motivo',
      receta: '',
      mascotaId: widget.cita.mascotaId,
      veteId: widget.cita.veteId,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _estadoActual = 'rechazada');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Cita rechazada y notificado al propietario.', style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ctrl.errorMessage ?? 'Error al rechazar cita'),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _iniciarAtencion() async {
    final ctrl = context.read<CitaController>();
    final ok = await ctrl.actualizarEstado(widget.cita.id, 'en atención');
    if (!mounted) return;
    if (ok) {
      setState(() => _estadoActual = 'en atención');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Atención iniciada. Registra los datos clínicos a continuación.', style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: const Color(0xFF7C6FCD),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ctrl.errorMessage ?? 'Error al iniciar atención'),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _guardarConsultaFinal() async {
    final ctrl = context.read<CitaController>();
    final diagnostico = _diagnosticoCtrl.text.trim();
    final observaciones = _observacionesCtrl.text.trim();
    final tratamiento = _tratamientoCtrl.text.trim();
    final medicamentos = _recetaCtrl.text.trim();
    final recomendaciones = _recomendacionesCtrl.text.trim();

    if (diagnostico.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor, ingresa el diagnóstico clínico.'),
        backgroundColor: Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final combinedDesc = 'Diagnóstico: $diagnostico\n\nObservaciones: $observaciones';
    final combinedReceta = 'Tratamiento: $tratamiento\n\nMedicamentos: $medicamentos\n\nRecomendaciones: $recomendaciones';

    final ok = await ctrl.guardarConsulta(
      citaId: widget.cita.id,
      estado: 'finalizada',
      descripcion: combinedDesc,
      receta: combinedReceta,
      mascotaId: widget.cita.mascotaId,
      veteId: widget.cita.veteId,
    );

    if (!mounted) return;
    if (ok) {
      setState(() => _estadoActual = 'finalizada');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text('Consulta finalizada y guardada en el historial médico.', style: GoogleFonts.poppins(fontSize: 13)),
        ]),
        backgroundColor: const Color(0xFF43B89C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ctrl.errorMessage ?? 'Error al finalizar consulta'),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }
}
