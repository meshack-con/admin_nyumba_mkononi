class AdminProperty {
  final int id;
  final int ownerId;
  final String jina;
  final String aina;
  final String mode;
  final int price;
  final String locationLabel;
  final double latitude;
  final double longitude;
  final bool hasWifi;
  final String description;
  final List<String> photoUrls;
  final String? verificationDocUrl;
  final String status;
  final DateTime createdAt;
  final DateTime? expiresAt;

  AdminProperty({
    required this.id,
    required this.ownerId,
    required this.jina,
    required this.aina,
    required this.mode,
    required this.price,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
    required this.hasWifi,
    required this.description,
    required this.photoUrls,
    required this.verificationDocUrl,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  factory AdminProperty.fromJson(Map<String, dynamic> json) {
    return AdminProperty(
      id: json['id'] as int,
      ownerId: json['owner_id'] as int,
      jina: json['jina'] as String,
      aina: json['aina'] as String,
      mode: json['mode'] as String,
      price: json['price'] as int,
      locationLabel: json['location_label'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      hasWifi: json['has_wifi'] as bool,
      description: json['description'] as String,
      photoUrls: (json['photo_urls'] as List<dynamic>).map((e) => e.toString()).toList(),
      verificationDocUrl: json['verification_doc_url'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
    );
  }
}
