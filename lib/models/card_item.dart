class CardItem {
  final int? id;
  final String title;
  final String? subtitle;
  final String? body;
  final String? imageUrl;
  final DateTime? eventDate;
  final double? latitude;
  final double? longitude;
  final double? targetDonation;
  final double? collectedDonation;
  final bool favorite;
  final DateTime? createdAt;
  final int? authorId;
  final int? categoryId;
  final String? authorName;
  final String? categoryName;

  CardItem({
    this.id,
    required this.title,
    this.subtitle,
    this.body,
    this.imageUrl,
    this.eventDate,
    this.latitude,
    this.longitude,
    this.targetDonation,
    this.collectedDonation,
    this.favorite = false,
    this.createdAt,
    this.authorId,
    this.categoryId,
    this.authorName,
    this.categoryName,
  });

  factory CardItem.fromMap(Map<String, dynamic> m) => CardItem(
        id: m['id'] as int?,
        title: m['title'] as String,
        subtitle: m['subtitle'] as String?,
        body: m['body'] as String?,
        imageUrl: m['imageUrl'] as String?,
        eventDate: m['event_date'] == null ? null : DateTime.fromMillisecondsSinceEpoch(m['event_date'] as int),
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        targetDonation: (m['target_donation'] as num?)?.toDouble(),
        collectedDonation: (m['collected_donation'] as num?)?.toDouble(),
        favorite: (m['favorite'] as int? ?? 0) == 1,
        createdAt: m['created_at'] == null ? null : DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        authorId: m['author_id'] as int?,
        categoryId: m['category_id'] as int?,
        authorName: m['author_name'] as String?,
        categoryName: m['category_name'] as String?,
      );

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'subtitle': subtitle,
      'body': body,
      'imageUrl': imageUrl,
      'event_date': eventDate?.millisecondsSinceEpoch,
      'latitude': latitude,
      'longitude': longitude,
      'target_donation': targetDonation,
      'collected_donation': collectedDonation,
      'favorite': favorite ? 1 : 0,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'author_id': authorId,
      'category_id': categoryId,
    };
  }
}
