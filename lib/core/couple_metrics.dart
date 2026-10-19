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

int? coupleMonths(DateTime? start, DateTime now) {
  if (coupleDays(start, now) == null) return null;
  final anniversary = start!;
  var months =
      (now.year - anniversary.year) * 12 + now.month - anniversary.month;
  final lastDay = DateTime.utc(now.year, now.month + 1, 0).day;
  final anniversaryDay = anniversary.day > lastDay ? lastDay : anniversary.day;
  if (now.day < anniversaryDay) months--;
  return months;
}
