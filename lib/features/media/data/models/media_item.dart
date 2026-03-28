class MediaItem {
  final String id;
  final String? userId;
  final String? clubId;
  final String? tournamentId;
  final String mediaType; // 'IMAGE' or 'VIDEO'
  final String url;
  final String? thumbnailUrl;
  final String? title;
  final String? description;
  final DateTime createdAt;

  MediaItem({
    required this.id,
    this.userId,
    this.clubId,
    this.tournamentId,
    required this.mediaType,
    required this.url,
    this.thumbnailUrl,
    this.title,
    this.description,
    required this.createdAt,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      clubId: json['club_id'] as String?,
      tournamentId: json['tournament_id'] as String?,
      mediaType: json['media_type'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'club_id': clubId,
      'tournament_id': tournamentId,
      'media_type': mediaType,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
