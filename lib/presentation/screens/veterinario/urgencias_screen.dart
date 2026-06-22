import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UrgenciasScreen extends StatefulWidget {
  const UrgenciasScreen({super.key});

  @override
  State<UrgenciasScreen> createState() => _UrgenciasScreenState();
}

class _UrgenciasScreenState extends State<UrgenciasScreen> {
  final List<Map<String, dynamic>> _urgencias = [
    {
      'paciente': 'Max (Beagle)',
      'propietario': 'Roberto Vega',
      'motivo': 'Dificultad respiratoria severa',
      'prioridad': 'crítica',
      'tiempo': 'Hace 5 min',
      'icon': Icons.pets,
    },
    {
      'paciente': 'Nala (Gata)',
      'propietario': 'Sofía Ruiz',
      'motivo': 'Trauma por accidente de tránsito',
      'prioridad': 'crítica',
      'tiempo': 'Hace 12 min',
      'icon': Icons.catching_pokemon,
    },
    {
      'paciente': 'Thor (Rottweiler)',
      'propietario': 'Miguel Ortega',
      'motivo': 'Posible ingestión de tóxico',
      'prioridad': 'alta',
      'tiempo': 'Hace 25 min',
      'icon': Icons.pets,
    },
    {
      'paciente': 'Coco (Canario)',
      'propietario': 'Laura Medina',
      'motivo': 'No come hace 3 días, letargo',
      'prioridad': 'media',
      'tiempo': 'Hace 40 min',
      'icon': Icons.flutter_dash_outlined,
    },
    {
      'paciente': 'Pelusa (Conejo)',
      'propietario': 'Diana Castro',
      'motivo': 'Herida en pata delantera',
      'prioridad': 'media',
      'tiempo': 'Hace 1h',
      'icon': Icons.cruelty_free_outlined,
    },
  ];

  String _filtroPrioridad = 'Todos';

  List<Map<String, dynamic>> get _urgenciasFiltradas {
    if (_filtroPrioridad == 'Todos') return _urgencias;
    return _urgencias
        .where((u) => u['prioridad'] == _filtroPrioridad.toLowerCase())
        .toList();
  }

  Color _colorPrioridad(String prioridad) {
    switch (prioridad) {
      case 'crítica':
        return const Color(0xFFE53935);
      case 'alta':
        return const Color(0xFFE58D57);
      case 'media':
        return const Color(0xFFFBC02D);
      default:
        return const Color(0xFF43B89C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // Cabecera roja urgencias
          ClipPath(
            clipper: _HeaderClipper(),
            child: Container(
              height: 230,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
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
                          const Icon(Icons.favorite_rounded,
                              color: Colors.white, size: 28),
                          Text(
                            'Urgencias 24h',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Indicador en vivo
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF69FF6E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'En vivo',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Filtros de prioridad
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: ['Todos', 'Crítica', 'Alta', 'Media'].map((f) {
                      final activo = _filtroPrioridad == f;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _filtroPrioridad = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: activo
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            f,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: activo
                                  ? const Color(0xFFE53935)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Lista de urgencias
                Expanded(
                  child: _urgenciasFiltradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'Sin urgencias activas',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _urgenciasFiltradas.length,
                          itemBuilder: (context, index) =>
                              _buildUrgenciaCard(
                                  _urgenciasFiltradas[index]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgenciaCard(Map<String, dynamic> urgencia) {
    final color = _colorPrioridad(urgencia['prioridad'] as String);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: color, width: 5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(urgencia['icon'] as IconData,
                      size: 26, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        urgencia['paciente'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        urgencia['propietario'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        urgencia['prioridad'].toString().toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      urgencia['tiempo'] as String,
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
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                urgencia['motivo'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone_outlined, size: 16),
                    label: Text('Llamar',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _atenderUrgencia(context, urgencia),
                    icon: const Icon(Icons.medical_services_outlined, size: 16),
                    label: Text('Atender',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
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
        ),
      ),
    );
  }

  void _atenderUrgencia(
      BuildContext context, Map<String, dynamic> urgencia) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Atender urgencia',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          '¿Confirmas que vas a atender la urgencia de ${urgencia['paciente']}?\n\nSe notificará al propietario.',
          style:
              GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _urgencias.remove(urgencia));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirmar',
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
