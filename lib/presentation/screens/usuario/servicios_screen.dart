import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({super.key});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _tipoMascota = 'Casa';

  final List<Map<String, dynamic>> _servicios = [
    {
      'titulo': 'Consulta Veterinaria',
      'descripcion': 'Revisión general de salud, diagnóstico y tratamiento.',
      'precio': '\$25.00',
      'duracion': '30 min',
      'icon': Icons.medical_services_outlined,
      'color': Color(0xFF1CB5C9),
      'disponible': true,
      'tipo': ['Casa', 'Campo'],
    },
    {
      'titulo': 'Vacunación',
      'descripcion': 'Esquema completo de vacunas según especie y edad.',
      'precio': '\$15.00',
      'duracion': '15 min',
      'icon': Icons.vaccines_outlined,
      'color': Color(0xFF7C6FCD),
      'disponible': true,
      'tipo': ['Casa', 'Campo'],
    },
    {
      'titulo': 'Grooming / Baño',
      'descripcion': 'Baño, corte de uñas, limpieza de oídos y peinado.',
      'precio': '\$20.00',
      'duracion': '60 min',
      'icon': Icons.shower_outlined,
      'color': Color(0xFFE58D57),
      'disponible': true,
      'tipo': ['Casa'],
    },
    {
      'titulo': 'Desparasitación',
      'descripcion': 'Tratamiento interno y externo contra parásitos.',
      'precio': '\$12.00',
      'duracion': '20 min',
      'icon': Icons.bug_report_outlined,
      'color': Color(0xFF43B89C),
      'disponible': true,
      'tipo': ['Casa', 'Campo'],
    },
    {
      'titulo': 'Radiografía / Ecografía',
      'descripcion': 'Diagnóstico por imagen para detectar patologías internas.',
      'precio': '\$45.00',
      'duracion': '45 min',
      'icon': Icons.screenshot_monitor_outlined,
      'color': Color(0xFF1CB5C9),
      'disponible': false,
      'tipo': ['Casa'],
    },
    {
      'titulo': 'Atención Ganadera',
      'descripcion': 'Revisión y tratamiento para bovinos, porcinos y equinos.',
      'precio': 'Desde \$60.00',
      'duracion': 'Variable',
      'icon': Icons.agriculture,
      'color': Color(0xFF43B89C),
      'disponible': true,
      'tipo': ['Campo'],
    },
    {
      'titulo': 'Cirugía',
      'descripcion': 'Procedimientos quirúrgicos con anestesia y seguimiento.',
      'precio': 'Desde \$80.00',
      'duracion': 'Variable',
      'icon': Icons.content_cut_rounded,
      'color': Color(0xFFE53935),
      'disponible': true,
      'tipo': ['Casa', 'Campo'],
    },
    {
      'titulo': 'Consulta Virtual',
      'descripcion': 'Atención online desde casa, sin desplazamientos.',
      'precio': '\$18.00',
      'duracion': '20 min',
      'icon': Icons.video_call_outlined,
      'color': Color(0xFF43B89C),
      'disponible': true,
      'tipo': ['Casa', 'Campo'],
    },
  ];

  final List<Map<String, dynamic>> _veterinarios = [
    {
      'nombre': 'Dr. Carlos Cevallos',
      'especialidad': 'Medicina General y Cirugía',
      'experiencia': '12 años',
      'rating': 4.9,
      'disponible': true,
      'tipo': ['Casa', 'Campo'],
      'color': Color(0xFF1CB5C9),
    },
    {
      'nombre': 'Dra. María Morales',
      'especialidad': 'Dermatología Veterinaria',
      'experiencia': '8 años',
      'rating': 4.7,
      'disponible': true,
      'tipo': ['Casa'],
      'color': Color(0xFF7C6FCD),
    },
    {
      'nombre': 'Dr. Andrés Vega',
      'especialidad': 'Medicina de Grandes Animales',
      'experiencia': '15 años',
      'rating': 4.8,
      'disponible': false,
      'tipo': ['Campo'],
      'color': Color(0xFF43B89C),
    },
    {
      'nombre': 'Dra. Sofía Ramírez',
      'especialidad': 'Nutrición y Bienestar Animal',
      'experiencia': '6 años',
      'rating': 4.6,
      'disponible': true,
      'tipo': ['Casa', 'Campo'],
      'color': Color(0xFFE58D57),
    },
  ];

  List<Map<String, dynamic>> get _serviciosFiltrados =>
      _servicios.where((s) => (s['tipo'] as List).contains(_tipoMascota)).toList();

  List<Map<String, dynamic>> get _veterinariosFiltrados =>
      _veterinarios.where((v) => (v['tipo'] as List).contains(_tipoMascota)).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
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
                    ],
                  ),
                ),
                // Selector Casa / Campo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildTipoBtn('Casa', Icons.home_outlined)),
                        Expanded(child: _buildTipoBtn('Campo', Icons.landscape_outlined)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Tabs Servicios / Veterinarios
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
                          ],
                        ),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildServiciosTab(), _buildVeterinariosTab()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoBtn(String tipo, IconData icon) {
    final activo = _tipoMascota == tipo;
    return GestureDetector(
      onTap: () => setState(() => _tipoMascota = tipo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: activo ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: activo ? const Color(0xFF126E82) : Colors.white),
            const SizedBox(width: 6),
            Text(
              'Mascota de $tipo',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: activo ? const Color(0xFF126E82) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiciosTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      children: [
        ..._serviciosFiltrados.map((s) => _buildServicioCard(s)),
        _buildMapaSection(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildVeterinariosTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${_veterinariosFiltrados.length} veterinarios disponibles',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        ..._veterinariosFiltrados.map((v) => _buildVeterinarioCard(v)),
        _buildMapaSection(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildServicioCard(Map<String, dynamic> servicio) {
    final disponible = servicio['disponible'] as bool;
    final color = servicio['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(servicio['icon'] as IconData, size: 28, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(servicio['titulo'] as String,
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)))),
                    if (!disponible)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                        child: Text('No disponible',
                            style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      ),
                  ]),
                  const SizedBox(height: 3),
                  Text(servicio['descripcion'] as String,
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(servicio['precio'] as String,
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text(servicio['duracion'] as String,
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
                    const Spacer(),
                    if (disponible)
                      GestureDetector(
                        onTap: () => _showAgendarDialog(context, servicio),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                          child: Text('Agendar',
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVeterinarioCard(Map<String, dynamic> vet) {
    final disponible = vet['disponible'] as bool;
    final color = vet['color'] as Color;
    final rating = vet['rating'] as double;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 62, height: 62,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3), width: 2),
              ),
              child: Icon(Icons.person_outline_rounded, size: 32, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(vet['nombre'] as String,
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: disponible ? Colors.green.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 6, height: 6,
                            decoration: BoxDecoration(
                                color: disponible ? Colors.green.shade400 : Colors.grey.shade400,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(disponible ? 'Disponible' : 'Ocupado',
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600,
                                color: disponible ? Colors.green.shade600 : Colors.grey.shade500)),
                      ]),
                    ),
                  ]),
                  Text(vet['especialidad'] as String,
                      style: GoogleFonts.poppins(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.star_rounded, size: 15, color: const Color(0xFFFBC02D)),
                    const SizedBox(width: 3),
                    Text('$rating', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
                    const SizedBox(width: 12),
                    Icon(Icons.work_outline_rounded, size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text(vet['experiencia'] as String,
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
                    const Spacer(),
                    if (disponible)
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                          child: Text('Consultar',
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapaSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.map_outlined, color: Color(0xFF1CB5C9), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clínicas y Veterinarias Cercanas',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Próximamente podrás encontrar clínicas cerca de tu ubicación.',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Pronto 🗺️',
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1CB5C9)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAgendarDialog(BuildContext context, Map<String, dynamic> servicio) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AgendarSheet(servicio: servicio),
    );
  }
}

// ── Sheet: Agendar ────────────────────────────────
class _AgendarSheet extends StatefulWidget {
  final Map<String, dynamic> servicio;
  const _AgendarSheet({required this.servicio});

  @override
  State<_AgendarSheet> createState() => _AgendarSheetState();
}

class _AgendarSheetState extends State<_AgendarSheet> {
  String? _fechaSeleccionada;
  String? _horaSeleccionada;

  final List<String> _horas = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
  ];

  @override
  Widget build(BuildContext context) {
    final color = widget.servicio['color'] as Color;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Agendar: ${widget.servicio['titulo']}',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
            const SizedBox(height: 6),
            Text('Precio: ${widget.servicio['precio']} · ${widget.servicio['duracion']}',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                  builder: (context, child) => Theme(
                    data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: color)),
                    child: child!,
                  ),
                );
                if (fecha != null) {
                  setState(() => _fechaSeleccionada = '${fecha.day}/${fecha.month}/${fecha.year}');
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_outlined, color: color, size: 20),
                  const SizedBox(width: 12),
                  Text(_fechaSeleccionada ?? 'Seleccionar fecha',
                      style: GoogleFonts.poppins(fontSize: 14,
                          color: _fechaSeleccionada != null ? const Color(0xFF1A1A2E) : Colors.grey.shade400)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Text('Selecciona un horario',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _horas.map((hora) {
                final sel = _horaSeleccionada == hora;
                return GestureDetector(
                  onTap: () => setState(() => _horaSeleccionada = hora),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? color : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(hora,
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : Colors.grey.shade700)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: (_fechaSeleccionada != null && _horaSeleccionada != null)
                    ? () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Cita agendada: $_fechaSeleccionada a las $_horaSeleccionada',
                              style: GoogleFonts.poppins(fontSize: 13)),
                          backgroundColor: color,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ));
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color, foregroundColor: Colors.white, elevation: 0,
                  disabledBackgroundColor: color.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Confirmar Cita',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header Clipper ────────────────────────────────
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
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
