import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../domain/controllers/mascota_controller.dart';
import '../../../data/models/mascota_model.dart';

// ─── Paleta de la imagen ───────────────────────────────────────────────────
const _turquesa = Color(0xFF5BBFBF);       // cabecera y botones
const _turquesaIcon = Color(0xFF4AAFAF);   // iconos categoría (ligeramente más oscuro)
const _naranja = Color(0xFFF0954A);        // botón adopta hoy
const _bgBlanco = Color(0xFFFFFFFF);       // fondo general
const _bgCard = Color(0xFFF3F3F3);         // fondo imagen en card
const _textoDark = Color(0xFF1A1A2E);      // texto principal
// ──────────────────────────────────────────────────────────────────────────

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
              color: _bgBlanco,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  const Icon(Icons.favorite_rounded,
                      color: Color(0xFFE53935), size: 22),
                  const SizedBox(width: 10),
                  Text('Mis Favoritos',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _textoDark)),
                ]),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Consumer<MascotaController>(
                  builder: (context, ctrl, _) {
                    final favs = ctrl.mascotasFavoritas;
                    if (favs.isEmpty) {
                      return Center(
                        child: Text('No tienes mascotas favoritas aún.',
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                                fontSize: 14)),
                      );
                    }
                    return ListView.builder(
                      controller: sc,
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
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                  color: _bgCard,
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              child: (m.fotoUrl != null &&
                                      m.fotoUrl!.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      child: Image.network(m.fotoUrl!,
                                          fit: BoxFit.cover))
                                  : const Icon(Icons.pets_rounded,
                                      color: _turquesa, size: 28),
                            ),
                            title: Text(m.nombre,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            subtitle: Text(
                                '${m.especie} · ${m.raza}',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey.shade500)),
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
                borderRadius: BorderRadius.circular(20)),
            backgroundColor: _bgBlanco,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Stack(children: [
                  Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(
                        color: _bgCard,
                        borderRadius: BorderRadius.circular(18)),
                    child: (mascota.fotoUrl != null &&
                            mascota.fotoUrl!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(mascota.fotoUrl!,
                                fit: BoxFit.cover))
                        : const Icon(Icons.pets_rounded,
                            size: 80, color: _turquesa),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => ctrl.toggleFavorito(mascota.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: _bgBlanco,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.12),
                                  blurRadius: 6)
                            ]),
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
                Text(mascota.nombre,
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _textoDark)),
                Text('${mascota.especie} · ${mascota.raza}',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey.shade500)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _infoChip(mascota.edad, Icons.cake_outlined,
                      _naranja),
                  const SizedBox(width: 8),
                  _infoChip(mascota.genero,
                      Icons.transgender_rounded, _turquesa),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.grey.shade200)),
                  child: Text(
                    mascota.descripcion ??
                        'Sin descripción disponible.',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _turquesa,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text('Cerrar',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color)),
      ]),
    );
  }

  // ── Build principal ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MascotaController>();
    final mascotas = ctrl.mascotasAdopcion;

    return Scaffold(
      backgroundColor: _bgBlanco,
      body: Column(
        children: [
          // Cabecera
          _buildHeader(context),

          // Contenido
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),

                  // Título sección
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Mascotas Destacadas',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textoDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cards
                  SizedBox(
                    height: 215,
                    child: ctrl.isLoadingAdopciones
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: _turquesa))
                        : mascotas.isEmpty
                            ? Center(
                                child: Text(
                                  'No hay mascotas destacadas.',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey.shade400),
                                ),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics:
                                    const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20),
                                itemCount: mascotas.length,
                                itemBuilder: (context, i) =>
                                    _petCard(context, mascotas[i]),
                              ),
                  ),
                  const SizedBox(height: 24),

                  // Botón Adopta Hoy
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 22),
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(
                          context, '/adopciones'),
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _naranja,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _naranja
                                  .withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              '¡Adopta Hoy!',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                                Icons.volunteer_activism_rounded,
                                color: Colors.white,
                                size: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom bar ──
      bottomNavigationBar: _buildBottomBar(context),

      // ── FAB pata central ──
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: _turquesa,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _turquesa.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () =>
              Navigator.pushNamed(context, '/mis_mascotas'),
          child: const Icon(Icons.pets_rounded,
              color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
    );
  }

  // ── Cabecera turquesa ────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return ClipPath(
      clipper: _HeaderClipper(),
      child: Container(
        color: _turquesa,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 52,
        ),
        child: Column(children: [
          // AppBar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Row(children: [
                  const Icon(Icons.pets_rounded,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Huellitas',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ]),
                Stack(children: [
                  IconButton(
                    icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 27),
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      width: 15, height: 15,
                      decoration: const BoxDecoration(
                          color: _naranja,
                          shape: BoxShape.circle),
                      child: Center(
                        child: Text('1',
                            style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Categorías
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 36),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                _catBtn(context, Icons.pets_rounded,
                    'Mis\nMascotas', '/mis_mascotas'),
                _catBtn(context,
                    Icons.volunteer_activism_rounded,
                    'Adopciones', '/adopciones'),
                _catBtn(context,
                    Icons.medical_services_outlined,
                    'Servicios', '/servicios'),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _catBtn(BuildContext context, IconData icon,
      String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            color: _turquesaIcon,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ]),
    );
  }

  // ── Card mascota ─────────────────────────────────────────────────────────
  Widget _petCard(BuildContext context, MascotaModel mascota) {
    return Container(
      width: 148,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: _bgBlanco,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: [
        // Zona imagen
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: (mascota.fotoUrl != null &&
                    mascota.fotoUrl!.isNotEmpty)
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Image.network(mascota.fotoUrl!,
                        fit: BoxFit.cover))
                : const Icon(Icons.pets_rounded,
                    size: 76, color: _turquesa),
          ),
        ),
        // Info
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(children: [
            Text(
              mascota.nombre,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textoDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showPerfil(context, mascota),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _turquesa,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    'Ver Perfil',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Bottom Navigation Bar ────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 7,
      color: _bgBlanco,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: SizedBox(
        height: 58,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navBtn(Icons.home_rounded, 0, onTap: () {}),
            _navBtn(Icons.map_outlined, 1,
                onTap: () => Navigator.pushNamed(
                    context, '/mapa_veterinarios')),
            const SizedBox(width: 60), // hueco para FAB
            _navBtn(Icons.favorite_border_rounded, 2,
                onTap: () => _showFavoritosDialog(context)),
            _navBtn(Icons.person_outline_rounded, 3,
                onTap: () =>
                    Navigator.pushNamed(context, '/perfil')),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, int index,
      {required VoidCallback onTap}) {
    final active = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        child: Icon(icon,
            size: 26,
            color: active
                ? _turquesa
                : Colors.grey.shade400),
      ),
    );
  }
}

// ── Header Clipper ────────────────────────────────────────────────────────
class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 48);
    path.quadraticBezierTo(
        size.width / 2, size.height + 8,
        size.width, size.height - 48);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
