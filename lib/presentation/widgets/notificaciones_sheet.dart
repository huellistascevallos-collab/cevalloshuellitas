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
const _teal    = Color(0xFF2FA3A3);
const _orange  = Color(0xFFE58D57);
const _green   = Color(0xFF43B89C);
const _red     = Color(0xFFE53935);
const _purple  = Color(0xFF7C6FCD);

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

  // Tabs: Todas · Urgencias · Adopciones · Citas · Recordatorios
  static const _cats = ['Todas', 'Urgencias', 'Adopciones', 'Citas', 'Recordatorios'];
  static const _catIcons = [
    Icons.notifications_rounded,
    Icons.emergency_rounded,
    Icons.volunteer_activism_rounded,
    Icons.calendar_month_rounded,
    Icons.alarm_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _cats.length, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<NotificacionModel> _combinar(
      List<NotificacionModel> citas, List<SolicitudAdopcionModel> adopciones,
      List<SolicitudAdopcionModel> todasRecibidas) {
    // IDs de solicitudes aún no leídas (en la lista de pendientes)
    final pendientesIds = adopciones.map((s) => s.id).toSet();

    // Usar todas las recibidas para el historial, marcando leídas las vistas
    final adopNotifs = todasRecibidas.map((s) => NotificacionModel(
      id: 'adopcion_${s.id}',
      tipo: TipoNotificacion.solicitudAdopcion,
      titulo: 'Solicitud de adopción',
      cuerpo: '${s.usuarioNombre ?? "Alguien"} quiere adoptar a ${s.mascotaNombre ?? "tu mascota"}.',
      mascotaNombre: s.mascotaNombre,
      creadaEn: s.fecha,           // usar la fecha real de la solicitud
      solicitanteId: s.usuaId,
      solicitanteNombre: s.usuarioNombre,
      solicitanteCorreo: s.usuarioCorreo,
      solicitanteTelefono: s.usuarioTelefono,
      solicitanteFotoUrl: s.usuarioFotoUrl,
      leida: !pendientesIds.contains(s.id),
    )).toList();

    final combinado = [...citas, ...adopNotifs];
    combinado.sort((a, b) => b.creadaEn.compareTo(a.creadaEn));
    return combinado;
  }

  List<NotificacionModel> _filtrar(List<NotificacionModel> lista) {
    switch (_tab.index) {
      case 0: return lista;
      case 1: return lista.where((n) => n.tipo == TipoNotificacion.urgencia).toList();
      case 2: return lista.where((n) => n.tipo == TipoNotificacion.solicitudAdopcion).toList();
      case 3: return lista.where((n) =>
        n.tipo == TipoNotificacion.nuevaCita ||
        n.tipo == TipoNotificacion.citaConfirmada ||
        n.tipo == TipoNotificacion.citaRechazada ||
        n.tipo == TipoNotificacion.citaPendiente).toList();
      case 4: return lista.where((n) =>
        n.tipo == TipoNotificacion.recordatorio30min ||
        n.tipo == TipoNotificacion.recordatorioAhora).toList();
      default: return lista;
    }
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
            solicCtrl.solicitudesRecibidas.toList(),
          );
          final noLeidas = todas.where((n) => !n.leida).length;
          final lista = _filtrar(todas);
          // Ambas sublistas ordenadas más reciente primero
          final urgentes = lista
              .where((n) => n.prioridad == PrioridadNotificacion.alta && !n.leida)
              .toList()
            ..sort((a, b) => b.creadaEn.compareTo(a.creadaEn));
          final resto = lista
              .where((n) => !(n.prioridad == PrioridadNotificacion.alta && !n.leida))
              .toList()
            ..sort((a, b) => b.creadaEn.compareTo(a.creadaEn));

          return Column(children: [
            const SizedBox(height: 12),
            // Handle
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 16),
            _buildCabecera(ctx, citaCtrl, solicCtrl, todas, noLeidas),
            const SizedBox(height: 16),
            _buildTabs(todas),
            const SizedBox(height: 4),
            const Divider(height: 1, color: _divider),
            Expanded(
              child: lista.isEmpty
                  ? _EmptyState(tabIndex: _tab.index)
                  : ListView(
                      controller: widget.sc,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                      children: [
                        if (_tab.index == 0 && urgentes.isNotEmpty) ...[
                          _SectionHeader(
                            label: 'Requieren atención',
                            icon: Icons.priority_high_rounded,
                            color: _red,
                          ),
                          ...urgentes.map((n) => _NotifCard(
                              notif: n, citaCtrl: citaCtrl,
                              solicCtrl: solicCtrl, destacada: true)),
                          if (resto.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _SectionHeader(
                              label: 'Anteriores',
                              icon: Icons.history_rounded,
                              color: Colors.grey.shade400,
                            ),
                          ],
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
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Ícono con gradiente
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2FA3A3), Color(0xFF1A7A7A)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: _teal.withValues(alpha: 0.35),
              blurRadius: 12, offset: const Offset(0, 4),
            )],
          ),
          child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Notificaciones', style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: _dark, letterSpacing: -0.3)),
          if (noLeidas > 0)
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$noLeidas sin leer', style: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w600, color: _teal)),
              ),
            ])
          else
            Text('Todo al día ✓', style: GoogleFonts.poppins(
                fontSize: 11, color: _green, fontWeight: FontWeight.w600)),
        ])),
        // Acciones
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (noLeidas > 0)
            _ActionBtn(
              label: 'Leer todo',
              icon: Icons.done_all_rounded,
              color: _green,
              onTap: () {
                HapticFeedback.lightImpact();
                for (final n in todas.where((n) => !n.leida)) {
                  if (n.tipo == TipoNotificacion.solicitudAdopcion) {
                    final soliId = n.id.replaceFirst('adopcion_', '');
                    solicCtrl.marcarNotificacionVista(soliId);
                  } else {
                    citaCtrl.marcarNotificacionVista(n.id);
                  }
                }
              },
            ),
          if (todas.isNotEmpty) ...[
            const SizedBox(height: 4),
            _ActionBtn(
              label: 'Limpiar',
              icon: Icons.delete_sweep_rounded,
              color: Colors.grey.shade500,
              onTap: () {
                HapticFeedback.lightImpact();
                citaCtrl.limpiarNotificaciones();
                solicCtrl.limpiarNotificaciones();
                widget.onClose();
              },
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _buildTabs(List<NotificacionModel> todas) {
    final counts = [
      todas.where((n) => !n.leida).length,
      todas.where((n) => !n.leida && n.tipo == TipoNotificacion.urgencia).length,
      todas.where((n) => !n.leida && n.tipo == TipoNotificacion.solicitudAdopcion).length,
      todas.where((n) => !n.leida && (
        n.tipo == TipoNotificacion.nuevaCita ||
        n.tipo == TipoNotificacion.citaConfirmada ||
        n.tipo == TipoNotificacion.citaRechazada ||
        n.tipo == TipoNotificacion.citaPendiente)).length,
      todas.where((n) => !n.leida && (
        n.tipo == TipoNotificacion.recordatorio30min ||
        n.tipo == TipoNotificacion.recordatorioAhora)).length,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tab,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: _teal,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade400,
        labelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
        padding: EdgeInsets.zero,
        tabs: List.generate(_cats.length, (i) {
          return Tab(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_catIcons[i], size: 14),
                const SizedBox(width: 5),
                Text(_cats[i]),
                if (counts[i] > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: _tab.index == i
                          ? Colors.white.withValues(alpha: 0.3)
                          : _teal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${counts[i]}', style: TextStyle(
                        color: _tab.index == i ? Colors.white : Colors.white,
                        fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
            ),
          );
        }),
      ),
    );
  }
}

// ── Botón de acción compacto ──────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}

// ── Encabezado de sección ─────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionHeader({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: color, letterSpacing: 0.1)),
      ]),
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final int tabIndex;
  const _EmptyState({required this.tabIndex});

  static const _msgs = [
    ('Sin notificaciones', 'Aquí verás tus citas,\nrecordatorios y adopciones.'),
    ('Sin urgencias', 'No hay urgencias activas.\nTodo tranquilo por ahora.'),
    ('Sin solicitudes', 'Aún no tienes solicitudes\nde adopción pendientes.'),
    ('Sin citas', 'Aquí aparecerán tus citas\ny sus actualizaciones.'),
    ('Sin recordatorios', 'No tienes recordatorios\npendientes por ahora.'),
  ];

  static const _emptyIcons = [
    Icons.notifications_none_rounded,
    Icons.emergency_outlined,
    Icons.volunteer_activism_outlined,
    Icons.calendar_today_outlined,
    Icons.alarm_off_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final idx = tabIndex.clamp(0, _msgs.length - 1);
    final (title, subtitle) = _msgs[idx];
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 86, height: 86,
          decoration: BoxDecoration(
            color: _teal.withValues(alpha: 0.07),
            shape: BoxShape.circle,
          ),
          child: Icon(_emptyIcons[idx], size: 40, color: _teal.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 18),
        Text(title, style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: Colors.grey.shade500)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.grey.shade400, height: 1.5)),
      ]),
    );
  }
}

// ── Tarjeta individual de notificación ────────────────────────────────────────
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
    TipoNotificacion.citaPendiente:      Icons.hourglass_empty_rounded,
    TipoNotificacion.recordatorio30min:  Icons.timer_rounded,
    TipoNotificacion.recordatorioAhora:  Icons.alarm_rounded,
    TipoNotificacion.solicitudAdopcion:  Icons.volunteer_activism_rounded,
    TipoNotificacion.urgencia:           Icons.emergency_rounded,
  };

  static const Map<TipoNotificacion, String> _etiquetas = {
    TipoNotificacion.nuevaCita:          'Cita nueva',
    TipoNotificacion.citaConfirmada:     'Confirmada ✓',
    TipoNotificacion.citaRechazada:      'Rechazada',
    TipoNotificacion.citaPendiente:      'En espera ⏳',
    TipoNotificacion.recordatorio30min:  'En 30 min',
    TipoNotificacion.recordatorioAhora:  '¡Ahora!',
    TipoNotificacion.solicitudAdopcion:  'Adopción',
    TipoNotificacion.urgencia:           '🚨 Urgencia',
  };

  void _eliminar() {
    HapticFeedback.lightImpact();
    if (notif.tipo == TipoNotificacion.solicitudAdopcion) {
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

  void _abrirDetalle(BuildContext context) {
    HapticFeedback.selectionClick();
    if (!notif.leida) {
      if (notif.tipo == TipoNotificacion.solicitudAdopcion) {
        final soliId = notif.id.replaceFirst('adopcion_', '');
        solicCtrl.marcarNotificacionVista(soliId);
      } else {
        citaCtrl.marcarNotificacionVista(notif.id);
      }
    }
    // Para adopciones: abrir perfil del solicitante
    if (_esAdopcion && notif.tieneSolicitante) {
      _mostrarPerfilSolicitante(context, notif);
    }
    // Para citas: las acciones están directamente en la tarjeta,
    // no se necesita sheet adicional.
  }

  // Determina si es tarjeta de adopción o de cita para diseño diferenciado
  bool get _esAdopcion => notif.tipo == TipoNotificacion.solicitudAdopcion;
  bool get _esCita => !_esAdopcion && notif.tipo != TipoNotificacion.urgencia;
  bool get _esUrgencia => notif.tipo == TipoNotificacion.urgencia;

  @override
  Widget build(BuildContext context) {
    final color    = Color(notif.colorValue);
    final icon     = _icons[notif.tipo] ?? Icons.notifications_rounded;
    final etiqueta = _etiquetas[notif.tipo] ?? '';
    final leida    = notif.leida;

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _eliminar(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _red.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 24),
          SizedBox(height: 3),
          Text('Eliminar', style: TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
      child: GestureDetector(
        onTap: () => _abrirDetalle(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: leida ? Colors.white : color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: leida
                  ? _divider
                  : color.withValues(alpha: destacada ? 0.45 : 0.22),
              width: destacada && !leida ? 1.8 : 1.0,
            ),
            boxShadow: leida
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6, offset: const Offset(0, 2))]
                : [BoxShadow(color: color.withValues(alpha: 0.1),
                    blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Cabecera de la tarjeta ──────────────────────────────────
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Ícono con badge de urgencia
                Stack(children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: leida ? 0.07 : 0.15),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon,
                        color: leida ? color.withValues(alpha: 0.4) : color,
                        size: 24),
                  ),
                  if (destacada && !leida)
                    Positioned(right: -1, top: -1,
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: _red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ]),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Título + etiqueta
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Text(notif.titulo, style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: leida ? FontWeight.w500 : FontWeight.w700,
                          color: leida ? Colors.grey.shade500 : _dark,
                          height: 1.3)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: leida
                            ? Colors.grey.shade100
                            : color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(etiqueta, style: GoogleFonts.poppins(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: leida ? Colors.grey.shade400 : color)),
                    ),
                  ]),
                  const SizedBox(height: 5),
                  // Cuerpo
                  Text(notif.cuerpo, style: GoogleFonts.poppins(
                      fontSize: 12, height: 1.45,
                      color: leida ? Colors.grey.shade400 : Colors.grey.shade700)),
                ])),
              ]),

              // ── Footer con chips de info ────────────────────────────────
              const SizedBox(height: 10),
              Row(children: [
                // Chip mascota
                if (notif.mascotaNombre != null)
                  _InfoChip(
                    icon: Icons.pets_rounded,
                    label: notif.mascotaNombre!,
                    color: leida ? Colors.grey.shade300 : color,
                  ),
                // Chip fecha/hora (solo citas)
                if (_esCita && notif.fecha != null && notif.hora != null) ...[
                  if (notif.mascotaNombre != null) const SizedBox(width: 6),
                  _InfoChip(
                    icon: Icons.access_time_rounded,
                    label: '${notif.fecha!.split('-').reversed.join('/')} · ${notif.hora}',
                    color: leida ? Colors.grey.shade300 : Colors.grey.shade500,
                  ),
                ],
                const Spacer(),
                // Tiempo relativo
                Text(notif.tiempoRelativo, style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: leida ? Colors.grey.shade300 : Colors.grey.shade400)),
                if (!leida) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ],
              ]),

              // ── Botón "Ver perfil del solicitante" (solo adopciones) ────
              if (_esAdopcion && notif.tieneSolicitante) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: _divider),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _mostrarPerfilSolicitante(context, notif),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _orange.withValues(alpha: 0.08),
                          _orange.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _orange.withValues(alpha: 0.25)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.person_rounded, size: 16, color: _orange),
                      const SizedBox(width: 7),
                      Text('Ver perfil del solicitante',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: _orange)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 10, color: _orange),
                    ]),
                  ),
                ),
              ],

              // ── Botones Confirmar / Rechazar (solo nueva cita para veterinario) ──
              if (notif.tipo == TipoNotificacion.nuevaCita && notif.citaId != null && !leida) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: _divider),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await citaCtrl.actualizarEstado(notif.citaId!, 'rechazada');
                        citaCtrl.marcarNotificacionVista(notif.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _red.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _red.withValues(alpha: 0.25)),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.close_rounded, size: 15, color: _red),
                          const SizedBox(width: 5),
                          Text('Rechazar', style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w700, color: _red)),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await citaCtrl.actualizarEstado(notif.citaId!, 'confirmada');
                        citaCtrl.marcarNotificacionVista(notif.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _green.withValues(alpha: 0.25)),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.check_rounded, size: 15, color: _green),
                          const SizedBox(width: 5),
                          Text('Confirmar', style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w700, color: _green)),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ],

              // ── Botones Aceptar / Rechazar urgencia ──────────────────────
              if (_esUrgencia && notif.citaId != null && !leida) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: _divider),
                const SizedBox(height: 10),
                // Banner rojo de urgencia
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C).withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFB71C1C).withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.crisis_alert_rounded,
                        color: Color(0xFFB71C1C), size: 14),
                    const SizedBox(width: 6),
                    Text('Urgencia crítica — respuesta inmediata',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB71C1C))),
                  ]),
                ),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await citaCtrl.actualizarEstado(
                            notif.citaId!, 'rechazada');
                        citaCtrl.marcarNotificacionVista(notif.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          const Icon(Icons.close_rounded,
                              size: 15, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text('Rechazar',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600)),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        HapticFeedback.heavyImpact();
                        await citaCtrl.actualizarEstado(
                            notif.citaId!, 'confirmada');
                        citaCtrl.marcarNotificacionVista(notif.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB71C1C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          const Icon(Icons.emergency_rounded,
                              size: 15, color: Colors.white),
                          const SizedBox(width: 5),
                          Text('Aceptar',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ]),
                      ),
                    ),
                  ),
                ]),
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

// ── Chip de información pequeño ───────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
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
      final userData = await Supabase.instance.client
          .from('usuarios')
          .select('usua_telefono, usua_foto_url')
          .eq('usua_id', uid)
          .maybeSingle();

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
    final notif  = widget.notif;
    final nombre = notif.solicitanteNombre ?? 'Solicitante';
    final correo = notif.solicitanteCorreo ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 20),
        // Título
        Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded, color: _orange, size: 22),
          ),
          const SizedBox(width: 12),
          Text('Perfil del solicitante', style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w800, color: _dark)),
        ]),
        const SizedBox(height: 24),

        if (_cargando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(color: _teal, strokeWidth: 2),
          )
        else ...[
          // Avatar
          Center(child: Stack(alignment: Alignment.bottomRight, children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _surface,
                border: Border.all(color: _teal.withValues(alpha: 0.3), width: 3),
              ),
              child: ClipOval(child: (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                  ? Image.network(_fotoUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person_rounded, size: 48, color: _teal))
                  : const Icon(Icons.person_rounded, size: 48, color: _teal)),
            ),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: _teal, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.volunteer_activism_rounded,
                  color: Colors.white, size: 14),
            ),
          ])),
          const SizedBox(height: 14),
          Center(child: Text(nombre, style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w800, color: _dark))),
          const SizedBox(height: 6),
          Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _totalAdopciones > 0
                  ? '$_totalAdopciones adopción${_totalAdopciones > 1 ? "es" : ""} previa${_totalAdopciones > 1 ? "s" : ""}'
                  : 'Primera solicitud de adopción',
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600, color: _teal)),
          )),
          const SizedBox(height: 22),
          _InfoRow(icon: Icons.email_outlined, label: 'Correo',
              value: correo.isNotEmpty ? correo : 'No registrado'),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.phone_outlined, label: 'Teléfono',
              value: (_telefono?.isNotEmpty == true) ? _telefono! : 'No registrado'),
          if (notif.mascotaNombre != null) ...[
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.pets_rounded, label: 'Quiere adoptar',
                value: notif.mascotaNombre!, valueColor: _orange),
          ],
          const SizedBox(height: 26),
          // Botones Rechazar / Aceptar adopción
          Consumer<SolicitudAdopcionController>(
            builder: (_, solicCtrl, __) {
              final soliId = notif.id.replaceFirst('adopcion_', '');
              return Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final ok = await solicCtrl.rechazarSolicitud(soliId);
                      if (context.mounted) Navigator.pop(context);
                      if (ok) solicCtrl.marcarNotificacionVista(soliId);
                    },
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text('Rechazar', style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: BorderSide(color: _red.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      // Buscar la solicitud completa en cualquier lista disponible
                      final SolicitudAdopcionModel? soli =
                          solicCtrl.notificacionesPendientes
                              .cast<SolicitudAdopcionModel?>()
                              .firstWhere((s) => s?.id == soliId, orElse: () => null) ??
                          solicCtrl.solicitudesRecibidas
                              .cast<SolicitudAdopcionModel?>()
                              .firstWhere((s) => s?.id == soliId, orElse: () => null);
                      if (soli == null) {
                        if (context.mounted) Navigator.pop(context);
                        return;
                      }
                      final ok = await solicCtrl.confirmarAdopcion(soli);
                      if (context.mounted) Navigator.pop(context);
                      if (ok) solicCtrl.marcarNotificacionVista(soliId);
                    },
                    icon: const Icon(Icons.favorite_rounded, size: 16),
                    label: Text('Aceptar', style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ]);
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar', style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 14,
                  color: Colors.grey.shade400)),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: _teal),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(
              fontSize: 10, color: Colors.grey.shade400,
              fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: valueColor ?? _dark)),
        ])),
      ]),
    );
  }
}
