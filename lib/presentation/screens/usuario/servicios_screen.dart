import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart';
import '../../../data/models/servicio_model.dart';
import '../../../data/models/veterinario_model.dart';
import '../../../domain/controllers/servicio_controller.dart';
import '../../../domain/controllers/veterinario_controller.dart';
import 'agendar_cita_screen.dart';

// ─── Paleta exacta de la imagen de referencia ─────────────────────────────────
const _teal      = Color(0xFF3BBFBF);   // Teal principal (cabecera, botones, íconos)
const _tealDark  = Color(0xFF2A9D9D);   // Teal oscuro (sombras y activos)
const _orange    = Color(0xFFE58D57);   // Naranja (acento y CTA)
const _headerBg  = Color(0xFFBBE7EC);   // Celeste pastel de la cabecera
const _bg        = Color(0xFFF4F9FA);   // Fondo general
const _cardBg    = Colors.white;
const _dark      = Color(0xFF1E2A2A);   // Textos principales
const _grey      = Color(0xFF8A9BB0);   // Textos secundarios

class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({super.key});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicioController>().cargarServicios();
      context.read<VeterinarioController>().cargarTodosLosVeterinarios();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Cabecera estilo imagen ───────────────────────────────────────
          _buildHeader(context),

          // ── Tabs selector estilo imagen ──────────────────────────────────
          _buildTabSelector(),

          // ── Contenido ────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildServiciosTab(),
                _buildVeterinariosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cabecera con la curva y el estilo de la imagen ──────────────────────────
  Widget _buildHeader(BuildContext context) {
    return ClipPath(
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
                      'Servicios',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Equilibrar el botón de retroceso
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Explora nuestros servicios y veterinarios disponibles',
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
    );
  }

  // ── Selector de tabs estilo pills de la imagen ──────────────────────────────
  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (ctx, child) => Row(
          children: [
            _tabPill(
              index: 0,
              icon: Icons.medical_services_outlined,
              label: 'Servicios',
            ),
            const SizedBox(width: 12),
            _tabPill(
              index: 1,
              icon: Icons.person_outline_rounded,
              label: 'Veterinarios',
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabPill({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isActive = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? _teal : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? _teal.withValues(alpha: 0.30)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: isActive ? Colors.white : _grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : _grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab Servicios ───────────────────────────────────────────────────────────
  Widget _buildServiciosTab() {
    return Consumer<ServicioController>(
      builder: (context, ctrl, _) {
        if (ctrl.isLoading) {
          return const Center(child: CircularProgressIndicator(color: _teal));
        }
        if (ctrl.servicios.isEmpty) {
          return _emptyState(
            icon: Icons.medical_services_outlined,
            message: 'Sin servicios disponibles',
          );
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          itemCount: ctrl.servicios.length,
          itemBuilder: (context, i) => _buildServicioCard(ctrl.servicios[i]),
        );
      },
    );
  }

  Widget _buildServicioCard(ServicioModel s) {
    return GestureDetector(
      onTap: () => _showVeterinariosDelServicio(context, s),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Ícono cuadrado resaltado con color y sombra
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: s.color,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: s.color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(s.iconData, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.nombre,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _dark,
                      ),
                    ),
                    if (s.descripcion != null && s.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        s.descripcion!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _grey,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Botón estilo "Ver Perfil" de la imagen
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _teal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Ver veterinarios',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: _grey, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab Veterinarios ────────────────────────────────────────────────────────
  Widget _buildVeterinariosTab() {
    return Consumer<VeterinarioController>(
      builder: (context, ctrl, _) {
        if (ctrl.isLoading) {
          return const Center(child: CircularProgressIndicator(color: _teal));
        }
        if (ctrl.todos.isEmpty) {
          return _emptyState(
            icon: Icons.person_off_outlined,
            message: 'Sin veterinarios registrados',
          );
        }

        final filtrados = _searchQuery.isEmpty
            ? ctrl.todos
            : ctrl.todos.where((v) =>
                (v.nombre ?? '').toLowerCase().contains(_searchQuery) ||
                (v.especialidad ?? '').toLowerCase().contains(_searchQuery))
                .toList();

        return Column(children: [
          // ── Barra de búsqueda ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12, offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(fontSize: 13, color: _dark),
                decoration: InputDecoration(
                  hintText: 'Buscar veterinario por nombre...',
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: _grey),
                  prefixIcon: const Icon(Icons.search_rounded, color: _teal, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: _grey, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          // Contador de resultados
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filtrados.length} resultado${filtrados.length != 1 ? "s" : ""} para "$_searchQuery"',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: _grey, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          Expanded(
            child: filtrados.isEmpty
                ? _emptyState(
                    icon: Icons.search_off_rounded,
                    message: 'Sin resultados para "$_searchQuery"',
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    itemCount: filtrados.length,
                    itemBuilder: (context, i) => _buildVeterinarioCard(filtrados[i]),
                  ),
          ),
        ]);
      },
    );
  }

  Widget _buildVeterinarioCard(VeterinarioModel v) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _PerfilVeterinarioDirectoPage(vet: v)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: _teal.withValues(alpha: 0.35), width: 2),
                ),
                child: ClipOval(
                  child: (v.fotoUrl != null && v.fotoUrl!.isNotEmpty)
                      ? Image.network(v.fotoUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_outline_rounded, size: 30, color: _teal))
                      : const Icon(Icons.person_outline_rounded, size: 30, color: _teal),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          v.nombre != null && v.nombre!.isNotEmpty
                              ? 'Dr/a. ${v.nombre}'
                              : 'Dr/a. Veterinario',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w700, color: _dark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _disponibilidadBadge(v.disponible),
                    ]),
                    if (v.especialidad != null && v.especialidad!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(v.especialidad!,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: _teal, fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 6),
                    Row(children: [
                      if (v.experiencia != null) ...[
                        const Icon(Icons.workspace_premium_rounded, size: 13, color: _grey),
                        const SizedBox(width: 4),
                        Text('${v.experiencia} años',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: _grey, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 12),
                      ],
                      if (v.tarifa != null) ...[
                        const Icon(Icons.attach_money_rounded, size: 13, color: _orange),
                        Text('\$${v.tarifa!.toStringAsFixed(0)}/consulta',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: _orange, fontWeight: FontWeight.w600)),
                      ],
                    ]),
                    if (v.direccion != null && v.direccion!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: _grey),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(v.direccion!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: _grey, fontWeight: FontWeight.w400)),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _grey, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _disponibilidadBadge(bool disponible) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: disponible
            ? Colors.green.shade50
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: disponible
                ? Colors.green.shade400
                : Colors.grey.shade400,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          disponible ? 'Disponible' : 'Ocupado',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: disponible
                ? Colors.green.shade700
                : Colors.grey.shade500,
          ),
        ),
      ]),
    );
  }

  // ── Estado vacío ────────────────────────────────────────────────────────────
  Widget _emptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: _teal.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: _grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom sheet: Veterinarios del servicio ─────────────────────────────────
  void _showVeterinariosDelServicio(
      BuildContext context, ServicioModel servicio) {
    context
        .read<ServicioController>()
        .cargarVeterinariosPorServicio(servicio.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ServicioController>(),
        child: _VeterinariosServicioSheet(servicio: servicio),
      ),
    );
  }
}

// ─── Sheet: Veterinarios del servicio ─────────────────────────────────────────
class _VeterinariosServicioSheet extends StatelessWidget {
  final ServicioModel servicio;
  const _VeterinariosServicioSheet({required this.servicio});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Handle
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
            const SizedBox(height: 18),
            // Cabecera del sheet estilo imagen
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: servicio.color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: servicio.color.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(servicio.iconData, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        servicio.nombre,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _dark,
                        ),
                      ),
                      Text(
                        'Veterinarios disponibles',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade100, height: 1),
            Expanded(
              child: Consumer<ServicioController>(
                builder: (context, ctrl, _) {
                  if (ctrl.isLoadingVets) {
                    return const Center(
                        child: CircularProgressIndicator(color: _teal));
                  }
                  final lista = ctrl.veterinariosPorServicio(servicio.id);
                  if (lista.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _teal.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_off_outlined,
                                size: 38,
                                color: _teal.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Ningún veterinario asignado',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pronto habrá profesionales disponibles.',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: _grey),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    itemCount: lista.length,
                    itemBuilder: (context, i) =>
                        _buildVetItem(context, lista[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVetItem(BuildContext context, VeterinarioServicioModel vsm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _teal.withValues(alpha: 0.12), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              // Avatar circular
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _teal.withValues(alpha: 0.3), width: 2),
                ),
                child: ClipOval(
                  child: (vsm.fotoUrl != null && vsm.fotoUrl!.isNotEmpty)
                      ? Image.network(vsm.fotoUrl!, fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(
                                Icons.person_outline_rounded,
                                size: 26,
                                color: _teal,
                              ))
                      : const Icon(Icons.person_outline_rounded,
                          size: 26, color: _teal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          (vsm.nombre != null && vsm.nombre!.isNotEmpty)
                              ? 'Dr/a. ${vsm.nombre}'
                              : 'Dr/a. Veterinario',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _dark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _badgeDisponible(vsm.disponible),
                    ]),
                    if (vsm.especialidad != null &&
                        vsm.especialidad!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        vsm.especialidad!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _teal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(children: [
                      if (vsm.precio != null) ...[
                        const Icon(Icons.attach_money_rounded,
                            size: 14, color: _orange),
                        Text(
                          '\$${vsm.precio!.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _orange,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (vsm.duracion != null &&
                          vsm.duracion!.isNotEmpty) ...[
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: _grey),
                        const SizedBox(width: 3),
                        Text(
                          vsm.duracion!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ]),
                  ],
                ),
              ),
            ]),

            // Botones de acción
            if (vsm.disponible) ...[
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _PerfilVeterinarioPage(
                            vsm: vsm,
                            servicio: servicio,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_outlined, size: 16),
                    label: Text('Ver perfil',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _teal,
                      side: const BorderSide(color: _teal, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AgendarCitaScreen(
                            vsm: vsm,
                            servicio: servicio,
                            vetNombre: vsm.nombre ?? 'Veterinario',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text('Agendar',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badgeDisponible(bool disponible) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: disponible ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: disponible ? Colors.green.shade400 : Colors.grey.shade400,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          disponible ? 'Disponible' : 'Ocupado',
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: disponible ? Colors.green.shade700 : Colors.grey.shade500,
          ),
        ),
      ]),
    );
  }

}


// ─── Página: Perfil del veterinario ───────────────────────────────────────────
class _PerfilVeterinarioPage extends StatelessWidget {
  final VeterinarioServicioModel vsm;
  final ServicioModel servicio;

  const _PerfilVeterinarioPage({
    required this.vsm,
    required this.servicio,
  });

  @override
  Widget build(BuildContext context) {
    final nombreMostrar = (vsm.nombre != null && vsm.nombre!.isNotEmpty)
        ? vsm.nombre!
        : 'Veterinario';

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Cabecera celeste con curva igual que la imagen ────────────
          Column(
            children: [
              ClipPath(
                clipper: _HeaderWaveClipper(),
                child: Container(
                  width: double.infinity,
                  color: _headerBg,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 52),
                      child: Column(
                      children: [
                        // Barra superior
                        Row(children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: _dark, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          Text(
                            'Perfil del Veterinario',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _dark,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ]),
                        const SizedBox(height: 16),
                        // Avatar
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _teal.withValues(alpha: 0.15),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: _teal.withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: (vsm.fotoUrl != null &&
                                  vsm.fotoUrl!.isNotEmpty)
                              ? ClipOval(
                                  child: Image.network(vsm.fotoUrl!,
                                      fit: BoxFit.cover))
                              : const Icon(Icons.person_rounded,
                                  size: 52, color: _teal),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Dr/a. $nombreMostrar',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _dark,
                          ),
                        ),
                        if (vsm.especialidad != null &&
                            vsm.especialidad!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: _teal,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              vsm.especialidad!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ],
          ),

          // ── Contenido scrollable ──────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Espacio para la cabecera (aprox)
                const SizedBox(height: 265),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    child: Column(
                      children: [
                        // Stats card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statItem(
                                icon: Icons.workspace_premium_rounded,
                                color: _teal,
                                value: vsm.experiencia != null
                                    ? '${vsm.experiencia} años'
                                    : 'N/D',
                                label: 'Experiencia',
                              ),
                              Container(
                                  width: 1,
                                  height: 50,
                                  color: Colors.grey.shade100),
                              _statItem(
                                icon: Icons.attach_money_rounded,
                                color: _orange,
                                value: vsm.precio != null
                                    ? '\$${vsm.precio!.toStringAsFixed(0)}'
                                    : (vsm.tarifa != null
                                        ? '\$${vsm.tarifa!.toStringAsFixed(0)}'
                                        : 'N/D'),
                                label: 'Tarifa',
                              ),
                              Container(
                                  width: 1,
                                  height: 50,
                                  color: Colors.grey.shade100),
                              _statItem(
                                icon: Icons.access_time_rounded,
                                color: _tealDark,
                                value: (vsm.duracion != null &&
                                        vsm.duracion!.isNotEmpty)
                                    ? vsm.duracion!
                                    : 'N/D',
                                label: 'Duración',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Card servicio
                        _infoCard(
                          title: 'Servicio',
                          icon: Icons.medical_services_outlined,
                          color: _teal,
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: servicio.color,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: servicio.color.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(servicio.iconData,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                servicio.nombre,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _dark,
                                ),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 14),

                        // Card estado
                        _infoCard(
                          title: 'Estado',
                          icon: Icons.circle,
                          color: vsm.disponible ? Colors.green : _grey,
                          child: Row(children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: vsm.disponible
                                    ? Colors.green.shade400
                                    : Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              vsm.disponible
                                  ? 'Disponible para citas'
                                  : 'No disponible en este momento',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: vsm.disponible
                                    ? Colors.green.shade700
                                    : _grey,
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 14),

                        // Card profesional
                        _infoCard(
                          title: 'Acerca del profesional',
                          icon: Icons.info_outline_rounded,
                          color: _teal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _profileRow(
                                Icons.school_outlined,
                                'Especialidad',
                                (vsm.especialidad != null &&
                                        vsm.especialidad!.isNotEmpty)
                                    ? vsm.especialidad!
                                    : 'Medicina general veterinaria',
                                _teal,
                              ),
                              if (vsm.experiencia != null) ...[
                                const SizedBox(height: 10),
                                _profileRow(
                                  Icons.workspace_premium_rounded,
                                  'Experiencia',
                                  '${vsm.experiencia} años de práctica clínica',
                                  _teal,
                                ),
                              ],
                              const SizedBox(height: 10),
                              _profileRow(
                                Icons.verified_outlined,
                                'Registro',
                                'Veterinario certificado y habilitado',
                                _teal,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Card ubicación
                        _infoCard(
                          title: 'Ubicación',
                          icon: Icons.location_on_rounded,
                          color: _orange,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (vsm.direccion != null && vsm.direccion!.isNotEmpty) ...[
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: _orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.place_rounded,
                                        color: _orange, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(vsm.direccion!,
                                        style: GoogleFonts.poppins(
                                            fontSize: 13, fontWeight: FontWeight.w600,
                                            color: _dark)),
                                  ),
                                ]),
                                const SizedBox(height: 14),
                              ],
                              if (vsm.latitud != null && vsm.longitud != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    height: 200,
                                    child: fmap.FlutterMap(
                                      options: fmap.MapOptions(
                                        initialCenter: LatLng(vsm.latitud!, vsm.longitud!),
                                        initialZoom: 15,
                                      ),
                                      children: [
                                        fmap.TileLayer(
                                          urlTemplate:
                                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        ),
                                        fmap.MarkerLayer(markers: [
                                          fmap.Marker(
                                            point: LatLng(vsm.latitud!, vsm.longitud!),
                                            width: 44, height: 44,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: _teal,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.white, width: 3),
                                                boxShadow: [BoxShadow(
                                                  color: _teal.withValues(alpha: 0.4),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                )],
                                              ),
                                              child: const Icon(
                                                  Icons.local_hospital_rounded,
                                                  color: Colors.white, size: 20),
                                            ),
                                          ),
                                        ]),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else if (vsm.direccion == null || vsm.direccion!.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Text('Ubicación no registrada',
                                        style: GoogleFonts.poppins(
                                            fontSize: 13, color: _grey)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Botón agendar flotante ───────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: vsm.disponible
                      ? () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AgendarCitaScreen(
                                vsm: vsm,
                                servicio: servicio,
                                vetNombre: vsm.nombre ?? 'Veterinario',
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.calendar_today_rounded, size: 20),
                  label: Text(
                    'Agendar Cita',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _teal.withValues(alpha: 0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(height: 6),
      Text(value,
          style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w700, color: _dark)),
      Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10, color: _grey, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _grey,
                letterSpacing: 0.8,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _profileRow(
      IconData icon, String label, String value, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: _grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _dark,
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

// ─── Página: Perfil directo del veterinario (desde tab Veterinarios) ──────────
class _PerfilVeterinarioDirectoPage extends StatelessWidget {
  final VeterinarioModel vet;
  const _PerfilVeterinarioDirectoPage({required this.vet});

  @override
  Widget build(BuildContext context) {
    final nombre = (vet.nombre != null && vet.nombre!.isNotEmpty)
        ? vet.nombre!
        : 'Veterinario';
    final tieneUbicacion = vet.latitud != null && vet.longitud != null;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Column(children: [
            ClipPath(
              clipper: _HeaderWaveClipper(),
              child: Container(
                width: double.infinity,
                color: _headerBg,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 52),
                    child: Column(children: [
                      Row(children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: _dark, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Text('Perfil Veterinario',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w700,
                                color: _dark)),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ]),
                      const SizedBox(height: 14),
                      // Avatar
                      Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _teal.withValues(alpha: 0.15),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [BoxShadow(
                            color: _teal.withValues(alpha: 0.25),
                            blurRadius: 20, offset: const Offset(0, 8),
                          )],
                        ),
                        child: (vet.fotoUrl != null && vet.fotoUrl!.isNotEmpty)
                            ? ClipOval(child: Image.network(vet.fotoUrl!, fit: BoxFit.cover))
                            : const Icon(Icons.person_rounded, size: 48, color: _teal),
                      ),
                      const SizedBox(height: 10),
                      Text('Dr/a. $nombre',
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.w800, color: _dark)),
                      if (vet.especialidad != null && vet.especialidad!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            color: _teal, borderRadius: BorderRadius.circular(20)),
                          child: Text(vet.especialidad!,
                              style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ]),
                  ),
                ),
              ),
            ),
          ]),

          // Contenido scrollable
          SafeArea(
            child: Column(children: [
              const SizedBox(height: 255),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(children: [
                    // Stats
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 18, offset: const Offset(0, 6),
                        )],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statCol(Icons.workspace_premium_rounded, _teal,
                              vet.experiencia != null ? '${vet.experiencia} años' : 'N/D',
                              'Experiencia'),
                          Container(width: 1, height: 50, color: Colors.grey.shade100),
                          _statCol(Icons.attach_money_rounded, _orange,
                              vet.tarifa != null ? '\$${vet.tarifa!.toStringAsFixed(0)}' : 'N/D',
                              'Tarifa'),
                          Container(width: 1, height: 50, color: Colors.grey.shade100),
                          _statCol(
                            vet.disponible ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            vet.disponible ? Colors.green : _grey,
                            vet.disponible ? 'Sí' : 'No',
                            'Disponible',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info profesional
                    _infoCard(
                      title: 'Acerca del profesional',
                      icon: Icons.info_outline_rounded,
                      color: _teal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _profileRow(Icons.school_outlined, 'Especialidad',
                              vet.especialidad?.isNotEmpty == true
                                  ? vet.especialidad!
                                  : 'Medicina general veterinaria',
                              _teal),
                          if (vet.experiencia != null) ...[
                            const SizedBox(height: 10),
                            _profileRow(Icons.workspace_premium_rounded, 'Experiencia',
                                '${vet.experiencia} años de práctica clínica', _teal),
                          ],
                          const SizedBox(height: 10),
                          _profileRow(Icons.verified_outlined, 'Registro',
                              'Veterinario certificado y habilitado', _teal),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ubicación
                    _infoCard(
                      title: 'Ubicación',
                      icon: Icons.location_on_rounded,
                      color: _orange,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (vet.direccion != null && vet.direccion!.isNotEmpty) ...[
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: _orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.place_rounded,
                                    color: _orange, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(vet.direccion!,
                                    style: GoogleFonts.poppins(
                                        fontSize: 13, fontWeight: FontWeight.w600,
                                        color: _dark)),
                              ),
                            ]),
                            const SizedBox(height: 14),
                          ],
                          if (tieneUbicacion) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                height: 200,
                                child: fmap.FlutterMap(
                                  options: fmap.MapOptions(
                                    initialCenter: LatLng(vet.latitud!, vet.longitud!),
                                    initialZoom: 15,
                                  ),
                                  children: [
                                    fmap.TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    ),
                                    fmap.MarkerLayer(markers: [
                                      fmap.Marker(
                                        point: LatLng(vet.latitud!, vet.longitud!),
                                        width: 44, height: 44,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _teal,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 3),
                                            boxShadow: [BoxShadow(
                                              color: _teal.withValues(alpha: 0.4),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            )],
                                          ),
                                          child: const Icon(Icons.local_hospital_rounded,
                                              color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ]),
                                  ],
                                ),
                              ),
                            ),
                          ] else if (vet.direccion == null || vet.direccion!.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Text('Ubicación no registrada',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13, color: _grey)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _statCol(IconData icon, Color color, String value, String label) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(height: 6),
      Text(value, style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w700, color: _dark)),
      Text(label, style: GoogleFonts.poppins(
          fontSize: 10, color: _grey, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _infoCard({required String title, required IconData icon,
      required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 16, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(title.toUpperCase(), style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: _grey, letterSpacing: 0.8)),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  Widget _profileRow(IconData icon, String label, String value, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(
            fontSize: 11, color: _grey, fontWeight: FontWeight.w500)),
        Text(value, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600, color: _dark)),
      ])),
    ]);
  }
}

// ── Cortador de cabecera en onda convexa ──
class _HeaderWaveClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(Size size) {
    final path = ui.Path();
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
  bool shouldReclip(covariant CustomClipper<ui.Path> oldClipper) => false;
}
