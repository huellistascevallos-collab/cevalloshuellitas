import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../domain/controllers/mascota_controller.dart';
import '../../../data/models/mascota_model.dart';

// ─── Paleta de colores exacta de la imagen ────────────────────────────────────
const _teal = Color(0xFF2FA3A3);       // Botones de categoría, "Ver Perfil" y FAB
const _orange = Color(0xFFE58D57);     // Botón "¡Adopta Hoy!" y badge de notificaciones
const _headerBg = Color(0xFFBBE7EC);   // Fondo celeste pastel de la cabecera
const _bg = Color(0xFFF6FAFA);         // Fondo general de la app
const _dark = Color(0xFF262A2B);       // Títulos y textos principales
const _grey = Color(0xFF8A9BB0);       // Textos secundarios e íconos inactivos
const _white = Colors.white;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MascotaController>().cargarMascotasAdopcion();
    });
  }

  // ── Favoritos sheet ──────────────────────────────────────────────────────
  void _showFavoritosDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<MascotaController>(),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.92,
          minChildSize: 0.3,
          builder: (_, sc) => Container(
            decoration: const BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(children: [
              const SizedBox(height: 12),
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Title row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: Color(0xFFE53935), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Mis Favoritos',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Consumer<MascotaController>(
                  builder: (context, ctrl, _) {
                    final favs = ctrl.mascotasFavoritas;
                    if (favs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border_rounded,
                                size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'No tienes mascotas favoritas aún.',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: sc,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      itemCount: favs.length,
                      itemBuilder: (_, i) {
                        final m = favs[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFFFCDD2)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            leading: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F9FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: (m.fotoUrl != null &&
                                      m.fotoUrl!.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      child: Image.network(m.fotoUrl!,
                                          fit: BoxFit.cover))
                                  : const Icon(Icons.pets_rounded,
                                      color: _teal, size: 28),
                            ),
                            title: Text(
                              m.nombre,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: _dark,
                              ),
                            ),
                            subtitle: Text(
                              '${m.especie} · ${m.raza}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            trailing: GestureDetector(
                              onTap: () => ctrl.toggleFavorito(m.id),
                              child: const Icon(Icons.favorite_rounded,
                                  color: Color(0xFFE53935), size: 22),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Dialog perfil mascota ────────────────────────────────────────────────
  void _showPerfil(BuildContext context, MascotaModel mascota) {
    showDialog(
      context: context,
      builder: (_) => Consumer<MascotaController>(
        builder: (ctx, ctrl, _) {
          final esFav = ctrl.esFavorito(mascota.id);
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            backgroundColor: _white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Stack(children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F9FA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: (mascota.fotoUrl != null &&
                            mascota.fotoUrl!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(mascota.fotoUrl!,
                                fit: BoxFit.cover))
                        : const Icon(Icons.pets_rounded,
                            size: 80, color: _teal),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => ctrl.toggleFavorito(mascota.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          esFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: esFav
                              ? const Color(0xFFE53935)
                              : Colors.grey.shade400,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Text(
                  mascota.nombre,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
                Text(
                  '${mascota.especie} · ${mascota.raza}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _infoChip(mascota.edad, Icons.cake_outlined, _orange),
                  const SizedBox(width: 8),
                  _infoChip(
                      mascota.genero, Icons.transgender_rounded, _teal),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _teal.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    mascota.descripcion ?? 'Sin descripción disponible.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      'Cerrar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _infoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MascotaController>();
    final mascotas = ctrl.mascotasAdopcion;

    return Scaffold(
      backgroundColor: _bg,
      // ── FAB central con anillo exterior de la imagen ──
      floatingActionButton: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _teal.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4), // Espaciador para el anillo exterior blanco
        child: Container(
          decoration: const BoxDecoration(
            color: _teal,
            shape: BoxShape.circle,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pushNamed(context, '/mis_mascotas'),
              child: const Icon(
                Icons.pets_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ── Bottom bar ──
      bottomNavigationBar: _buildBottomBar(context),

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Cabecera celeste con curva exacta ──
          SliverToBoxAdapter(
            child: ClipPath(
              clipper: _HeaderWaveClipper(),
              child: Container(
                height: 250,
                color: _headerBg,
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
                            Row(
                              children: [
                                const Icon(
                                  Icons.pets_rounded,
                                  color: _dark,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Huellitas',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: _dark,
                                  ),
                                ),
                              ],
                            ),
                            // Botón de notificaciones con número
                            Stack(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: _dark,
                                      size: 24,
                                    ),
                                    onPressed: () {},
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: _orange,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '1',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Fila de botones de categoría
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _categoryBtn(
                              context,
                              Icons.pets_rounded,
                              'Mis Mascotas',
                              '/mis_mascotas',
                            ),
                            _categoryBtn(
                              context,
                              Icons.volunteer_activism_rounded,
                              'Adopciones',
                              '/adopciones',
                            ),
                            _categoryBtn(
                              context,
                              Icons.medical_services_rounded,
                              'Servicios',
                              '/servicios',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Sección Mascotas Destacadas ──
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Mascotas Destacadas',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _dark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 236,
                  child: ctrl.isLoadingAdopciones
                      ? const Center(
                          child: CircularProgressIndicator(color: _teal))
                      : mascotas.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.pets_rounded,
                                      size: 52,
                                      color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No hay mascotas destacadas.',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade400,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: mascotas.length,
                              itemBuilder: (context, i) =>
                                  _petCard(context, mascotas[i]),
                            ),
                ),

                const SizedBox(height: 28),

                // ── Botón ¡Adopta Hoy! ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/adopciones'),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _orange.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¡Adopta Hoy!',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.volunteer_activism_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Botón de Categoría ──────────────────────────────────────────────────────
  Widget _categoryBtn(BuildContext context, IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _teal.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _dark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tarjeta de Mascota ────────────────────────────────────────────────────
  Widget _petCard(BuildContext context, MascotaModel mascota) {
    return Container(
      width: 156,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F9FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: (mascota.fotoUrl != null && mascota.fotoUrl!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        mascota.fotoUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.pets_rounded, size: 48, color: _teal),
                    ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    mascota.nombre.toLowerCase(), // Mantiene el nombre en minúscula tal como en la imagen
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _dark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  GestureDetector(
                    onTap: () => _showPerfil(context, mascota),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _teal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Ver Perfil',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
    );
  }

  // ── Barra de Navegación Inferior ──────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: _white,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navBtn(Icons.home_rounded, 0, onTap: () {}),
            _navBtn(Icons.map_outlined, 1,
                onTap: () => Navigator.pushNamed(context, '/mapa_veterinarios')),
            const SizedBox(width: 48), // Espacio para el FAB central
            _navBtn(Icons.favorite_border_rounded, 2,
                onTap: () => _showFavoritosDialog(context)),
            _navBtn(Icons.person_outline_rounded, 3,
                onTap: () => Navigator.pushNamed(context, '/perfil')),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, int index, {required VoidCallback onTap}) {
    final active = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Icon(
          icon,
          size: 26,
          color: active ? _teal : _grey,
        ),
      ),
    );
  }
}

// ── Cortador de cabecera en onda convexa ──────────────────────────────────────
class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    // Dibuja una curva de bezier cuadrática que baja en el centro
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 15,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
