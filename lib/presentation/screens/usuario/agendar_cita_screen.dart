import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/cita_model.dart';
import '../../../data/models/mascota_model.dart';
import '../../../data/models/servicio_model.dart';
import '../../../domain/controllers/auth_controller.dart';
import '../../../domain/controllers/cita_controller.dart';
import '../../../domain/controllers/mascota_controller.dart';

class AgendarCitaScreen extends StatefulWidget {
  final VeterinarioServicioModel vsm;
  final ServicioModel servicio;
  final String vetNombre;

  const AgendarCitaScreen({
    super.key,
    required this.vsm,
    required this.servicio,
    required this.vetNombre,
  });

  @override
  State<AgendarCitaScreen> createState() => _AgendarCitaScreenState();
}

class _AgendarCitaScreenState extends State<AgendarCitaScreen> {
  // ── Paso actual (0=Mascota, 1=Fecha/Hora, 2=Confirmar) ──
  int _paso = 0;

  // ── Selección mascota ──
  MascotaModel? _mascotaSeleccionada;
  bool _esOtraMascota = false;

  // ── Campos "Otra mascota" ──
  final _nombreMascotaCtrl = TextEditingController();
  final _especieMascotaCtrl = TextEditingController();
  final _razaCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();

  // ── Fecha / Hora ──
  String? _fechaSeleccionada;
  String? _horaSeleccionada;

  // ── Motivo ──
  final _motivoCtrl = TextEditingController();

  final List<String> _horas = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
    '11:00', '11:30', '14:00', '14:30', '15:00', '15:30', '16:00',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthController>().currentUser?.id;
      if (uid != null) {
        context.read<MascotaController>().cargarMascotas(uid);
      }
    });
  }

  @override
  void dispose() {
    _nombreMascotaCtrl.dispose();
    _especieMascotaCtrl.dispose();
    _razaCtrl.dispose();
    _edadCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  bool get _paso0Valido {
    if (_esOtraMascota) return _nombreMascotaCtrl.text.trim().isNotEmpty;
    return _mascotaSeleccionada != null;
  }

  bool get _paso1Valido => _fechaSeleccionada != null && _horaSeleccionada != null;

  String get _nombreMascota {
    if (_esOtraMascota) return _nombreMascotaCtrl.text.trim();
    return _mascotaSeleccionada?.nombre ?? '';
  }

  String get _especieMascota {
    if (_esOtraMascota) return _especieMascotaCtrl.text.trim();
    return _mascotaSeleccionada?.especie ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.servicio.color;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // Cabecera
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF0D5C70), color],
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
                        if (_paso > 0) {
                          setState(() => _paso--);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const Spacer(),
                    Text('Agendar Cita',
                        style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ]),
                ),
                // Indicador de pasos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      _stepDot(0, 'Mascota'),
                      Expanded(child: Container(height: 2,
                          color: _paso > 0 ? Colors.white : Colors.white.withValues(alpha: 0.3))),
                      _stepDot(1, 'Fecha'),
                      Expanded(child: Container(height: 2,
                          color: _paso > 1 ? Colors.white : Colors.white.withValues(alpha: 0.3))),
                      _stepDot(2, 'Confirmar'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Contenido
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildPaso(),
                  ),
                ),
                // Botón siguiente / confirmar
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  color: Colors.white,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _pasoValido()
                          ? () {
                              if (_paso < 2) {
                                setState(() => _paso++);
                              } else {
                                _confirmarCita();
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: color.withValues(alpha: 0.35),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _paso < 2 ? 'Siguiente →' : 'Confirmar Cita',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: activo
                      ? const Color(0xFF126E82)
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
      case 0:
        return _buildPasoMascota();
      case 1:
        return _buildPasoFecha();
      case 2:
        return _buildPasoConfirmacion();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── PASO 0: Selección de mascota ──────────────────────────────────────────
  Widget _buildPasoMascota() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('¿Para cuál mascota?', Icons.pets_rounded),
        const SizedBox(height: 14),
        Consumer<MascotaController>(
          builder: (ctx, ctrl, _) {
            if (ctrl.isLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF1CB5C9)));
            }
            return Column(children: [
              // Lista de mascotas del usuario
              ...ctrl.mascotas.map((m) => _mascotaCard(m)),
              // Opción "Otra mascota"
              _otraMascotaCard(),
              // Formulario si eligió "Otra"
              if (_esOtraMascota) ...[
                const SizedBox(height: 16),
                _sectionTitle('Datos de la mascota', Icons.edit_note_rounded),
                const SizedBox(height: 10),
                _field('Nombre *', _nombreMascotaCtrl, Icons.badge_outlined),
                const SizedBox(height: 10),
                _field('Especie (Perro, Gato…)', _especieMascotaCtrl, Icons.category_outlined),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _field('Raza', _razaCtrl, Icons.pets_outlined)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('Edad', _edadCtrl, Icons.cake_outlined, keyboard: TextInputType.number)),
                ]),
              ],
            ]);
          },
        ),
        const SizedBox(height: 16),
        _sectionTitle('Motivo de la consulta', Icons.notes_rounded),
        const SizedBox(height: 10),
        TextField(
          controller: _motivoCtrl,
          maxLines: 3,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: _inputDeco('Describe el motivo (opcional)', Icons.notes_rounded),
        ),
      ]),
    );
  }

  Widget _mascotaCard(MascotaModel m) {
    final sel = _mascotaSeleccionada?.id == m.id && !_esOtraMascota;
    final color = m.color;
    return GestureDetector(
      onTap: () => setState(() {
        _mascotaSeleccionada = m;
        _esOtraMascota = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: sel ? color : Colors.grey.shade200,
              width: sel ? 2 : 1.2),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(m.icon, color: color, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.nombre, style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E))),
            Text('${m.especie} · ${m.raza} · ${m.edad} años',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
          ])),
          if (sel) Icon(Icons.check_circle_rounded, color: color, size: 22),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF7C6FCD).withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: sel ? const Color(0xFF7C6FCD) : Colors.grey.shade200,
              width: sel ? 2 : 1.2),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: const Color(0xFF7C6FCD).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.add_circle_outline_rounded,
                color: Color(0xFF7C6FCD), size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Otra mascota', style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E))),
            Text('Ingresa los datos manualmente',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
          ])),
          if (sel) const Icon(Icons.check_circle_rounded,
              color: Color(0xFF7C6FCD), size: 22),
        ]),
      ),
    );
  }

  // ── PASO 1: Fecha y hora ─────────────────────────────────────────────────
  Widget _buildPasoFecha() {
    final color = widget.servicio.color;
    return SingleChildScrollView(
      key: const ValueKey(1),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Selecciona la fecha', Icons.calendar_today_rounded),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final fecha = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
              builder: (ctx, child) => Theme(
                data: ThemeData.light().copyWith(
                    colorScheme: ColorScheme.light(primary: color)),
                child: child!,
              ),
            );
            if (fecha != null) {
              setState(() {
                _fechaSeleccionada =
                    '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _fechaSeleccionada != null ? color : Colors.grey.shade200,
                  width: _fechaSeleccionada != null ? 2 : 1.2),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              Icon(Icons.calendar_today_outlined, color: color, size: 22),
              const SizedBox(width: 14),
              Text(
                _fechaSeleccionada != null
                    ? _fechaSeleccionada!.split('-').reversed.join('/')
                    : 'Toca para seleccionar fecha',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: _fechaSeleccionada != null
                        ? FontWeight.w600 : FontWeight.normal,
                    color: _fechaSeleccionada != null
                        ? const Color(0xFF1A1A2E) : Colors.grey.shade400),
              ),
              const Spacer(),
              if (_fechaSeleccionada != null)
                Icon(Icons.check_circle_rounded, color: color, size: 20),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Selecciona un horario', Icons.access_time_rounded),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _horas.map((h) {
            final sel = _horaSeleccionada == h;
            return GestureDetector(
              onTap: () => setState(() => _horaSeleccionada = h),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? color : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: sel ? color : Colors.grey.shade200,
                      width: sel ? 0 : 1.2),
                  boxShadow: sel ? [BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8, offset: const Offset(0, 3))] : [],
                ),
                child: Text(h,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : Colors.grey.shade600)),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ── PASO 2: Confirmación ─────────────────────────────────────────────────
  Widget _buildPasoConfirmacion() {
    final color = widget.servicio.color;
    final user = context.read<AuthController>().currentUser;
    return SingleChildScrollView(
      key: const ValueKey(2),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Resumen de la cita', Icons.fact_check_outlined),
        const SizedBox(height: 14),
        // Card veterinario
        _resumenCard(
          icon: Icons.person_outline_rounded,
          color: color,
          titulo: 'Veterinario',
          items: [
            _resumenRow('Dr/a.', widget.vetNombre),
            _resumenRow('Servicio', widget.servicio.nombre),
            if (widget.vsm.precio != null)
              _resumenRow('Tarifa', '\$${widget.vsm.precio!.toStringAsFixed(0)}'),
            if (widget.vsm.duracion != null)
              _resumenRow('Duración', widget.vsm.duracion!),
          ],
        ),
        const SizedBox(height: 12),
        // Card mascota
        _resumenCard(
          icon: Icons.pets_rounded,
          color: const Color(0xFF43B89C),
          titulo: 'Mascota',
          items: [
            _resumenRow('Nombre', _nombreMascota.isNotEmpty ? _nombreMascota : '—'),
            _resumenRow('Especie', _especieMascota.isNotEmpty ? _especieMascota : '—'),
            if (_esOtraMascota && _razaCtrl.text.isNotEmpty)
              _resumenRow('Raza', _razaCtrl.text),
            if (_esOtraMascota && _edadCtrl.text.isNotEmpty)
              _resumenRow('Edad', '${_edadCtrl.text} años'),
            if (_motivoCtrl.text.trim().isNotEmpty)
              _resumenRow('Motivo', _motivoCtrl.text.trim()),
          ],
        ),
        const SizedBox(height: 12),
        // Card fecha
        _resumenCard(
          icon: Icons.calendar_today_rounded,
          color: const Color(0xFF7C6FCD),
          titulo: 'Fecha y Hora',
          items: [
            _resumenRow('Fecha',
                _fechaSeleccionada?.split('-').reversed.join('/') ?? '—'),
            _resumenRow('Hora', _horaSeleccionada ?? '—'),
          ],
        ),
        const SizedBox(height: 12),
        // Card cliente
        _resumenCard(
          icon: Icons.person_rounded,
          color: const Color(0xFFE58D57),
          titulo: 'Propietario',
          items: [
            _resumenRow('Nombre', user?.nombre ?? '—'),
            _resumenRow('Teléfono',
                (user?.telefono?.isNotEmpty == true) ? user!.telefono! : 'No registrado'),
            _resumenRow('Correo', user?.correo ?? '—'),
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
        SizedBox(
          width: 100,
          child: Text(label, style: GoogleFonts.poppins(
              fontSize: 12, color: Colors.grey.shade500)),
        ),
        Expanded(child: Text(value, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A2E)))),
      ]),
    );
  }

  // ── Confirmar y guardar ──────────────────────────────────────────────────
  Future<void> _confirmarCita() async {
    final auth = context.read<AuthController>();
    final citaCtrl = context.read<CitaController>();
    final user = auth.currentUser;
    if (user == null) return;

    final motivo = _motivoCtrl.text.trim().isNotEmpty
        ? _motivoCtrl.text.trim()
        : widget.servicio.nombre;

    final cita = CitaModel(
      id: '',
      usuarioId: user.id,
      veteId: widget.vsm.veteId,
      mascotaId: _mascotaSeleccionada?.id,
      mascotaNombre: _nombreMascota,
      propietarioNombre: user.nombre,
      motivo: motivo,
      fecha: _fechaSeleccionada!,
      hora: _horaSeleccionada!,
      estado: 'pendiente',
    );

    final ok = await citaCtrl.crearCita(cita);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(
              '¡Cita agendada para el ${_fechaSeleccionada!.split('-').reversed.join('/')} a las $_horaSeleccionada!',
              style: GoogleFonts.poppins(fontSize: 13))),
        ]),
        backgroundColor: widget.servicio.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(citaCtrl.errorMessage ?? 'Error al guardar la cita'),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  // ── Helpers de UI ────────────────────────────────────────────────────────
  Widget _sectionTitle(String t, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: const Color(0xFFE8F6F8),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF1CB5C9), size: 18),
      ),
      const SizedBox(width: 10),
      Text(t, style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1A2E))),
    ]);
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF2D2D2D)),
      decoration: _inputDeco(label, icon),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 12),
      prefixIcon: Icon(icon, color: const Color(0xFF1CB5C9), size: 18),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDEEF0), width: 1.2)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1CB5C9), width: 2)),
    );
  }
}
