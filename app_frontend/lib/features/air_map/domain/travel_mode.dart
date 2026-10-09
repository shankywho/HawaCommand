/// How the citizen travels. Drives the router profile and the inhaled-dose model.
///
/// [breathingM3h] is the typical minute ventilation for the activity (m³/h); [infiltration] is the
/// share of outdoor PM2.5 that reaches the traveller (a closed car with recirculation keeps out
/// roughly 40 %). Rough, published-range values: the app shows them as estimates.
enum TravelMode {
  walk(profile: 'foot', googleMode: 'walking', breathingM3h: 1.3, infiltration: 1),
  cycle(profile: 'bike', googleMode: 'bicycling', breathingM3h: 2.2, infiltration: 1),
  twoWheeler(profile: 'car', googleMode: 'driving', breathingM3h: 0.8, infiltration: 1),
  car(profile: 'car', googleMode: 'driving', breathingM3h: 0.6, infiltration: 0.6);

  const TravelMode({
    required this.profile,
    required this.googleMode,
    required this.breathingM3h,
    required this.infiltration,
  });

  /// OSRM profile: `car`, `bike` or `foot`.
  final String profile;

  /// Google Maps `travelmode` for the navigation hand-off.
  final String googleMode;
  final double breathingM3h;
  final double infiltration;
}
