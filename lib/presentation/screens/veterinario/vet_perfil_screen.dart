import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/veterinario_model.dart';
import '../../../domain/controllers/auth_controller.dart';
import '../../../domain/controllers/cita_controller.dart';
import '../../../domain/controllers/mascota_controller.dart';
import '../../../domain/controllers/veterinario_controller.dart';
import '../../../domain/controllers/servicio_controller.dart';
import '../shared/historial_citas_screen.dart';

class VetPerfilScreen extends StatefulWidget {
  const VetPerfilScreen({super.key});

  @override
  State<VetPerfilScreen> createState() => _VetPerfilScreenState();
}

class _VetPerfilScreenState extends State<VetPerfilScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = context.read<AuthController>().currentUser?.id;
      if (uid == null) return;

      final vetCtrl = context.read<VeterinarioController>();
      final servCtrl = context.read<ServicioController>();

      await vetCtrl.cargarPerfil(uid);

      // Cargar catálogo de servicios siempre
      servCtrl.cargarServicios();

      // Cargar mis servicios si ya tiene perfil en veterinarios
      final veteId = vetCtrl.perfil?.id;
      if (veteId != null && veteId.isNotEmpty) {
        servCtrl.cargarMisServicios(veteId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final vetCtrl = context.watch<VeterinarioController>();
    final vet = vetCtrl.perfil;
    final citas = context.watch<CitaController>();
    final mascotas = context.watch<MascotaController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          ClipPath(
            clipper: _HeaderClipper(),
            child: Container(
              height: 300,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D5C70), Color(0xFF1CB5C9)],
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
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text('Mi Perfil',
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white, size: 24),
                        onPressed: () async {
                          await auth.logout();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // Avatar + nombre
                Column(children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 14)],
                    ),
                    child: const Icon(Icons.person_rounded,
                        size: 52, color: Color(0xFF1CB5C9)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Dr. ${user?.nombre ?? 'Veterinario'}',
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vet?.especialidad != null
                          ? '🩺 ${vet!.especialidad}'
                          : '🩺 Médico Veterinario',
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                // Contenido scrollable
                Expanded(
                  child: vetCtrl.isLoading
                      ? const Center(child: CircularProgressIndicator(
                          color: Color(0xFF1CB5C9)))
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Estadísticas
                              Row(children: [
                                _statCard('${citas.todasLasCitas.length}',
                                    'Citas\ntotales',
                                    Icons.calendar_today_rounded,
                                    const Color(0xFF1CB5C9)),
                                const SizedBox(width: 10),
                                _statCard('${citas.citasCompletadasHoy}',
                                    'Hoy\ncompletadas',
                                    Icons.task_alt_rounded,
                                    const Color(0xFF43B89C)),
                                const SizedBox(width: 10),
                                _statCard(
                                    '${mascotas.todasLasMascotas.length}',
                                    'Pacientes',
                                    Icons.pets_rounded,
                                    const Color(0xFF7C6FCD)),
                              ]),
                              const SizedBox(height: 16),
                              // Info desde tabla veterinarios
                              _sectionCard(
                                titulo: 'Información Profesional',
                                icon: Icons.medical_services_outlined,
                                child: Column(children: [
                                  _infoRow(Icons.badge_outlined, 'Especialidad',
                                      vet?.especialidad ?? 'No registrada'),
                                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                                  _infoRow(Icons.work_outline_rounded, 'Experiencia',
                                      vet?.experiencia != null
                                          ? '${vet!.experiencia} años'
                                          : 'No registrada'),
                                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                                  _infoRow(Icons.attach_money_rounded, 'Tarifa',
                                      vet?.tarifa != null
                                          ? '\$${vet!.tarifa!.toStringAsFixed(2)}'
                                          : 'No registrada'),
                                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                                  _infoRow(
                                    vet?.disponible == true
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.cancel_outlined,
                                    'Disponible',
                                    vet?.disponible == true ? 'Sí' : 'No',
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 16),
                              // Info personal (tabla usuarios)
                              _sectionCard(
                                titulo: 'Información Personal',
                                icon: Icons.person_outline_rounded,
                                child: Column(children: [
                                  _infoRow(Icons.email_outlined, 'Correo',
                                      user?.correo ?? '—'),
                                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                                  _infoRow(Icons.phone_outlined, 'Teléfono',
                                      user?.telefono ?? 'No registrado'),
                                  if (user?.fechaRegistro != null) ...[
                                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                                    _infoRow(Icons.calendar_today_outlined,
                                        'Miembro desde',
                                        '${user!.fechaRegistro!.day}/${user.fechaRegistro!.month}/${user.fechaRegistro!.year}'),
                                  ],
                                ]),
                              ),
                              const SizedBox(height: 16),
                              // Opciones
                              _sectionCard(
                                titulo: 'Cuenta',
                                icon: Icons.settings_outlined,
                                child: Column(children: [
                                  _optionRow(Icons.history_rounded,
                                      'Historial de Citas',
                                      const Color(0xFF1CB5C9),
                                      () {
                                        final veteId = vetCtrl.perfil?.id;
                                        if (veteId != null && veteId.isNotEmpty) {
                                          Navigator.push(context, MaterialPageRoute(
                                            builder: (_) => HistorialCitasScreen(
                                                modo: 'veterinario', entityId: veteId),
                                          ));
                                        }
                                      }),
                                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                                  _optionRow(Icons.edit_outlined,
                                      'Editar información',
                                      const Color(0xFF43B89C),
                                      () => _showEditSheet(context, vet)),
                                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                                  _optionRow(Icons.lock_outline_rounded,
                                      'Cambiar contraseña',
                                      const Color(0xFF43B89C),
                                      () => _showCambiarContrasena(context)),
                                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                                  _optionRow(Icons.swap_horiz_rounded,
                                      'Cambiar a rol Usuario',
                                      const Color(0xFF7C6FCD),
                                      () => _cambiarRol(context)),
                                ]),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity, height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await auth.logout();
                                    if (context.mounted) {
                                      Navigator.pushReplacementNamed(
                                          context, '/login');
                                    }
                                  },
                                  icon: const Icon(Icons.logout_rounded, size: 20),
                                  label: Text('Cerrar Sesión',
                                      style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE53935),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets ────────────────────────────────────

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E))),
          Text(label, textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: Colors.grey.shade500, height: 1.2)),
        ]),
      ),
    );
  }

  Widget _sectionCard({required String titulo, required IconData icon,
      required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: const Color(0xFFE8F6F8),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: const Color(0xFF1CB5C9), size: 18),
            ),
            const SizedBox(width: 10),
            Text(titulo, style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E))),
          ]),
        ),
        child,
        const SizedBox(height: 4),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 20, color: const Color(0xFF1CB5C9)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(label, style: GoogleFonts.poppins(
              fontSize: 11, color: Colors.grey.shade500)),
          Text(value, style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E))),
        ])),
      ]),
    );
  }

  Widget _optionRow(IconData icon, String label, Color color,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A2E)))),
          Icon(Icons.chevron_right_rounded,
              color: Colors.grey.shade400, size: 22),
        ]),
      ),
    );
  }

  // ── Acciones ───────────────────────────────────

  void _showEditSheet(BuildContext context, VeterinarioModel? vet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ServicioController>(),
        child: _VetEditSheet(vetActual: vet),
      ),
    );
  }

  void _showCambiarContrasena(BuildContext context) {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Cambiar Contraseña', style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E))),
                const SizedBox(height: 18),
                _fieldForm('Nueva contraseña', passCtrl,
                    Icons.lock_outline_rounded, obscure: true,
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Mínimo 6 caracteres' : null),
                const SizedBox(height: 12),
                _fieldForm('Confirmar contraseña', confirmCtrl,
                    Icons.lock_outline_rounded, obscure: true,
                    validator: (v) =>
                        v != passCtrl.text ? 'No coinciden' : null),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, height: 52,
                  child: Consumer<AuthController>(
                    builder: (ctx, auth, _) => ElevatedButton(
                      onPressed: auth.isLoading ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        final ok = await auth.cambiarContrasena(passCtrl.text);
                        if (ok && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('¡Contraseña actualizada!')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43B89C),
                          foregroundColor: Colors.white, elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: auth.isLoading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text('Actualizar', style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _cambiarRol(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cambiar a rol Usuario',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
            '¿Deseas cambiar tu rol a Usuario? Serás redirigido al panel de usuario.',
            style: GoogleFonts.poppins(
                fontSize: 13, color: Colors.grey.shade600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          Consumer<AuthController>(
            builder: (ctx, auth, _) => ElevatedButton(
              onPressed: auth.isLoading ? null : () async {
                final ok = await auth.updateRol('usuario');
                if (ok && context.mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6FCD),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Text('Confirmar',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldForm(String label, TextEditingController ctrl, IconData icon,
      {bool obscure = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF2D2D2D)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
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
}

// ── Sheet: Editar datos del Vet (tabla veterinarios) ──
class _VetEditSheet extends StatefulWidget {
  final VeterinarioModel? vetActual;
  const _VetEditSheet({this.vetActual});

  @override
  State<_VetEditSheet> createState() => _VetEditSheetState();
}

class _VetEditSheetState extends State<_VetEditSheet> {
  // Campos de tabla usuarios
  late TextEditingController _nombreCtrl;
  late TextEditingController _telefonoCtrl;
  // Campos de tabla veterinarios
  late TextEditingController _especialidadCtrl;
  late TextEditingController _experienciaCtrl;
  late TextEditingController _tarifaCtrl;
  bool _disponible = true;

  @override
  void initState() {
    super.initState();
    final v = widget.vetActual;
    final user = context.read<AuthController>().currentUser;
    _nombreCtrl = TextEditingController(text: user?.nombre ?? '');
    _telefonoCtrl = TextEditingController(text: user?.telefono ?? '');
    _especialidadCtrl = TextEditingController(text: v?.especialidad ?? '');
    _experienciaCtrl = TextEditingController(
        text: v?.experiencia?.toString() ?? '');
    _tarifaCtrl = TextEditingController(
        text: v?.tarifa?.toStringAsFixed(2) ?? '');
    _disponible = v?.disponible ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _especialidadCtrl.dispose();
    _experienciaCtrl.dispose();
    _tarifaCtrl.dispose();
    super.dispose();
  }

  void _guardar() async {
    final auth = context.read<AuthController>();
    final vetCtrl = context.read<VeterinarioController>();
    final uid = auth.currentUser?.id ?? '';

    if (_nombreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El nombre es obligatorio')));
      return;
    }

    // 1. Actualizar nombre y teléfono en tabla usuarios
    await auth.updateProfile(
        _nombreCtrl.text.trim(), _telefonoCtrl.text.trim());
    if (!mounted) return;

    // 2. Guardar/actualizar en tabla veterinarios
    final vetModel = VeterinarioModel(
      id: vetCtrl.perfil?.id ?? '',
      usuarioId: uid,
      especialidad: _especialidadCtrl.text.trim().isNotEmpty
          ? _especialidadCtrl.text.trim()
          : null,
      experiencia: int.tryParse(_experienciaCtrl.text.trim()),
      tarifa: double.tryParse(_tarifaCtrl.text.trim()),
      disponible: _disponible,
    );

    final ok = await vetCtrl.guardarPerfil(vetModel);
    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Información actualizada correctamente'),
        backgroundColor: Color(0xFF1CB5C9),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(vetCtrl.errorMessage ?? 'Error al guardar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vetCtrl = context.watch<VeterinarioController>();
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Editar Información',
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E))),
              const SizedBox(height: 6),
              Text('Datos personales y profesionales',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 18),

              // ── Datos tabla usuarios ──
              _sectionLabel('Datos Personales'),
              const SizedBox(height: 10),
              _field('Nombre completo *', _nombreCtrl,
                  Icons.person_outline_rounded),
              const SizedBox(height: 12),
              _field('Teléfono', _telefonoCtrl, Icons.phone_outlined,
                  keyboard: TextInputType.phone),
              const SizedBox(height: 18),

              // ── Datos tabla veterinarios ──
              _sectionLabel('Datos Profesionales'),
              const SizedBox(height: 10),
              _field('Especialidad', _especialidadCtrl,
                  Icons.medical_services_outlined),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _field('Años de experiencia', _experienciaCtrl,
                      Icons.work_outline_rounded,
                      keyboard: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field('Tarifa (\$)', _tarifaCtrl,
                      Icons.attach_money_rounded,
                      keyboard: const TextInputType.numberWithOptions(
                          decimal: true)),
                ),
              ]),
              const SizedBox(height: 12),

              // Disponible toggle
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFBBEBF0), width: 1.2),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Color(0xFF1CB5C9), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Disponible para citas',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF2D2D2D))),
                  ),
                  Switch(
                    value: _disponible,
                    onChanged: (v) => setState(() => _disponible = v),
                    activeColor: const Color(0xFF1CB5C9),
                  ),
                ]),
              ),
              const SizedBox(height: 18),

              // ── Servicios que brinda ──
              _sectionLabel('Servicios que Brindo'),
              const SizedBox(height: 10),
              Consumer<ServicioController>(
                builder: (context, servCtrl, _) {
                  if (servCtrl.isLoading || servCtrl.isLoadingMisServicios) {
                    return const Center(
                        child: SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1CB5C9))));
                  }
                  if (servCtrl.servicios.isEmpty) {
                    return Text('Sin servicios disponibles',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade400));
                  }
                  return Column(
                    children: servCtrl.servicios.map((s) {
                      final asignado = servCtrl.tieneServicio(s.id);
                      final veseId = servCtrl.misServicios
                          .where((ms) => ms.servId == s.id)
                          .map((ms) => ms.id)
                          .firstOrNull;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: asignado
                              ? s.color.withValues(alpha: 0.06)
                              : const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: asignado
                                ? s.color.withValues(alpha: 0.4)
                                : Colors.grey.shade200,
                            width: 1.2,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 2),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: s.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(s.iconData, color: s.color, size: 18),
                          ),
                          title: Text(s.nombre,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A2E))),
                          trailing: Switch(
                            value: asignado,
                            activeColor: s.color,
                            onChanged: (val) async {
                              final veteId = context
                                      .read<VeterinarioController>()
                                      .perfil
                                      ?.id ??
                                  '';
                              if (veteId.isEmpty) return;
                              if (val) {
                                await servCtrl.asignarServicio(
                                    veteId: veteId, servId: s.id);
                              } else if (veseId != null) {
                                await servCtrl.quitarServicio(veseId, veteId);
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: vetCtrl.isLoading ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1CB5C9),
                    foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: vetCtrl.isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Guardar Cambios',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Row(children: [
      Container(width: 4, height: 16,
          decoration: BoxDecoration(
              color: const Color(0xFF1CB5C9),
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: const Color(0xFF126E82))),
    ]);
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl, keyboardType: keyboard,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF2D2D2D)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
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
