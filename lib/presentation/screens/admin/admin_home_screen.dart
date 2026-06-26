import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../domain/controllers/admin_controller.dart';
import '../../../domain/controllers/auth_controller.dart';
import 'admin_usuarios_screen.dart';
import 'admin_veterinarios_screen.dart';
import 'admin_citas_screen.dart';
import 'admin_mascotas_screen.dart';
import 'admin_adopciones_screen.dart';
import 'admin_solicitudes_rol_screen.dart';

// ── Paleta ────────────────────────────────────────────────────────────────────
const _bg       = Color(0xFFF4F6FB);
const _dark     = Color(0xFF1A1F36);
const _grey     = Color(0xFF8A9BB0);
const _white    = Colors.white;
const _gradA    = Color(0xFF1A3A5C);
const _gradB    = Color(0xFF1A73E8);

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().cargarTodo();
    });
  }

  void _navTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<AdminController>(),
          child: screen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthController>();
    final admin = context.watch<AdminController>();
    final nombre = auth.currentUser?.nombre ?? 'Administrador';
    final stats  = admin.estadisticas;

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _gradB,
        onRefresh: () => admin.cargarTodo(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── Cabecera con gradiente ────────────────────────────────────
            SliverToBoxAdapter(
              child: ClipPath(
                clipper: _WaveClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_gradA, _gradB],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top bar
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: _white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: _white, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Text('Panel Admin',
                                style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: _white)),
                            const Spacer(),
                            // Botón logout
                            _IconBtn(
                              icon: Icons.logout_rounded,
                              onTap: () async {
                                await auth.logout();
                                if (!context.mounted) return;
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                            ),
                          ]),
                          const SizedBox(height: 20),
                          Text('Bienvenido 👋',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: _white.withValues(alpha: 0.7))),
                          Text(nombre,
                              style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Sección Gestión ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -36),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 4, height: 18,
                          decoration: BoxDecoration(
                            color: _gradB,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Gestión',
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _dark)),
                      ]),
                      const SizedBox(height: 14),

                      // Grid 2 columnas para las 6 secciones
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.35,
                        children: [
                          _GestionTile(
                            icon: Icons.people_alt_rounded,
                            color: const Color(0xFF1A73E8),
                            titulo: 'Usuarios',
                            valor: '${stats['usuarios'] ?? 0}',
                            onTap: () => _navTo(const AdminUsuariosScreen()),
                          ),
                          _GestionTile(
                            icon: Icons.medical_services_rounded,
                            color: const Color(0xFF0E9F6E),
                            titulo: 'Veterinarios',
                            valor: '${stats['veterinarios'] ?? 0}',
                            onTap: () => _navTo(const AdminVeterinariosScreen()),
                          ),
                          _GestionTile(
                            icon: Icons.badge_rounded,
                            color: const Color(0xFF7C6FCD),
                            titulo: 'Solicitudes',
                            valor: '${admin.solicitudesRolPendientes}',
                            badge: admin.solicitudesRolPendientes,
                            onTap: () => _navTo(const AdminSolicitudesRolScreen()),
                          ),
                          _GestionTile(
                            icon: Icons.pets_rounded,
                            color: const Color(0xFFE58D57),
                            titulo: 'Mascotas',
                            valor: '${stats['mascotas'] ?? 0}',
                            onTap: () => _navTo(const AdminMascotasScreen()),
                          ),
                          _GestionTile(
                            icon: Icons.calendar_month_rounded,
                            color: const Color(0xFF7C6FCD),
                            titulo: 'Citas',
                            valor: '${stats['citas'] ?? 0}',
                            onTap: () => _navTo(const AdminCitasScreen()),
                          ),
                          _GestionTile(
                            icon: Icons.volunteer_activism_rounded,
                            color: const Color(0xFFE91E8C),
                            titulo: 'Adopciones',
                            valor: '${stats['adopciones'] ?? 0}',
                            onTap: () => _navTo(const AdminAdopcionesScreen()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tile de gestión (grid 2 col) ──────────────────────────────────────────────
class _GestionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String titulo;
  final String valor;
  final int badge;
  final VoidCallback onTap;

  const _GestionTile({
    required this.icon,
    required this.color,
    required this.titulo,
    required this.valor,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icono + badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$badge',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _white)),
                  ),
              ],
            ),
            // Texto
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor,
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _dark)),
                Text(titulo,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Botón icono en cabecera ───────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: _white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _white, size: 20),
      ),
    );
  }
}

// ── Wave clipper ──────────────────────────────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.cubicTo(
      size.width * 0.25, size.height + 10,
      size.width * 0.75, size.height - 20,
      size.width, size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}
