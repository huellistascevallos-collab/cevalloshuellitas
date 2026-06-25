import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/usuario_model.dart';
import '../../../domain/controllers/admin_controller.dart';
import '../../../presentation/widgets/safe_network_image.dart';

const _blue  = Color(0xFF1A73E8);
const _dark  = Color(0xFF1A1F36);
const _grey  = Color(0xFF8A9BB0);
const _bg    = Color(0xFFF4F6FB);
const _green = Color(0xFF0E9F6E);
const _red   = Color(0xFFE53935);

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  final _searchCtrl = TextEditingController();
  String _busqueda = '';
  String _filtroRol = 'todos'; // todos | usuario | veterinario | administrador

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().cargarUsuarios();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<UsuarioModel> _filtrar(List<UsuarioModel> todos) {
    return todos.where((u) {
      final matchRol =
          _filtroRol == 'todos' || u.rol == _filtroRol;
      final q = _busqueda.toLowerCase();
      final matchBusqueda = q.isEmpty ||
          u.nombre.toLowerCase().contains(q) ||
          u.correo.toLowerCase().contains(q);
      return matchRol && matchBusqueda;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _dark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Usuarios',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _dark)),
        centerTitle: true,
        actions: [
          Consumer<AdminController>(
            builder: (_, ctrl, __) => IconButton(
              tooltip: 'Recargar',
              icon: const Icon(Icons.refresh_rounded, color: _blue),
              onPressed: () => ctrl.cargarUsuarios(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Buscador + filtro rol ──────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Buscador
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _busqueda = v),
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o correo…',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: _blue, size: 20),
                    suffixIcon: _busqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: _grey, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _busqueda = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: _bg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                // Filtro chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filtroChip('Todos', 'todos'),
                      const SizedBox(width: 8),
                      _filtroChip('Usuarios', 'usuario'),
                      const SizedBox(width: 8),
                      _filtroChip('Veterinarios', 'veterinario'),
                      const SizedBox(width: 8),
                      _filtroChip('Admins', 'administrador'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Lista ─────────────────────────────────────────────────────
          Expanded(
            child: Consumer<AdminController>(
              builder: (ctx, ctrl, _) {
                if (ctrl.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator(color: _blue));
                }
                final lista = _filtrar(ctrl.usuarios);
                if (lista.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_rounded,
                            size: 56, color: _grey.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('Sin resultados',
                            style: GoogleFonts.poppins(
                                color: _grey, fontSize: 15)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: _blue,
                  onRefresh: () => ctrl.cargarUsuarios(),
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _UsuarioCard(usuario: lista[i], ctrl: ctrl),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtroChip(String label, String valor) {
    final sel = _filtroRol == valor;
    return GestureDetector(
      onTap: () => setState(() => _filtroRol = valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? _blue : _bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? _blue : Colors.grey.shade300,
              width: sel ? 0 : 1),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : _grey)),
      ),
    );
  }
}

// ── Tarjeta de usuario ─────────────────────────────────────────────────────────

class _UsuarioCard extends StatelessWidget {
  final UsuarioModel usuario;
  final AdminController ctrl;

  const _UsuarioCard({required this.usuario, required this.ctrl});

  Color get _rolColor {
    switch (usuario.rol) {
      case 'veterinario':
        return _green;
      case 'administrador':
        return _blue;
      default:
        return const Color(0xFFE58D57);
    }
  }

  IconData get _rolIcon {
    switch (usuario.rol) {
      case 'veterinario':
        return Icons.medical_services_rounded;
      case 'administrador':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            SafeNetworkAvatar(
              url: usuario.fotoUrl,
              size: 52,
              fallbackIcon: Icons.person_rounded,
              fallbackColor: _rolColor,
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(usuario.nombre,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _dark)),
                  Text(usuario.correo,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: _grey),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _rolColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_rolIcon, size: 11, color: _rolColor),
                        const SizedBox(width: 4),
                        Text(usuario.rol,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _rolColor)),
                      ]),
                    ),
                    if (usuario.fechaRegistro != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatFecha(usuario.fechaRegistro!),
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: _grey),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            // Menú de acciones
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: _grey, size: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (accion) =>
                  _ejecutarAccion(context, accion),
              itemBuilder: (_) => [
                _menuItem('rol_usuario', Icons.person_rounded,
                    'Cambiar a Usuario', const Color(0xFFE58D57)),
                _menuItem('rol_veterinario',
                    Icons.medical_services_rounded,
                    'Cambiar a Veterinario', _green),
                _menuItem('rol_admin',
                    Icons.admin_panel_settings_rounded,
                    'Cambiar a Admin', _blue),
                const PopupMenuDivider(),
                _menuItem('eliminar', Icons.delete_outline_rounded,
                    'Eliminar usuario', _red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: _dark, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Future<void> _ejecutarAccion(BuildContext context, String accion) async {
    if (accion == 'eliminar') {
      final ok = await _confirmarEliminacion(context);
      if (!ok) return;
      if (!context.mounted) return;
      final exito = await ctrl.eliminarUsuario(usuario.id);
      if (!context.mounted) return;
      _snack(context,
          exito ? 'Usuario eliminado' : (ctrl.errorMessage ?? 'Error'),
          exito ? _green : _red);
      return;
    }

    final nuevoRol = accion == 'rol_veterinario'
        ? 'veterinario'
        : accion == 'rol_admin'
            ? 'administrador'
            : 'usuario';

    if (nuevoRol == usuario.rol) return;

    final exito = await ctrl.cambiarRolUsuario(usuario.id, nuevoRol);
    if (!context.mounted) return;
    _snack(
        context,
        exito ? 'Rol actualizado a $nuevoRol' : (ctrl.errorMessage ?? 'Error'),
        exito ? _green : _red);
  }

  Future<bool> _confirmarEliminacion(BuildContext context) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar usuario',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: _dark)),
        content: Text(
          '¿Eliminar a "${usuario.nombre}"? Esta acción no se puede deshacer.',
          style: GoogleFonts.poppins(fontSize: 13, color: _grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(color: _grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Eliminar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  void _snack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _formatFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
