import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../data/models/mascota_model.dart';
import '../../../domain/controllers/auth_controller.dart';
import '../../../domain/controllers/cita_controller.dart';
import '../../../domain/controllers/mascota_controller.dart';

class VetMascotasScreen extends StatefulWidget {
  const VetMascotasScreen({super.key});

  @override
  State<VetMascotasScreen> createState() => _VetMascotasScreenState();
}

class _VetMascotasScreenState extends State<VetMascotasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthController>().currentUser?.id ?? '';
      context.read<MascotaController>().cargarTodasLasMascotas();
      context.read<MascotaController>().cargarMascotas(uid);
      context.read<CitaController>().cargarTodasLasCitas();
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMascotaSheet(context),
        backgroundColor: const Color(0xFF1CB5C9),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text('Pacientes',
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ]),
                ),
                // Buscador
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _busqueda = v),
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar paciente...',
                        hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
                              const Icon(Icons.pets_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text('Mis Mascotas',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ]),
                      ),
                      Tab(
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.medical_services_outlined,
                                  size: 16),
                              const SizedBox(width: 6),
                              Text('Atendidos',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
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
                      _buildMisMascotas(),
                      _buildAtendidos(),
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

  // Tab 1: Mascotas propias del veterinario
  Widget _buildMisMascotas() {
    return Consumer<MascotaController>(
      builder: (context, ctrl, _) {
        if (ctrl.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1CB5C9)));
        }
        final lista = ctrl.mascotas.where((m) {
          if (_busqueda.isEmpty) return true;
          return m.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
              m.especie.toLowerCase().contains(_busqueda.toLowerCase()) ||
              m.raza.toLowerCase().contains(_busqueda.toLowerCase());
        }).toList();

        if (lista.isEmpty) {
          return _emptyState(
              'No tienes mascotas registradas',
              'Presiona + para agregar una.',
              Icons.pets_rounded);
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: lista.length,
          itemBuilder: (ctx, i) => _buildMascotaCard(lista[i], esPropia: true),
        );
      },
    );
  }

  // Tab 2: Mascotas atendidas (con citas registradas)
  Widget _buildAtendidos() {
    return Consumer2<MascotaController, CitaController>(
      builder: (context, mascotaCtrl, citaCtrl, _) {
        if (mascotaCtrl.isLoading || citaCtrl.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1CB5C9)));
        }

        // Nombres únicos de mascotas que tienen cita
        final nombresConCita = citaCtrl.todasLasCitas
            .map((c) => c.mascotaNombre.toLowerCase().trim())
            .toSet();

        // Filtrar de todas las mascotas las que tienen cita
        var atendidos = mascotaCtrl.todasLasMascotas
            .where((m) =>
                nombresConCita.contains(m.nombre.toLowerCase().trim()))
            .toList();

        // Aplicar búsqueda
        if (_busqueda.isNotEmpty) {
          atendidos = atendidos
              .where((m) =>
                  m.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
                  m.especie.toLowerCase().contains(_busqueda.toLowerCase()) ||
                  m.raza.toLowerCase().contains(_busqueda.toLowerCase()))
              .toList();
        }

        if (atendidos.isEmpty) {
          return _emptyState(
              'Sin pacientes atendidos aún',
              'Aquí aparecerán las mascotas con citas registradas.',
              Icons.medical_services_outlined);
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: atendidos.length,
          itemBuilder: (ctx, i) =>
              _buildMascotaCard(atendidos[i], esPropia: false),
        );
      },
    );
  }

  Widget _emptyState(String titulo, String subtitulo, IconData icon) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(titulo,
            style: GoogleFonts.poppins(
                fontSize: 15, color: Colors.grey.shade500)),
        const SizedBox(height: 6),
        Text(subtitulo,
            style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.grey.shade400)),
      ]),
    );
  }

  Widget _buildMascotaCard(MascotaModel m, {required bool esPropia}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: esPropia
            ? null
            : Border(
                left: BorderSide(
                    color: const Color(0xFF1CB5C9), width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: m.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: (m.fotoUrl != null && m.fotoUrl!.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(m.fotoUrl!, fit: BoxFit.cover))
                : Icon(m.icon, size: 34, color: m.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(m.nombre,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E))),
                ),
                if (!esPropia)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F6F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('En cita',
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1CB5C9))),
                  ),
              ]),
              Text('${m.especie} · ${m.raza}',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Row(children: [
                _chip(m.edad, Icons.cake_outlined),
                const SizedBox(width: 6),
                _chip(m.genero, Icons.transgender_rounded),
              ]),
            ]),
          ),
          if (esPropia)
            GestureDetector(
              onTap: () => _showAddMascotaSheet(context, mascota: m),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFE8F6F8),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit_rounded,
                    color: Color(0xFF1CB5C9), size: 20),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: const Color(0xFFE8F6F8),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: const Color(0xFF1CB5C9)),
        const SizedBox(width: 3),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF1CB5C9),
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  void _showAddMascotaSheet(BuildContext context, {MascotaModel? mascota}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VetAddMascotaSheet(mascota: mascota),
    );
  }
}

// ── Sheet: Agregar/Editar paciente (Vet) ─────────
class _VetAddMascotaSheet extends StatefulWidget {
  final MascotaModel? mascota;
  const _VetAddMascotaSheet({this.mascota});

  @override
  State<_VetAddMascotaSheet> createState() => _VetAddMascotaSheetState();
}

class _VetAddMascotaSheetState extends State<_VetAddMascotaSheet> {
  final _nombreCtrl = TextEditingController();
  final _razaCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  String _especie = 'Perro';
  String _genero = 'Macho';
  String _estado = 'propio';
  File? _imagenFisica;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.mascota != null) {
      final m = widget.mascota!;
      _nombreCtrl.text = m.nombre;
      _razaCtrl.text = m.raza;
      _edadCtrl.text = m.edad;
      _especie = m.especie.isNotEmpty ? m.especie : 'Perro';
      _genero = m.genero.isNotEmpty ? m.genero : 'Macho';
      _estado = m.estado.isNotEmpty ? m.estado : 'propio';
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _razaCtrl.dispose();
    _edadCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final f = await _picker.pickImage(source: ImageSource.gallery);
    if (f != null) setState(() => _imagenFisica = File(f.path));
  }

  void _guardar() async {
    final authCtrl = context.read<AuthController>();
    final mascotaCtrl = context.read<MascotaController>();
    final vetId = authCtrl.currentUser?.id ?? '';

    if (_nombreCtrl.text.trim().isEmpty || _razaCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nombre y raza son obligatorios')));
      return;
    }

    String? fotoUrl = widget.mascota?.fotoUrl;
    if (_imagenFisica != null) {
      final ext = _imagenFisica!.path.split('.').last;
      fotoUrl = await mascotaCtrl.subirImagenMascota(_imagenFisica!, ext);
    }

    final nueva = MascotaModel(
      id: widget.mascota?.id ?? '',
      usuarioId: vetId,
      nombre: _nombreCtrl.text.trim(),
      especie: _especie,
      raza: _razaCtrl.text.trim(),
      genero: _genero,
      edad: _edadCtrl.text.trim(),
      estado: _estado,
      fotoUrl: fotoUrl,
    );

    bool ok;
    if (widget.mascota != null) {
      ok = await mascotaCtrl.actualizarMascota(nueva);
    } else {
      ok = await mascotaCtrl.agregarMascota(nueva);
    }

    if (ok && mounted) {
      // Recargar mis mascotas del vet
      await mascotaCtrl.cargarMascotas(vetId);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.mascota != null
            ? 'Paciente actualizado' : 'Paciente registrado'),
        backgroundColor: const Color(0xFF1CB5C9),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MascotaController>();
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(widget.mascota != null
                  ? 'Editar Paciente' : 'Registrar Paciente',
                  style: GoogleFonts.poppins(fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E))),
              const SizedBox(height: 16),
              _field('Nombre *', _nombreCtrl, Icons.pets_rounded),
              const SizedBox(height: 12),
              _dropdown('Especie', _especie,
                  ['Perro', 'Gato', 'Conejo', 'Ave', 'Reptil', 'Otro'],
                  (v) => setState(() => _especie = v!)),
              const SizedBox(height: 12),
              _field('Raza *', _razaCtrl, Icons.category_outlined),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field('Edad', _edadCtrl, Icons.cake_outlined,
                    keyboard: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _dropdown('Género', _genero,
                    ['Macho', 'Hembra'],
                    (v) => setState(() => _genero = v!))),
              ]),
              const SizedBox(height: 12),
              _dropdown('Estado', _estado,
                  ['propio', 'para adoptar', 'adoptado'],
                  (v) => setState(() => _estado = v!)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 100, width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFBBEBF0), width: 1.2),
                  ),
                  child: _imagenFisica != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_imagenFisica!, fit: BoxFit.cover))
                      : (widget.mascota?.fotoUrl != null &&
                              widget.mascota!.fotoUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                  widget.mascota!.fotoUrl!, fit: BoxFit.cover))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate_outlined,
                                    color: Color(0xFF1CB5C9), size: 28),
                                const SizedBox(height: 4),
                                Text('Agregar foto',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: const Color(0xFF1CB5C9))),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: ctrl.isLoading ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1CB5C9),
                    foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: ctrl.isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(widget.mascota != null
                          ? 'Guardar Cambios' : 'Registrar Paciente',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl, keyboardType: keyboard,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF2D2D2D)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
            color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF1CB5C9), size: 20),
        filled: true, fillColor: const Color(0xFFF0FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFBBEBF0), width: 1.2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1CB5C9), width: 2)),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBEBF0), width: 1.2),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(border: InputBorder.none,
            labelText: label,
            labelStyle: GoogleFonts.poppins(
                color: Colors.grey.shade500, fontSize: 13)),
        style: GoogleFonts.poppins(
            fontSize: 14, color: const Color(0xFF2D2D2D)),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),
        items: items.map((e) =>
            DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
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
