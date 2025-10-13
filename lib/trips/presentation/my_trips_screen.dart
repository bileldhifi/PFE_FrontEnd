import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_diary_frontend/core/widgets/empty_state.dart';
import 'package:travel_diary_frontend/core/widgets/retry_widget.dart';
import 'package:travel_diary_frontend/core/widgets/skeleton_loader.dart';
import 'package:travel_diary_frontend/trips/presentation/controllers/trip_list_controller.dart';
import 'package:travel_diary_frontend/trips/presentation/widgets/trip_card.dart';

class MyTripsScreen extends ConsumerWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripState = ref.watch(tripListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              // TODO: Show all trips on map
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Map view coming soon!')),
              );
            },
          ),
        ],
      ),
      body: _buildBody(context, ref, tripState),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/trips/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, TripListState state) {
    if (state.isLoading && state.trips.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: 3,
        itemBuilder: (context, index) => const TripCardSkeleton(),
      );
    }

    if (state.error != null && state.trips.isEmpty) {
      return RetryWidget(
        message: state.error!,
        onRetry: () => ref.read(tripListControllerProvider.notifier).refresh(),
      );
    }

    if (state.trips.isEmpty) {
      return EmptyState(
        icon: Icons.luggage_outlined,
        title: 'No Trips Yet',
        message: 'Start documenting your adventures by creating your first trip',
        actionLabel: 'Create Trip',
        onAction: () {
          context.push('/trips/create');
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(tripListControllerProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: state.trips.length,
        itemBuilder: (context, index) {
          final trip = state.trips[index];
          return TripCard(
            trip: trip,
            onTap: () => context.push('/trips/${trip.id}'),
            onDelete: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Trip'),
                  content: Text('Are you sure you want to delete "${trip.title}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await ref.read(tripListControllerProvider.notifier).deleteTrip(trip.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trip deleted')),
                  );
                }
              }
            },
            onEdit: () {
              // TODO: Navigate to edit trip
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit trip coming soon!')),
              );
            },
          );
        },
      ),
    );
  }
}

