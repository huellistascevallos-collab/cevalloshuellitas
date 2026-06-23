import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../domain/controllers/auth_controller.dart';
import '../../../domain/controllers/mascota_controller.dart';
import '../../../domain/controllers/solicitud_adopcion_controller.dart';
import '../../../data/models/mascota_model.dart';

// ─── Paleta de colores Premium de la imagen ───────────────────────────────────
const _teal = Color(0xFF2FA3A3);       // Botones secundarios, "Ver Perfil" y tags
const _orange = Color(0xFFE58D57);     // Botón "¡Adoptar!", favoritos e información
const _headerBg = Color(0xFFBBE7EC);   // Fondo celeste pastel de la cabecera
const _bg = Color(0xFFF6FAFA);         // Fondo general de la app
const _dark = Color(0xFF262A2B);       // Títulos y textos principales
const _grey = Color(0xFF8A9BB0);       // Textos e íconos secundarios

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
    final uid = context.read<AuthController>().currentUser?.id;
    final esDuenio = uid != null && mascota.usuarioId == uid;
    showDialog(
      context: context,
      builder: (_) => Consumer<MascotaController>(
        builder: (ctx, controller, _) {
          final esFav = controller.esFavorito(mascota.id);
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 6)
                              ],
                            ),
                            child: Icon(
                              esFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: esFav ? const Color(0xFFE53935) : Colors.grey.shade400,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    mascota.nombre,
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: _dark),
                  ),
                  Text(
                    '${mascota.especie} · ${mascota.raza}',
                    style: GoogleFonts.poppins(fontSize: 13, color: _grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildChip(mascota.edad, Icons.cake_outlined, _orange),
                      const SizedBox(width: 8),
                      _buildChip(mascota.genero, Icons.transgender_rounded, _teal),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _teal.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      mascota.descripcion ?? 'Sin descripción disponible.',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _teal),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Cerrar',
                            style: GoogleFonts.poppins(color: _teal, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: esDuenio
                            ? OutlinedButton(
                                onPressed: null,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: _teal.withValues(alpha: 0.4)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  '🏠 Tu mascota',
                                  style: GoogleFonts.poppins(color: _teal, fontWeight: FontWeight.w600),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showAdoptarDialog(context, mascota);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _orange,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  '¡Adoptar!',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                                ),
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
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Cabecera celeste con curva convexa ──
          SliverToBoxAdapter(
            child: ClipPath(
              clipper: _HeaderWaveClipper(),
              child: Container(
                height: 180,
                color: _headerBg,
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            Text(
                              'Adopciones',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _dark,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.list_alt_rounded, color: _dark, size: 24),
                              tooltip: 'Mis solicitudes',
                              onPressed: () => Navigator.pushNamed(
                                  context, '/solicitudes_adopcion'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Encuentra a tu compañero ideal',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _dark.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Filtros horizontales ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filtros.length,
                  itemBuilder: (context, i) {
                    final activo = _filtroEspecie == _filtros[i];
                    return GestureDetector(
                      onTap: () => setState(() => _filtroEspecie = _filtros[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: activo ? _teal : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _teal.withValues(alpha: activo ? 0.2 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _filtros[i],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: activo ? Colors.white : _dark,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Lista de adopciones (Feed Profesional) ──
          isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: _teal)),
                )
              : mascotasFiltradas.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pets_outlined, size: 60, color: _grey.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text(
                              'Sin mascotas en esta categoría',
                              style: GoogleFonts.poppins(color: _grey, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildAdopcionCard(mascotasFiltradas[index]);
                        },
                        childCount: mascotasFiltradas.length,
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildAdopcionCard(MascotaModel mascota) {
    // El estado 'para adoptar' es el único que llega aquí (filtra el servicio)
    final color = mascota.color;
    final descripcion = (mascota.descripcion != null && mascota.descripcion!.isNotEmpty)
        ? mascota.descripcion!
        : 'Mascota lista para encontrar un nuevo hogar lleno de amor. ¡Ven a conocerla!';

    return Consumer<MascotaController>(
      builder: (context, controller, _) {
        final esFav = controller.esFavorito(mascota.id);
        final uid = context.read<AuthController>().currentUser?.id;
        final esDuenio = uid != null && mascota.usuarioId == uid;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de la Tarjeta
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Icon(mascota.icon, size: 22, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                mascota.nombre,
                                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _dark),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                  mascota.especie,
                                  style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                                ),
                              ),
                              if (esDuenio) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: _teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Text(
                                    '🏠 Tuya',
                                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: _teal),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 12, color: _grey),
                              const SizedBox(width: 2),
                              Text('Ecuador',
                                  style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Área de Foto con Overlay de información estilizado
              Container(
                width: double.infinity,
                height: 280,
                color: color.withValues(alpha: 0.05),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (mascota.fotoUrl != null && mascota.fotoUrl!.isNotEmpty)
                      Positioned.fill(
                        child: ClipRect(
                          child: Image.network(
                            mascota.fotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(color, mascota.icon),
                          ),
                        ),
                      )
                    else
                      _buildPlaceholder(color, mascota.icon),
                    // Badges de información flotantes en la foto (Glassmorphism style)
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
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
              // Fila de Acciones
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
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
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _dark),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showPerfilDialog(context, mascota),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: _teal),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Ver perfil',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _teal),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (esDuenio)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '🏠 Tu mascota',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _teal),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => _showAdoptarDialog(context, mascota),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _orange,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _orange.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            '¡Adoptar!',
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Descripción del animal
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
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
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(12)),
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
          child: CustomPaint(painter: _PawPatternPainter(color: color.withValues(alpha: 0.05))),
        ),
        Icon(icon, size: 100, color: color.withValues(alpha: 0.4)),
      ],
    );
  }

  void _showAdoptarDialog(BuildContext context, MascotaModel mascota) {
    final uid = context.read<AuthController>().currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debes iniciar sesión para enviar una solicitud'),
      ));
      return;
    }

    // Bloquear al dueño de adoptar su propia mascota
    if (mascota.usuarioId == uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Esta mascota te pertenece, no puedes adoptarla.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
          ]),
          backgroundColor: _teal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.volunteer_activism_rounded,
                color: _orange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Adoptar a ${mascota.nombre}',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Al confirmar, se enviará una solicitud al dueño de la mascota.',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _orange.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: _orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El dueño revisará tu solicitud y te notificará su decisión.',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: _orange, height: 1.4),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(
                    color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          Consumer<SolicitudAdopcionController>(
            builder: (ctx, ctrl, _) => ElevatedButton(
              onPressed: ctrl.isLoading
                  ? null
                  : () async {
                      final ok = await ctrl.enviarSolicitud(
                        usuaId: uid,
                        mascId: mascota.id,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Row(children: [
                          Icon(
                            ok
                                ? Icons.check_circle_outline_rounded
                                : Icons.error_outline_rounded,
                            color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ok
                                  ? '¡Solicitud enviada! El dueño te contactará pronto.'
                                  : (ctrl.errorMessage ?? 'Error al enviar'),
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                        ]),
                        backgroundColor:
                            ok ? const Color(0xFF43B89C) : const Color(0xFFE53935),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ));
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: ctrl.isLoading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Enviar Solicitud',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
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

// ── Cortador de cabecera en onda convexa ──
class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
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
