class ApodEntry {
  final String title;
  final String date;
  final String explanation;
  final String mediaType;
  final String imageUrl;
  final String nasaUrl;
  final String? copyright;

  const ApodEntry({
    required this.title,
    required this.date,
    required this.explanation,
    required this.mediaType,
    required this.imageUrl,
    required this.nasaUrl,
    this.copyright,
  });

  factory ApodEntry.fromJson(Map<String, dynamic> json) {
    final date = json['date'] as String? ?? '';
    return ApodEntry(
      title: json['title'] as String? ?? 'Astronomy Picture of the Day',
      date: date,
      explanation: json['explanation'] as String? ?? '',
      mediaType: json['media_type'] as String? ?? 'image',
      imageUrl: (json['hdurl'] ?? json['url']) as String? ?? '',
      nasaUrl: 'https://apod.nasa.gov/apod/ap${_shortDate(date)}.html',
      copyright: json['copyright'] as String?,
    );
  }

  static String _shortDate(String isoDate) {
    // NASA APOD's own page URLs use yyMMdd from the yyyy-MM-dd API date.
    final parts = isoDate.split('-');
    if (parts.length != 3) return '';
    return '${parts[0].substring(2)}${parts[1]}${parts[2]}';
  }
}
