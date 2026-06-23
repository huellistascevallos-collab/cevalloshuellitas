import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../domain/controllers/auth_controller.dart';
import '../../../domain/controllers/cita_controller.dart';
import '../../../domain/controllers/mascota_controller.dart';
import '../../../domain/controllers/veterinario_controller.dart';
import 'detalle_cita_screen.dart';

// ─── Paleta verde veterinario ─────────────────────────────────────────────────
const _vetGreen = Color(0xFF4A9B7F);       // Acento principal verde
const _vetHeaderBg = Color(0xFFBAD1C2);    // Fondo de cabecera verde pastel
const _vetOrange = Color(0xFFE58D57);      // Naranja para badges y citas urgentes
const _vetDark = Color(0xFF1A2E25);        // Textos oscuros
const _vetGrey = Color(0xFF8A9BB0);        // Textos secundarios
const _vetBg = Color(0xFFF4F8F6);          // Fondo general

class VetHomeScreen extends StatefulWidget {
  const VetHomeScreen({super.key});

  @override
  State<VetHomeScreen> createState() => _VetHomeScreenState();
}

class _VetHomeScreenState extends State<VetHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final citaCtrl = context.read<CitaController>();
      final vetCtrl = context.read<VeterinarioController>();
      final auth = context.read<AuthController>();
      final uid = auth.currentUser?.id;

      citaCtrl.cargarCitasHoy();
      citaCtrl.cargarTodasLasCitas();
      context.read<MascotaController>().cargarTodasLasMascotas();

      // Cargar citas del veterinario logueado
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
    final auth = context.watch<AuthController>();
    final nombre = auth.currentUser?.nombre ?? 'Veterinario';

    return Scaffold(
      backgroundColor: _vetBg,
      body: Stack(
        children: [
          // ── Cabecera verde con curva wave ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: ClipPath(
              clipper: _HeaderClipper(),
              child: Container(
                height: 320,
                color: _vetHeaderBg,
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Fila Logo y Campana
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              const Icon(Icons.local_hospital_rounded,
                                  color: _vetDark, size: 24),
                              const SizedBox(width: 8),
                              Text('Huellitas',
                                  style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: _vetDark)),
                            ]),
                            // Notificaciones
                            Stack(children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: _vetDark, size: 24),
                                  onPressed: () {},
                                ),
                              ),
                              Positioned(
                                right: 0, top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                      color: _vetOrange, shape: BoxShape.circle),
                                  constraints: const BoxConstraints(
                                      minWidth: 16, minHeight: 16),
                                  child: const Center(
                                    child: Text('!',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Bienvenida
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bienvenido 👋',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: _vetDark.withValues(alpha: 0.7))),
                              Text('Dr. $nombre',
                                  style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: _vetDark)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Botones de acceso rápido
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _categoryBtn(context, Icons.pets_rounded,
                                'Pacientes', '/vet_mascotas'),
                            _categoryBtn(context, Icons.calendar_month_rounded,
                                'Citas', '/vet_citas'),
                            _categoryBtn(context, Icons.favorite_rounded,
                                'Urgencias', '/urgencias'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Contenido scrollable debajo de la cabecera ──
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 320), // Espacio para la cabecera

                  // Estadísticas del día
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Consumer2<CitaController, MascotaController>(
                      builder: (ctx, citaCtrl, mascotaCtrl, _) => Row(children: [
                        _statCard('${citaCtrl.citasPendientesHoy}', 'Citas hoy',
                            Icons.calendar_today_rounded, const Color(0xFFE58D57)),
                        const SizedBox(width: 10),
                        _statCard('${citaCtrl.citasCompletadasHoy}', 'Completadas',
                            Icons.task_alt_rounded, _vetGreen),
                        const SizedBox(width: 10),
                        _statCard('${mascotaCtrl.todasLasMascotas.length}', 'Pacientes',
                            Icons.pets_rounded, const Color(0xFF7C6FCD)),
                      ]),
                    ),
                  ),

                  // Contenido scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          // Gestión de Citas — tabs Pendientes / Completadas
                          Row(children: [
                            Icon(Icons.calendar_month_rounded,
                                color: _vetGreen, size: 20),
                            const SizedBox(width: 8),
                            Text('Gestión de Citas',
                                style: GoogleFonts.poppins(
                                    fontSize: 16, fontWeight: FontWeight.w700,
                                    color: _vetDark)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/vet_citas'),
                              child: Text('Ver todas',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                      color: _vetGreen)),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          // Tab bar compacta
                          Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                  color: _vetGreen,
                                  borderRadius: BorderRadius.circular(10)),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey.shade600,
                              dividerColor: Colors.transparent,
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelStyle: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              tabs: const [
                                Tab(text: '⏳  Pendientes'),
                                Tab(text: '✅  Completadas'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Tab content
                          Consumer<CitaController>(
                            builder: (ctx, ctrl, _) {
                              if (ctrl.isLoading) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(child: CircularProgressIndicator(
                                      color: _vetGreen)),
                                );
                              }
                              return AnimatedBuilder(
                                animation: _tabController,
                                builder: (ctx, _) {
                                  final pendientes = ctrl.citasDelVeterinario
                                      .where((c) =>
                                          c.estado.toLowerCase() == 'pendiente' ||
                                          c.estado.toLowerCase() == 'confirmada')
                                      .toList();
                                  final completadas = ctrl.citasDelVeterinario
                                      .where((c) =>
                                          c.estado.toLowerCase() == 'completada')
                                      .toList();
                                  final lista = _tabController.index == 0
                                      ? pendientes : completadas;

                                  if (lista.isEmpty) {
                                    return _emptyCard(
                                      _tabController.index == 0
                                          ? 'Sin citas pendientes' : 'Sin citas completadas',
                                      _tabController.index == 0
                                          ? Icons.event_available_rounded : Icons.task_alt_rounded,
                                    );
                                  }
                                  return Column(
                                    children: lista.take(5).map((c) =>
                                        _citaCardClickable(context, c)).toList(),
                                  );
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // Últimos pacientes atendidos (con citas)
                          _sectionHeader('Últimos Atendidos', Icons.pets_rounded,
                              onTap: () => Navigator.pushNamed(context, '/vet_mascotas')),
                          const SizedBox(height: 10),
                          Consumer2<CitaController, MascotaController>(
                            builder: (ctx, citaCtrl, mascotaCtrl, _) {
                              if (mascotaCtrl.isLoading) {
                                return const Center(
                                    child: CircularProgressIndicator(
                                        color: _vetGreen));
                              }
                              // Nombres únicos de mascotas que tienen citas registradas
                              final nombresConCitas = citaCtrl.todasLasCitas
                                  .map((c) => c.mascotaNombre.toLowerCase())
                                  .toSet();

                              final atendidos = mascotaCtrl.todasLasMascotas
                                  .where((m) => nombresConCitas
                                      .contains(m.nombre.toLowerCase()))
                                  .toList();

                              if (atendidos.isEmpty) {
                                return _emptyCard(
                                    'Aún no hay pacientes atendidos',
                                    Icons.pets_outlined);
                              }
                              return Column(
                                children: atendidos
                                    .take(4)
                                    .map((m) => _pacienteCard(m))
                                    .toList(),
                              );
                            },
                          ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Nav
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _bottomNav(context, auth),
          ),

          // FAB central
          Positioned(
            bottom: 25,
            left: MediaQuery.of(context).size.width / 2 - 35,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/vet_mascotas'),
              child: Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _vetGreen.withValues(alpha: 0.3),
                      blurRadius: 14, offset: const Offset(0, 4)),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: const BoxDecoration(
                      color: _vetGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.pets_rounded,
                      color: Colors.white, size: 30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Botón de categoría estilo imagen ────────────────────────────────────────
  Widget _categoryBtn(BuildContext context, IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _vetGreen.withValues(alpha: 0.18),
                  blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: _vetGreen, size: 34),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: _vetDark,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w800, color: _vetDark)),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: _vetGrey, height: 1.2)),
        ]),
      ),
    );
  }




  Widget _sectionHeader(String title, IconData icon, {VoidCallback? onTap}) {
    return Row(children: [
      Icon(icon, color: _vetGreen, size: 20),
      const SizedBox(width: 8),
      Text(title,
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w700, color: _vetDark)),
      const Spacer(),
      GestureDetector(
        onTap: onTap,
        child: Text('Ver todos',
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600, color: _vetGreen)),
      ),
    ]);
  }

  Widget _citaCardClickable(BuildContext context, dynamic cita) {
    Color color;
    IconData icon;
    switch (cita.estado.toLowerCase()) {
      case 'completada':
        color = const Color(0xFF43B89C);
        icon = Icons.task_alt_rounded;
        break;
      case 'cancelada':
        color = const Color(0xFFE53935);
        icon = Icons.cancel_outlined;
        break;
      default:
        color = const Color(0xFFE58D57);
        icon = Icons.schedule_rounded;
    }
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleCitaScreen(cita: cita),
        ),
      ).then((_) {
        final veteId = context.read<VeterinarioController>().perfil?.id;
        if (veteId != null) {
          context.read<CitaController>().cargarCitasDeVeterinario(veteId);
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(cita.mascotaNombre,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E))),
              Text(cita.motivo,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey.shade500)),
              if (cita.propietarioNombre.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.person_outline_rounded,
                      size: 11, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Text(cita.propietarioNombre,
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.grey.shade400)),
                ]),
              ],
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(cita.hora, style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(cita.fecha.split('-').reversed.join('/'),
                style: GoogleFonts.poppins(
                    fontSize: 10, color: Colors.grey.shade400)),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.grey, size: 18),
          ]),
        ]),
      ),
    );
  }

  Widget _pacienteCard(dynamic mascota) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: mascota.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: (mascota.fotoUrl != null && mascota.fotoUrl!.isNotEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(mascota.fotoUrl!, fit: BoxFit.cover))
              : Icon(mascota.icon, size: 26, color: mascota.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(mascota.nombre,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E))),
            Text('${mascota.especie} · ${mascota.raza} · ${mascota.edad}',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey.shade500)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: mascota.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(mascota.especie,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: mascota.color)),
        ),
      ]),
    );
  }

  Widget _emptyCard(String msg, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: [
        Icon(icon, size: 40, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text(msg,
            style: GoogleFonts.poppins(
                fontSize: 13, color: Colors.grey.shade400)),
      ]),
    );
  }

  Widget _bottomNav(BuildContext context, AuthController auth) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
              icon: const Icon(Icons.home_rounded,
                  color: _vetGreen, size: 30),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.calendar_today_outlined,
                  color: _vetGrey, size: 26),
              onPressed: () => Navigator.pushNamed(context, '/vet_citas')),
          const SizedBox(width: 50),
          IconButton(
              icon: const Icon(Icons.volunteer_activism_rounded,
                  color: _vetGrey, size: 28),
              onPressed: () => Navigator.pushNamed(context, '/adopciones')),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded,
                color: _vetGrey, size: 28),
            onPressed: () => Navigator.pushNamed(context, '/vet_perfil'),
          ),
        ],
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
