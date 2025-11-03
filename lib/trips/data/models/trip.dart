import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

@freezed
class Trip with _$Trip {
  const factory Trip({
    required String id,
    required String title,
    String? coverUrl,
    required DateTime startDate,
    DateTime? endDate,
    @Default('PUBLIC') String visibility,
    required TripStats stats,
    required String createdBy,
    required DateTime createdAt,
    String? description,
    // Additional fields for enhanced UI (stored locally)
    String? location,
    String? tripType,
    String? budgetRange,
    String? budget,
    List<String>? travelBuddies,
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}

@freezed
class TripStats with _$TripStats {
  const factory TripStats({
    @Default(0) int stepsCount,
    @Default(0) double distanceKm,
    @Default(0) int countriesCount,
    @Default(0) int citiesCount,
    @Default(0) int photosCount,
    @Default({}) Map<String, double> transportMethods,
  }) = _TripStats;

  factory TripStats.fromJson(Map<String, dynamic> json) =>
      _$TripStatsFromJson(json);
}

