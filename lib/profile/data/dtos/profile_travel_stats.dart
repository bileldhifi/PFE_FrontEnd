class ProfileTravelStats {
  const ProfileTravelStats({
    required this.tripsCount,
    required this.totalDistanceKm,
    required this.countriesVisited,
    required this.citiesVisited,
    required this.postsCount,
    required this.photosCount,
  });

  factory ProfileTravelStats.fromJson(Map<String, dynamic> json) {
    return ProfileTravelStats(
      tripsCount: (json['tripsCount'] as num?)?.toInt() ?? 0,
      totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
      countriesVisited: (json['countriesVisited'] as num?)?.toInt() ?? 0,
      citiesVisited: (json['citiesVisited'] as num?)?.toInt() ?? 0,
      postsCount: (json['postsCount'] as num?)?.toInt() ?? 0,
      photosCount: (json['photosCount'] as num?)?.toInt() ?? 0,
    );
  }

  final int tripsCount;
  final double totalDistanceKm;
  final int countriesVisited;
  final int citiesVisited;
  final int postsCount;
  final int photosCount;
}

