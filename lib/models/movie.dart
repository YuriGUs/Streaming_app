class Movie {
  final int id;
  final String title;
  final String? thumbnailPath;
  final String category;
  final int duration; // NOVO: Duração em segundos
  final String? showTitle; // NOVO: Nome do programa/série
  final int season;

  Movie({
    required this.id,
    required this.title,
    this.thumbnailPath,
    required this.category,
    required this.duration,
    this.showTitle,
    required this.season,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      thumbnailPath: json['thumbnail_path'],
      category: json['category'] ?? 'filme',
      duration: json['duration'] ?? 0,
      showTitle: json['show_title'],
      season: json['season'] ?? 1,
    );
  }
}