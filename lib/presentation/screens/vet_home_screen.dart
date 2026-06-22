import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../domain/controllers/auth_controller.dart';

class VetHomeScreen extends StatelessWidget {
  const VetHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Fondo claro
      body: Stack(
        children: [
          // ── Cabecera Turquesa Curva ──
          ClipPath(
            clipper: _HeaderClipper(),
            child: Container(
              height: 280, // Cabecera un poco más corta que el home normal
              width: double.infinity,
              color: const Color(0xFF1CB5C9),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── AppBar Custom ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                        onPressed: () {},
                      ),
                      Row(
                        children: [
                          const Icon(Icons.pets, color: Colors.white, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Huellitas CevallosVet',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── Grid de Acciones (Veterinario) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildActionItem(Icons.calendar_month_rounded, 'Registrar\nNuevo Paciente'),
                      _buildActionItem(Icons.monitor_heart_rounded, 'Consultas\nVirtuales'),
                      _buildActionItem(Icons.favorite_rounded, 'Urgencias\n24h'),
                      _buildActionItem(Icons.cases_rounded, 'Inventario\ny Facturas'),
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
                        // Título Consultas Finalizadas
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Últimas Consultas Finalizadas',
                            style: GoogleFonts.poppins(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D2D2D),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Lista de Consultas (Tarjetas verticales)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              _buildConsultCard(
                                number: '1',
                                name: 'Leo (Golden Retriever)',
                                subtitle: 'Día de Visita',
                                iconData: Icons.pets,
                                btn1: 'Ver Reporte',
                                btn2: 'Receta Digital',
                              ),
                              const SizedBox(height: 14),
                              _buildConsultCard(
                                number: '2',
                                name: 'Bella (Persian Cat)',
                                subtitle: 'Día de Vacunación',
                                iconData: Icons.catching_pokemon, // Icono alternativo para gato
                                btn1: 'Ver Reporte',
                                btn2: 'Próximo Control',
                              ),
                              const SizedBox(height: 14),
                              _buildConsultCard(
                                number: '3',
                                name: 'Rocky (Bulldog)',
                                subtitle: 'Control de Peso',
                                iconData: Icons.pets,
                                btn1: 'Ver Reporte',
                                btn2: 'Ver Gráfica',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Botón Contactar Especialista Externo ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE58D57), // Naranja
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE58D57).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {},
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Contactar Especialista Externo',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.add_ic_call_rounded, color: Colors.white, size: 26),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Alertas Importantes ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alertas Importantes',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Recordatorio subrayado parcialmente (estilo de la imagen)
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xFF2D2D2D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Recordatorio: ',
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        decorationColor: const Color(0xFF1CB5C9),
                                        decorationThickness: 2,
                                      ),
                                    ),
                                    const TextSpan(text: 'Vacunas de Luna (Siamés) en 2 días'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Stock bajo: Amoxicilina',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF2D2D2D),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Atención: Paciente Max con tos',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF2D2D2D),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100), // Espacio para el bottom navbar
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
            child: _buildBottomNavigationBar(context, authController),
          ),

          // ── Botón Flotante Central (Estetoscopio) ──
          Positioned(
            bottom: 25,
            left: MediaQuery.of(context).size.width / 2 - 35,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF126E82), // Turquesa oscuro
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF5F6FA), width: 6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF126E82).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF229AA8), // Turquesa oscuro
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w500,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildDot(bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildConsultCard({
    required String number,
    required String name,
    required String subtitle,
    required IconData iconData,
    required String btn1,
    required String btn2,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono/Imagen de mascota
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F6F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(iconData, size: 45, color: const Color(0xFF1CB5C9)),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Botones
                      Row(
                        children: [
                          Expanded(child: _buildSmallBtn(btn1)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildSmallBtn(btn2)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Banderita con número
          Positioned(
            left: 0,
            top: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF126E82),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Text(
                number,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBtn(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1CB5C9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, AuthController authController) {
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: const Icon(Icons.home, color: Color(0xFF1CB5C9), size: 30), onPressed: () {}),
          IconButton(icon: const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 26), onPressed: () {}),
          const SizedBox(width: 50), // Espacio para el botón flotante central
          IconButton(icon: const Icon(Icons.add_box_outlined, color: Colors.grey, size: 28), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.grey, size: 30),
            onPressed: () async {
              await authController.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
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
