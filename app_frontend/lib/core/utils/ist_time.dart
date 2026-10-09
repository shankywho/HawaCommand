import 'package:intl/intl.dart';

/// IST helpers. IST is a fixed UTC+05:30 with no DST, so adding the offset is exact and no tz
/// database is needed (ARCHITECTURE §14). Times are stored in UTC and only formatted in IST.
abstract final class IstTime {
  static const offset = Duration(hours: 5, minutes: 30);

  /// Wall-clock IST time carried in a UTC [DateTime] (read `.hour`, `.day`, … as IST).
  static DateTime wall(DateTime t) => t.toUtc().add(offset);

  /// IST service date `YYYY-MM-DD` for the instant [t].
  static String serviceDate(DateTime t) {
    final w = wall(t);
    return '${w.year.toString().padLeft(4, '0')}-${_two(w.month)}-${_two(w.day)}';
  }

  /// UTC instant of 00:00 IST on [date] (`YYYY-MM-DD`).
  static DateTime startOfDayUtc(String date) =>
      DateTime.parse('${date}T00:00:00Z').subtract(offset);

  /// The IST date [days] after [date].
  static String addDays(String date, int days) =>
      serviceDate(startOfDayUtc(date).add(Duration(days: days)).add(const Duration(hours: 1)));

  /// Hindi day part for an IST hour: रात 00–04, सुबह 04–12, दोपहर 12–16, शाम 16–20, रात 20–24.
  static String dayPartHi(int hour) {
    if (hour < 4) return 'रात';
    if (hour < 12) return 'सुबह';
    if (hour < 16) return 'दोपहर';
    if (hour < 20) return 'शाम';
    return 'रात';
  }

  /// en "6:30 AM"; hi "सुबह 6:30". Latin digits in both.
  static String time(DateTime t, String lang) {
    final w = wall(t);
    final h12 = w.hour % 12 == 0 ? 12 : w.hour % 12;
    final hm = '$h12:${_two(w.minute)}';
    if (lang == 'hi') return '${dayPartHi(w.hour)} $hm';
    return '$hm ${w.hour < 12 ? 'AM' : 'PM'}';
  }

  /// "Thu 13 Nov" / "गुरु 13 नव॰" (intl date symbols; digits stay Latin).
  static String shortDate(DateTime t, String lang) =>
      DateFormat('EEE d MMM', _locale(lang)).format(wall(t));

  /// "Thursday" / "गुरुवार".
  static String weekday(DateTime t, String lang) =>
      DateFormat('EEEE', _locale(lang)).format(wall(t));

  /// "13 Nov" for a `YYYY-MM-DD` date.
  static String dayMonth(String date, String lang) =>
      DateFormat('d MMM', _locale(lang)).format(DateTime.parse('${date}T12:00:00Z'));

  /// "Thursday" for a `YYYY-MM-DD` date.
  static String weekdayOfDate(String date, String lang) =>
      DateFormat('EEEE', _locale(lang)).format(DateTime.parse('${date}T12:00:00Z'));

  /// Relative age, e.g. 4 → "4 min". Callers wrap it in an ARB template.
  static int minutesBetween(DateTime earlier, DateTime later) =>
      later.difference(earlier).inMinutes.clamp(0, 1 << 30);

  static String _locale(String lang) => lang == 'hi' ? 'hi' : 'en';

  static String _two(int v) => v.toString().padLeft(2, '0');
}
