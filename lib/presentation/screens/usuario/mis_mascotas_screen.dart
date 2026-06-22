import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/controllers/auth_controller.dart';
import '../../../domain/controllers/mascota_controller.dart';
import '../../../data/models/mascota_model.dart';

class MisMascotasScreen extends StatefulWidget {
  const MisMascotasScreen({super.key});

  @override
  State<MisMascotasScreen> createState() => _MisMascotasScreenState();
}

class _MisMascotasScreenState extends State<MisMascotasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = context.read<AuthController>();
      final mascotaController = context.read<MascotaController>();
      if (authController.currentUser != null) {
        mascotaController.cargarMascotas(authController.currentUser!.id);
      }
    });
  }

  void _showAddMascotaSheet(BuildContext context, {MascotaModel? mascota}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMascotaSheet(mascota: mascota),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMascotaSheet(context),
        backgroundColor: const Color(0xFF1CB5C9),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: Stack(
        children: [
          // Cabecera turquesa
          ClipPath(
            clipper: _HeaderClipper(),
            child: Container(
              height: 200,
              width: double.infinity,
              color: const Color(0xFF1CB5C9),
            ),
          ),

          SafeArea(
            child: Consumer<MascotaController>(
              builder: (context, mascotaController, child) {
                final mascotas = mascotaController.mascotas;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AppBar custom
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
                          Text(
                            'Mis Mascotas',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Contador
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        '${mascotas.length} mascotas registradas',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Estado de carga, vacío o lista
                    Expanded(
                      child: mascotaController.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1CB5C9),
                              ),
                            )
                          : mascotas.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.pets_rounded,
                                          size: 64, color: Colors.grey.shade300),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No tienes mascotas registradas.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Presiona + para agregar una.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: mascotas.length,
                                  itemBuilder: (context, index) {
                                    final mascota = mascotas[index];
                                    return _buildMascotaCard(mascota);
                                  },
                                ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotaCard(MascotaModel mascota) {
    final esParaAdoptar = mascota.estado.toLowerCase() == 'para adoptar';
    return Consumer<MascotaController>(
      builder: (context, controller, _) {
        final esFav = controller.esFavorito(mascota.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar (foto o icono)
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: mascota.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: (mascota.fotoUrl != null && mascota.fotoUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(mascota.fotoUrl!, fit: BoxFit.cover),
                        )
                      : Icon(mascota.icon, size: 40, color: mascota.color),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mascota.nombre,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        '${mascota.especie} · ${mascota.raza}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildChip(mascota.edad, Icons.cake_outlined),
                          const SizedBox(width: 6),
                          _buildEstadoChip(mascota.estado),
                        ],
                      ),
                    ],
                  ),
                ),
                // Botones de acción
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón editar
                    GestureDetector(
                      onTap: () => _showAddMascotaSheet(context, mascota: mascota),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FAFB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: Color(0xFF1CB5C9), size: 20),
                      ),
                    ),
                    // Botón favorito (solo para mascotas en adopción)
                    if (esParaAdoptar) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => controller.toggleFavorito(mascota.id),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: esFav
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFF0FAFB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            esFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: esFav ? const Color(0xFFE53935) : Colors.grey.shade400,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF1CB5C9)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF1CB5C9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color color;
    switch (estado.toLowerCase()) {
      case 'para adoptar':
        color = const Color(0xFFE58D57);
        break;
      case 'adoptado':
        color = const Color(0xFF43B89C);
        break;
      default:
        color = const Color(0xFF7C6FCD);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// Sheet: Agregar / Editar Mascota
// ────────────────────────────────────────────────
class _AddMascotaSheet extends StatefulWidget {
  final MascotaModel? mascota;
  const _AddMascotaSheet({this.mascota});

  @override
  State<_AddMascotaSheet> createState() => _AddMascotaSheetState();
}

class _AddMascotaSheetState extends State<_AddMascotaSheet> {
  final _nombreController = TextEditingController();
  final _razaController = TextEditingController();
  final _edadController = TextEditingController();
  final _descripcionController = TextEditingController();
  String _especie = 'Perro';
  String _genero = 'Macho';
  String _estado = 'propio';
  File? _imagenFisica;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.mascota != null) {
      final m = widget.mascota!;
      _nombreController.text = m.nombre;
      _razaController.text = m.raza;
      _edadController.text = m.edad;
      _descripcionController.text = m.descripcion ?? '';
      _especie = m.especie.isNotEmpty ? m.especie : 'Perro';
      _genero = m.genero.isNotEmpty ? m.genero : 'Macho';
      _estado = m.estado.isNotEmpty ? m.estado : 'propio';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _razaController.dispose();
    _edadController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final extension = pickedFile.path.split('.').last.toLowerCase();
      const formatosPermitidos = ['jpg', 'jpeg', 'png', 'webp'];
      if (!formatosPermitidos.contains(extension)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Formato no permitido: .$extension\nSolo se aceptan: JPG, JPEG, PNG, WEBP',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
      setState(() {
        _imagenFisica = File(pickedFile.path);
      });
    }
  }

  void _guardarMascota() async {
    final mascotaController = context.read<MascotaController>();
    final authController = context.read<AuthController>();
    final usuarioId = authController.currentUser?.id;

    if (usuarioId == null) return;

    if (_nombreController.text.trim().isEmpty ||
        _razaController.text.trim().isEmpty ||
        _edadController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa los campos requeridos.')),
      );
      return;
    }

    // Validar rango de edad
    final edadVal = int.tryParse(_edadController.text.trim());
    if (edadVal == null || edadVal < 0 || edadVal > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La edad debe ser un número entre 0 y 100.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Subir imagen si se seleccionó
    String? fotoUrl = widget.mascota?.fotoUrl;
    if (_imagenFisica != null) {
      final ext = _imagenFisica!.path.split('.').last.toLowerCase();
      // Capturamos el controller antes del await para evitar usar context
      // después de un posible desmontaje del widget
      final controller = context.read<MascotaController>();
      fotoUrl = await controller.subirImagenMascota(_imagenFisica!, ext);

      if (!mounted) return;

      if (fotoUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Error al subir la imagen'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    final nuevaMascota = MascotaModel(
      id: widget.mascota?.id ?? '',
      usuarioId: usuarioId,
      nombre: _nombreController.text.trim(),
      especie: _especie,
      raza: _razaController.text.trim(),
      genero: _genero,
      edad: _edadController.text.trim(),
      estado: _estado,
      descripcion: _estado == 'para adoptar' ? _descripcionController.text.trim() : null,
      fotoUrl: fotoUrl,
    );

    bool success;
    if (widget.mascota != null) {
      success = await mascotaController.actualizarMascota(nuevaMascota);
    } else {
      success = await mascotaController.agregarMascota(nuevaMascota);
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.mascota != null
              ? 'Mascota actualizada correctamente'
              : 'Mascota registrada exitosamente'),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mascotaController.errorMessage ?? 'Error al guardar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mascotaController = context.watch<MascotaController>();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 20),

              Text(
                widget.mascota != null ? 'Editar Mascota' : 'Añadir Mascota',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 20),

              _buildInputField('Nombre de la mascota', _nombreController, Icons.pets_rounded),
              const SizedBox(height: 14),

              _buildDropdown('Especie', _especie, ['Perro', 'Gato', 'Conejo', 'Ave', 'Otro'],
                  (val) => setState(() => _especie = val!)),
              const SizedBox(height: 14),

              _buildInputField('Raza', _razaController, Icons.category_outlined),
              const SizedBox(height: 14),

              _buildInputField('Edad (ej. 3)', _edadController, Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _MaxValueFormatter(100),
                  ]),
              const SizedBox(height: 14),

              _buildDropdown('Género', _genero, ['Macho', 'Hembra'],
                  (val) => setState(() => _genero = val!)),
              const SizedBox(height: 14),

              _buildDropdown('Estado', _estado, ['propio', 'para adoptar', 'adoptado'],
                  (val) => setState(() => _estado = val!)),
              const SizedBox(height: 14),

              // Campo descripción solo si es para adoptar
              if (_estado == 'para adoptar') ...[
                _buildInputField(
                    'Descripción para adopción', _descripcionController, Icons.description_outlined),
                const SizedBox(height: 14),
              ],

              // Selector de imagen (siempre disponible)
              Text('Foto de la mascota',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _seleccionarImagen,
                child: Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBEBF0), width: 1.2),
                  ),
                  child: _imagenFisica != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_imagenFisica!, fit: BoxFit.cover),
                        )
                      : (widget.mascota?.fotoUrl != null &&
                              widget.mascota!.fotoUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(widget.mascota!.fotoUrl!,
                                  fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate_outlined,
                                    color: Color(0xFF1CB5C9), size: 36),
                                const SizedBox(height: 8),
                                Text('Toca para subir una imagen',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12, color: const Color(0xFF1CB5C9))),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: mascotaController.isLoading ? null : _guardarMascota,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1CB5C9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: mascotaController.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          widget.mascota != null ? 'Guardar Cambios' : 'Registrar Mascota',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF2D2D2D)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF1CB5C9), size: 20),
        filled: true,
        fillColor: const Color(0xFFF0FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFBBEBF0), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1CB5C9), width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAFB),
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFBBEBF0), width: 1.2),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
        ),
        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF2D2D2D)),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ────────────────────────────────────────────────
// Formatter: limita el valor numérico a un máximo
// ────────────────────────────────────────────────
class _MaxValueFormatter extends TextInputFormatter {
  final int max;
  _MaxValueFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final val = int.tryParse(newValue.text);
    if (val == null || val > max) return oldValue;
    return newValue;
  }
}

// ────────────────────────────────────────────────
// Custom Clipper
// ────────────────────────────────────────────────
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
