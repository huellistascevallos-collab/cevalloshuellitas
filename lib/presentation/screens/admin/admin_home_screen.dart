import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../domain/controllers/admin_controller.dart';
import '../../../domain/controllers/auth_controller.dart';
import 'admin_usuarios_screen.dart';
import 'admin_veterinarios_screen.dart';

// ── Paleta administrador ──────────────────────────────────────────────────────
const _adminBlue   = Color(0xFF1A73E8);
const _adminDark   = Color(0xFF1A1F36);
const _adminGrey   = Color(0xFF8A9BB0);
const _adminBg     = Color(0xFFF4F6FB);
const _adminHeader = Color(0xFFD6E4FF);

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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final admin = context.watch<AdminController>();
    final nombre = auth.currentUser?.nombre ?? 'Administrador';
    final stats = admin.estadisticas;

    return Scaffold(
      backgroundColor: _adminBg,
      body: RefreshIndicator(
        color: _adminBlue,
        onRefresh: () => admin.cargarTodo(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Cabecera ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: ClipPath(
                clipper: _HeaderClipper(),
                child: Container(
                  height: 220,
                  color: _adminHeader,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _adminBlue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.admin_panel_settings_rounded,
                                    color: _adminBlue, size: 24),
                              ),
                              const SizedBox(width: 10),
                              Text('Panel Admin',
                                  style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _adminDark)),
                              const Spacer(),
                              // Logout
                              IconButton(
                                tooltip: 'Cerrar sesión',
                                icon: const Icon(Icons.logout_rounded,
                                    color: _adminDark, size: 22),
                                onPressed: () async {
                                  await auth.logout();
                                  if (!context.mounted) return;
                                  Navigator.pushReplacementNamed(
                                      context, '/login');
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text('Bienvenido 👋',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: _adminDark.withValues(alpha: 0.6))),
                          Text(nombre,
                              style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _adminDark)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Tarjetas de estadísticas ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumen general',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _adminDark)),
                    const SizedBox(height: 12),
                    admin.isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(
                                  color: _adminBlue),
                            ),
                          )
                        : GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.7,
                            children: [
                              _StatCard(
                                label: 'Usuarios',
                                value: '${stats['usuarios'] ?? 0}',
                                icon: Icons.people_rounded,
                                color: const Color(0xFF1A73E8),
                              ),
                              _StatCard(
                                label: 'Veterinarios',
                                value: '${stats['veterinarios'] ?? 0}',
                                icon: Icons.medical_services_rounded,
                                color: const Color(0xFF0E9F6E),
                              ),
                              _StatCard(
                                label: 'Mascotas',
                                value: '${stats['mascotas'] ?? 0}',
                                icon: Icons.pets_rounded,
                                color: const Color(0xFFE58D57),
                              ),
                              _StatCard(
                                label: 'Citas',
                                value: '${stats['citas'] ?? 0}',
                                icon: Icons.calendar_month_rounded,
                                color: const Color(0xFF7C6FCD),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),

            // ── Accesos rápidos ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gestión',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _adminDark)),
                    const SizedBox(height: 12),
                    _GestionCard(
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF1A73E8),
                      titulo: 'Usuarios',
                      subtitulo:
                          '${stats['usuarios'] ?? 0} usuarios registrados',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: context.read<AdminController>(),
                            child: const AdminUsuariosScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _GestionCard(
                      icon: Icons.medical_services_rounded,
                      color: const Color(0xFF0E9F6E),
                      titulo: 'Veterinarios',
                      subtitulo:
                          '${stats['veterinarios'] ?? 0} veterinarios registrados',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: context.read<AdminController>(),
                            child: const AdminVeterinariosScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _adminDark)),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: _adminGrey,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GestionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _GestionCard({
    required this.icon,
    required this.color,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _adminDark)),
                  const SizedBox(height: 2),
                  Text(subtitulo,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: _adminGrey)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: _adminGrey.withValues(alpha: 0.6)),
          ],
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
        size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}
