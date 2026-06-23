import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../domain/controllers/mascota_controller.dart';
import '../../../data/models/mascota_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MascotaController>().cargarMascotasAdopcion();
    });
  }

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
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite_rounded, color: Color(0xFFE53935), size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Mis Favoritos',
                          style: GoogleFonts.poppins(
                            fontSize: 20, fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Consumer<MascotaController>(
                      builder: (context, controller, _) {
                        final favoritas = controller.mascotasFavoritas;
                        if (favoritas.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.favorite_border_rounded,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No tienes mascotas favoritas aún.',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey.shade500, fontSize: 15),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Márcalas con ❤️ en Mis Mascotas.',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey.shade400, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: favoritas.length,
                          itemBuilder: (context, index) {
                            final m = favoritas[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8F8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFFCDD2)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: Container(
                                  width: 60, height: 60,
                                  decoration: BoxDecoration(
                                    color: m.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: (m.fotoUrl != null && m.fotoUrl!.isNotEmpty)
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: Image.network(m.fotoUrl!, fit: BoxFit.cover),
                                        )
                                      : Icon(m.icon, color: m.color, size: 32),
                                ),
                                title: Text(m.nombre,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700, fontSize: 15)),
                                subtitle: Text(
                                  '${m.especie} · ${m.raza} · ${m.edad} años',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.grey.shade600),
                                ),
                                trailing: GestureDetector(
                                  onTap: () => controller.toggleFavorito(m.id),
                                  child: const Icon(Icons.favorite_rounded,
                                      color: Color(0xFFE53935), size: 24),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showMascotaProfileDialog(BuildContext context, MascotaModel mascota) {
    showDialog(
      context: context,
      builder: (_) => Consumer<MascotaController>(
        builder: (ctx, controller, _) {
          final esFav = controller.esFavorito(mascota.id);
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Foto + botón favorito superpuesto
                  Stack(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: mascota.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: (mascota.fotoUrl != null && mascota.fotoUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(mascota.fotoUrl!, fit: BoxFit.cover),
                              )
                            : Icon(mascota.icon, size: 80, color: mascota.color),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => controller.toggleFavorito(mascota.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
                            ),
                            child: Icon(
                              esFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: esFav ? const Color(0xFFE53935) : Colors.grey.shade400,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Nombre
                  Text(
                    mascota.nombre,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    '${mascota.especie} · ${mascota.raza}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Chips de info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDetailChip(mascota.edad, Icons.cake_outlined, const Color(0xFFE58D57)),
                      const SizedBox(width: 8),
                      _buildDetailChip(mascota.genero, Icons.transgender_rounded, const Color(0xFF1CB5C9)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Descripción
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      mascota.descripcion ?? 'Sin descripción disponible. ¡Anímate a conocer más sobre esta mascota!',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Botón cerrar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1CB5C9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Cerrar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mascotaController = context.watch<MascotaController>();
    final mascotasAdopcion = mascotaController.mascotasAdopcion;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Fondo gris claro de la parte inferior
      body: Stack(
        children: [
          // ── Cabecera Turquesa Curva ──
          ClipPath(
            clipper: _HeaderClipper(),
            child: Container(
              height: 380, // Altura ajustada
              width: double.infinity,
              color: const Color(0xFF1CB5C9), // Color turquesa de la imagen
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── AppBar Custom (sin botón menú) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Espacio en blanco donde estaba el menú
                      const SizedBox(width: 48),
                      // Título con logo
                      Row(
                        children: [
                          const Icon(Icons.pets, color: Colors.white, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Huellitas Cevallos',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      // Campana de notificaciones
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                            onPressed: () {},
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE58D57), // Color naranja del badge
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '1',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // ── Grid de Categorías ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategoryItem(context, Icons.pets_rounded, 'Mis\nMascotas', '/mis_mascotas'),
                      _buildCategoryItem(context, Icons.volunteer_activism_rounded, 'Adopciones', '/adopciones'),
                      _buildCategoryItem(context, Icons.medical_services_outlined, 'Servicios', '/servicios'),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // Indicadores de carrusel (dots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDot(true),
                    _buildDot(false),
                    _buildDot(false),
                  ],
                ),
                const SizedBox(height: 35),

                // ── Contenido Inferior (Scrollable) ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título Mascotas Destacadas (sin Ver All)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Mascotas Destacadas',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D2D2D),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Lista horizontal de mascotas destacadas
                        SizedBox(
                          height: 230,
                          child: mascotaController.isLoadingAdopciones
                              ? const Center(child: CircularProgressIndicator())
                              : mascotasAdopcion.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No hay mascotas destacadas por ahora.',
                                        style: GoogleFonts.poppins(color: Colors.grey.shade500),
                                      ),
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: mascotasAdopcion.length,
                                      itemBuilder: (context, index) {
                                        return _buildPetCard(context, mascotasAdopcion[index]);
                                      },
                                    ),
                        ),
                        const SizedBox(height: 20),

                        // ── Botón ¡Adopta Hoy! ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            width: double.infinity,
                            height: 65,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE58D57), // Naranja
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE58D57).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.pushNamed(context, '/adopciones'),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '¡Adopta Hoy!',
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.volunteer_activism, color: Colors.white, size: 30),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 100), // Espacio extra para el bottom nav bar flotante
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Navigation Bar Custom ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigationBar(context),
          ),

          // ── Botón Flotante Central (Añadir Mascota) ──
          Positioned(
            bottom: 25,
            left: MediaQuery.of(context).size.width / 2 - 35,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/mis_mascotas'),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF1CB5C9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF5F6FA), width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1CB5C9).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 38),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: const Color(0xFF229AA8), // Color turquesa más oscuro para el botón
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 35),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, MascotaModel mascota) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Imagen / Icono de la mascota
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: mascota.color.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: (mascota.fotoUrl != null && mascota.fotoUrl!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Image.network(mascota.fotoUrl!, fit: BoxFit.cover),
                    )
                  : Icon(mascota.icon, size: 80, color: mascota.color),
            ),
          ),
          // Info y botón
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  mascota.nombre,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D2D2D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showMascotaProfileDialog(context, mascota),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1CB5C9),
                      borderRadius: BorderRadius.circular(20),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: const Icon(Icons.home, color: Color(0xFF1CB5C9), size: 30), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.map_outlined, color: Colors.grey, size: 28),
            onPressed: () => Navigator.pushNamed(context, '/mapa_veterinarios'),
          ),
          const SizedBox(width: 50), // Espacio para el botón flotante central (+)
          IconButton(
            icon: const Icon(Icons.favorite_outline, color: Colors.grey, size: 28),
            onPressed: () => _showFavoritosDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.grey, size: 30),
            onPressed: () => Navigator.pushNamed(context, '/perfil'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────
// Custom Clipper: Para la curva del fondo turquesa
// ────────────────────────────────────────────────
class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40); // Inicia un poco más arriba

    // Crea una curva cóncava
    path.quadraticBezierTo(
      size.width / 2, size.height + 10, // Punto de control (abajo al centro)
      size.width, size.height - 40,     // Punto final (derecha)
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
