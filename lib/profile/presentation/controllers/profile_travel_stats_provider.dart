import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dtos/profile_travel_stats.dart';
import '../../data/repo/profile_repository.dart';

final profileTravelStatsProvider =
    FutureProvider.autoDispose.family<ProfileTravelStats, String>((ref, userId) async {
  final repository = ProfileRepository();
  return repository.getTravelStats(userId);
});

