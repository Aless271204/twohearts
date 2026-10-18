int? coupleDays(DateTime? start, DateTime now) {
  if (start == null) return null;
  final a = DateTime.utc(start.year, start.month, start.day);
  final b = DateTime.utc(now.year, now.month, now.day);
  return b.isBefore(a) ? null : b.difference(a).inDays;
}

String coupleDistanceLabel(num? km) {
  if (km == null || !km.isFinite || km < 0) return '—';
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km < 100 ? km.toStringAsFixed(1) : km.round()} km';
}
