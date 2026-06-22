import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/servicio_model.dart';
import '../../../data/models/veterinario_model.dart';
import '../../../domain/controllers/servicio_controller.dart';
import '../../../domain/controllers/veterinario_controller.dart';
import 'agendar_cita_screen.dart';

class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({super.key});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicioController>().cargarServicios();
      context.read<VeterinarioController>().cargarTodosLosVeterinarios();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          ClipPath(
            clipper: _HeaderClipper(),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF126E82), Color(0xFF1CB5C9)],
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
                  child: Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Column(children: [
                      const Icon(Icons.medical_services_outlined,
                          color: Colors.white, size: 28),
                      Text('Servicios',
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ]),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ]),
                ),
                // Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    labelColor: const Color(0xFF126E82),
                    unselectedLabelColor: Colors.white,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: [
                      Tab(
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.medical_services_outlined, size: 16),
                              const SizedBox(width: 6),
                              Text('Servicios',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, fontWeight: FontWeight.w600)),
                            ]),
                      ),
                      Tab(
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_outline, size: 16),
                              const SizedBox(width: 6),
                              Text('Veterinarios',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, fontWeight: FontWeight.w600)),
                            ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
          ),
        ],
      ),
    );
  }

  // ── Tab Servicios (desde Supabase) ────────────
  Widget _buildServiciosTab() {
    return Consumer<ServicioController>(
      builder: (context, ctrl, _) {
        if (ctrl.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1CB5C9)));
        }
        if (ctrl.servicios.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.medical_services_outlined,
                  size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('Sin servicios registrados',
                  style: GoogleFonts.poppins(
                      fontSize: 15, color: Colors.grey.shade500)),
            ]),
          );
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: ctrl.servicios.length,
          itemBuilder: (context, i) =>
              _buildServicioCard(ctrl.servicios[i]),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 58, height: 58,
              decoration: BoxDecoration(
                color: s.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(s.iconData, size: 30, color: s.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(s.nombre,
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E))),
                if (s.descripcion != null && s.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(s.descripcion!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.person_outline_rounded,
                          size: 13, color: s.color),
                      const SizedBox(width: 4),
                      Text('Ver veterinarios',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: s.color)),
                    ]),
                  ),
                ]),
              ]),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 22),
          ]),
        ),
      ),
    );
  }

  // ── Tab Veterinarios (desde Supabase) ─────────
  Widget _buildVeterinariosTab() {
    return Consumer<VeterinarioController>(
      builder: (context, ctrl, _) {
        if (ctrl.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1CB5C9)));
        }
        if (ctrl.todos.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.person_off_outlined,
                  size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('Sin veterinarios registrados',
                  style: GoogleFonts.poppins(
                      fontSize: 15, color: Colors.grey.shade500)),
            ]),
          );
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: ctrl.todos.length,
          itemBuilder: (context, i) =>
              _buildVeterinarioCard(ctrl.todos[i]),
        );
      },
    );
  }

  Widget _buildVeterinarioCard(VeterinarioModel v) {
    final colors = [
      const Color(0xFF1CB5C9),
      const Color(0xFF7C6FCD),
      const Color(0xFF43B89C),
      const Color(0xFFE58D57),
    ];
    final color = colors[v.id.hashCode.abs() % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 62, height: 62,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(Icons.person_outline_rounded, size: 30, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Expanded(
                  child: Text('Dr/a. Veterinario',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: v.disponible
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                            color: v.disponible
                                ? Colors.green.shade400
                                : Colors.grey.shade400,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(v.disponible ? 'Disponible' : 'Ocupado',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: v.disponible
                                ? Colors.green.shade600
                                : Colors.grey.shade500)),
                  ]),
                ),
              ]),
              if (v.especialidad != null && v.especialidad!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(v.especialidad!,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500)),
              ],
              const SizedBox(height: 4),
              Row(children: [
                if (v.experiencia != null) ...[
                  Icon(Icons.work_outline_rounded,
                      size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text('${v.experiencia} años',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey.shade500)),
                  const SizedBox(width: 12),
                ],
                if (v.tarifa != null) ...[
                  Icon(Icons.attach_money_rounded,
                      size: 13, color: Colors.grey.shade400),
                  Text('\$${v.tarifa!.toStringAsFixed(0)}/consulta',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Modal: Veterinarios del servicio ──────────
  void _showVeterinariosDelServicio(
      BuildContext context, ServicioModel servicio) {
    // Cargar veterinarios de ese servicio
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

// ── Sheet: Veterinarios que atienden el servicio ──
class _VeterinariosServicioSheet extends StatelessWidget {
  final ServicioModel servicio;
  const _VeterinariosServicioSheet({required this.servicio});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, scrollController) => Container(
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
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            // Encabezado del servicio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: servicio.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(servicio.iconData,
                      color: servicio.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(servicio.nombre,
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E))),
                    Text('Veterinarios disponibles',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            const Divider(),
            // Lista de veterinarios
            Expanded(
              child: Consumer<ServicioController>(
                builder: (context, ctrl, _) {
                  if (ctrl.isLoadingVets) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF1CB5C9)));
                  }
                  final lista = ctrl.veterinariosPorServicio(servicio.id);
                  if (lista.isEmpty) {
                    return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Icon(Icons.person_off_outlined,
                            size: 52, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Ningún veterinario asignado aún',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade500)),
                        const SizedBox(height: 6),
                        Text('Pronto habrá profesionales disponibles.',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade400)),
                      ]),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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

  Widget _buildVetItem(
      BuildContext context, VeterinarioServicioModel vsm) {
    final colors = [
      const Color(0xFF1CB5C9),
      const Color(0xFF7C6FCD),
      const Color(0xFF43B89C),
      const Color(0xFFE58D57),
    ];
    final color = colors[vsm.veteId.hashCode.abs() % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: servicio.color.withValues(alpha: 0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: color.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(Icons.person_outline_rounded, size: 26, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Expanded(
                  child: Text('Dr/a. Veterinario',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E))),
                ),
                // Disponible
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: vsm.disponible
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                            color: vsm.disponible
                                ? Colors.green.shade400
                                : Colors.grey.shade400,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(vsm.disponible ? 'Disponible' : 'Ocupado',
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: vsm.disponible
                                ? Colors.green.shade600
                                : Colors.grey.shade500)),
                  ]),
                ),
              ]),
              if (vsm.especialidad != null &&
                  vsm.especialidad!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(vsm.especialidad!,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500)),
              ],
              const SizedBox(height: 6),
              Row(children: [
                if (vsm.precio != null) ...[
                  Icon(Icons.attach_money_rounded,
                      size: 14, color: servicio.color),
                  Text('\$${vsm.precio!.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: servicio.color)),
                  const SizedBox(width: 12),
                ],
                if (vsm.duracion != null && vsm.duracion!.isNotEmpty) ...[
                  Icon(Icons.access_time_rounded,
                      size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Text(vsm.duracion!,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ]),
              if (vsm.disponible) ...[
                const SizedBox(height: 10),
                Row(children: [
                  // Ver perfil
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
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Agendar
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAgendarSheet(context, vsm);
                      },
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: Text('Agendar',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: servicio.color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  void _showAgendarSheet(
      BuildContext context, VeterinarioServicioModel vsm) {
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
}

// ── Página: Perfil del veterinario ───────────────
class _PerfilVeterinarioPage extends StatelessWidget {
  final VeterinarioServicioModel vsm;
  final ServicioModel servicio;

  const _PerfilVeterinarioPage({
    required this.vsm,
    required this.servicio,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF1CB5C9),
      const Color(0xFF7C6FCD),
      const Color(0xFF43B89C),
      const Color(0xFFE58D57),
    ];
    final avatarColor = colors[vsm.veteId.hashCode.abs() % colors.length];
    final nombreMostrar = (vsm.nombre != null && vsm.nombre!.isNotEmpty)
        ? vsm.nombre!
        : 'Veterinario';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // Cabecera degradada
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0D5C70),
                  avatarColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text('Perfil del Veterinario',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ]),
                ),

                // Avatar y nombre
                const SizedBox(height: 12),
                Center(
                  child: Column(children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: avatarColor.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: (vsm.fotoUrl != null && vsm.fotoUrl!.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(vsm.fotoUrl!,
                                  fit: BoxFit.cover))
                          : Icon(Icons.person_rounded,
                              size: 52, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text('Dr/a. $nombreMostrar',
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    if (vsm.especialidad != null &&
                        vsm.especialidad!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(vsm.especialidad!,
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ],
                  ]),
                ),

                const SizedBox(height: 20),

                // Tarjeta de presentación
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      children: [
                        // Stats rápidos
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: [
                              _statItem(
                                icon: Icons.workspace_premium_rounded,
                                color: const Color(0xFF7C6FCD),
                                value: vsm.experiencia != null
                                    ? '${vsm.experiencia} años'
                                    : 'N/D',
                                label: 'Experiencia',
                              ),
                              _divider(),
                              _statItem(
                                icon: Icons.attach_money_rounded,
                                color: servicio.color,
                                value: vsm.precio != null
                                    ? '\$${vsm.precio!.toStringAsFixed(0)}'
                                    : (vsm.tarifa != null
                                        ? '\$${vsm.tarifa!.toStringAsFixed(0)}'
                                        : 'N/D'),
                                label: 'Tarifa',
                              ),
                              _divider(),
                              _statItem(
                                icon: Icons.access_time_rounded,
                                color: const Color(0xFF43B89C),
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

                        // Servicio que atiende
                        _infoCard(
                          title: 'Servicio',
                          icon: Icons.medical_services_outlined,
                          color: servicio.color,
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    servicio.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(servicio.iconData,
                                  color: servicio.color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(servicio.nombre,
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A1A2E))),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 16),

                        // Disponibilidad
                        _infoCard(
                          title: 'Estado',
                          icon: Icons.circle,
                          color: vsm.disponible
                              ? Colors.green
                              : Colors.grey,
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
                                      : Colors.grey.shade600),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 16),

                        // Acerca del profesional
                        _infoCard(
                          title: 'Acerca del profesional',
                          icon: Icons.info_outline_rounded,
                          color: avatarColor,
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
                                avatarColor,
                              ),
                              if (vsm.experiencia != null) ...[
                                const SizedBox(height: 10),
                                _profileRow(
                                  Icons.workspace_premium_rounded,
                                  'Experiencia',
                                  '${vsm.experiencia} años de práctica clínica',
                                  avatarColor,
                                ),
                              ],
                              const SizedBox(height: 10),
                              _profileRow(
                                Icons.verified_outlined,
                                'Registro',
                                'Veterinario certificado y habilitado',
                                avatarColor,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botón Agendar fijo en la parte inferior
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
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4)),
                ],
              ),
              child: SizedBox(
                height: 54,
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
                  label: Text('Agendar Cita',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: servicio.color,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        servicio.color.withValues(alpha: 0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E))),
      Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10, color: Colors.grey.shade500)),
    ]);
  }

  Widget _divider() {
    return Container(
        width: 1, height: 50, color: Colors.grey.shade200);
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5)),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E))),
        ]),
      ),
    ]);
  }
}

// ── Sheet: Agendar cita ── (reemplazado por AgendarCitaScreen)

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
