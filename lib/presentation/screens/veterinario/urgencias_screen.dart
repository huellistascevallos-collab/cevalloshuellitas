import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/cita_model.dart';
import '../../../domain/controllers/auth_controller.dart';
import '../../../domain/controllers/cita_controller.dart';
import '../../../domain/controllers/veterinario_controller.dart';
import 'detalle_cita_screen.dart';

class UrgenciasScreen extends StatefulWidget {
  const UrgenciasScreen({super.key});

  @override
  State<UrgenciasScreen> createState() => _UrgenciasScreenState();
}

class _UrgenciasScreenState extends State<UrgenciasScreen> {
  bool _cargando = true;
  final Set<String> _urgenciasNotificadas = {};
  // Referencia guardada para usar en dispose() sin acceder a context
  CitaController? _citaCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final uid = context.read<AuthController>().currentUser?.id;
      final vetCtrl = context.read<VeterinarioController>();
      _citaCtrl = context.read<CitaController>();

      if (uid != null) {
        await vetCtrl.cargarPerfil(uid);
        final veteId = vetCtrl.perfil?.id;
        if (veteId != null && veteId.isNotEmpty) {
          await _citaCtrl!.cargarCitasDeVeterinario(veteId);
          _citaCtrl!.suscribirNotificaciones(
              entityId: veteId, rol: 'veterinario');
          _citaCtrl!.addListener(_onNuevaUrgencia);
        }
      }
      if (mounted) setState(() => _cargando = false);
    });
  }

  @override
  void dispose() {
    // Usar referencia guardada, nunca context en dispose
    _citaCtrl?.removeListener(_onNuevaUrgencia);
    super.dispose();
  }

  /// Listener: cuando llega una nueva urgencia muestra el diálogo de alerta
  void _onNuevaUrgencia() {
    if (!mounted) return;
    final citaCtrl = _citaCtrl;
    if (citaCtrl == null) return;
    final urgenciasNuevas = citaCtrl.citasDelVeterinario.where((c) {
      final esUrgencia = c.motivo.startsWith('[URGENCIA:');
      final esPendiente = c.estado.toLowerCase() == 'pendiente';
      final noNotificada = !_urgenciasNotificadas.contains(c.id);
      return esUrgencia && esPendiente && noNotificada;
    }).toList();

    for (final cita in urgenciasNuevas) {
      _urgenciasNotificadas.add(cita.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mostrarDialogoUrgencia(cita);
      });
    }
  }

  /// Diálogo de alerta de emergencia con Aceptar / Rechazar
  void _mostrarDialogoUrgencia(CitaModel cita) {
    HapticFeedback.heavyImpact();
    final sintomas = _extraerSintomas(cita.motivo);
    final citaCtrl = context.read<CitaController>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono pulsante de emergencia
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFB71C1C).withValues(alpha: 0.4),
                        width: 2.5),
                  ),
                  child: const Icon(Icons.emergency_rounded,
                      color: Color(0xFFB71C1C), size: 38),
                ),
                const SizedBox(height: 16),
                // Título
                Text(
                  '🚨 Urgencia Crítica',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFB71C1C)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Nueva emergencia veterinaria entrante',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Info mascota + propietario
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFB71C1C).withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _urgRow(Icons.pets_rounded, 'Mascota',
                          cita.mascotaNombre, const Color(0xFFB71C1C)),
                      const SizedBox(height: 8),
                      _urgRow(Icons.person_outline_rounded, 'Propietario',
                          cita.propietarioNombre, Colors.grey.shade600),
                      const SizedBox(height: 8),
                      _urgRow(Icons.notes_rounded, 'Síntomas',
                          sintomas, const Color(0xFF1A1A2E)),
                      if (cita.direccion != null &&
                          cita.direccion!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _urgRow(Icons.home_rounded, 'Domicilio',
                            cita.direccion!, const Color(0xFF1CB5C9)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Botones Aceptar / Rechazar
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await citaCtrl.actualizarEstado(
                            cita.id, 'rechazada');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Urgencia rechazada',
                              style: GoogleFonts.poppins(fontSize: 13)),
                          backgroundColor: Colors.grey.shade700,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ));
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text('Rechazar',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await citaCtrl.actualizarEstado(
                            cita.id, 'confirmada');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Row(children: [
                            const Icon(Icons.emergency_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('¡Urgencia aceptada! Atiende a ${cita.mascotaNombre}.',
                                  style: GoogleFonts.poppins(fontSize: 13)),
                            ),
                          ]),
                          backgroundColor: const Color(0xFFB71C1C),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ));
                        // Navegar al detalle
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    DetalleCitaScreen(cita: cita)),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text('Aceptar',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _urgRow(IconData icon, String label, String value, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 7),
      SizedBox(
        width: 74,
        child: Text('$label:',
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500)),
      ),
      Expanded(
        child: Text(value,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color)),
      ),
    ]);
  }

  /// Filtra solo urgencias críticas activas
  List<CitaModel> get _urgencias {
    final ctrl = context.read<CitaController>();
    return ctrl.citasDelVeterinario.where((c) {
      final estado = c.estado.toLowerCase();
      final esUrgencia = c.motivo.startsWith('[URGENCIA:');
      final estaActiva = estado == 'pendiente' ||
          estado == 'confirmada' ||
          estado == 'en atención';
      return esUrgencia && estaActiva;
    }).toList();
  }

  /// Extrae la prioridad del prefijo: [URGENCIA:ALTA] → "ALTA"
  String _extraerPrioridad(String motivo) {
    final match = RegExp(r'\[URGENCIA:(\w+)\]').firstMatch(motivo);
    return match?.group(1)?.toLowerCase() ?? 'alta';
  }

  /// Extrae el texto de síntomas quitando el prefijo
  String _extraerSintomas(String motivo) {
    return motivo.replaceAll(RegExp(r'\[URGENCIA:\w+\]\s*'), '');
  }

  Color _colorPrioridad(String p) {
    switch (p.toLowerCase()) {
      case 'crítica': return const Color(0xFFB71C1C);
      case 'alta':    return const Color(0xFFE53935);
      case 'media':   return const Color(0xFFE58D57);
      default:        return const Color(0xFFFBC02D);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          ClipPath(
            clipper: _HeaderClipper(),
            child: Container(
              height: 230,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Column(children: [
                    const Icon(Icons.emergency_rounded,
                        color: Colors.white, size: 28),
                    Text('Urgencias',
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ]),
                  const Spacer(),
                  // Indicador en vivo
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Row(children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: Color(0xFF69FF6E), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text('En vivo',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ),
              // Indicador de prioridad única: Crítica
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 7),
                    Text('Solo urgencias CRÍTICAS',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              // Lista
              Expanded(
                child: Consumer<CitaController>(
                  builder: (ctx, ctrl, _) {
                    if (_cargando || ctrl.isLoading) {
                      return const Center(child: CircularProgressIndicator(
                          color: Color(0xFFE53935)));
                    }
                    final lista = _urgencias;
                    if (lista.isEmpty) {
                      return Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Sin urgencias activas',
                              style: GoogleFonts.poppins(
                                  fontSize: 16, color: Colors.grey.shade400)),
                          const SizedBox(height: 8),
                          Text('Las urgencias de tus pacientes\naparecerán aquí en tiempo real.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.grey.shade400)),
                        ]),
                      );
                    }
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: lista.length,
                      itemBuilder: (ctx, i) => _buildUrgenciaCard(lista[i]),
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

  Widget _buildUrgenciaCard(CitaModel cita) {
    final prioridad = _extraerPrioridad(cita.motivo);
    final sintomas  = _extraerSintomas(cita.motivo);
    final color     = _colorPrioridad(prioridad);

    // Calcular tiempo transcurrido (usamos la fecha/hora de la cita)
    String tiempoLabel = '';
    try {
      final dt = DateTime.parse('${cita.fecha}T${cita.hora}:00');
      final diff = DateTime.now().difference(dt);
      if (diff.isNegative) {
        tiempoLabel = 'Ahora mismo';
      } else if (diff.inMinutes < 60) {
        tiempoLabel = 'Hace ${diff.inMinutes} min';
      } else {
        tiempoLabel = 'Hace ${diff.inHours}h';
      }
    } catch (_) {
      tiempoLabel = '${cita.fecha.split('-').reversed.join('/')} ${cita.hora}';
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetalleCitaScreen(cita: cita)),
      ).then((_) {
        if (!context.mounted) return;
        final veteId = context.read<VeterinarioController>().perfil?.id;
        if (veteId != null) {
          context.read<CitaController>().cargarCitasDeVeterinario(veteId);
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border(left: BorderSide(color: color, width: 5)),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.pets_rounded, size: 26, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(cita.mascotaNombre,
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E))),
                if (cita.propietarioNombre.isNotEmpty)
                  Text(cita.propietarioNombre,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade500)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(prioridad.toUpperCase(),
                      style: GoogleFonts.poppins(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: color)),
                ),
                const SizedBox(height: 4),
                Text(tiempoLabel,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade400)),
              ]),
            ]),
            const SizedBox(height: 10),
            // Síntomas
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(sintomas,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: const Color(0xFF2D2D2D))),
            ),
            // Dirección de domicilio (si aplica)
            if (cita.direccion != null && cita.direccion!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFF1CB5C9).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1CB5C9).withValues(alpha: 0.2))),
                child: Row(children: [
                  const Icon(Icons.home_rounded, color: Color(0xFF1CB5C9), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Domicilio: ${cita.direccion}',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: const Color(0xFF126E82),
                          fontWeight: FontWeight.w500),
                      maxLines: 2, overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            // Botón atender
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DetalleCitaScreen(cita: cita)),
                ).then((_) {
                  if (!context.mounted) return;
                  final veteId = context.read<VeterinarioController>().perfil?.id;
                  if (veteId != null) {
                    context.read<CitaController>().cargarCitasDeVeterinario(veteId);
                  }
                }),
                icon: const Icon(Icons.medical_services_outlined, size: 16),
                label: Text('Atender urgencia',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width / 2, size.height + 10, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
