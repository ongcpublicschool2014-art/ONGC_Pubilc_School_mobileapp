/// The School Bus map's data, from the server function `tr_parent_bus`
/// (transport module): the child's route with its stops in pickup order and
/// the child's trips (pickup / drop), each with its vehicle and the vehicle's
/// last position.
library;

double? _num(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
int? _int(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse('$v'));
String _str(dynamic v) => v == null ? '' : '$v'.trim();

class BusInfo {
  /// False when the school has switched Transport off.
  final bool enabled;

  /// False when the child has no active school transport.
  final bool enrolled;
  final String serviceType; // BOTH / PICKUP / DROP
  final String routeCode;
  final String routeName;
  final int? pickupStopId;
  final int? dropStopId;
  final List<BusStop> stops;
  final List<BusTrip> trips;

  /// The server's clock when it answered (for "updated ... ago").
  final DateTime? serverNow;

  const BusInfo({
    required this.enabled,
    required this.enrolled,
    this.serviceType = '',
    this.routeCode = '',
    this.routeName = '',
    this.pickupStopId,
    this.dropStopId,
    this.stops = const [],
    this.trips = const [],
    this.serverNow,
  });

  factory BusInfo.fromJson(Map<String, dynamic> j) {
    final route = (j['route'] as Map?)?.cast<String, dynamic>() ?? const {};
    return BusInfo(
      enabled: j['enabled'] != false,
      enrolled: j['enrolled'] == true,
      serviceType: _str(j['service_type']),
      routeCode: _str(route['code']),
      routeName: _str(route['name']),
      pickupStopId: _int(j['pickup_stop_id']),
      dropStopId: _int(j['drop_stop_id']),
      stops: [
        for (final s in (j['stops'] as List? ?? const []))
          BusStop.fromJson((s as Map).cast<String, dynamic>()),
      ],
      trips: [
        for (final t in (j['trips'] as List? ?? const []))
          BusTrip.fromJson((t as Map).cast<String, dynamic>()),
      ],
      serverNow: DateTime.tryParse(_str(j['now'])),
    );
  }

  /// The stops that have a usable position, in pickup order.
  List<BusStop> get mappedStops => [for (final s in stops) if (s.hasPosition) s];

  BusStop? stopById(int? id) {
    if (id == null) return null;
    for (final s in stops) {
      if (s.stopId == id) return s;
    }
    return null;
  }

  /// The trip to show first: the drop trip from midday on, else the pickup
  /// trip (whichever the child has).
  BusTrip? defaultTrip(DateTime now) {
    if (trips.isEmpty) return null;
    final afternoon = now.hour >= 12;
    for (final t in trips) {
      if (afternoon == t.isDrop) return t;
    }
    return trips.first;
  }
}

class BusStop {
  final int stopId;
  final String name;
  final String code;
  final String landmark;
  final int? seq;
  final int? stageNo;
  final double? lat;
  final double? lon;
  final bool isPickup;
  final bool isDrop;

  const BusStop({
    required this.stopId,
    required this.name,
    this.code = '',
    this.landmark = '',
    this.seq,
    this.stageNo,
    this.lat,
    this.lon,
    this.isPickup = false,
    this.isDrop = false,
  });

  factory BusStop.fromJson(Map<String, dynamic> j) => BusStop(
        stopId: _int(j['stop_id']) ?? 0,
        name: _str(j['name']),
        code: _str(j['code']),
        landmark: _str(j['landmark']),
        seq: _int(j['seq']),
        stageNo: _int(j['stage_no']),
        lat: _num(j['lat']),
        lon: _num(j['lon']),
        isPickup: j['pickup'] == true,
        isDrop: j['drop'] == true,
      );

  /// A real position on the map (not empty, not a 90 / 90 placeholder).
  bool get hasPosition =>
      lat != null && lon != null && lat!.abs() < 85 && lon!.abs() <= 180 && !(lat == 0 && lon == 0);

  bool get isChildStop => isPickup || isDrop;
}

class BusTrip {
  final int scheduleId;
  final String name;
  final String direction; // PICKUP / DROP
  final String plannedStart; // HH:MM
  final String plannedEnd;
  final bool runsToday;
  final String tripStatus; // today's trip: SCHEDULED / IN_PROGRESS / COMPLETED / CANCELLED, '' when none
  final int? nextStopId;
  final String vehicleCode;
  final String registrationNo;
  final BusLive? live;

  const BusTrip({
    required this.scheduleId,
    required this.name,
    required this.direction,
    this.plannedStart = '',
    this.plannedEnd = '',
    this.runsToday = true,
    this.tripStatus = '',
    this.nextStopId,
    this.vehicleCode = '',
    this.registrationNo = '',
    this.live,
  });

  factory BusTrip.fromJson(Map<String, dynamic> j) {
    final v = (j['vehicle'] as Map?)?.cast<String, dynamic>() ?? const {};
    final l = (j['live'] as Map?)?.cast<String, dynamic>();
    return BusTrip(
      scheduleId: _int(j['schedule_id']) ?? 0,
      name: _str(j['name']),
      direction: _str(j['direction']).toUpperCase(),
      plannedStart: _str(j['planned_start']),
      plannedEnd: _str(j['planned_end']),
      runsToday: j['runs_today'] != false,
      tripStatus: _str(j['trip_status']).toUpperCase(),
      nextStopId: _int(j['next_stop_id']),
      vehicleCode: _str(v['code']),
      registrationNo: _str(v['registration_no']),
      live: l == null ? null : BusLive.fromJson(l),
    );
  }

  bool get isDrop => direction == 'DROP';

  /// "Morning pickup" / "Evening drop".
  String get label => isDrop ? 'Drop' : 'Pickup';
}

class BusLive {
  final double lat;
  final double lon;
  final double? speedKmph;
  final int? headingDeg;
  final DateTime? recordedAt;

  const BusLive({required this.lat, required this.lon, this.speedKmph, this.headingDeg, this.recordedAt});

  factory BusLive.fromJson(Map<String, dynamic> j) => BusLive(
        lat: _num(j['lat']) ?? 0,
        lon: _num(j['lon']) ?? 0,
        speedKmph: _num(j['speed_kmph']),
        headingDeg: _int(j['heading_deg']),
        recordedAt: DateTime.tryParse(_str(j['recorded_at'])),
      );

  /// How old the position is, by the server's clock when there is one.
  Duration age(DateTime? serverNow) {
    if (recordedAt == null) return const Duration(days: 365);
    final now = serverNow ?? DateTime.now();
    final d = now.difference(recordedAt!);
    return d.isNegative ? Duration.zero : d;
  }

  /// A position counts as live for 10 minutes.
  bool isLive(DateTime? serverNow) => age(serverNow) <= const Duration(minutes: 10);
}
