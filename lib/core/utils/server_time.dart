/// Turning a timestamp from the database into the phone's local time.
///
/// The money tables store instants in `timestamp WITHOUT time zone` columns,
/// and the Supabase server runs on **UTC** — `now()` writes UTC digits with no
/// offset attached. PostgREST then hands them over as `2026-09-29T04:27:44`.
///
/// `DateTime.parse` reads a string with no offset as **local**, so those UTC
/// digits were displayed verbatim: a payment made at 09:57 IST showed as
/// "4:27 am". Calling `.toLocal()` afterwards does not help — the value is
/// already flagged local, so it is a no-op. The offset has to be applied at
/// parse time, which is what this does.
///
/// A pure date (`duedate`, `stubdate`) is deliberately left alone: a due date
/// is a calendar date, not an instant, and shifting it by the UTC offset would
/// move it to the wrong day.
library;

/// Parses a server timestamp and returns it in the device's local zone.
///
/// * carries an offset (`...Z`, `...+05:30`) → parsed, then converted
/// * naive but has a time part → read as UTC, then converted
/// * date only (`2026-10-31`) → returned untouched
///
/// Returns null when [value] is null or unparseable.
DateTime? parseServerTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.isUtc ? value.toLocal() : value;

  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  // A date with no time is a calendar date. Converting zones would move it.
  final hasTime = raw.contains('T') || raw.contains(' ');
  if (!hasTime) return DateTime.tryParse(raw);

  final carriesZone = raw.endsWith('Z') ||
      RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(raw);

  final parsed = DateTime.tryParse(carriesZone ? raw : '${raw}Z');
  return parsed?.toLocal();
}

/// Same, for a field the caller knows is always present.
DateTime parseServerTimeOr(dynamic value, DateTime fallback) =>
    parseServerTime(value) ?? fallback;
