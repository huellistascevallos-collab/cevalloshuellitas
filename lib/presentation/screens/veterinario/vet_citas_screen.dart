import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/cita_model.dart';
import '../../../domain/controllers/auth_controller.dart';
import '../../../domain/controllers/cita_controller.dart';
import '../../../domain/controllers/veterinario_controller.dart';
import 'detalle_cita_screen.dart';

// ── Paleta ────────────────────────────────────────────────────────────────────
const _tealDark   = Color(0xFF126E82);
const _teal       = Color(0xFF1CB5C9);
const _green      = Color(0xFF43B89C);
const _orange     = Color(0xFFE58D57);
const _red        = Color(0xFFE53935);
const _purple     = Color(0xFF7C6FCD);
const _dark       = Color(0xFF1A1A2E);
const _grey       = Color(0xFF8A9BB0);
const _headerBg   = Color(0xFF126E82);

class VetCitasScreen extends StatefulWidget {
  const VetCitasScreen({super.key});

  @override
  State<VetCitasScreen> createState() => _VetCitasScreenState();
}

class _VetCitasScreenState extends State<VetCitasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final citaCtrl = context.read<CitaController>();
      final vetCtrl = context.read<VeterinarioController>();
      final uid = context.read<AuthController>().currentUser?.id;

      citaCtrl.cargarCitasHoy();
      citaCtrl.cargarTodasLasCitas();

      if (uid != null) {
        await vetCtrl.cargarPerfil(uid);
        final veteId = vetCtrl.perfil?.id;
        if (veteId != null && veteId.isNotEmpty) {
          citaCtrl.cargarCitasDeVeterinario(veteId);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNuevaCitaSheet(context),
        backgroundColor: const Color(0xFF1CB5C9),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Nueva Cita',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Stack(
        children: [
          ClipPath(
            clipper: _HeaderClipper(),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF126E82), Color(0xFF1CB5C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
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
                      const Icon(Icons.calendar_month_rounded,
                          color: Colors.white, size: 28),
                      Text('Gestión de Citas',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ]),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ]),
                ),
                // Stats chips
                Consumer<CitaController>(
                  builder: (ctx, ctrl, _) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      _statChip('${ctrl.citasPendientesHoy}',
                          'Pendientes hoy', const Color(0xFFE58D57)),
                      const SizedBox(width: 10),
                      _statChip('${ctrl.citasCompletadasHoy}',
                          'Completadas', const Color(0xFF43B89C)),
                      const SizedBox(width: 10),
                      _statChip(
                          '${ctrl.citasDelVeterinario.length}',
                          'Mis citas', const Color(0xFF7C6FCD)),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                // Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    labelColor: const Color(0xFF126E82),
                    unselectedLabelColor: Colors.white,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Pendientes'),
                      Tab(text: 'Completadas'),
                      Tab(text: 'Todas'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLista(filtro: 'pendiente'),
                      _buildLista(filtro: 'completada'),
                      _buildLista(filtro: 'todas'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String numero, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Text(numero,
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: Colors.white)),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500, height: 1.2)),
        ]),
      ),
    );
  }

  Widget _buildLista({required String filtro}) {
    return Consumer<CitaController>(
      builder: (ctx, ctrl, _) {
        if (ctrl.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1CB5C9)));
        }
        List<CitaModel> lista;
        if (filtro == 'todas') {
          lista = ctrl.citasDelVeterinario;
        } else if (filtro == 'pendiente') {
          lista = ctrl.citasDelVeterinario
              .where((c) =>
                  c.estado.toLowerCase() == 'pendiente' ||
                  c.estado.toLowerCase() == 'confirmada' ||
                  c.estado.toLowerCase() == 'en atención')
              .toList();
        } else {
          lista = ctrl.citasDelVeterinario
              .where((c) =>
                  c.estado.toLowerCase() == 'completada' ||
                  c.estado.toLowerCase() == 'finalizada')
              .toList();
        }

        if (lista.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filtro == 'pendiente'
                      ? Icons.event_available_rounded
                      : filtro == 'completada'
                          ? Icons.task_alt_rounded
                          : Icons.calendar_today_outlined,
                  size: 60,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  filtro == 'pendiente'
                      ? 'Sin citas pendientes'
                      : filtro == 'completada'
                          ? 'Sin citas completadas'
                          : 'Sin citas registradas',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        // ── Historial (completadas) → tabla Excel ──
        if (filtro == 'completada') {
          return _HistorialTabla(lista: lista, onVerDetalle: (cita) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetalleCitaScreen(cita: cita)),
            ).then((_) {
              if (!context.mounted) return;
              final veteId =
                  context.read<VeterinarioController>().perfil?.id;
              if (veteId != null) {
                context.read<CitaController>().cargarCitasDeVeterinario(veteId);
              }
            });
          });
        }

        // ── Pendientes / Todas → cards ──
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: lista.length,
          itemBuilder: (ctx, i) => _citaCard(lista[i]),
        );
      },
    );
  }

  Widget _citaCard(CitaModel cita) {
    Color estadoColor;
    IconData estadoIcon;
    switch (cita.estado.toLowerCase()) {
      case 'confirmada':
        estadoColor = const Color(0xFF1CB5C9);
        estadoIcon = Icons.check_circle_outline_rounded;
        break;
      case 'en atención':
        estadoColor = const Color(0xFF7C6FCD);
        estadoIcon = Icons.play_circle_outline_rounded;
        break;
      case 'completada':
      case 'finalizada':
        estadoColor = const Color(0xFF43B89C);
        estadoIcon = Icons.task_alt_rounded;
        break;
      case 'cancelada':
      case 'rechazada':
        estadoColor = const Color(0xFFE53935);
        estadoIcon = Icons.cancel_outlined;
        break;
      default:
        estadoColor = const Color(0xFFE58D57);
        estadoIcon = Icons.schedule_rounded;
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
          border: Border(left: BorderSide(color: estadoColor, width: 4)),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(estadoIcon, color: estadoColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(cita.mascotaNombre,
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E))),
                  if (cita.propietarioNombre.isNotEmpty)
                    Text('Propietario: ${cita.propietarioNombre}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade500)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(cita.hora, style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: estadoColor)),
                Text(cita.fecha.split('-').reversed.join('/'),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade400)),
              ]),
            ]),
            const SizedBox(height: 8),
            // Motivo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(10)),
              child: Text('Motivo: ${cita.motivo}',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: const Color(0xFF2D2D2D))),
            ),
            // Si tiene descripción o receta, mostrar preview
            if ((cita.descripcion != null && cita.descripcion!.isNotEmpty) ||
                (cita.receta != null && cita.receta!.isNotEmpty)) ...[
              const SizedBox(height: 8),
              Row(children: [
                if (cita.descripcion != null &&
                    cita.descripcion!.isNotEmpty) ...[
                  Icon(Icons.description_outlined,
                      size: 13, color: const Color(0xFF7C6FCD)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(cita.descripcion!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600)),
                  ),
                ],
                if (cita.receta != null && cita.receta!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.medication_outlined,
                      size: 13, color: const Color(0xFF43B89C)),
                  const SizedBox(width: 4),
                  Text('Receta',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600)),
                ],
              ]),
            ],
            // Botón abrir detalle
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: estadoColor.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Ver detalle',
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: estadoColor)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 10, color: estadoColor),
                ]),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showNuevaCitaSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NuevaCitaSheet(),
    );
  }
}

// ── Sheet: Nueva Cita ─────────────────────────────
class _NuevaCitaSheet extends StatefulWidget {
  const _NuevaCitaSheet();

  @override
  State<_NuevaCitaSheet> createState() => _NuevaCitaSheetState();
}

class _NuevaCitaSheetState extends State<_NuevaCitaSheet> {
  final _mascotaController = TextEditingController();
  final _propietarioController = TextEditingController();
  final _motivoController = TextEditingController();
  String? _fechaSeleccionada;
  String? _horaSeleccionada;

  final List<String> _horas = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
    '11:00', '11:30', '14:00', '14:30', '15:00', '15:30', '16:00',
  ];

  @override
  void dispose() {
    _mascotaController.dispose();
    _propietarioController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (_mascotaController.text.trim().isEmpty ||
        _propietarioController.text.trim().isEmpty ||
        _motivoController.text.trim().isEmpty ||
        _fechaSeleccionada == null ||
        _horaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Por favor completa todos los campos')));
      return;
    }

    // Obtener el veteId del veterinario logueado
    final vetCtrl = context.read<VeterinarioController>();
    final veteId = vetCtrl.perfil?.id ?? '';

    final cita = CitaModel(
      id: '',
      usuarioId: '',
      veteId: veteId.isNotEmpty ? veteId : null,
      mascotaId: null,
      mascotaNombre: _mascotaController.text.trim(),
      propietarioNombre: _propietarioController.text.trim(),
      motivo: _motivoController.text.trim(),
      fecha: _fechaSeleccionada!,
      hora: _horaSeleccionada!,
      estado: 'confirmada',
    );

    final ok = await context.read<CitaController>().crearCita(cita);
    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita registrada exitosamente'),
          backgroundColor: Color(0xFF1CB5C9),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Nueva Cita',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E))),
              const SizedBox(height: 18),
              _buildField('Nombre de la mascota', _mascotaController, Icons.pets_rounded),
              const SizedBox(height: 12),
              _buildField('Nombre del propietario', _propietarioController, Icons.person_outline_rounded),
              const SizedBox(height: 12),
              _buildField('Motivo de consulta', _motivoController, Icons.medical_services_outlined),
              const SizedBox(height: 12),
              // Selector de fecha
              GestureDetector(
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    builder: (ctx, child) => Theme(
                      data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: Color(0xFF1CB5C9))),
                      child: child!,
                    ),
                  );
                  if (fecha != null) {
                    setState(() {
                      _fechaSeleccionada =
                          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
                      // Limpiar hora si ya no es válida para la fecha elegida
                      if (_horaSeleccionada != null) {
                        final ahora = DateTime.now();
                        final hoyStr = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';
                        if (_fechaSeleccionada == hoyStr) {
                          final parts = _horaSeleccionada!.split(':');
                          final timeVal = DateTime(ahora.year, ahora.month, ahora.day,
                              int.parse(parts[0]), int.parse(parts[1]));
                          if (timeVal.isBefore(ahora)) {
                            _horaSeleccionada = null;
                          }
                        }
                      }
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBEBF0), width: 1.2),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Color(0xFF1CB5C9), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _fechaSeleccionada ?? 'Seleccionar fecha',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _fechaSeleccionada != null
                              ? const Color(0xFF1A1A2E)
                              : Colors.grey.shade400),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Text('Horario',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _horas.map((h) {
                  // Deshabilitar horas pasadas si la fecha es hoy
                  final ahora = DateTime.now();
                  final hoyStr = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';
                  bool esPasado = false;
                  if (_fechaSeleccionada == hoyStr) {
                    final parts = h.split(':');
                    final timeVal = DateTime(ahora.year, ahora.month, ahora.day,
                        int.parse(parts[0]), int.parse(parts[1]));
                    if (timeVal.isBefore(ahora)) esPasado = true;
                  }
                  final sel = _horaSeleccionada == h && !esPasado;
                  return GestureDetector(
                    onTap: esPasado ? null : () => setState(() => _horaSeleccionada = h),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: esPasado
                            ? Colors.grey.shade200
                            : (sel ? const Color(0xFF1CB5C9) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(h,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: esPasado
                                  ? Colors.grey.shade400
                                  : (sel ? Colors.white : Colors.grey.shade700))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Consumer<CitaController>(
                  builder: (context, ctrl, _) => ElevatedButton(
                    onPressed: ctrl.isLoading ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1CB5C9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: ctrl.isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Registrar Cita',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF2D2D2D)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF1CB5C9), size: 20),
        filled: true,
        fillColor: const Color(0xFFF0FAFB),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFBBEBF0), width: 1.2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1CB5C9), width: 2)),
      ),
    );
  }
}

// ── Tabla Excel: Historial de citas completadas ───────────────────────────────
class _HistorialTabla extends StatelessWidget {
  final List<CitaModel> lista;
  final void Function(CitaModel) onVerDetalle;

  const _HistorialTabla({required this.lista, required this.onVerDetalle});

  // Anchos de columna
  static const double _colFecha      = 100;
  static const double _colHora       = 68;
  static const double _colMascota    = 120;
  static const double _colPropietario = 130;
  static const double _colMotivo     = 150;
  static const double _colDireccion  = 140;
  static const double _colEstado     = 110;
  static const double _colDetalle    = 72;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contador
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${lista.length} cita${lista.length == 1 ? '' : 's'} completada${lista.length == 1 ? '' : 's'}',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _green),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  Container(
                    color: _headerBg,
                    child: Row(children: [
                      _TH('Fecha',       _colFecha),
                      _TD(),
                      _TH('Hora',        _colHora),
                      _TD(),
                      _TH('Mascota',     _colMascota),
                      _TD(),
                      _TH('Propietario', _colPropietario),
                      _TD(),
                      _TH('Motivo',      _colMotivo),
                      _TD(),
                      _TH('Dirección',   _colDireccion),
                      _TD(),
                      _TH('Estado',      _colEstado),
                      _TD(),
                      _TH('Detalle',     _colDetalle),
                    ]),
                  ),
                  // Filas
                  ...lista.asMap().entries.map((e) {
                    final i = e.key;
                    final c = e.value;
                    final rowColor = i.isEven
                        ? Colors.white
                        : const Color(0xFFF0FAFB);
                    return _HistorialFila(
                      cita: c,
                      rowColor: rowColor,
                      onVerDetalle: () => onVerDetalle(c),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TH extends StatelessWidget {
  final String label;
  final double width;
  const _TH(this.label, this.width);

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: 44,
        child: Center(
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3)),
        ),
      );
}

class _TD extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 44,
        color: Colors.white.withValues(alpha: 0.15),
      );
}

class _HistorialFila extends StatelessWidget {
  final CitaModel cita;
  final Color rowColor;
  final VoidCallback onVerDetalle;

  const _HistorialFila({
    required this.cita,
    required this.rowColor,
    required this.onVerDetalle,
  });

  Color get _estadoColor {
    switch (cita.estado.toLowerCase()) {
      case 'completada':
      case 'finalizada':
        return _green;
      case 'confirmada':
        return _teal;
      case 'cancelada':
      case 'rechazada':
        return _red;
      default:
        return _orange;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: rowColor,
      child: Row(children: [
        // Fecha
        _TC(
          width: _HistorialTabla._colFecha,
          child: Text(
            cita.fecha.isNotEmpty
                ? cita.fecha.split('-').reversed.join('/')
                : '—',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 11, color: _dark),
          ),
        ),
        _VD(rowColor),

        // Hora
        _TC(
          width: _HistorialTabla._colHora,
          child: Text(
            cita.hora.isNotEmpty ? cita.hora : '—',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w600, color: _teal),
          ),
        ),
        _VD(rowColor),

        // Mascota
        _TC(
          width: _HistorialTabla._colMascota,
          child: Row(children: [
            const Icon(Icons.pets_rounded, size: 11, color: _teal),
            const SizedBox(width: 4),
            Flexible(
              child: Text(cita.mascotaNombre,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _dark)),
            ),
          ]),
        ),
        _VD(rowColor),

        // Propietario
        _TC(
          width: _HistorialTabla._colPropietario,
          child: Row(children: [
            const Icon(Icons.person_outline_rounded, size: 11, color: _purple),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                cita.propietarioNombre.isNotEmpty
                    ? cita.propietarioNombre
                    : '—',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 11, color: _dark),
              ),
            ),
          ]),
        ),
        _VD(rowColor),

        // Motivo
        _TC(
          width: _HistorialTabla._colMotivo,
          child: Text(
            cita.motivo.isNotEmpty ? cita.motivo : '—',
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: GoogleFonts.poppins(fontSize: 11, color: _grey),
          ),
        ),
        _VD(rowColor),

        // Dirección
        _TC(
          width: _HistorialTabla._colDireccion,
          child: Text(
            cita.direccion?.isNotEmpty == true ? cita.direccion! : '—',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 11, color: _grey),
          ),
        ),
        _VD(rowColor),

        // Estado
        _TC(
          width: _HistorialTabla._colEstado,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _estadoColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _estadoColor.withValues(alpha: 0.4), width: 1),
              ),
              child: Text(
                _capitalize(cita.estado),
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _estadoColor),
              ),
            ),
          ),
        ),
        _VD(rowColor),

        // Botón detalle
        _TC(
          width: _HistorialTabla._colDetalle,
          child: Center(
            child: GestureDetector(
              onTap: onVerDetalle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _teal.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ver',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _teal)),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 8, color: _teal),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _TC extends StatelessWidget {
  final double width;
  final Widget child;
  const _TC({required this.width, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Align(alignment: Alignment.centerLeft, child: child),
      );
}

class _VD extends StatelessWidget {
  final Color rowColor;
  const _VD(this.rowColor);

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 48,
        color: const Color(0xFFDDE5ED),
      );
}

// ── Clipper cabecera ──────────────────────────────────────────────────────────
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
