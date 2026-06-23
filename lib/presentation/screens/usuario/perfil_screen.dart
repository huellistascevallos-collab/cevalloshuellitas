import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../domain/controllers/auth_controller.dart';
import '../../../domain/controllers/mascota_controller.dart';
import '../shared/historial_citas_screen.dart';

// ─── Paleta de colores Premium ───────────────────────────
const _teal = Color(0xFF5BBFBF);
const _tealDark = Color(0xFF3A9A9A);
const _orange = Color(0xFFF0954A);
const _headerBg = Color(0xFFBBE7EC); // Fondo celeste pastel de la cabecera
const _bg = Color(0xFFF0F9FF);
const _dark = Color(0xFF1A1A2E);
const _grey = Color(0xFF8A9BB0);

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
                  _SheetHandle(),
                  const SizedBox(height: 20),
                  Text('Cambiar Contraseña',
                      style: GoogleFonts.poppins(
                          fontSize: 22, fontWeight: FontWeight.w700, color: _dark)),
                  const SizedBox(height: 20),
                  _PasswordField(controller: contrasenaController, label: 'Nueva contraseña'),
                  const SizedBox(height: 14),
                  _PasswordField(
                    controller: confirmarController,
                    label: 'Confirmar contraseña',
                    validator: (v) =>
                        v != contrasenaController.text ? 'Las contraseñas no coinciden' : null,
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
                                final ok =
                                    await auth.cambiarContrasena(contrasenaController.text);
                                if (ok && context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('¡Contraseña actualizada correctamente!')),
                                  );
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(auth.errorMessage ??
                                            'Error al cambiar contraseña')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text('Actualizar Contraseña',
                                style: GoogleFonts.poppins(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
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
    final isVet = user?.rol == 'veterinario';

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header Premium ────────────────────────────────
          SliverToBoxAdapter(
            child: ClipPath(
              clipper: _HeaderWaveClipper(),
              child: Container(
                height: 320,
                color: _headerBg,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Fila de botones (Atrás y Cerrar Sesión)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout_rounded, color: _dark, size: 22),
                              onPressed: () async {
                                context.read<MascotaController>().limpiarMascotas();
                                await authController.logout();
                                if (context.mounted) {
                                  Navigator.pushReplacementNamed(context, '/login');
                                }
                              },
                              tooltip: 'Cerrar sesión',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _AvatarPicker(fotoUrl: user?.fotoUrl),
                      const SizedBox(height: 14),
                      Text(
                        user?.nombre ?? 'Usuario',
                        style: GoogleFonts.poppins(
                            fontSize: 22, fontWeight: FontWeight.w800, color: _dark),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: _teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _teal.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          isVet ? '🩺 Veterinario' : '🐾 Dueño de Mascotas',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w700, color: _tealDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Tarjetas de Estadísticas (Dashboard Style)
                Row(
                  children: [
                    _StatCard(
                      value: '${mascotas.length}',
                      label: 'Mascotas',
                      icon: Icons.pets_rounded,
                      color: _teal,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      value: '0',
                      label: 'Citas',
                      icon: Icons.calendar_today_rounded,
                      color: _orange,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      value: '0',
                      label: 'Vacunas',
                      icon: Icons.vaccines_rounded,
                      color: const Color(0xFF43B89C),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Información personal
                _SectionLabel(label: 'Información Personal'),
                const SizedBox(height: 10),
                _InfoCard(
                  children: [
                    _InfoTile(
                      icon: Icons.email_outlined,
                      label: 'Correo electrónico',
                      value: user?.correo ?? '—',
                      iconColor: _teal,
                    ),
                    _Separator(),
                    _InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      value: (user?.telefono?.isNotEmpty == true)
                          ? user!.telefono!
                          : 'No registrado',
                      iconColor: _teal,
                    ),
                    _Separator(),
                    _InfoTile(
                      icon: Icons.badge_outlined,
                      label: 'Rol en la app',
                      value: isVet ? 'Veterinario' : 'Dueño de Mascotas',
                      iconColor: _orange,
                    ),
                    if (user?.fechaRegistro != null) ...[
                      _Separator(),
                      _InfoTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Miembro desde',
                        value:
                            '${user!.fechaRegistro!.day}/${user.fechaRegistro!.month}/${user.fechaRegistro!.year}',
                        iconColor: const Color(0xFF43B89C),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 28),

                // Mis mascotas
                _SectionLabel(label: 'Mis Mascotas'),
                const SizedBox(height: 10),
                _InfoCard(
                  headerAction: mascotas.isNotEmpty
                      ? _HeaderAction(
                          label: 'Ver todas',
                          onTap: () => Navigator.pushNamed(context, '/mis_mascotas'),
                        )
                      : null,
                  children: mascotas.isEmpty
                      ? [
                          _EmptyState(
                            icon: Icons.pets_rounded,
                            message: 'No tienes mascotas registradas aún.',
                          ),
                        ]
                      : [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: Row(
                              children: mascotas.take(4).map((m) {
                                return Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _bg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _teal.withValues(alpha: 0.15)),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: m.color.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(m.icon, size: 24, color: m.color),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        m.nombre,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _dark,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        m.raza.isNotEmpty ? m.raza : m.especie,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: _grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                ),

                const SizedBox(height: 28),

                // Configuración de cuenta
                _SectionLabel(label: 'Ajustes y Cuenta'),
                const SizedBox(height: 10),
                _InfoCard(
                  children: [
                    _OptionTile(
                      icon: Icons.history_rounded,
                      label: 'Historial de Citas',
                      iconColor: _teal,
                      iconBg: _teal.withValues(alpha: 0.1),
                      onTap: () {
                        final uid = context.read<AuthController>().currentUser?.id;
                        if (uid != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  HistorialCitasScreen(modo: 'usuario', entityId: uid),
                            ),
                          );
                        }
                      },
                    ),
                    _Separator(),
                    _OptionTile(
                      icon: Icons.edit_outlined,
                      label: 'Editar Perfil',
                      iconColor: _teal,
                      iconBg: _teal.withValues(alpha: 0.1),
                      onTap: () => _showEditProfileDialog(context),
                    ),
                    _Separator(),
                    _OptionTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'Cambiar Contraseña',
                      iconColor: _orange,
                      iconBg: _orange.withValues(alpha: 0.1),
                      onTap: () => _showCambiarContrasenaDialog(context),
                    ),
                    _Separator(),
                    _OptionTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Ayuda y Soporte',
                      iconColor: _grey,
                      iconBg: _grey.withValues(alpha: 0.08),
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Botón cerrar sesión
                _LogoutButton(
                  onTap: () async {
                    context.read<MascotaController>().limpiarMascotas();
                    await authController.logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Stat Card (Dashboard Style)
// ═══════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _dark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Reusable Section Components
// ═══════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _grey,
              letterSpacing: 0.8)),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _HeaderAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600, color: _teal)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  final Widget? headerAction;

  const _InfoCard({required this.children, this.headerAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF5BBFBF).withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerAction != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(alignment: Alignment.centerRight, child: headerAction!),
            ),
          ...children,
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFFF0F4F8),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: _grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _dark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w500, color: _dark)),
            ),
            Icon(Icons.chevron_right_rounded, color: _grey.withValues(alpha: 0.5), size: 22),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(children: [
        Icon(icon, size: 36, color: _grey.withValues(alpha: 0.4)),
        const SizedBox(height: 8),
        Text(message,
            style: GoogleFonts.poppins(fontSize: 13, color: _grey),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFF5252).withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 20, color: Color(0xFFE53935)),
            const SizedBox(width: 10),
            Text('Cerrar Sesión',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE53935))),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Widget: Avatar con selector de foto
// ═══════════════════════════════════════════════════
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
        backgroundColor: ok ? _teal : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl = context.select<AuthController, String?>(
      (c) => c.currentUser?.fotoUrl,
    );
    final isLoading = context.select<AuthController, bool>((c) => c.isLoading);

    return GestureDetector(
      onTap: isLoading ? null : _seleccionarFoto,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: ClipOval(
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                            color: _teal, strokeWidth: 2.5),
                      ),
                    )
                  : (fotoUrl != null && fotoUrl.isNotEmpty)
                      ? Image.network(
                          fotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.person_rounded,
                            size: 58,
                            color: _teal,
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          size: 58,
                          color: _teal,
                        ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                    color: _orange.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))
              ],
            ),
            child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Sheet: Editar Perfil
// ═══════════════════════════════════════════════════
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

    final okPerfil = await authController.updateProfile(
      _nombreController.text.trim(),
      _telefonoController.text.trim(),
    );

    if (!okPerfil) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(authController.errorMessage ?? 'Error al actualizar perfil')),
        );
      }
      return;
    }

    final rolActual = authController.currentUser?.rol ?? 'usuario';
    if (_rolSeleccionado != rolActual) {
      final okRol = await authController.updateRol(_rolSeleccionado);
      if (!okRol && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(authController.errorMessage ?? 'Error al cambiar el rol')),
        );
        return;
      }
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: _teal,
        ),
      );

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
    final currentRol = context.read<AuthController>().currentUser?.rol ?? 'usuario';

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              _SheetHandle(),
              const SizedBox(height: 20),
              Text('Editar Perfil',
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.w700, color: _dark)),
              const SizedBox(height: 20),

              _buildInputField('Nombre completo', _nombreController,
                  Icons.person_outline_rounded),
              const SizedBox(height: 14),

              _buildInputField('Teléfono', _telefonoController, Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBEBF0), width: 1.2),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _rolSeleccionado,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Rol',
                    labelStyle:
                        GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
                    prefixIcon:
                        const Icon(Icons.badge_outlined, color: _teal, size: 20),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF2D2D2D)),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  items: const [
                    DropdownMenuItem(
                        value: 'usuario', child: Text('🐾  Usuario (Dueño de mascotas)')),
                    DropdownMenuItem(
                        value: 'veterinario', child: Text('🩺  Veterinario')),
                  ],
                  onChanged: (val) => setState(() => _rolSeleccionado = val!),
                ),
              ),

              if (_rolSeleccionado != currentRol) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFFBC02D).withValues(alpha: 0.5)),
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
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: authController.isLoading ? null : _guardarPerfil,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: authController.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
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

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF2D2D2D)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: _teal, size: 20),
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
          borderSide: const BorderSide(color: _teal, width: 2),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Password Field Helper
// ═══════════════════════════════════════════════════
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    this.validator,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: _teal, size: 20),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: _grey, size: 20),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        filled: true,
        fillColor: const Color(0xFFF3FAFD),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCEEF0), width: 1.2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _teal, width: 2)),
      ),
      validator: widget.validator ??
          (v) {
            if (v == null || v.length < 6) return 'Mínimo 6 caracteres';
            return null;
          },
    );
  }
}

// ── Cortador de cabecera en onda convexa ──
class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 15,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
