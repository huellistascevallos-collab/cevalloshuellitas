import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ControlSanitarioScreen extends StatefulWidget {
  const ControlSanitarioScreen({super.key});

  @override
  State<ControlSanitarioScreen> createState() =>
      _ControlSanitarioScreenState();
}

class _ControlSanitarioScreenState extends State<ControlSanitarioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _mascotaSeleccionada = 'Luna';

  final List<String> _mascotas = ['Luna', 'Michi', 'Rocky'];

  // Vacunas de ejemplo
  final List<Map<String, dynamic>> _vacunas = [
    {
      'nombre': 'Rabia',
      'fecha': '10/01/2025',
      'proxima': '10/01/2026',
      'vencida': false,
      'icono': Icons.vaccines_outlined,
    },
    {
      'nombre': 'Parvovirus',
      'fecha': '15/03/2025',
      'proxima': '15/03/2026',
      'vencida': false,
      'icono': Icons.vaccines_outlined,
    },
    {
      'nombre': 'Moquillo',
      'fecha': '20/06/2024',
      'proxima': '20/06/2025',
      'vencida': true,
      'icono': Icons.vaccines_outlined,
    },
    {
      'nombre': 'Leptospirosis',
      'fecha': '05/09/2024',
      'proxima': '05/09/2025',
      'vencida': true,
      'icono': Icons.vaccines_outlined,
    },
  ];

  // Desparasitaciones de ejemplo
  final List<Map<String, dynamic>> _desparasitaciones = [
    {
      'tipo': 'Interna',
      'producto': 'Milbemax',
      'fecha': '01/04/2025',
      'proxima': '01/07/2025',
      'vencida': false,
    },
    {
      'tipo': 'Externa',
      'producto': 'Frontline',
      'fecha': '01/03/2025',
      'proxima': '01/04/2025',
      'vencida': true,
    },
  ];

  // Consultas pasadas
  final List<Map<String, dynamic>> _consultas = [
    {
      'motivo': 'Revisión general',
      'fecha': '12/05/2025',
      'veterinario': 'Dr. Cevallos',
      'notas': 'Mascota en excelente estado. Peso: 12 kg.',
      'icon': Icons.medical_services_outlined,
    },
    {
      'motivo': 'Problema digestivo',
      'fecha': '28/03/2025',
      'veterinario': 'Dra. Morales',
      'notas': 'Gastroenteritis leve. Dieta blanda 3 días.',
      'icon': Icons.sick_outlined,
    },
    {
      'motivo': 'Control de vacunas',
      'fecha': '15/01/2025',
      'veterinario': 'Dr. Cevallos',
      'notas': 'Vacunas al día. Desparasitación aplicada.',
      'icon': Icons.fact_check_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          // Cabecera
          ClipPath(
            clipper: _HeaderClipper(),
            child: Container(
              height: 260,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          const Icon(Icons.assignment_rounded,
                              color: Colors.white, size: 28),
                          Text(
                            'Control Sanitario',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Selector de mascota
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _mascotas.length,
                    itemBuilder: (context, i) {
                      final activo = _mascotaSeleccionada == _mascotas[i];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _mascotaSeleccionada = _mascotas[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: activo
                                ? Colors.white
                                : Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _mascotas[i],
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: activo
                                  ? const Color(0xFF126E82)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: const Color(0xFF126E82),
                    unselectedLabelColor: Colors.white,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: [
                      Tab(
                        child: Text('Vacunas',
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      Tab(
                        child: Text('Desparas.',
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      Tab(
                        child: Text('Consultas',
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Contenido de tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab Vacunas
                      _buildVacunasTab(),
                      // Tab Desparasitaciones
                      _buildDesparasitacionesTab(),
                      // Tab Consultas
                      _buildConsultasTab(),
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

  Widget _buildVacunasTab() {
    final pendientes = _vacunas.where((v) => v['vencida'] == true).length;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (pendientes > 0) _buildAlertaBanner('$pendientes vacuna(s) vencidas o por vencer', const Color(0xFFE53935)),
        const SizedBox(height: 12),
        ..._vacunas.map((v) => _buildVacunaCard(v)),
      ],
    );
  }

  Widget _buildVacunaCard(Map<String, dynamic> vacuna) {
    final vencida = vacuna['vencida'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: vencida ? const Color(0xFFFFCDD2) : const Color(0xFFBBEBF0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: vencida
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFE8F6F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                vacuna['icono'] as IconData,
                color: vencida
                    ? const Color(0xFFE53935)
                    : const Color(0xFF1CB5C9),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vacuna['nombre'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    'Aplicada: ${vacuna['fecha']}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: vencida
                        ? const Color(0xFFFFEBEE)
                        : const Color(0xFFE8F6F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vencida ? '¡VENCIDA!' : 'Al día ✓',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: vencida
                          ? const Color(0xFFE53935)
                          : const Color(0xFF1CB5C9),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Próx: ${vacuna['proxima']}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesparasitacionesTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        ..._desparasitaciones.map((d) {
          final vencida = d['vencida'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: vencida
                    ? const Color(0xFFFFCDD2)
                    : const Color(0xFFBBEBF0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: vencida
                              ? const Color(0xFFFFEBEE)
                              : const Color(0xFFE8F6F8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          d['tipo'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: vencida
                                ? const Color(0xFFE53935)
                                : const Color(0xFF1CB5C9),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        vencida ? '⚠️ Vencida' : '✅ Vigente',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: vencida ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    d['producto'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Aplicado: ${d['fecha']}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.update_rounded,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Próximo: ${d['proxima']}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildConsultasTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        ..._consultas.map((c) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F6F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(c['icon'] as IconData,
                        color: const Color(0xFF1CB5C9), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['motivo'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          c['veterinario'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF1CB5C9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c['notas'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    c['fecha'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAlertaBanner(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
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
