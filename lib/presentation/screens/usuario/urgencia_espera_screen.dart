import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/cita_model.dart';
import '../../../domain/controllers/cita_controller.dart';

// ── Paleta ────────────────────────────────────────────────────────────────────
const _red    = Color(0xFFB71C1C);
const _redBg  = Color(0xFFFFF5F5);
const _green  = Color(0xFF2E7D32);
const _greenBg = Color(0xFFF1FFF4);
const _dark   = Color(0xFF1A1A2E);
const _grey   = Color(0xFF8A9BB0);

/// Pantalla de sala de espera que el usuario ve después de emitir una urgencia.
/// Escucha el CitaController vía Realtime y reacciona cuando el veterinario
/// acepta o rechaza la solicitud.
class UrgenciaEsperaScreen extends StatefulWidget {
  /// ID de la cita urgente recién creada.
  final CitaModel cita;

  const UrgenciaEsperaScreen({super.key, required this.cita});

  @override
  State<UrgenciaEsperaScreen> createState() => _UrgenciaEsperaScreenState();
}

class _UrgenciaEsperaScreenState extends State<UrgenciaEsperaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Estado local: null = esperando, 'confirmada' = aceptada, 'rechazada' = rechazada
  String? _respuesta;
  bool _respondido = false;

  @override
  void initState() {
    super.initState();

    // Animación pulsante del ícono de emergencia
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Registrar listener para detectar respuesta del veterinario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CitaController>().addListener(_onRespuesta);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    context.read<CitaController>().removeListener(_onRespuesta);
    super.dispose();
  }

  void _onRespuesta() {
    if (_respondido || !mounted) return;
    final ctrl = context.read<CitaController>();
    final ultima = ctrl.ultimaRespuestaUrgencia;
    if (ultima == null || ultima.id != widget.cita.id) return;

    final estado = ultima.estado.toLowerCase();
    if (estado == 'confirmada' || estado == 'rechazada') {
      ctrl.limpiarRespuestaUrgencia();
      setState(() {
        _respondido = true;
        _respuesta = estado;
      });
      // Detener la animación pulsante
      _pulseCtrl.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Mientras espera no se puede salir con back; cuando ya hay respuesta sí
      onWillPop: () async => _respondido,
      child: Scaffold(
        backgroundColor:
            _respondido ? (_respuesta == 'confirmada' ? _greenBg : _redBg) : _redBg,
        body: SafeArea(
          child: _respondido ? _buildRespuesta() : _buildEspera(),
        ),
      ),
    );
  }

  // ── Vista: esperando respuesta ─────────────────────────────────────────────
  Widget _buildEspera() {
    final sintomas = widget.cita.motivo
        .replaceAll(RegExp(r'\[URGENCIA:\w+\]\s*'), '');

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícono pulsante
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _red.withValues(alpha: 0.4), width: 3),
              ),
              child: const Icon(Icons.emergency_rounded,
                  color: _red, size: 60),
            ),
          ),
          const SizedBox(height: 32),

          Text('🚨 Urgencia enviada',
              style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _red),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text('Esperando respuesta del veterinario…',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: _grey),
              textAlign: TextAlign.center),

          const SizedBox(height: 32),

          // Datos de la urgencia
          _infoCard(children: [
            _fila(Icons.pets_rounded, 'Mascota', widget.cita.mascotaNombre, _red),
            if (sintomas.isNotEmpty) ...[
              _divider(),
              _fila(Icons.notes_rounded, 'Síntomas', sintomas, _dark),
            ],
            if (widget.cita.direccion != null &&
                widget.cita.direccion!.isNotEmpty) ...[
              _divider(),
              _fila(Icons.home_rounded, 'Domicilio',
                  widget.cita.direccion!, const Color(0xFF1CB5C9)),
            ],
          ]),

          const SizedBox(height: 32),

          // Indicador de carga
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: _red, strokeWidth: 2.5),
            ),
            const SizedBox(width: 12),
            Text('El veterinario recibirá la alerta en segundos',
                style: GoogleFonts.poppins(fontSize: 12, color: _grey)),
          ]),

          const Spacer(),

          // Botón cancelar (solo mientras espera)
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.cancel_outlined,
                color: _red.withValues(alpha: 0.7), size: 18),
            label: Text('Cancelar urgencia',
                style: GoogleFonts.poppins(
                    color: _red.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Vista: respuesta recibida ──────────────────────────────────────────────
  Widget _buildRespuesta() {
    final aceptada = _respuesta == 'confirmada';
    final color = aceptada ? _green : _red;
    final bgColor = aceptada ? _greenBg : _redBg;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícono de respuesta
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: color.withValues(alpha: 0.4), width: 3),
            ),
            child: Icon(
              aceptada
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: color,
              size: 64,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            aceptada ? '✅ ¡Urgencia aceptada!' : '❌ Urgencia rechazada',
            style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Text(
              aceptada
                  ? 'El veterinario está en camino o listo para atenderte. '
                    'Dirígete al consultorio o espera en tu domicilio.'
                  : 'El veterinario no puede atender esta emergencia en este momento. '
                    'Regresa para seleccionar otro veterinario disponible.',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: _dark,
                  height: 1.6),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 32),

          // Datos resumidos
          _infoCard(children: [
            _fila(Icons.pets_rounded, 'Mascota',
                widget.cita.mascotaNombre, color),
            if (widget.cita.direccion != null &&
                widget.cita.direccion!.isNotEmpty) ...[
              _divider(),
              _fila(Icons.home_rounded, 'Domicilio',
                  widget.cita.direccion!, const Color(0xFF1CB5C9)),
            ],
          ]),

          const Spacer(),

          // Botón de acción
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                aceptada ? 'Entendido' : 'Volver',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _infoCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _fila(IconData icon, String label, String value, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: _grey,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: _dark,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    ]);
  }

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(vertical: 10),
        color: Colors.grey.shade100,
      );
}
