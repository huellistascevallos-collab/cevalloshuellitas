import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../domain/controllers/mascota_controller.dart';
import '../../../data/models/mascota_model.dart';

class AdopcionesScreen extends StatefulWidget {
  const AdopcionesScreen({super.key});

  @override
  State<AdopcionesScreen> createState() => _AdopcionesScreenState();
}

class _AdopcionesScreenState extends State<AdopcionesScreen> {
  String _filtroEspecie = 'Todos';
  final List<String> _filtros = ['Todos', 'Perros', 'Gatos', 'Aves', 'Conejos', 'Otros'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MascotaController>().cargarMascotasAdopcion();
    });
  }

  List<MascotaModel> _obtenerMascotasFiltradas(List<MascotaModel> todas) {
    return todas.where((m) {
      if (_filtroEspecie == 'Todos') return true;
      if (_filtroEspecie == 'Perros') return m.especie.toLowerCase().contains('perro');
      if (_filtroEspecie == 'Gatos') return m.especie.toLowerCase().contains('gato');
      if (_filtroEspecie == 'Aves') return m.especie.toLowerCase().contains('ave');
      if (_filtroEspecie == 'Conejos') return m.especie.toLowerCase().contains('conejo');
      return !m.especie.toLowerCase().contains('perro') &&
             !m.especie.toLowerCase().contains('gato') &&
             !m.especie.toLowerCase().contains('ave') &&
             !m.especie.toLowerCase().contains('conejo');
    }).toList();
  }

  void _showPerfilDialog(BuildContext context, MascotaModel mascota) {
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
                  // Foto con corazón superpuesto
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
                        top: 8, right: 8,
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
                  const SizedBox(height: 14),
                  Text(mascota.nombre,
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
                  Text('${mascota.especie} · ${mascota.raza}',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildChip(mascota.edad, Icons.cake_outlined, const Color(0xFFE58D57)),
                      const SizedBox(width: 8),
                      _buildChip(mascota.genero, Icons.transgender_rounded, const Color(0xFF1CB5C9)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      mascota.descripcion ?? 'Sin descripción disponible.',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1CB5C9)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Cerrar', style: GoogleFonts.poppins(color: const Color(0xFF1CB5C9), fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showAdoptarDialog(context, mascota);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE58D57),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('¡Adoptar!', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mascotaController = context.watch<MascotaController>();
    final isLoading = mascotaController.isLoadingAdopciones;
    final mascotasAdopcion = mascotaController.mascotasAdopcion;
    final mascotasFiltradas = _obtenerMascotasFiltradas(mascotasAdopcion);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          ClipPath(
            clipper: _HeaderClipper(),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE58D57), Color(0xFFEFAA7A)],
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
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 28),
                          Text('Adopciones',
                              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                // Filtros
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtros.length,
                    itemBuilder: (context, i) {
                      final activo = _filtroEspecie == _filtros[i];
                      return GestureDetector(
                        onTap: () => setState(() => _filtroEspecie = _filtros[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: activo ? Colors.white : Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_filtros[i],
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: activo ? const Color(0xFFE58D57) : Colors.white)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Lista
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFE58D57)))
                      : mascotasFiltradas.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.pets_outlined, size: 60, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text('Sin mascotas en esta categoría',
                                      style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 15)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                              itemCount: mascotasFiltradas.length,
                              itemBuilder: (context, index) {
                                return _buildInstagramCard(mascotasFiltradas[index]);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstagramCard(MascotaModel mascota) {
    final adoptada = mascota.estado.toLowerCase() == 'adoptado';
    final color = mascota.color;
    final descripcion = (mascota.descripcion != null && mascota.descripcion!.isNotEmpty)
        ? mascota.descripcion!
        : 'Mascota lista para encontrar un nuevo hogar lleno de amor. ¡Ven a conocerla!';

    return Consumer<MascotaController>(
      builder: (context, controller, _) {
        final esFav = controller.esFavorito(mascota.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
                      ),
                      child: Icon(mascota.icon, size: 24, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(mascota.nombre,
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                child: Text(mascota.especie,
                                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                              ),
                              if (adoptada) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                                  child: Text('✓ Adoptado',
                                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green.shade600)),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 2),
                              Text('Ecuador',
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Foto
              Container(
                width: double.infinity,
                height: 280,
                color: color.withValues(alpha: 0.08),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (mascota.fotoUrl != null && mascota.fotoUrl!.isNotEmpty)
                      Positioned.fill(
                        child: Image.network(
                          mascota.fotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(color, mascota.icon),
                        ),
                      )
                    else
                      _buildPlaceholder(color, mascota.icon),
                    // Overlay info
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            _buildInfoBadge(mascota.raza, Icons.category_outlined),
                            const SizedBox(width: 8),
                            _buildInfoBadge(mascota.edad, Icons.cake_outlined),
                            const SizedBox(width: 8),
                            _buildInfoBadge(mascota.genero, Icons.transgender_rounded),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Acciones: ❤️ favorito + botones
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    // Botón favorito funcional
                    GestureDetector(
                      onTap: () => controller.toggleFavorito(mascota.id),
                      child: Row(
                        children: [
                          Icon(
                            esFav ? Icons.favorite_rounded : Icons.favorite_outline,
                            color: const Color(0xFFE53935),
                            size: 26,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            esFav ? '1' : '0',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Botón Ver Perfil
                    GestureDetector(
                      onTap: () => _showPerfilDialog(context, mascota),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF1CB5C9)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Ver perfil',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1CB5C9))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botón Adoptar
                    if (!adoptada)
                      GestureDetector(
                        onTap: () => _showAdoptarDialog(context, mascota),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFE58D57), Color(0xFFEFAA7A)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('¡Adoptar!',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                        child: Text('Ya tiene hogar ❤️',
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade600)),
                      ),
                  ],
                ),
              ),
              // Descripción
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF2D2D2D)),
                    children: [
                      TextSpan(text: '${mascota.nombre} ', style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: descripcion),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF555555)),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF2D2D2D))),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(Color color, IconData icon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _PawPatternPainter(color: color.withValues(alpha: 0.06))),
        ),
        Icon(icon, size: 120, color: color.withValues(alpha: 0.5)),
      ],
    );
  }

  void _showAdoptarDialog(BuildContext context, MascotaModel mascota) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Adoptar a ${mascota.nombre}?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
        content: Text(
          'Mascota lista para encontrar un nuevo hogar lleno de amor.\n\nUn asesor se pondrá en contacto contigo para el proceso de adopción.',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE58D57),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirmar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _PawPatternPainter extends CustomPainter {
  final Color color;
  const _PawPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 4; j++) {
        canvas.drawCircle(
          Offset(size.width * (0.15 + i * 0.18), size.height * (0.15 + j * 0.24)),
          8, paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height + 10, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldDelegate) => false;
}
