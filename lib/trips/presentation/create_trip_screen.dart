import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_diary_frontend/app/theme/colors.dart';
import 'package:travel_diary_frontend/core/utils/validators.dart';
import 'package:travel_diary_frontend/core/widgets/app_text_field.dart';
import 'package:travel_diary_frontend/trips/data/models/trip.dart';
import 'package:travel_diary_frontend/trips/presentation/controllers/trip_list_controller.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _coverImagePath;
  DateTime? _startDate;
  DateTime? _endDate;
  String _visibility = 'PUBLIC';
  final List<String> _travelBuddies = [];
  final _buddyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _buddyController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    setState(() {
      _coverImagePath = 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800';
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cover image selected!')),
      );
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _addTravelBuddy() {
    if (_buddyController.text.trim().isNotEmpty) {
      setState(() {
        _travelBuddies.add(_buddyController.text.trim());
        _buddyController.clear();
      });
    }
  }

  void _removeTravelBuddy(int index) {
    setState(() {
      _travelBuddies.removeAt(index);
    });
  }

  Future<void> _createTrip() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a start date')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Create trip
      final newTrip = Trip(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _nameController.text,
        coverUrl: _coverImagePath,
        startDate: _startDate!,
        endDate: _endDate,
        visibility: _visibility,
        stats: const TripStats(),
        createdBy: '1',
        createdAt: DateTime.now(),
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      );

      await ref.read(tripListControllerProvider.notifier).createTrip(newTrip);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip created successfully! 🎉')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Trip'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createTrip,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              _buildCoverImageSection(),
              
              const SizedBox(height: 24),
              
              // Trip Name
              AppTextField(
                label: 'Trip Name *',
                hint: 'e.g., Summer Adventure in Europe',
                controller: _nameController,
                prefixIcon: const Icon(Icons.edit_outlined),
                validator: (value) => Validators.required(value, fieldName: 'Trip name'),
                enabled: !_isLoading,
              ),
              
              const SizedBox(height: 20),
              
              // Description
              AppTextField(
                label: 'Description',
                hint: 'Tell us about your adventure...',
                controller: _descriptionController,
                prefixIcon: const Icon(Icons.description_outlined),
                maxLines: 4,
                enabled: !_isLoading,
              ),
              
              const SizedBox(height: 24),
              
              // Dates Section
              Text(
                'Trip Dates',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildDateButton(
                      context,
                      label: 'Start Date *',
                      date: _startDate,
                      onTap: _selectStartDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateButton(
                      context,
                      label: 'End Date',
                      date: _endDate,
                      onTap: _selectEndDate,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Visibility
              Text(
                'Visibility',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              
              _buildVisibilitySelector(),
              
              const SizedBox(height: 24),
              
              // Travel Buddies
              Text(
                'Travel Buddies',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              
              _buildTravelBuddiesSection(),
              
              const SizedBox(height: 32),
              
              // Create Button
              ElevatedButton(
                onPressed: _isLoading ? null : _createTrip,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Create Trip'),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cover Photo',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isLoading ? null : _pickCoverImage,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              image: _coverImagePath != null
                  ? DecorationImage(
                      image: NetworkImage(_coverImagePath!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _coverImagePath == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add cover photo',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'Select date',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: date != null
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilitySelector() {
    return Row(
      children: [
        _buildVisibilityChip('PUBLIC', 'Public', Icons.public),
        const SizedBox(width: 8),
        _buildVisibilityChip('FRIENDS', 'Friends', Icons.people),
        const SizedBox(width: 8),
        _buildVisibilityChip('PRIVATE', 'Private', Icons.lock),
      ],
    );
  }

  Widget _buildVisibilityChip(String value, String label, IconData icon) {
    final isSelected = _visibility == value;
    
    return Expanded(
      child: ChoiceChip(
        selected: isSelected,
        onSelected: _isLoading ? null : (selected) {
          if (selected) {
            setState(() {
              _visibility = value;
            });
          }
        },
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        selectedColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildTravelBuddiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _buddyController,
                decoration: InputDecoration(
                  hintText: 'Add travel buddy name',
                  prefixIcon: const Icon(Icons.person_add_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: _isLoading ? null : _addTravelBuddy,
                  ),
                ),
                onSubmitted: (_) => _addTravelBuddy(),
                enabled: !_isLoading,
              ),
            ),
          ],
        ),
        
        if (_travelBuddies.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _travelBuddies.asMap().entries.map((entry) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    entry.value.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                label: Text(entry.value),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: _isLoading ? null : () => _removeTravelBuddy(entry.key),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}