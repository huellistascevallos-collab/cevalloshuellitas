import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../domain/controllers/auth_controller.dart';
import '../../../domain/controllers/mascota_controller.dart';
import '../../../data/models/mascota_model.dart';
import '../shared/historial_citas_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {

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

  void _showEditProfileDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EditProfileSheet(),
    );
  }

  void _showCambiarContrasenaDialog(BuildContext context) {
    final contrasenaController = TextEditingController();
    final confirmarController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Cambiar Contraseña',
                      style: GoogleFonts.poppins(
                          fontSize: 22, fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E))),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: contrasenaController,
                    obscureText: true,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF1CB5C9), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF0FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFBBEBF0), width: 1.2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1CB5C9), width: 2)),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: confirmarController,
                    obscureText: true,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF43B89C), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF0FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFBBEBF0), width: 1.2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF43B89C), width: 2)),
                    ),
                    validator: (v) {
                      if (v != contrasenaController.text) return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Consumer<AuthController>(
                      builder: (ctx, auth, _) => ElevatedButton(
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                final ok = await auth.cambiarContrasena(contrasenaController.text);
                                if (ok && context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('¡Contraseña actualizada correctamente!')),
                                  );
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(auth.errorMessage ?? 'Error al cambiar contraseña')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43B89C),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(width: 24, height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('Actualizar Contraseña',
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;
    final mascotaController = context.watch<MascotaController>();
    final mascotas = mascotaController.mascotas;

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
                              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                      const Spacer(),
                      // Botón logout
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                        onPressed: () async {
                          context.read<MascotaController>().limpiarMascotas();
                          await authController.logout();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // Avatar + nombre del usuario
                const SizedBox(height: 8),
                Column(
                  children: [
                    _AvatarPicker(fotoUrl: user?.fotoUrl),
                    const SizedBox(height: 10),
                    Text(
                      user?.nombre ?? 'Usuario',
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user?.rol == 'veterinario' ? '🩺 Veterinario' : '🐾 Dueño de Mascotas',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Contenido scrollable
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card info personal
                        _buildSectionCard(
                          titulo: 'Información Personal',
                          icon: Icons.person_outline_rounded,
                          child: Column(
                            children: [
                              _buildInfoRow(Icons.email_outlined, 'Correo', user?.correo ?? '—'),
                              const Divider(height: 1, color: Color(0xFFF0F0F0)),
                              _buildInfoRow(Icons.phone_outlined, 'Teléfono',
                                  (user?.telefono?.isNotEmpty == true) ? user!.telefono! : 'No registrado'),
                              const Divider(height: 1, color: Color(0xFFF0F0F0)),
                              _buildInfoRow(Icons.badge_outlined, 'Rol',
                                  user?.rol == 'veterinario' ? 'Veterinario' : 'Usuario'),
                              if (user?.fechaRegistro != null) ...[
                                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                                _buildInfoRow(Icons.calendar_today_outlined, 'Miembro desde',
                                    '${user!.fechaRegistro!.day}/${user.fechaRegistro!.month}/${user.fechaRegistro!.year}'),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Estadísticas
                        Row(children: [
                          Expanded(child: _buildStatCard('${mascotas.length}', 'Mascotas', Icons.pets_rounded, const Color(0xFF1CB5C9))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard('0', 'Citas', Icons.calendar_today_outlined, const Color(0xFF7C6FCD))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard('0', 'Vacunas\npendientes', Icons.vaccines_outlined, const Color(0xFFE58D57))),
                        ]),
                        const SizedBox(height: 16),
                        // Mis mascotas
                        _buildSectionCard(
                          titulo: 'Mis Mascotas',
                          icon: Icons.pets_rounded,
                          actionLabel: 'Ver todas',
                          onAction: () => Navigator.pushNamed(context, '/mis_mascotas'),
                          child: mascotas.isEmpty 
                            ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No tienes mascotas registradas.',
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
                                ),
                              )
                            : Column(
                            children: mascotas.take(3).toList().asMap().entries.map((entry) {
                              final i = entry.key;
                              final m = entry.value;
                              return Column(
                                children: [
                                  if (i > 0) const Divider(height: 1, color: Color(0xFFF0F0F0)),
                                  _buildMascotaRow(m),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Opciones de cuenta
                        _buildSectionCard(
                          titulo: 'Cuenta',
                          icon: Icons.settings_outlined,
                          child: Column(
                            children: [
                              _buildOptionRow(Icons.history_rounded, 'Historial de Citas', const Color(0xFF1CB5C9), () {
                                final uid = context.read<AuthController>().currentUser?.id;
                                if (uid != null) {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => HistorialCitasScreen(
                                        modo: 'usuario', entityId: uid),
                                  ));
                                }
                              }),
                              const Divider(height: 1, color: Color(0xFFF0F0F0)),
                              _buildOptionRow(Icons.edit_outlined, 'Editar perfil', const Color(0xFF43B89C), () => _showEditProfileDialog(context)),
                              const Divider(height: 1, color: Color(0xFFF0F0F0)),
                              _buildOptionRow(Icons.notifications_outlined, 'Notificaciones', const Color(0xFF7C6FCD), () {}),
                              const Divider(height: 1, color: Color(0xFFF0F0F0)),
                              _buildOptionRow(Icons.lock_outline_rounded, 'Cambiar contraseña', const Color(0xFF43B89C), () => _showCambiarContrasenaDialog(context)),
                              const Divider(height: 1, color: Color(0xFFF0F0F0)),
                              _buildOptionRow(Icons.help_outline_rounded, 'Ayuda y soporte', const Color(0xFFE58D57), () {}),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Botón cerrar sesión
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              context.read<MascotaController>().limpiarMascotas();
                              await authController.logout();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            label: Text('Cerrar Sesión',
                                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _buildSectionCard({
    required String titulo,
    required IconData icon,
    required Widget child,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: const Color(0xFFE8F6F8), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: const Color(0xFF1CB5C9), size: 18),
              ),
              const SizedBox(width: 10),
              Text(titulo,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
              const Spacer(),
              if (actionLabel != null && onAction != null)
                GestureDetector(
                  onTap: onAction,
                  child: Text(actionLabel,
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1CB5C9))),
                ),
            ]),
          ),
          child,
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 20, color: const Color(0xFF1CB5C9)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
          Text(value,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E))),
        ]),
      ]),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E))),
        Text(label, textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500, height: 1.2)),
      ]),
    );
  }

  Widget _buildMascotaRow(MascotaModel mascota) {
    final color = mascota.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(mascota.icon, size: 24, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(mascota.nombre,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
          Text('${mascota.especie} · ${mascota.raza} · ${mascota.edad}',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(mascota.genero,
              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ),
      ]),
    );
  }

  Widget _buildOptionRow(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A2E)))),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
        ]),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// Widget: Avatar con selector de foto
// ────────────────────────────────────────────────
class _AvatarPicker extends StatefulWidget {
  final String? fotoUrl;
  const _AvatarPicker({this.fotoUrl});

  @override
  State<_AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<_AvatarPicker> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _seleccionarFoto() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;

    final extension = picked.path.split('.').last.toLowerCase();
    const formatosPermitidos = ['jpg', 'jpeg', 'png', 'webp'];
    if (!formatosPermitidos.contains(extension)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Formato no permitido: .$extension\nSolo se aceptan: JPG, JPEG, PNG, WEBP',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final authController = context.read<AuthController>();
    final ok = await authController.subirFotoUsuario(File(picked.path), extension);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Foto actualizada correctamente'
            : (authController.errorMessage ?? 'Error al subir foto')),
        backgroundColor: ok ? const Color(0xFF1CB5C9) : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl = context.select<AuthController, String?>(
      (c) => c.currentUser?.fotoUrl,
    );
    final isLoading =
        context.select<AuthController, bool>((c) => c.isLoading);

    return GestureDetector(
      onTap: isLoading ? null : _seleccionarFoto,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12),
              ],
            ),
            child: ClipOval(
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Color(0xFF1CB5C9),
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : (fotoUrl != null && fotoUrl.isNotEmpty)
                      ? Image.network(
                          fotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            size: 52,
                            color: Color(0xFF1CB5C9),
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          size: 52,
                          color: Color(0xFF1CB5C9),
                        ),
            ),
          ),
          // Ícono de cámara
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF1CB5C9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child:
                const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
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
    path.quadraticBezierTo(size.width / 2, size.height + 10, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ────────────────────────────────────────────────
// Sheet: Editar Perfil
// ────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nombreController;
  late TextEditingController _telefonoController;
  late String _rolSeleccionado;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    _nombreController = TextEditingController(text: user?.nombre ?? '');
    _telefonoController = TextEditingController(text: user?.telefono ?? '');
    _rolSeleccionado = user?.rol ?? 'usuario';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _guardarPerfil() async {
    final authController = context.read<AuthController>();

    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío.')),
      );
      return;
    }

    // Guardar nombre y teléfono
    final okPerfil = await authController.updateProfile(
      _nombreController.text.trim(),
      _telefonoController.text.trim(),
    );

    if (!okPerfil) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authController.errorMessage ?? 'Error al actualizar perfil')),
        );
      }
      return;
    }

    // Si cambió el rol, actualizarlo también
    final rolActual = authController.currentUser?.rol ?? 'usuario';
    if (_rolSeleccionado != rolActual) {
      final okRol = await authController.updateRol(_rolSeleccionado);
      if (!okRol && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authController.errorMessage ?? 'Error al cambiar el rol')),
        );
        return;
      }
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: Color(0xFF1CB5C9),
        ),
      );

      // Redirigir según el nuevo rol
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        if (_rolSeleccionado == 'veterinario') {
          Navigator.pushReplacementNamed(context, '/vet_home');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

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
                'Editar Perfil',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 20),

              // Nombre
              _buildInputField('Nombre completo', _nombreController, Icons.person_outline_rounded),
              const SizedBox(height: 14),

              // Teléfono
              _buildInputField('Teléfono', _telefonoController, Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 14),

              // Rol — selector funcional
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBEBF0), width: 1.2),
                ),
                child: DropdownButtonFormField<String>(
                  value: _rolSeleccionado,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Rol',
                    labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
                    prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF1CB5C9), size: 20),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF2D2D2D)),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  items: const [
                    DropdownMenuItem(
                      value: 'usuario',
                      child: Text('🐾  Usuario (Dueño de mascotas)'),
                    ),
                    DropdownMenuItem(
                      value: 'veterinario',
                      child: Text('🩺  Veterinario'),
                    ),
                  ],
                  onChanged: (val) => setState(() => _rolSeleccionado = val!),
                ),
              ),
              const SizedBox(height: 8),
              // Aviso informativo del cambio de rol
              if (_rolSeleccionado != (context.read<AuthController>().currentUser?.rol ?? 'usuario'))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFBC02D).withValues(alpha: 0.5)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFFBC02D), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Al guardar serás redirigido al panel de $_rolSeleccionado.',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFFF57F17),
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
              const SizedBox(height: 24),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: authController.isLoading ? null : _guardarPerfil,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1CB5C9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: authController.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Guardar Cambios',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF2D2D2D)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF1CB5C9), size: 20),
        filled: true,
        fillColor: const Color(0xFFF0FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFBBEBF0), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1CB5C9), width: 2),
        ),
      ),
    );
  }
}
