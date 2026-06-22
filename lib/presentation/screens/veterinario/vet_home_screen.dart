import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../domain/controllers/auth_controller.dart';
import '../../../domain/controllers/cita_controller.dart';
import '../../../domain/controllers/mascota_controller.dart';
import '../../../domain/controllers/veterinario_controller.dart';
import 'detalle_cita_screen.dart';

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
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // Cabecera
          ClipPath(
            clipper: _HeaderClipper(),
            child: Container(
              height: 300,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D5C70), Color(0xFF1CB5C9)],
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Bienvenido 👋',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85))),
                        Text('Dr. $nombre',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ]),
                      Row(children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded,
                              color: Colors.white, size: 28),
                          onPressed: () {},
                        ),
                      ]),
                    ],
                  ),
                ),

                // Estadísticas del día
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Consumer2<CitaController, MascotaController>(
                    builder: (ctx, citaCtrl, mascotaCtrl, _) => Row(children: [
                      _statCard('${citaCtrl.citasPendientesHoy}', 'Citas hoy',
                          Icons.calendar_today_rounded, const Color(0xFFE58D57)),
                      const SizedBox(width: 10),
                      _statCard('${citaCtrl.citasCompletadasHoy}', 'Completadas',
                          Icons.task_alt_rounded, const Color(0xFF43B89C)),
                      const SizedBox(width: 10),
                      _statCard('${mascotaCtrl.todasLasMascotas.length}', 'Pacientes',
                          Icons.pets_rounded, const Color(0xFF7C6FCD)),
                    ]),
                  ),
                ),

                const SizedBox(height: 16),

                // Grid de acciones rápidas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _actionItem(context, Icons.pets_rounded, 'Pacientes', '/vet_mascotas', const Color(0xFF1CB5C9)),
                      _actionItem(context, Icons.calendar_month_rounded, 'Citas', '/vet_citas', const Color(0xFFE58D57)),
                      _actionItem(context, Icons.favorite_rounded, 'Urgencias', '/urgencias', const Color(0xFFE53935)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Contenido scrollable
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gestión de Citas — tabs Pendientes / Completadas
                        Row(children: [
                          const Icon(Icons.calendar_month_rounded,
                              color: Color(0xFF1CB5C9), size: 20),
                          const SizedBox(width: 8),
                          Text('Gestión de Citas',
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A2E))),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/vet_citas'),
                            child: Text('Ver todas',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1CB5C9))),
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
                                color: const Color(0xFF126E82),
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
                                    color: Color(0xFF1CB5C9))),
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
                                      color: Color(0xFF1CB5C9)));
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
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF126E82),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF5F6FA), width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF126E82).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.pets_rounded, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.2)),
        ]),
      ),
    );
  }

  Widget _actionItem(BuildContext context, IconData icon, String label,
      String route, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF2D2D2D),
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _sectionHeader(String title, IconData icon, {VoidCallback? onTap}) {
    return Row(children: [
      Icon(icon, color: const Color(0xFF1CB5C9), size: 20),
      const SizedBox(width: 8),
      Text(title,
          style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E))),
      const Spacer(),
      GestureDetector(
        onTap: onTap,
        child: Text('Ver todos',
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1CB5C9))),
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
                  color: Color(0xFF1CB5C9), size: 30),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.calendar_today_outlined,
                  color: Colors.grey, size: 26),
              onPressed: () => Navigator.pushNamed(context, '/vet_citas')),
          const SizedBox(width: 50),
          IconButton(
              icon: const Icon(Icons.volunteer_activism_rounded,
                  color: Colors.grey, size: 28),
              onPressed: () => Navigator.pushNamed(context, '/adopciones')),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded,
                color: Colors.grey, size: 28),
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
