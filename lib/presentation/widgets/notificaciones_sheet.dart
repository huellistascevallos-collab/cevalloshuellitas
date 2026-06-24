import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/notificacion_model.dart';
import '../../data/models/solicitud_adopcion_model.dart';
import '../../domain/controllers/cita_controller.dart';
import '../../domain/controllers/solicitud_adopcion_controller.dart';

// ── Paleta ────────────────────────────────────────────────────────────────────
const _dark    = Color(0xFF1A2035);
const _surface = Color(0xFFF7F9FC);
const _divider = Color(0xFFEEF1F6);
const _teal    = Color(0xFF1CB5C9);
const _orange  = Color(0xFFE58D57);

/// Sheet unificado de notificaciones (usuario y veterinario).
class NotificacionesSheet extends StatefulWidget {
  final ScrollController sc;
  final String rol;
  final VoidCallback onClose;

  const NotificacionesSheet({
    super.key,
    required this.sc,
    required this.rol,
    required this.onClose,
  });

  @override
  State<NotificacionesSheet> createState() => _NotificacionesSheetState();
}

class _NotificacionesSheetState extends State<NotificacionesSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  static const _categorias = ['Todas', 'Solicitudes', 'Confirmaciones', 'Recordatorios'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _categorias.length, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  /// Combina notificaciones de citas + solicitudes de adopción en una lista unificada
  List<NotificacionModel> _combinar(
      List<NotificacionModel> citas, List<SolicitudAdopcionModel> adopciones) {
    final adopNotifs = adopciones.map((s) => NotificacionModel(
      id: 'adopcion_${s.id}',
      tipo: TipoNotificacion.solicitudAdopcion,
      titulo: '🐾 Nueva solicitud de adopción',
      cuerpo: '${s.usuarioNombre ?? "Alguien"} quiere adoptar a ${s.mascotaNombre ?? "tu mascota"}.',
      mascotaNombre: s.mascotaNombre,
      solicitanteId: s.usuaId,
      solicitanteNombre: s.usuarioNombre,
      solicitanteCorreo: s.usuarioCorreo,
      solicitanteTelefono: s.usuarioTelefono,
      solicitanteFotoUrl: s.usuarioFotoUrl,
    )).toList();

    final combinado = [...citas, ...adopNotifs];
    combinado.sort((a, b) => b.creadaEn.compareTo(a.creadaEn));
    return combinado;
  }

  List<NotificacionModel> _filtrar(List<NotificacionModel> lista) {
    if (_tab.index == 0) return lista;
    final cat = _categorias[_tab.index];
    return lista.where((n) => n.categoria == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Consumer2<CitaController, SolicitudAdopcionController>(
        builder: (ctx, citaCtrl, solicCtrl, _) {
          final todas = _combinar(
            citaCtrl.notificaciones.toList(),
            solicCtrl.notificacionesPendientes.toList(),
          );
          final noLeidas = todas.where((n) => !n.leida).length;
          final lista = _filtrar(todas);
          final urgentes = lista
              .where((n) => n.prioridad == PrioridadNotificacion.alta && !n.leida)
              .toList();
          final resto = lista
              .where((n) => !(n.prioridad == PrioridadNotificacion.alta && !n.leida))
              .toList();

          return Column(children: [
            const SizedBox(height: 12),
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            _buildCabecera(ctx, citaCtrl, solicCtrl, todas, noLeidas),
            const SizedBox(height: 14),
            _buildTabs(todas, noLeidas),
            const SizedBox(height: 8),
            const Divider(height: 1, color: _divider),
            Expanded(
              child: lista.isEmpty
                  ? _EmptyState(categoria: _categorias[_tab.index])
                  : ListView(
                      controller: widget.sc,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        if (_tab.index == 0 && urgentes.isNotEmpty) ...[
                          _SectionLabel(label: '🔴  Requieren atención',
                              color: const Color(0xFFE53935)),
                          const SizedBox(height: 6),
                          ...urgentes.map((n) => _NotifCard(
                              notif: n, citaCtrl: citaCtrl,
                              solicCtrl: solicCtrl, destacada: true)),
                          const SizedBox(height: 12),
                          if (resto.isNotEmpty)
                            _SectionLabel(label: '📋  Anteriores',
                                color: Colors.grey.shade500),
                          const SizedBox(height: 6),
                          ...resto.map((n) => _NotifCard(
                              notif: n, citaCtrl: citaCtrl, solicCtrl: solicCtrl)),
                        ] else
                          ...lista.map((n) => _NotifCard(
                              notif: n, citaCtrl: citaCtrl, solicCtrl: solicCtrl)),
                      ],
                    ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _buildCabecera(BuildContext ctx, CitaController citaCtrl,
      SolicitudAdopcionController solicCtrl,
      List<NotificacionModel> todas, int noLeidas) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1CB5C9), Color(0xFF0D8FA8)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: _teal.withValues(alpha: 0.3),
              blurRadius: 10, offset: const Offset(0, 4),
            )],
          ),
          child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Notificaciones', style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: _dark, letterSpacing: -0.3)),
          if (noLeidas > 0)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$noLeidas sin leer', style: GoogleFonts.poppins(
                  fontSize: 10, fontWeight: FontWeight.w600, color: _teal)),
            )
          else
            Text('Todo al día', style: GoogleFonts.poppins(
                fontSize: 11, color: Colors.grey.shade400)),
        ])),
        if (noLeidas > 0) ...[
          _ActionChip(
            label: 'Leer todo', icon: Icons.done_all_rounded,
            color: const Color(0xFF43B89C),
            onTap: () {
              HapticFeedback.lightImpact();
              for (final n in todas.where((n) => !n.leida)) {
                citaCtrl.marcarNotificacionVista(n.id);
              }
              for (final s in solicCtrl.notificacionesPendientes.toList()) {
                solicCtrl.marcarNotificacionVista(s.id);
              }
            },
          ),
          const SizedBox(width: 6),
        ],
        if (todas.isNotEmpty)
          _ActionChip(
            label: 'Limpiar', icon: Icons.delete_sweep_rounded,
            color: Colors.grey.shade500,
            onTap: () {
              HapticFeedback.lightImpact();
              citaCtrl.limpiarNotificaciones();
              solicCtrl.limpiarNotificaciones();
              widget.onClose();
            },
          ),
      ]),
    );
  }

  Widget _buildTabs(List<NotificacionModel> todas, int noLeidas) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.all(3),
          indicator: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(9),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6, offset: const Offset(0, 2),
            )],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: _dark,
          unselectedLabelColor: Colors.grey.shade400,
          labelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
          tabs: _categorias.map((c) {
            final count = c == 'Todas'
                ? noLeidas
                : todas.where((n) => !n.leida && n.categoria == c).length;
            return Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(c),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: _teal, borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$count', style: const TextStyle(
                      color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ],
            ]));
          }).toList(),
        ),
      ),
    );
  }
}

// ── Chip de acción ────────────────────────────────────────────────────────────
class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip({required this.label, required this.icon,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}

// ── Etiqueta de sección ───────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(label, style: GoogleFonts.poppins(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: color, letterSpacing: 0.2)),
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String categoria;
  const _EmptyState({required this.categoria});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(color: _surface, shape: BoxShape.circle),
          child: Icon(Icons.notifications_none_rounded,
              size: 38, color: Colors.grey.shade300),
        ),
        const SizedBox(height: 16),
        Text(categoria == 'Todas' ? 'Sin notificaciones' : 'Sin $categoria',
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: Colors.grey.shade400)),
        const SizedBox(height: 6),
        Text('Aquí aparecerán tus citas,\nrecordatorios y actualizaciones.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade300)),
      ]),
    );
  }
}

// ── Tarjeta individual ────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final NotificacionModel notif;
  final CitaController citaCtrl;
  final SolicitudAdopcionController solicCtrl;
  final bool destacada;

  const _NotifCard({required this.notif, required this.citaCtrl,
      required this.solicCtrl, this.destacada = false});

  static const Map<TipoNotificacion, IconData> _icons = {
    TipoNotificacion.nuevaCita:          Icons.calendar_today_rounded,
    TipoNotificacion.citaConfirmada:     Icons.check_circle_rounded,
    TipoNotificacion.citaRechazada:      Icons.cancel_rounded,
    TipoNotificacion.recordatorio30min:  Icons.timer_rounded,
    TipoNotificacion.recordatorioAhora:  Icons.alarm_rounded,
    TipoNotificacion.solicitudAdopcion:  Icons.volunteer_activism_rounded,
  };

  static const Map<TipoNotificacion, String> _etiquetas = {
    TipoNotificacion.nuevaCita:          'Nueva solicitud',
    TipoNotificacion.citaConfirmada:     'Confirmada ✓',
    TipoNotificacion.citaRechazada:      'Rechazada',
    TipoNotificacion.recordatorio30min:  'En 30 min',
    TipoNotificacion.recordatorioAhora:  '¡Ahora!',
    TipoNotificacion.solicitudAdopcion:  'Adopción',
  };

  void _eliminar() {
    HapticFeedback.lightImpact();
    if (notif.tipo == TipoNotificacion.solicitudAdopcion) {
      // Extraer el id de la solicitud del id de notificación
      final soliId = notif.id.replaceFirst('adopcion_', '');
      solicCtrl.marcarNotificacionVista(soliId);
    } else {
      citaCtrl.eliminarNotificacion(notif.id);
    }
  }

  void _marcarLeida() {
    HapticFeedback.selectionClick();
    if (!notif.leida) citaCtrl.marcarNotificacionVista(notif.id);
  }

  @override
  Widget build(BuildContext context) {
    final color   = Color(notif.colorValue);
    final icon    = _icons[notif.tipo] ?? Icons.notifications_rounded;
    final etiqueta = _etiquetas[notif.tipo] ?? '';
    final leida   = notif.leida;
    final esAdopcion = notif.tipo == TipoNotificacion.solicitudAdopcion;

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _eliminar(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 22),
          SizedBox(height: 2),
          Text('Eliminar', style: TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
      child: GestureDetector(
        onTap: _marcarLeida,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: leida ? Colors.white : color.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: leida ? _divider : color.withValues(alpha: destacada ? 0.4 : 0.2),
              width: destacada && !leida ? 1.5 : 1.0,
            ),
            boxShadow: leida
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6, offset: const Offset(0, 2))]
                : [BoxShadow(color: color.withValues(alpha: 0.08),
                    blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Ícono
                Stack(children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: leida ? 0.07 : 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon,
                        color: leida ? color.withValues(alpha: 0.45) : color,
                        size: 22),
                  ),
                  if (destacada && !leida)
                    Positioned(right: 0, top: 0,
                      child: Container(width: 10, height: 10,
                        decoration: const BoxDecoration(
                            color: Color(0xFFE53935), shape: BoxShape.circle)),
                    ),
                ]),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(notif.titulo,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: leida ? FontWeight.w500 : FontWeight.w700,
                            color: leida ? Colors.grey.shade500 : _dark))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: leida ? Colors.grey.shade100 : color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(etiqueta, style: GoogleFonts.poppins(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: leida ? Colors.grey.shade400 : color)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(notif.cuerpo, style: GoogleFonts.poppins(
                      fontSize: 12, height: 1.4,
                      color: leida ? Colors.grey.shade400 : Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  // Footer
                  Row(children: [
                    if (notif.mascotaNombre != null) ...[
                      Icon(Icons.pets_rounded, size: 11,
                          color: leida ? Colors.grey.shade300 : color.withValues(alpha: 0.6)),
                      const SizedBox(width: 3),
                      Text(notif.mascotaNombre!, style: GoogleFonts.poppins(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: leida ? Colors.grey.shade300 : color.withValues(alpha: 0.8))),
                      const SizedBox(width: 8),
                    ],
                    if (notif.fecha != null && notif.hora != null) ...[
                      Icon(Icons.access_time_rounded, size: 11,
                          color: leida ? Colors.grey.shade300 : Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text('${notif.fecha!.split('-').reversed.join('/')} · ${notif.hora}',
                          style: GoogleFonts.poppins(fontSize: 10,
                              color: leida ? Colors.grey.shade300 : Colors.grey.shade400)),
                    ],
                    const Spacer(),
                    Text(notif.tiempoRelativo, style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: leida ? Colors.grey.shade300 : Colors.grey.shade400)),
                    if (!leida) ...[
                      const SizedBox(width: 6),
                      Container(width: 7, height: 7,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    ],
                  ]),
                ])),
              ]),
              // ── Botón "Ver perfil del solicitante" ────────────────────────
              if (esAdopcion && notif.tieneSolicitante) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: _divider),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _mostrarPerfilSolicitante(context, notif),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _orange.withValues(alpha: 0.25)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.person_rounded, size: 15, color: _orange),
                      const SizedBox(width: 6),
                      Text('Ver perfil del solicitante',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w700, color: _orange)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _orange),
                    ]),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  void _mostrarPerfilSolicitante(BuildContext context, NotificacionModel notif) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PerfilSolicitanteSheet(notif: notif),
    );
  }
}

// ── Sheet de perfil del solicitante ──────────────────────────────────────────
class _PerfilSolicitanteSheet extends StatefulWidget {
  final NotificacionModel notif;
  const _PerfilSolicitanteSheet({required this.notif});

  @override
  State<_PerfilSolicitanteSheet> createState() => _PerfilSolicitanteSheetState();
}

class _PerfilSolicitanteSheetState extends State<_PerfilSolicitanteSheet> {
  String? _telefono;
  String? _fotoUrl;
  int _totalAdopciones = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final uid = widget.notif.solicitanteId;
    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _cargando = false);
      return;
    }
    try {
      // Cargar datos del usuario
      final userData = await Supabase.instance.client
          .from('usuarios')
          .select('usua_telefono, usua_foto_url')
          .eq('usua_id', uid)
          .maybeSingle();

      // Contar solicitudes previas aprobadas (adopciones completadas)
      final adoptadas = await Supabase.instance.client
          .from('solicitudes_adopcion')
          .select('soli_id')
          .eq('usua_id', uid)
          .eq('soli_estado', 'Adoptado');

      if (mounted) {
        setState(() {
          _telefono = widget.notif.solicitanteTelefono
              ?? userData?['usua_telefono'] as String?;
          _fotoUrl = widget.notif.solicitanteFotoUrl
              ?? userData?['usua_foto_url'] as String?;
          _totalAdopciones = (adoptadas as List).length;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notif = widget.notif;
    final nombre = notif.solicitanteNombre ?? 'Solicitante';
    final correo = notif.solicitanteCorreo ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),

        // Título
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person_rounded, color: _orange, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Perfil del solicitante', style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
        ]),
        const SizedBox(height: 20),

        if (_cargando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(color: _teal, strokeWidth: 2),
          )
        else ...[
          // Avatar
          Center(child: Stack(alignment: Alignment.bottomRight, children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF3F9FA),
                border: Border.all(color: _teal.withValues(alpha: 0.3), width: 2.5),
              ),
              child: ClipOval(
                child: (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                    ? Image.network(_fotoUrl!, fit: BoxFit.cover,
                        errorBuilder: (ctx2, err, stack) => const Icon(
                            Icons.person_rounded, size: 44, color: _teal))
                    : const Icon(Icons.person_rounded, size: 44, color: _teal),
              ),
            ),
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: _teal, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.volunteer_activism_rounded,
                  color: Colors.white, size: 13),
            ),
          ])),
          const SizedBox(height: 14),

          // Nombre
          Center(child: Text(nombre, style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w800, color: _dark))),
          const SizedBox(height: 4),
          // Chip adopciones previas
          Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _totalAdopciones > 0
                  ? '$_totalAdopciones adopción${_totalAdopciones > 1 ? "es" : ""} previa${_totalAdopciones > 1 ? "s" : ""}'
                  : 'Primera solicitud de adopción',
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600, color: _teal),
            ),
          )),
          const SizedBox(height: 20),

          // Datos de contacto
          _InfoRow(icon: Icons.email_outlined, label: 'Correo',
              value: correo.isNotEmpty ? correo : 'No registrado'),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.phone_outlined, label: 'Teléfono',
              value: (_telefono?.isNotEmpty == true) ? _telefono! : 'No registrado'),
          const SizedBox(height: 10),

          // Mascota que quiere adoptar
          if (notif.mascotaNombre != null)
            _InfoRow(
              icon: Icons.pets_rounded,
              label: 'Quiere adoptar',
              value: notif.mascotaNombre!,
              valueColor: _orange,
            ),
          const SizedBox(height: 24),

          // Botón cerrar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Cerrar', style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ]),
    );
  }
}

// ── Fila de información del perfil ────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.icon, required this.label,
      required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _teal),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(
              fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: valueColor ?? _dark)),
        ])),
      ]),
    );
  }
}
