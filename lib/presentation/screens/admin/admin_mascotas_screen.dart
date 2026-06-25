import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/mascota_model.dart';
import '../../../domain/controllers/admin_controller.dart';
import '../../../presentation/widgets/safe_network_image.dart';

const _blue = Color(0xFF1A73E8);
const _dark = Color(0xFF1A1F36);
const _grey = Color(0xFF8A9BB0);
const _bg = Color(0xFFF4F6FB);
const _green = Color(0xFF0E9F6E);
const _red = Color(0xFFE53935);
const _orange = Color(0xFFE58D57);
const _teal = Color(0xFF1CB5C9);

class AdminMascotasScreen extends StatefulWidget {
  const AdminMascotasScreen({super.key});

  @override
  State<AdminMascotasScreen> createState() => _AdminMascotasScreenState();
}

class _AdminMascotasScreenState extends State<AdminMascotasScreen> {
  final _searchCtrl = TextEditingController();
  String _busqueda = '';
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().cargarMascotas();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MascotaModel> _filtrar(List<MascotaModel> todas) {
    return todas.where((m) {
      final matchEstado = _filtroEstado == 'todos' ||
          m.estado.toLowerCase() == _filtroEstado.toLowerCase();
      final q = _busqueda.toLowerCase();
      final matchBusqueda = q.isEmpty ||
          m.nombre.toLowerCase().contains(q) ||
          m.especie.toLowerCase().contains(q) ||
          m.raza.toLowerCase().contains(q) ||
          (m.propietarioNombre?.toLowerCase().contains(q) ?? false);
      return matchEstado && matchBusqueda;
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mascotas',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700, color: _dark)),
        centerTitle: true,
        actions: [
          Consumer<AdminController>(
            builder: (_, ctrl, __) => IconButton(
              tooltip: 'Recargar',
              icon: const Icon(Icons.refresh_rounded, color: _orange),
              onPressed: () => ctrl.cargarMascotas(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Buscador + filtros ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _busqueda = v),
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, especie o propietario…',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: _orange, size: 20),
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('Todos', 'todos', _orange),
                      const SizedBox(width: 8),
                      _chip('Propio', 'propio', _teal),
                      const SizedBox(width: 8),
                      _chip('Para adoptar', 'para adoptar', _green),
                      const SizedBox(width: 8),
                      _chip('Adoptado', 'adoptado', _blue),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Lista ───────────────────────────────────────────────────────
          Expanded(
            child: Consumer<AdminController>(
              builder: (ctx, ctrl, _) {
                if (ctrl.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator(color: _orange));
                }
                final lista = _filtrar(ctrl.mascotas);
                if (lista.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets_rounded,
                            size: 56, color: _grey.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('Sin resultados',
                            style:
                                GoogleFonts.poppins(color: _grey, fontSize: 15)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: _orange,
                  onRefresh: () => ctrl.cargarMascotas(),
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _MascotaCard(mascota: lista[i], ctrl: ctrl),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String valor, Color color) {
    final sel = _filtroEstado == valor;
    return GestureDetector(
      onTap: () => setState(() => _filtroEstado = valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? color : _bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? color : Colors.grey.shade300, width: sel ? 0 : 1),
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

// ── Tarjeta de mascota ────────────────────────────────────────────────────────

class _MascotaCard extends StatelessWidget {
  final MascotaModel mascota;
  final AdminController ctrl;
  const _MascotaCard({required this.mascota, required this.ctrl});

  Color get _estadoColor {
    switch (mascota.estado.toLowerCase()) {
      case 'para adoptar':
        return _green;
      case 'adoptado':
        return _blue;
      default:
        return _teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Foto
            SafeNetworkAvatar(
              url: mascota.fotoUrl,
              size: 52,
              fallbackIcon: Icons.pets_rounded,
              fallbackColor: mascota.color,
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mascota.nombre,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _dark)),
                  Text('${mascota.especie} · ${mascota.raza}',
                      style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
                  if (mascota.propietarioNombre?.isNotEmpty == true)
                    Text('Dueño: ${mascota.propietarioNombre}',
                        style: GoogleFonts.poppins(fontSize: 10, color: _grey)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    _badge(mascota.estado, _estadoColor),
                    _badge('${mascota.edad} años', _orange),
                    _badge(mascota.genero, _grey),
                  ]),
                ],
              ),
            ),
            // Eliminar
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: _red, size: 20),
              onPressed: () => _confirmarEliminar(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar mascota',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _dark)),
        content: Text(
          '¿Eliminar a "${mascota.nombre}"? Esto también eliminará sus citas y solicitudes de adopción asociadas.',
          style: GoogleFonts.poppins(fontSize: 13, color: _grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: _grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child:
                Text('Eliminar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final exito = await ctrl.eliminarMascota(mascota.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(exito ? 'Mascota eliminada' : (ctrl.errorMessage ?? 'Error'),
          style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: exito ? _green : _red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
