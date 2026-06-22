import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NuevoPacienteScreen extends StatefulWidget {
  const NuevoPacienteScreen({super.key});

  @override
  State<NuevoPacienteScreen> createState() => _NuevoPacienteScreenState();
}

class _NuevoPacienteScreenState extends State<NuevoPacienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreMascotaController = TextEditingController();
  final _razaController = TextEditingController();
  final _edadController = TextEditingController();
  final _pesoController = TextEditingController();
  final _nombrePropietarioController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _observacionesController = TextEditingController();
  String _especie = 'Perro';
  String _genero = 'Macho';
  int _paso = 0; // 0 = mascota, 1 = dueño, 2 = confirmación

  @override
  void dispose() {
    _nombreMascotaController.dispose();
    _razaController.dispose();
    _edadController.dispose();
    _pesoController.dispose();
    _nombrePropietarioController.dispose();
    _telefonoController.dispose();
    _observacionesController.dispose();
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
              height: 200,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
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
                          const Icon(Icons.calendar_month_rounded,
                              color: Colors.white, size: 28),
                          Text(
                            'Nuevo Paciente',
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

                // Indicador de pasos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _buildStepIndicator(0, 'Mascota'),
                      _buildStepLine(0),
                      _buildStepIndicator(1, 'Dueño'),
                      _buildStepLine(1),
                      _buildStepIndicator(2, 'Confirmar'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Contenido
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildPaso(),
                      ),
                    ),
                  ),
                ),

                // Botones de navegación
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      if (_paso > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _paso--),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFF1CB5C9), width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Anterior',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1CB5C9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (_paso > 0) const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_paso < 2) {
                              setState(() => _paso++);
                            } else {
                              _registrarPaciente();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1CB5C9),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _paso < 2 ? 'Siguiente' : 'Registrar Paciente',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildPaso() {
    switch (_paso) {
      case 0:
        return _buildPasoMascota();
      case 1:
        return _buildPasoDueno();
      case 2:
        return _buildPasoConfirmacion();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPasoMascota() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Datos de la mascota', Icons.pets_rounded),
        const SizedBox(height: 16),
        _buildInputField('Nombre de la mascota *', _nombreMascotaController,
            Icons.badge_outlined,
            required: true),
        const SizedBox(height: 14),
        _buildDropdown('Especie', _especie, ['Perro', 'Gato', 'Conejo', 'Ave', 'Reptil', 'Otro'],
            (val) => setState(() => _especie = val!)),
        const SizedBox(height: 14),
        _buildInputField('Raza', _razaController, Icons.category_outlined),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                  'Edad', _edadController, Icons.cake_outlined,
                  hint: 'Ej: 2 años'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInputField(
                  'Peso (kg)', _pesoController, Icons.monitor_weight_outlined,
                  hint: 'Ej: 5.2',
                  keyboardType: TextInputType.number),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildDropdown('Género', _genero, ['Macho', 'Hembra'],
            (val) => setState(() => _genero = val!)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPasoDueno() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Datos del propietario', Icons.person_outline_rounded),
        const SizedBox(height: 16),
        _buildInputField('Nombre completo *', _nombrePropietarioController,
            Icons.person_outline_rounded,
            required: true),
        const SizedBox(height: 14),
        _buildInputField('Teléfono', _telefonoController,
            Icons.phone_outlined,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 14),
        _buildTextAreaField('Observaciones / Motivo de consulta',
            _observacionesController),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPasoConfirmacion() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Resumen del registro', Icons.fact_check_outlined),
        const SizedBox(height: 16),
        _buildResumenCard('Mascota', [
          _buildResumenItem('Nombre', _nombreMascotaController.text.isEmpty ? '—' : _nombreMascotaController.text),
          _buildResumenItem('Especie / Raza', '$_especie · ${_razaController.text.isEmpty ? '—' : _razaController.text}'),
          _buildResumenItem('Género', _genero),
          _buildResumenItem('Edad', _edadController.text.isEmpty ? '—' : _edadController.text),
          _buildResumenItem('Peso', _pesoController.text.isEmpty ? '—' : '${_pesoController.text} kg'),
        ]),
        const SizedBox(height: 14),
        _buildResumenCard('Propietario', [
          _buildResumenItem('Nombre', _nombrePropietarioController.text.isEmpty ? '—' : _nombrePropietarioController.text),
          _buildResumenItem('Teléfono', _telefonoController.text.isEmpty ? '—' : _telefonoController.text),
          _buildResumenItem('Observaciones', _observacionesController.text.isEmpty ? '—' : _observacionesController.text),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildResumenCard(String titulo, List<Widget> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(
            BorderSide(color: Color(0xFFBBEBF0), width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF126E82),
              )),
          const Divider(color: Color(0xFFE8F6F8)),
          ...items,
        ],
      ),
    );
  }

  Widget _buildResumenItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F6F8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF1CB5C9), size: 22),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            )),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final activo = _paso >= step;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: activo ? Colors.white : Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: activo
                      ? const Color(0xFF126E82)
                      : Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: activo
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
                fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
              )),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    return Container(
      width: 20,
      height: 2,
      color: _paso > step
          ? Colors.white
          : Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      IconData icon,
      {bool required = false,
      String? hint,
      TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF2D2D2D)),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
        hintStyle:
            GoogleFonts.poppins(color: Colors.grey.shade300, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF1CB5C9), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDEEF0), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1CB5C9), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTextAreaField(
      String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF2D2D2D)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDEEF0), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1CB5C9), width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(
            BorderSide(color: Color(0xFFDDEEF0), width: 1.2)),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle:
              GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
        ),
        style: GoogleFonts.poppins(
            fontSize: 14, color: const Color(0xFF2D2D2D)),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _registrarPaciente() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Paciente ${_nombreMascotaController.text} registrado exitosamente',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: const Color(0xFF1CB5C9),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
