import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/solicitud_adopcion_model.dart';
import '../../../domain/controllers/admin_controller.dart';

const _dark = Color(0xFF1A1F36);
const _grey = Color(0xFF8A9BB0);
const _bg = Color(0xFFF4F6FB);
const _green = Color(0xFF0E9F6E);
const _red = Color(0xFFE53935);
const _orange = Color(0xFFE58D57);
const _blue = Color(0xFF1A73E8);
const _pink = Color(0xFFE91E8C);
const _headerBg = Color(0xFF6B3A5E);

class AdminAdopcionesScreen extends StatefulWidget {
  const AdminAdopcionesScreen({super.key});

  @override
  State<AdminAdopcionesScreen> createState() => _AdminAdopcionesScreenState();
}

class _AdminAdopcionesScreenState extends State<AdminAdopcionesScreen> {
  final _searchCtrl = TextEditingController();
  String _busqueda = '';
  String _filtroEstado = 'todos';

  // Anchos de columna
  static const double _colFecha     = 110;
  static const double _colMascota   = 120;
  static const double _colEspecie   = 90;
  static const double _colRaza      = 110;
  static const double _colSolicitante = 140;
  static const double _colCorreo    = 170;
  static const double _colTelefono  = 110;
  static const double _colEstado    = 110;
  static const double _colAccion    = 56;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().cargarAdopciones();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SolicitudAdopcionModel> _filtrar(List<SolicitudAdopcionModel> todas) {
    return todas.where((s) {
      final matchEstado = _filtroEstado == 'todos' ||
          s.estado.toLowerCase() == _filtroEstado.toLowerCase();
      final q = _busqueda.toLowerCase();
      final matchBusqueda = q.isEmpty ||
          (s.mascotaNombre?.toLowerCase().contains(q) ?? false) ||
          (s.usuarioNombre?.toLowerCase().contains(q) ?? false) ||
          (s.usuarioCorreo?.toLowerCase().contains(q) ?? false) ||
          (s.mascotaEspecie?.toLowerCase().contains(q) ?? false) ||
          (s.mascotaRaza?.toLowerCase().contains(q) ?? false);
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _dark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Gestión de Adopciones',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700, color: _dark)),
        centerTitle: true,
        actions: [
          Consumer<AdminController>(
            builder: (_, ctrl, __) => IconButton(
              tooltip: 'Recargar',
              icon: const Icon(Icons.refresh_rounded, color: _pink),
              onPressed: () => ctrl.cargarAdopciones(),
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
                    hintText:
                        'Buscar por mascota, solicitante, correo o especie…',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: _pink, size: 20),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('Todos', 'todos', _pink),
                      const SizedBox(width: 8),
                      _chip('Pendiente', 'pendiente', _orange),
                      const SizedBox(width: 8),
                      _chip('Adoptado', 'adoptado', _green),
                      const SizedBox(width: 8),
                      _chip('Rechazada', 'rechazada', _red),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Tabla ───────────────────────────────────────────────────────
          Expanded(
            child: Consumer<AdminController>(
              builder: (ctx, ctrl, _) {
                if (ctrl.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator(color: _pink));
                }
                final lista = _filtrar(ctrl.adopciones);

                return Column(
                  children: [
                    // Contador
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _pink.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${lista.length} solicitud${lista.length == 1 ? '' : 'es'}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _pink),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: lista.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.volunteer_activism_rounded,
                                      size: 56,
                                      color: _grey.withValues(alpha: 0.4)),
                                  const SizedBox(height: 12),
                                  Text('Sin resultados',
                                      style: GoogleFonts.poppins(
                                          color: _grey, fontSize: 15)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              color: _pink,
                              onRefresh: () => ctrl.cargarAdopciones(),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Encabezado
                                      _TableHeader(),
                                      // Filas
                                      ...lista.asMap().entries.map((entry) {
                                        return _TableRow(
                                          solicitud: entry.value,
                                          ctrl: ctrl,
                                          isEven: entry.key.isEven,
                                        );
                                      }),
                                      const SizedBox(height: 40),
                                    ],
                                  ),
                                ),
                              ),
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

  Widget _chip(String label, String valor, Color color) {
    final sel = _filtroEstado == valor;
    return GestureDetector(
      onTap: () => setState(() => _filtroEstado = valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? color : _bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? color : Colors.grey.shade300,
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

// ── Encabezado ────────────────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _headerBg,
      child: Row(
        children: [
          _H('Fecha',       _AdminAdopcionesScreenState._colFecha),
          _D(),
          _H('Mascota',     _AdminAdopcionesScreenState._colMascota),
          _D(),
          _H('Especie',     _AdminAdopcionesScreenState._colEspecie),
          _D(),
          _H('Raza',        _AdminAdopcionesScreenState._colRaza),
          _D(),
          _H('Solicitante', _AdminAdopcionesScreenState._colSolicitante),
          _D(),
          _H('Correo',      _AdminAdopcionesScreenState._colCorreo),
          _D(),
          _H('Teléfono',    _AdminAdopcionesScreenState._colTelefono),
          _D(),
          _H('Estado',      _AdminAdopcionesScreenState._colEstado),
          _D(),
          _H('',            _AdminAdopcionesScreenState._colAccion),
        ],
      ),
    );
  }
}

class _H extends StatelessWidget {
  final String label;
  final double width;
  const _H(this.label, this.width);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 44,
      child: Center(
        child: Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3)),
      ),
    );
  }
}

class _D extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 44,
        color: Colors.white.withValues(alpha: 0.15),
      );
}

// ── Fila ──────────────────────────────────────────────────────────────────────
class _TableRow extends StatelessWidget {
  final SolicitudAdopcionModel solicitud;
  final AdminController ctrl;
  final bool isEven;

  const _TableRow({
    required this.solicitud,
    required this.ctrl,
    required this.isEven,
  });

  Color get _estadoColor {
    switch (solicitud.estado.toLowerCase()) {
      case 'adoptado':
        return _green;
      case 'rechazada':
        return _red;
      default:
        return _orange;
    }
  }

  String _formatFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final rowColor = isEven ? Colors.white : const Color(0xFFFDF5FB);

    return Container(
      color: rowColor,
      child: Row(
        children: [
          // Fecha
          _Cell(
            width: _AdminAdopcionesScreenState._colFecha,
            child: Text(_formatFecha(solicitud.fecha),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 11, color: _dark)),
          ),
          _VD(),

          // Mascota
          _Cell(
            width: _AdminAdopcionesScreenState._colMascota,
            child: Row(children: [
              const Icon(Icons.pets_rounded, size: 12, color: _pink),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  solicitud.mascotaNombre ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _dark),
                ),
              ),
            ]),
          ),
          _VD(),

          // Especie
          _Cell(
            width: _AdminAdopcionesScreenState._colEspecie,
            child: Text(
              solicitud.mascotaEspecie ?? '—',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 11, color: _grey),
            ),
          ),
          _VD(),

          // Raza
          _Cell(
            width: _AdminAdopcionesScreenState._colRaza,
            child: Text(
              solicitud.mascotaRaza ?? '—',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 11, color: _grey),
            ),
          ),
          _VD(),

          // Solicitante
          _Cell(
            width: _AdminAdopcionesScreenState._colSolicitante,
            child: Row(children: [
              const Icon(Icons.person_outline_rounded,
                  size: 12, color: _blue),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  solicitud.usuarioNombre ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 11, color: _dark),
                ),
              ),
            ]),
          ),
          _VD(),

          // Correo
          _Cell(
            width: _AdminAdopcionesScreenState._colCorreo,
            child: Text(
              solicitud.usuarioCorreo ?? '—',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 11, color: _grey),
            ),
          ),
          _VD(),

          // Teléfono
          _Cell(
            width: _AdminAdopcionesScreenState._colTelefono,
            child: Row(children: [
              const Icon(Icons.phone_outlined, size: 12, color: _grey),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  solicitud.usuarioTelefono?.isNotEmpty == true
                      ? solicitud.usuarioTelefono!
                      : '—',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 11, color: _grey),
                ),
              ),
            ]),
          ),
          _VD(),

          // Estado
          _Cell(
            width: _AdminAdopcionesScreenState._colEstado,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _estadoColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _estadoColor.withValues(alpha: 0.4), width: 1),
                ),
                child: Text(
                  _capitalize(solicitud.estado),
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _estadoColor),
                ),
              ),
            ),
          ),
          _VD(),

          // Acción eliminar
          _Cell(
            width: _AdminAdopcionesScreenState._colAccion,
            child: Center(
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: _red, size: 18),
                onPressed: () => _confirmarEliminar(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar solicitud',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: _dark)),
        content: Text(
          '¿Eliminar la solicitud de "${solicitud.mascotaNombre ?? 'esta mascota'}"? Esta acción no se puede deshacer.',
          style: GoogleFonts.poppins(fontSize: 13, color: _grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Cancelar', style: GoogleFonts.poppins(color: _grey)),
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
    if (ok != true || !context.mounted) return;
    final exito = await ctrl.eliminarAdopcion(solicitud.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          exito
              ? 'Solicitud eliminada'
              : (ctrl.errorMessage ?? 'Error'),
          style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: exito ? _green : _red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────
class _Cell extends StatelessWidget {
  final double width;
  final Widget child;
  const _Cell({required this.width, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Align(alignment: Alignment.centerLeft, child: child),
      );
}

class _VD extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 48,
        color: const Color(0xFFE2E8F0),
      );
}
