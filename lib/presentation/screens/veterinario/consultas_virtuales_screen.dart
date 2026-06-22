import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConsultasVirtualesScreen extends StatefulWidget {
  const ConsultasVirtualesScreen({super.key});

  @override
  State<ConsultasVirtualesScreen> createState() =>
      _ConsultasVirtualesScreenState();
}

class _ConsultasVirtualesScreenState extends State<ConsultasVirtualesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _pendientes = [
    {
      'paciente': 'Luna (Labrador)',
      'propietario': 'María Torres',
      'hora': '10:00 AM',
      'fecha': 'Hoy',
      'motivo': 'Control post-operatorio',
      'estado': 'pendiente',
      'avatar': Icons.pets,
    },
    {
      'paciente': 'Michi (Persa)',
      'propietario': 'Carlos López',
      'hora': '11:30 AM',
      'fecha': 'Hoy',
      'motivo': 'Revisión de vacunas',
      'estado': 'pendiente',
      'avatar': Icons.catching_pokemon,
    },
    {
      'paciente': 'Rocky (Bulldog)',
      'propietario': 'Ana Martínez',
      'hora': '03:00 PM',
      'fecha': 'Hoy',
      'motivo': 'Consulta general',
      'estado': 'pendiente',
      'avatar': Icons.pets,
    },
  ];

  final List<Map<String, dynamic>> _completadas = [
    {
      'paciente': 'Bella (Siamés)',
      'propietario': 'Luis Ramírez',
      'hora': '09:00 AM',
      'fecha': 'Ayer',
      'motivo': 'Fiebre y decaimiento',
      'estado': 'completada',
      'avatar': Icons.catching_pokemon,
    },
    {
      'paciente': 'Max (Beagle)',
      'propietario': 'Rosa Sánchez',
      'hora': '02:30 PM',
      'fecha': 'Ayer',
      'motivo': 'Control de peso',
      'estado': 'completada',
      'avatar': Icons.pets,
    },
  ];

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
          // Cabecera
          ClipPath(
            clipper: _HeaderClipper(),
            child: Container(
              height: 240,
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
                          const Icon(Icons.monitor_heart_rounded,
                              color: Colors.white, size: 28),
                          Text(
                            'Consultas Virtuales',
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

                // Stats rápidos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildStatChip('${_pendientes.length}', 'Pendientes',
                          const Color(0xFFFFE0B2)),
                      const SizedBox(width: 10),
                      _buildStatChip('${_completadas.length}', 'Completadas',
                          Colors.white.withOpacity(0.3)),
                    ],
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
                          child: Text('Pendientes',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600))),
                      Tab(
                          child: Text('Completadas',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLista(_pendientes),
                      _buildLista(_completadas),
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

  Widget _buildStatChip(String numero, String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            numero,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista(List<Map<String, dynamic>> lista) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Sin consultas',
                style: GoogleFonts.poppins(
                    color: Colors.grey.shade400, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: lista.length,
      itemBuilder: (context, index) => _buildConsultaCard(lista[index]),
    );
  }

  Widget _buildConsultaCard(Map<String, dynamic> consulta) {
    final pendiente = consulta['estado'] == 'pendiente';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                // Avatar
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F6F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(consulta['avatar'] as IconData,
                      size: 30, color: const Color(0xFF1CB5C9)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        consulta['paciente'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        'Propietario: ${consulta['propietario']}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Hora / Fecha
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      consulta['hora'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1CB5C9),
                      ),
                    ),
                    Text(
                      consulta['fecha'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Motivo: ${consulta['motivo']}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
            ),
            if (pendiente) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 16),
                      label: Text('Chat',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1CB5C9),
                        side: const BorderSide(
                            color: Color(0xFF1CB5C9), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _iniciarVideoLlamada(context, consulta),
                      icon: const Icon(Icons.videocam_rounded, size: 16),
                      label: Text('Iniciar',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1CB5C9),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _iniciarVideoLlamada(
      BuildContext context, Map<String, dynamic> consulta) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Iniciar videollamada',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Conectando con ${consulta['propietario']} para la consulta de ${consulta['paciente']}.',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1CB5C9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Conectar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
