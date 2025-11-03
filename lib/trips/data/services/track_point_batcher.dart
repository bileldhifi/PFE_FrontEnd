import 'dart:async';
import 'dart:io';
import 'dart:developer';
import 'package:geocoding/geocoding.dart';
import 'package:travel_diary_frontend/trips/data/dtos/track_point_request.dart';
import 'package:travel_diary_frontend/trips/data/repo/track_point_repository.dart';

/// Service for automatically batching track points
/// Collects track points and sends them in batches to optimize network usage
class TrackPointBatcher {
  final TrackPointRepository _repository;
  final String _tripId;
  
  List<TrackPointRequest> _batch = [];
  Timer? _timer;
  bool _isProcessing = false;
  
  // Configuration constants
  static const int MAX_BATCH_SIZE = 10;
  static const Duration BATCH_TIMEOUT = Duration(seconds: 30);
  static const Duration RETRY_DELAY = Duration(seconds: 5);
  static const int MAX_RETRIES = 3;
  
  // Callbacks for UI updates
  Function(String)? onError;
  Function(int)? onBatchSent;
  Function(int)? onBatchQueued;
  Function(int)? onAfterBatchSent;
  
  TrackPointBatcher({
    required TrackPointRepository repository,
    required String tripId,
    this.onError,
    this.onBatchSent,
    this.onBatchQueued,
    this.onAfterBatchSent,
  }) : _repository = repository, _tripId = tripId;
  
  /// Geocode a batch of requests to enrich them with location names
  Future<List<TrackPointRequest>> _geocodeRequests(
      List<TrackPointRequest> batch) async {
    final updated = <TrackPointRequest>[];
    for (final req in batch) {
      // Skip if already has a location name
      if (req.locationName != null && req.locationName!.isNotEmpty) {
        updated.add(req);
        continue;
      }

      String? locationName;
      try {
        final placemarks = await placemarkFromCoordinates(
          req.latitude,
          req.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final city = place.locality ?? place.subAdministrativeArea;
          final country = place.country;
          if (city != null && city.isNotEmpty) {
            locationName =
                (country != null && country.isNotEmpty) ? '$city, $country' : city;
          } else if (country != null && country.isNotEmpty) {
            locationName = country;
          }
        }
      } catch (e) {
        log('⚠️ Geocoding failed for (${req.latitude},${req.longitude}): $e');
      }

      updated.add(req.copyWith(locationName: locationName));
    }
    return updated;
  }

  /// Add a track point to the batch
  void addTrackPoint(TrackPointRequest point) {
    _batch.add(point);
    onBatchQueued?.call(_batch.length);
    
    // Send batch if it reaches max size
    if (_batch.length >= MAX_BATCH_SIZE) {
      _sendBatch();
    } else if (_timer == null) {
      // Start timer for timeout-based batching
      _timer = Timer(BATCH_TIMEOUT, _sendBatch);
    }
  }
  
  /// Force send the current batch
  Future<void> flush() async {
    if (_batch.isNotEmpty) {
      await _sendBatch();
    }
  }
  
  /// Send the current batch to the server
  Future<void> _sendBatch() async {
    if (_isProcessing || _batch.isEmpty) {
      return;
    }
    
    _isProcessing = true;
    _timer?.cancel();
    _timer = null;
    
    final batchToSend = List<TrackPointRequest>.from(_batch);
    _batch.clear();
    
    int retryCount = 0;
    bool success = false;
    
    while (retryCount < MAX_RETRIES && !success) {
      try {
        // Check internet connectivity
        if (!await _hasInternetConnection()) {
          // Queue back for later if no internet
          _batch.insertAll(0, batchToSend);
          onError?.call('No internet connection. Batch queued for later.');
          break;
        }
        
        // Enrich with location names before sending
        final enrichedBatch = await _geocodeRequests(batchToSend);

        // Send batch to server
        final responses =
            await _repository.addTrackPointsBulk(_tripId, enrichedBatch);
        success = true;
        onBatchSent?.call(responses.length);
        onAfterBatchSent?.call(responses.length);
        
      } catch (e) {
        retryCount++;
        if (retryCount < MAX_RETRIES) {
          // Wait before retry
          await Future.delayed(RETRY_DELAY);
        } else {
          // Max retries reached, queue back for later
          _batch.insertAll(0, batchToSend);
          onError?.call('Failed to send batch after $MAX_RETRIES retries: $e');
        }
      }
    }
    
    _isProcessing = false;
  }
  
  /// Check if there's an internet connection
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Get current batch size
  int get batchSize => _batch.length;
  
  /// Check if currently processing
  bool get isProcessing => _isProcessing;
  
  /// Dispose resources
  void dispose() {
    _timer?.cancel();
    _batch.clear();
  }
}

/// Offline queue for track points when no internet is available
class OfflineTrackPointQueue {
  final List<TrackPointRequest> _queue = [];
  final String _tripId;
  
  OfflineTrackPointQueue({required String tripId}) : _tripId = tripId;
  
  /// Add track point to offline queue
  void addTrackPoint(TrackPointRequest point) {
    _queue.add(point);
    _saveToLocalStorage();
  }
  
  /// Sync queued points when internet is available
  Future<void> syncWhenOnline(TrackPointRepository repository) async {
    if (_queue.isEmpty) return;
    
    try {
      final pointsToSync = List<TrackPointRequest>.from(_queue);

      // Enrich queued points with location names before syncing
      final updated = <TrackPointRequest>[];
      for (final req in pointsToSync) {
        if (req.locationName != null && req.locationName!.isNotEmpty) {
          updated.add(req);
          continue;
        }
        String? locationName;
        try {
          final placemarks = await placemarkFromCoordinates(
            req.latitude,
            req.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final city = place.locality ?? place.subAdministrativeArea;
            final country = place.country;
            if (city != null && city.isNotEmpty) {
              locationName = (country != null && country.isNotEmpty)
                  ? '$city, $country'
                  : city;
            } else if (country != null && country.isNotEmpty) {
              locationName = country;
            }
          }
        } catch (_) {
          // ignore and keep null
        }
        updated.add(req.copyWith(locationName: locationName));
      }
      
      await repository.addTrackPointsBulk(_tripId, updated);
      
      _queue.clear();
      await _clearLocalStorage();
    } catch (e) {
      // Keep in queue if sync fails
      print('Failed to sync offline queue: $e');
    }
  }
  
  /// Save queue to local storage
  Future<void> _saveToLocalStorage() async {
    // Implementation would use shared_preferences or similar
    // For now, just keep in memory
  }
  
  /// Clear local storage
  Future<void> _clearLocalStorage() async {
    // Implementation would clear shared_preferences
  }
  
  /// Get queue size
  int get queueSize => _queue.length;
}
