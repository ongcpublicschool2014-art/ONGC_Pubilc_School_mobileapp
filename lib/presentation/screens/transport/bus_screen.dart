import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_ui.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/bus_info_model.dart';
import '../../providers/bus_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/app_icon_circle_button.dart';
import '../../widgets/common/breadcrumb_bar.dart';
import '../../widgets/common/desktop_detail_scaffold.dart';

/// School Bus: the child's route on a map (OpenStreetMap, no key), the
/// stops in pickup order with the child's stop marked, and where the bus is
/// now. Refreshes every 20 seconds while open.
class BusScreen extends ConsumerStatefulWidget {
  const BusScreen({super.key, this.showTiles = true});

  /// False in tests: the map is drawn without its background tiles.
  final bool showTiles;

  @override
  ConsumerState<BusScreen> createState() => _BusScreenState();
}

class _BusScreenState extends ConsumerState<BusScreen> {
  static const _refreshEvery = Duration(seconds: 20);
  Timer? _timer;
  int? _scheduleId; // the trip shown; null = the one for the time of day
  final _map = MapController();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_refreshEvery, (_) {
      if (mounted) ref.invalidate(busInfoProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(busInfoProvider);
    return DesktopDetailScaffold(
      isNested: true,
      header: Column(children: [
        const SizedBox(height: 16),
        _header(context, async.isLoading),
        const SizedBox(height: 16),
      ]),
      toolbar: const BreadcrumbBar(currentLabel: 'School Bus', currentIcon: 'bus'),
      body: async.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
        error: (e, _) => _message('info-circle', 'Could not load the bus', busErrorText(e),
            action: OutlinedButton(onPressed: () => ref.invalidate(busInfoProvider), child: const Text('Try again'))),
        data: (info) => _content(context, info),
      ),
    );
  }

  Widget _header(BuildContext context, bool loading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        AppIconCircleButton(
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
          icon: SvgPicture.asset('assets/icons/arrow-left.svg',
              width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
        ),
        Expanded(
          child: Text('School Bus',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimaryC(context))),
        ),
        AppIconCircleButton(
          onPressed: loading ? null : () => ref.invalidate(busInfoProvider),
          icon: const AppIcon('refresh', size: 20, color: Colors.white),
        ),
      ]),
    );
  }

  Widget _content(BuildContext context, BusInfo? info) {
    final student = ref.watch(selectedStudentProvider);
    final who = student?.name.trim().isNotEmpty == true ? student!.name.trim() : 'Your child';
    if (info == null) {
      return _message('bus', 'Sign in to see the bus', 'The bus map needs you to be signed in.');
    }
    if (!info.enabled) {
      return _message('bus', 'School transport is not available',
          'The school has not turned on transport in the app. For bus details, contact the school office.');
    }
    if (!info.enrolled) {
      return _message('bus', '$who does not use the school bus',
          'If this is wrong, please contact the school office.');
    }
    final trip = info.trips.where((t) => t.scheduleId == _scheduleId).firstOrNull ?? info.defaultTrip(DateTime.now());
    final desktop = context.isDesktop;
    return ListView(
      padding: EdgeInsets.fromLTRB(desktop ? 0 : AppUi.gutter, desktop ? 0 : 4, desktop ? 0 : AppUi.gutter, 28),
      children: [
        if (info.trips.length > 1) ...[
          _tripToggle(info, trip),
          const SizedBox(height: 14),
        ],
        _mapCard(info, trip, height: desktop ? 460 : 330),
        const SizedBox(height: 14),
        _statusCard(info, trip),
        const SizedBox(height: 14),
        _stopsCard(info, trip),
      ],
    );
  }

  // ── trip toggle ────────────────────────────────────────────────────────
  Widget _tripToggle(BusInfo info, BusTrip? shown) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppUi.fill, borderRadius: BorderRadius.circular(AppUi.controlRadius + 2)),
      child: Row(children: [
        for (final t in info.trips)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _scheduleId = t.scheduleId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: t.scheduleId == shown?.scheduleId ? AppUi.navy : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppUi.controlRadius),
                ),
                child: Text(
                  '${t.label}${t.plannedStart.isEmpty ? '' : ' · ${_time(t.plannedStart)}'}',
                  textAlign: TextAlign.center,
                  style: AppFonts.body(
                    size: 14.5,
                    weight: FontWeight.w600,
                    color: t.scheduleId == shown?.scheduleId ? AppColors.onPrimary : AppUi.inkMuted,
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  // ── map ────────────────────────────────────────────────────────────────
  Widget _mapCard(BusInfo info, BusTrip? trip, {required double height}) {
    final stops = info.mappedStops;
    final live = trip?.live;
    final busOn = live != null && (live.lat.abs() < 85) && !(live.lat == 0 && live.lon == 0);
    final points = [
      for (final s in stops) LatLng(s.lat!, s.lon!),
      if (busOn) LatLng(live.lat, live.lon),
    ];
    if (points.isEmpty) {
      return Container(
        height: 140,
        decoration: AppUi.cardBox(),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Text('The stops of this route are not on the map yet. The school can add their positions.',
            textAlign: TextAlign.center, style: AppFonts.body(size: 14, color: AppUi.inkMuted)),
      );
    }
    final isLive = busOn && live.isLive(info.serverNow);
    final fit = points.length == 1
        ? null
        : CameraFit.bounds(bounds: LatLngBounds.fromPoints(points), padding: const EdgeInsets.all(44), maxZoom: 16);
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: AppUi.cardBox(),
      child: Stack(children: [
        FlutterMap(
          // a new trip fits the camera again; a refresh leaves it where it is
          key: ValueKey('bus-map-${trip?.scheduleId}'),
          mapController: _map,
          options: MapOptions(
            initialCameraFit: fit,
            initialCenter: points.first,
            initialZoom: 15,
            backgroundColor: AppUi.fill,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            if (widget.showTiles)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.school_fees_app',
              ),
            if (stops.length > 1)
              PolylineLayer(polylines: [
                Polyline(
                  points: [for (final s in stops) LatLng(s.lat!, s.lon!)],
                  strokeWidth: 4,
                  color: AppUi.navy.withValues(alpha: 0.75),
                ),
              ]),
            MarkerLayer(markers: [
              for (var i = 0; i < stops.length; i++)
                if (!stops[i].isChildStop)
                  Marker(
                    point: LatLng(stops[i].lat!, stops[i].lon!),
                    width: 24,
                    height: 24,
                    child: _stopDot(i + 1, next: stops[i].stopId == trip?.nextStopId),
                  ),
              // the child's own stop on top of the others
              for (final s in stops)
                if (s.isChildStop)
                  Marker(
                    point: LatLng(s.lat!, s.lon!),
                    width: 34,
                    height: 34,
                    alignment: Alignment.topCenter,
                    child: Tooltip(message: 'Your stop: ${s.name}', child: _childPin()),
                  ),
              if (busOn)
                Marker(
                  point: LatLng(live.lat, live.lon),
                  width: 42,
                  height: 42,
                  child: Tooltip(
                    message: isLive ? 'The bus is here' : 'The bus was last here',
                    child: _busMarker(isLive),
                  ),
                ),
            ]),
            if (widget.showTiles)
              const SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
          ],
        ),
        Positioned(
          right: 10,
          top: 10,
          child: Column(children: [
            if (busOn)
              _mapButton('bus', 'Show the bus', () => _map.move(LatLng(live.lat, live.lon), 16)),
            if (busOn && fit != null) const SizedBox(height: 8),
            if (fit != null) _mapButton('routing', 'Show the whole route', () => _map.fitCamera(fit)),
          ]),
        ),
      ]),
    );
  }

  Widget _mapButton(String icon, String tip, VoidCallback onTap) => Tooltip(
        message: tip,
        child: Material(
          color: AppColors.card,
          shape: const CircleBorder(side: BorderSide(color: AppUi.line)),
          elevation: 2,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(9), child: AppIcon(icon, size: 20, color: AppUi.navy, bold: true)),
          ),
        ),
      );

  Widget _stopDot(int n, {bool next = false}) => Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: next ? AppUi.navy : AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppUi.navy, width: 2),
        ),
        child: Text('$n',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: next ? AppColors.onPrimary : AppUi.navy)),
      );

  Widget _childPin() => Container(
        decoration: BoxDecoration(
          color: AppUi.marigold,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        alignment: Alignment.center,
        child: const AppIcon('location', size: 16, color: Colors.white, bold: true),
      );

  Widget _busMarker(bool live) => Container(
        decoration: BoxDecoration(
          color: live ? AppUi.navy : AppUi.inkFaint,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        alignment: Alignment.center,
        child: const AppIcon('bus', size: 20, color: Colors.white, bold: true),
      );

  // ── status ─────────────────────────────────────────────────────────────
  Widget _statusCard(BusInfo info, BusTrip? trip) {
    final live = trip?.live;
    final isLive = live != null && live.isLive(info.serverNow);
    final (dot, line) = switch ((trip, live)) {
      (null, _) => (AppUi.inkFaint, 'No bus trip is set for your child yet.'),
      (_, null) => (AppUi.inkFaint, 'The bus has not shared its location yet.'),
      _ when isLive => (
          AppColors.success,
          'Live · updated ${_ago(live.age(info.serverNow))}'
              '${live.speedKmph != null && live.speedKmph! >= 1 ? ' · ${live.speedKmph!.round()} km/h' : ''}'
        ),
      _ => (AppUi.marigold, 'Last seen ${_ago(live!.age(info.serverNow))}. Not sharing its location now.'),
    };
    final vehicle = [
      if (trip?.registrationNo.isNotEmpty == true) trip!.registrationNo,
      if (trip?.vehicleCode.isNotEmpty == true) trip!.vehicleCode,
    ].join(' · ');
    final childStop = info.stopById(trip?.isDrop == true ? info.dropStopId : info.pickupStopId) ??
        info.stopById(info.pickupStopId ?? info.dropStopId);
    final next = info.stopById(trip?.nextStopId);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppUi.cardBox(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppUi.paidBg, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const AppIcon('bus', size: 22, color: AppUi.navy, bold: true),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(vehicle.isEmpty ? 'School bus' : vehicle,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.body(size: 16, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Route ${info.routeCode}${info.routeName.isEmpty ? '' : ' · ${info.routeName}'}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.body(size: 13.5, color: AppUi.inkMuted)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(width: 9, height: 9, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(line, style: AppFonts.body(size: 14.5, weight: FontWeight.w600))),
        ]),
        if (trip != null) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppUi.lineSoft),
          const SizedBox(height: 12),
          _fact('clock', '${trip.label} trip',
              '${_time(trip.plannedStart)}${trip.plannedEnd.isEmpty ? '' : ' – ${_time(trip.plannedEnd)}'} · ${_today(trip)}'),
          if (next != null) _fact('routing', 'Next stop', next.name),
          if (childStop != null)
            _fact('location', 'Your stop', '${childStop.name}${childStop.landmark.isEmpty ? '' : ' (${childStop.landmark})'}'),
        ],
      ]),
    );
  }

  Widget _fact(String icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppIcon(icon, size: 18, color: AppUi.inkFaint),
          const SizedBox(width: 10),
          SizedBox(width: 92, child: Text(label, style: AppFonts.body(size: 13.5, color: AppUi.inkMuted))),
          Expanded(child: Text(value, style: AppFonts.body(size: 14, weight: FontWeight.w600))),
        ]),
      );

  // ── stops ──────────────────────────────────────────────────────────────
  Widget _stopsCard(BusInfo info, BusTrip? trip) {
    return Container(
      decoration: AppUi.cardBox(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Stops', style: AppFonts.body(size: 16, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('${info.stops.length} ${info.stops.length == 1 ? 'stop' : 'stops'} in pickup order',
            style: AppFonts.body(size: 13, color: AppUi.inkMuted)),
        const SizedBox(height: 10),
        for (var i = 0; i < info.stops.length; i++) _stopRow(info.stops[i], i + 1, last: i == info.stops.length - 1, trip: trip),
      ]),
    );
  }

  Widget _stopRow(BusStop s, int n, {required bool last, BusTrip? trip}) {
    final next = s.stopId == trip?.nextStopId;
    final mine = s.isChildStop;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 28,
          child: Column(children: [
            const SizedBox(height: 10),
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: mine ? AppUi.marigold : (next ? AppUi.navy : AppColors.card),
                shape: BoxShape.circle,
                border: Border.all(color: mine ? AppUi.marigold : AppUi.navy, width: 2),
              ),
              child: Text('$n',
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mine || next ? Colors.white : AppUi.navy)),
            ),
            if (!last) Expanded(child: Container(width: 2, color: AppUi.line)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(s.name, style: AppFonts.body(size: 14.5, weight: mine ? FontWeight.w700 : FontWeight.w600)),
                if (s.isPickup && s.isDrop)
                  _chip('Your stop', AppUi.dueBg, AppUi.dueInk)
                else if (s.isPickup)
                  _chip('Your pickup', AppUi.dueBg, AppUi.dueInk)
                else if (s.isDrop)
                  _chip('Your drop', AppUi.dueBg, AppUi.dueInk),
                if (next) _chip('Next', AppUi.paidBg, AppUi.paidInk),
              ]),
              if (s.landmark.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(s.landmark, style: AppFonts.body(size: 13, color: AppUi.inkMuted)),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: AppFonts.body(size: 11.5, weight: FontWeight.w700, color: fg)),
      );

  // ── shared ─────────────────────────────────────────────────────────────
  Widget _message(String icon, String title, String why, {Widget? action}) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: AppUi.paidBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: AppIcon(icon, size: 40, color: AppUi.navy),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: AppFonts.body(size: 17, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(why, textAlign: TextAlign.center, style: AppFonts.body(size: 14.5, color: AppUi.inkMuted)),
            if (action != null) ...[const SizedBox(height: 18), action],
          ]),
        ),
      );

  /// "07:05" -> "7:05 AM".
  static String _time(String hhmm) {
    final p = hhmm.split(':');
    if (p.length < 2) return hhmm;
    final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
    if (h == null || m == null) return hhmm;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
  }

  static String _ago(Duration d) {
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${d.inDays} ${d.inDays == 1 ? 'day' : 'days'} ago';
  }

  static String _today(BusTrip t) {
    if (!t.runsToday) return 'no trip today';
    return switch (t.tripStatus) {
      'IN_PROGRESS' => 'on the way now',
      'COMPLETED' => 'done for today',
      'CANCELLED' || 'ABORTED' => 'cancelled today',
      _ => 'today',
    };
  }
}
