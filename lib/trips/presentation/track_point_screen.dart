import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_diary_frontend/trips/data/models/track_point.dart';
import 'package:travel_diary_frontend/trips/data/dtos/track_point_request.dart';
import 'package:travel_diary_frontend/trips/presentation/controllers/track_point_controller.dart';

/// Screen for testing and demonstrating TrackPoint functionality
class TrackPointScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String tripTitle;

  const TrackPointScreen({
    super.key,
    required this.tripId,
    required this.tripTitle,
  });

  @override
  ConsumerState<TrackPointScreen> createState() => _TrackPointScreenState();
}

class _TrackPointScreenState extends ConsumerState<TrackPointScreen> {
  final _latitudeController = TextEditingController(text: '36.8065');
  final _longitudeController = TextEditingController(text: '10.1815');
  final _accuracyController = TextEditingController(text: '5.0');
  final _speedController = TextEditingController(text: '0.0');

  @override
  void initState() {
    super.initState();
    // Load existing track points when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackPointControllerProvider(widget.tripId).notifier).loadTrackPoints();
    });
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _accuracyController.dispose();
    _speedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackPointState = ref.watch(trackPointControllerProvider(widget.tripId));
    final trackPointController = ref.read(trackPointControllerProvider(widget.tripId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Track Points - ${widget.tripTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => trackPointController.loadTrackPoints(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status and Stats Card
          _buildStatsCard(trackPointState, trackPointController),
          
          // Add Track Point Form
          _buildAddTrackPointForm(trackPointController),
          
          // Track Points List
          Expanded(
            child: _buildTrackPointsList(trackPointState, trackPointController),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBulkAddDialog(trackPointController),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Bulk Add'),
      ),
    );
  }

  Widget _buildStatsCard(TrackPointState state, TrackPointController controller) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Points',
                    '${state.totalPoints}',
                    Icons.location_on,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Distance',
                    controller.formattedTotalDistance,
                    Icons.straighten,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Batch Queue',
                    '${state.batchSize}',
                    Icons.queue,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Batch Status',
                    state.isBatching ? 'Processing...' : 'Ready',
                    Icons.sync,
                    state.isBatching ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.latestTrackPoint != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Latest Point:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Lat: ${state.latestTrackPoint!.latitude.toStringAsFixed(6)}, '
                'Lon: ${state.latestTrackPoint!.longitude.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Time: ${_formatDateTime(state.latestTrackPoint!.timestamp)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (state.successMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.successMessage!,
                        style: const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAddTrackPointForm(TrackPointController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Track Point',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.navigation),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.navigation),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _accuracyController,
                    decoration: const InputDecoration(
                      labelText: 'Accuracy (m)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.gps_fixed),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _speedController,
                    decoration: const InputDecoration(
                      labelText: 'Speed (m/s)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.speed),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addTrackPoint(controller),
                    icon: const Icon(Icons.add_location),
                    label: const Text('Add Point'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addTrackPointToBatch(controller),
                    icon: const Icon(Icons.queue),
                    label: const Text('Queue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addCurrentLocation(controller),
                    icon: const Icon(Icons.my_location),
                    label: const Text('Current'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.flushBatch(),
                    icon: const Icon(Icons.send),
                    label: const Text('Flush Batch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackPointsList(TrackPointState state, TrackPointController controller) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.trackPoints.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No track points yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Add your first location point to start tracking',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.trackPoints.length,
      itemBuilder: (context, index) {
        final trackPoint = state.trackPoints[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: trackPoint.isSignificant ? Colors.orange : Colors.blue,
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              '${trackPoint.latitude.toStringAsFixed(6)}, ${trackPoint.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDateTime(trackPoint.timestamp)),
                if (trackPoint.accuracyMeters != null)
                  Text('Accuracy: ${trackPoint.formattedAccuracy}'),
                if (trackPoint.speedKmh != null)
                  Text('Speed: ${trackPoint.formattedSpeed}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteDialog(trackPoint, controller);
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _addTrackPoint(TrackPointController controller) {
    final lat = double.tryParse(_latitudeController.text);
    final lon = double.tryParse(_longitudeController.text);
    final accuracy = double.tryParse(_accuracyController.text);
    final speed = double.tryParse(_speedController.text);

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid latitude and longitude'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final request = TrackPointRequest(
      latitude: lat,
      longitude: lon,
      accuracyMeters: accuracy,
      speedMps: speed,
    );

    controller.addTrackPoint(request);
    
    // Clear form
    _latitudeController.clear();
    _longitudeController.clear();
    _accuracyController.clear();
    _speedController.clear();
  }

  void _addCurrentLocation(TrackPointController controller) {
    // Simulate current location (Tunis, Tunisia)
    _latitudeController.text = '36.8065';
    _longitudeController.text = '10.1815';
    _accuracyController.text = '5.0';
    _speedController.text = '0.0';
    
    _addTrackPoint(controller);
  }
  
  void _addTrackPointToBatch(TrackPointController controller) {
    final lat = double.tryParse(_latitudeController.text);
    final lon = double.tryParse(_longitudeController.text);
    final accuracy = double.tryParse(_accuracyController.text);
    final speed = double.tryParse(_speedController.text);

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid latitude and longitude'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final request = TrackPointRequest(
      latitude: lat,
      longitude: lon,
      accuracyMeters: accuracy,
      speedMps: speed,
    );

    controller.addTrackPointToBatch(request);
    
    // Clear form
    _latitudeController.clear();
    _longitudeController.clear();
    _accuracyController.clear();
    _speedController.clear();
  }

  void _showDeleteDialog(TrackPoint trackPoint, TrackPointController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Track Point'),
        content: Text(
          'Are you sure you want to delete this track point?\n\n'
          'Lat: ${trackPoint.latitude.toStringAsFixed(6)}\n'
          'Lon: ${trackPoint.longitude.toStringAsFixed(6)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.deleteTrackPoint(trackPoint.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showBulkAddDialog(TrackPointController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Add Track Points'),
        content: const Text(
          'This will add 5 sample track points around Tunis to demonstrate bulk operations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addBulkTrackPoints(controller);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addBulkTrackPoints(TrackPointController controller) {
    // Sample track points around Tunis
    final requests = [
      TrackPointRequest(latitude: 36.8065, longitude: 10.1815, accuracyMeters: 5.0, speedMps: 0.0),
      TrackPointRequest(latitude: 36.8075, longitude: 10.1825, accuracyMeters: 4.5, speedMps: 1.2),
      TrackPointRequest(latitude: 36.8085, longitude: 10.1835, accuracyMeters: 6.0, speedMps: 2.1),
      TrackPointRequest(latitude: 36.8095, longitude: 10.1845, accuracyMeters: 3.8, speedMps: 1.8),
      TrackPointRequest(latitude: 36.8105, longitude: 10.1855, accuracyMeters: 5.2, speedMps: 0.9),
    ];

    controller.addTrackPointsBulk(requests);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
