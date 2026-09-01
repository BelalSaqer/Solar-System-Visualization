enum HistoricalEventType { discovery, mission, observation, theory }

class HistoricalEvent {
  final String date;
  final String title;
  final String description;
  final HistoricalEventType type;

  /// Name of the [Planet] this event is about, if any. When set, selecting
  /// this event in the timeline focuses the 3D view on that planet.
  final String? relatedPlanet;

  final String wikipediaUrl;

  const HistoricalEvent({
    required this.date,
    required this.title,
    required this.description,
    required this.type,
    required this.wikipediaUrl,
    this.relatedPlanet,
  });
}
