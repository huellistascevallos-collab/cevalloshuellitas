import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/cita_model.dart';
import '../../../data/models/mascota_model.dart';
import '../../../domain/controllers/auth_controller.dart';
import '../../../domain/controllers/cita_controller.dart';
import '../../../domain/controllers/mascota_controller.dart';
import '../../../domain/controllers/veterinario_controller.dart';
import '../../../data/models/veterinario_model.dart';

class UrgenciasUsuarioScreen extends StatefulWidget {
  const UrgenciasUsuarioScreen({super.key});

  @override
  State<UrgenciasUsuarioScreen> createState() => _UrgenciasUsuarioScreenState();
}

class _UrgenciasUsuarioScreenState extends State<UrgenciasUsuarioScreen> {
  // Paso: 0=síntomas/mascota, 1=veterinario, 2=confirmar
  int _paso = 0;

  // Selección mascota
  MascotaModel? _mascotaSeleccionada;
  final _nombreMascotaCtrl = TextEditingController();
  bool _esOtraMascota = false;

  // Síntomas / prioridad
  final _sintomasCtrl = TextEditingController();
  String _prioridad = 'alta';

  // Veterinario
  VeterinarioModel? _vetSeleccionado;

  // Estado de carga de vets
  bool _cargandoVets = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthController>().currentUser?.id;
      if (uid != null) {
        context.read<MascotaController>().cargarMascotas(uid);
      }
      _cargarVeterinarios();
    });
  }

  Future<void> _cargarVeterinarios() async {
    setState(() => _cargandoVets = true);
    await context.read<VeterinarioController>().cargarTodosLosVeterinarios();
    if (mounted) setState(() => _cargandoVets = false);
  }

  @override
  void dispose() {
    _nombreMascotaCtrl.dispose();
    _sintomasCtrl.dispose();
    super.dispose();
  }

  bool get _paso0Valido {
    final tieneNombreMascota = _esOtraMascota
        ? _nombreMascotaCtrl.text.trim().isNotEmpty
        : _mascotaSeleccionada != null;
    return tieneNombreMascota && _sintomasCtrl.text.trim().isNotEmpty;
  }

  bool get _paso1Valido => _vetSeleccionado != null;

  String get _nombreMascota => _esOtraMascota
      ? _nombreMascotaCtrl.text.trim()
      : (_mascotaSeleccionada?.nombre ?? '');

  Color get _prioridadColor {
    switch (_prioridad) {
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
          Container(
            height: 210,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 22),
                      onPressed: () {
                        if (_paso > 0) setState(() => _paso--);
                        else Navigator.pop(context);
                      },
                    ),
                    const Spacer(),
                    Column(children: [
                      const Icon(Icons.emergency_rounded, color: Colors.white, size: 28),
                      Text('Urgencia Veterinaria',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ]),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ]),
                ),
                // Indicador de pasos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(children: [
                    _stepDot(0, 'Síntomas'),
                    Expanded(child: Container(height: 2,
                        color: _paso > 0 ? Colors.white : Colors.white.withValues(alpha: 0.3))),
                    _stepDot(1, 'Veterinario'),
                    Expanded(child: Container(height: 2,
                        color: _paso > 1 ? Colors.white : Colors.white.withValues(alpha: 0.3))),
                    _stepDot(2, 'Confirmar'),
                  ]),
                ),
                const SizedBox(height: 8),
                // Contenido por paso
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildPaso(),
                  ),
                ),
                // Botón siguiente/confirmar
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  color: Colors.white,
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _pasoValido() ? _avanzar : null,
                      icon: Icon(
                        _paso < 2 ? Icons.arrow_forward_rounded : Icons.emergency_rounded,
                        color: Colors.white),
                      label: Text(
                        _paso < 2 ? 'Siguiente' : 'Enviar Urgencia',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFFE53935).withValues(alpha: 0.35),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _pasoValido() {
    if (_paso == 0) return _paso0Valido;
    if (_paso == 1) return _paso1Valido;
    return true;
  }

  void _avanzar() {
    if (_paso < 2) setState(() => _paso++);
    else _confirmarUrgencia();
  }

  Widget _stepDot(int step, String label) {
    final activo = _paso >= step;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: activo ? Colors.white : Colors.white.withValues(alpha: 0.3),
        ),
        child: Center(
          child: Text('${step + 1}',
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: activo ? const Color(0xFFE53935)
                      : Colors.white.withValues(alpha: 0.6))),
        ),
      ),
      const SizedBox(height: 2),
      Text(label,
          style: GoogleFonts.poppins(
              fontSize: 9,
              color: activo ? Colors.white : Colors.white.withValues(alpha: 0.5))),
    ]);
  }

  Widget _buildPaso() {
    switch (_paso) {
      case 0: return _buildPasoSintomas();
      case 1: return _buildPasoVeterinario();
      case 2: return _buildPasoConfirmacion();
      default: return const SizedBox.shrink();
    }
  }

  // ── PASO 0: Síntomas y mascota ────────────────────────────────────────────
  Widget _buildPasoSintomas() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('¿Cuál es la emergencia?', Icons.crisis_alert_rounded),
        const SizedBox(height: 12),
        // Prioridad
        Row(children: [
          _prioridadBtn('crítica', '🔴 Crítica'),
          const SizedBox(width: 8),
          _prioridadBtn('alta', '🟠 Alta'),
          const SizedBox(width: 8),
          _prioridadBtn('media', '🟡 Media'),
        ]),
        const SizedBox(height: 16),
        // Síntomas
        _sectionTitle('Describe los síntomas', Icons.notes_rounded),
        const SizedBox(height: 10),
        TextField(
          controller: _sintomasCtrl,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Ej: dificultad para respirar, convulsiones, sangrado...',
            hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFFFCDD2), width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE53935), width: 2)),
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle('Mascota afectada', Icons.pets_rounded),
        const SizedBox(height: 10),
        Consumer<MascotaController>(
          builder: (_, ctrl, __) {
            if (ctrl.isLoading) {
              return const Center(child: CircularProgressIndicator(
                  color: Color(0xFFE53935)));
            }
            return Column(children: [
              ...ctrl.mascotas.map((m) => _mascotaCard(m)),
              _otraMascotaCard(),
              if (_esOtraMascota) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _nombreMascotaCtrl,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Nombre de la mascota *',
                    labelStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade500, fontSize: 12),
                    prefixIcon: const Icon(Icons.badge_outlined,
                        color: Color(0xFFE53935), size: 18),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFFFFCDD2), width: 1.2)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFFE53935), width: 2)),
                  ),
                ),
              ],
            ]);
          },
        ),
      ]),
    );
  }

  Widget _prioridadBtn(String valor, String label) {
    final sel = _prioridad == valor;
    final color = _colorPrioridadValue(valor);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _prioridad = valor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: sel ? color : Colors.grey.shade200,
                width: sel ? 2 : 1.2),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: sel ? color : Colors.grey.shade500)),
          ),
        ),
      ),
    );
  }

  Color _colorPrioridadValue(String val) {
    switch (val) {
      case 'crítica': return const Color(0xFFB71C1C);
      case 'alta':    return const Color(0xFFE53935);
      case 'media':   return const Color(0xFFE58D57);
      default:        return const Color(0xFFFBC02D);
    }
  }

  Widget _mascotaCard(MascotaModel m) {
    final sel = _mascotaSeleccionada?.id == m.id && !_esOtraMascota;
    return GestureDetector(
      onTap: () => setState(() {
        _mascotaSeleccionada = m;
        _esOtraMascota = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFEBEE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: sel ? const Color(0xFFE53935) : Colors.grey.shade200,
              width: sel ? 2 : 1.2),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: m.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(m.icon, color: m.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(m.nombre, style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E))),
            Text('${m.especie} · ${m.raza}',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
          ])),
          if (sel) const Icon(Icons.check_circle_rounded,
              color: Color(0xFFE53935), size: 22),
        ]),
      ),
    );
  }

  Widget _otraMascotaCard() {
    final sel = _esOtraMascota;
    return GestureDetector(
      onTap: () => setState(() {
        _esOtraMascota = true;
        _mascotaSeleccionada = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFEBEE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: sel ? const Color(0xFFE53935) : Colors.grey.shade200,
              width: sel ? 2 : 1.2),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add_circle_outline_rounded,
                color: Color(0xFFE53935), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('Otra mascota', style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E))),
            Text('Ingresa el nombre manualmente',
                style: GoogleFonts.poppins(fontSize: 11,
                    color: Colors.grey.shade500)),
          ])),
          if (sel) const Icon(Icons.check_circle_rounded,
              color: Color(0xFFE53935), size: 22),
        ]),
      ),
    );
  }

  // ── PASO 1: Selección de veterinario ─────────────────────────────────────
  Widget _buildPasoVeterinario() {
    final vets = context.read<VeterinarioController>().todos
        .where((v) => v.disponible)
        .toList();

    return SingleChildScrollView(
      key: const ValueKey(1),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Selecciona un veterinario', Icons.medical_services_rounded),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: Color(0xFFE53935), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Solo se muestran veterinarios disponibles en este momento.',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: const Color(0xFFB71C1C)),
            )),
          ]),
        ),
        const SizedBox(height: 14),
        if (_cargandoVets)
          const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
        else if (vets.isEmpty)
          Center(
            child: Column(children: [
              const Icon(Icons.sentiment_dissatisfied_rounded,
                  size: 48, color: Color(0xFFFFCDD2)),
              const SizedBox(height: 10),
              Text('No hay veterinarios disponibles ahora',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey.shade500)),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _cargarVeterinarios,
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFFE53935)),
                label: Text('Recargar',
                    style: GoogleFonts.poppins(color: const Color(0xFFE53935))),
              ),
            ]),
          )
        else
          ...vets.map((v) => _vetCard(v)),
      ]),
    );
  }

  Widget _vetCard(VeterinarioModel v) {
    final sel = _vetSeleccionado?.id == v.id;
    return GestureDetector(
      onTap: () => setState(() => _vetSeleccionado = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFEBEE) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: sel ? const Color(0xFFE53935) : Colors.grey.shade200,
              width: sel ? 2 : 1.2),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          // Avatar
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE53935).withValues(alpha: 0.1),
              image: v.fotoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(v.fotoUrl!),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: v.fotoUrl == null
                ? const Icon(Icons.person_rounded,
                    color: Color(0xFFE53935), size: 28)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(v.nombre ?? 'Veterinario',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E))),
            if (v.especialidad != null && v.especialidad!.isNotEmpty)
              Text(v.especialidad!,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey.shade500)),
            Row(children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: Color(0xFF43B89C), shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text('Disponible',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: const Color(0xFF43B89C),
                      fontWeight: FontWeight.w600)),
            ]),
          ])),
          if (sel) const Icon(Icons.check_circle_rounded,
              color: Color(0xFFE53935), size: 24),
        ]),
      ),
    );
  }

  // ── PASO 2: Confirmación ─────────────────────────────────────────────────
  Widget _buildPasoConfirmacion() {
    final user = context.read<AuthController>().currentUser;
    final now = DateTime.now();
    final fechaStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final horaStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      key: const ValueKey(2),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Banner urgencia
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFB71C1C), Color(0xFFE53935)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            const Icon(Icons.emergency_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Reporte de Urgencia',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: Colors.white)),
              Text('Se notificará al veterinario inmediatamente.',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.white.withValues(alpha: 0.9))),
            ])),
          ]),
        ),
        const SizedBox(height: 16),
        _resumenCard(
          icon: Icons.pets_rounded,
          color: const Color(0xFFE53935),
          titulo: 'Mascota',
          items: [
            _resumenRow('Nombre', _nombreMascota),
            _resumenRow('Síntomas', _sintomasCtrl.text.trim()),
            _resumenRow('Prioridad', _prioridad.toUpperCase()),
          ],
        ),
        const SizedBox(height: 12),
        _resumenCard(
          icon: Icons.medical_services_rounded,
          color: const Color(0xFF43B89C),
          titulo: 'Veterinario asignado',
          items: [
            _resumenRow('Nombre', _vetSeleccionado?.nombre ?? '—'),
            if (_vetSeleccionado?.especialidad != null)
              _resumenRow('Especialidad', _vetSeleccionado!.especialidad!),
          ],
        ),
        const SizedBox(height: 12),
        _resumenCard(
          icon: Icons.access_time_rounded,
          color: const Color(0xFF7C6FCD),
          titulo: 'Fecha y hora',
          items: [
            _resumenRow('Fecha', fechaStr.split('-').reversed.join('/')),
            _resumenRow('Hora', horaStr),
            _resumenRow('Propietario', user?.nombre ?? '—'),
          ],
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _resumenCard({required IconData icon, required Color color,
      required String titulo, required List<Widget> items}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(titulo, style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E))),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        const SizedBox(height: 8),
        ...items,
      ]),
    );
  }

  Widget _resumenRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 90,
            child: Text(label, style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.grey.shade500))),
        Expanded(child: Text(value, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A2E)))),
      ]),
    );
  }

  Widget _sectionTitle(String t, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFFE53935), size: 18),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(t, style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1A2E)))),
    ]);
  }

  // ── Confirmar y crear la cita urgente ────────────────────────────────────
  Future<void> _confirmarUrgencia() async {
    final auth = context.read<AuthController>();
    final citaCtrl = context.read<CitaController>();
    final user = auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    // Redondear a los próximos 5 minutos para que no falle la validación "no pasado"
    final minutos = (now.minute ~/ 5 + 1) * 5;
    final horaAjustada = now.add(Duration(minutes: minutos - now.minute));
    final fechaStr =
        '${horaAjustada.year}-${horaAjustada.month.toString().padLeft(2, '0')}-${horaAjustada.day.toString().padLeft(2, '0')}';
    final horaStr =
        '${horaAjustada.hour.toString().padLeft(2, '0')}:${horaAjustada.minute.toString().padLeft(2, '0')}';

    // El motivo lleva el prefijo [URGENCIA] y la prioridad para que el vet lo identifique
    final motivo =
        '[URGENCIA:${_prioridad.toUpperCase()}] ${_sintomasCtrl.text.trim()}';

    final cita = CitaModel(
      id: '',
      usuarioId: user.id,
      veteId: _vetSeleccionado!.id,
      mascotaId: _mascotaSeleccionada?.id,
      mascotaNombre: _nombreMascota,
      propietarioNombre: user.nombre,
      motivo: motivo,
      fecha: fechaStr,
      hora: horaStr,
      estado: 'pendiente',
    );

    final ok = await citaCtrl.crearCita(cita);
    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(
            '¡Urgencia reportada! El veterinario fue notificado.',
            style: GoogleFonts.poppins(fontSize: 13))),
        ]),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(citaCtrl.errorMessage ?? 'Error al reportar la urgencia'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }
}
