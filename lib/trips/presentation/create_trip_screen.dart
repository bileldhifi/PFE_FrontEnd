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
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  
  String? _coverImagePath;
  DateTime? _startDate;
  DateTime? _endDate;
  String _visibility = 'PUBLIC';
  String _tripType = 'LEISURE';
  String _budgetRange = 'MEDIUM';
  final List<String> _travelBuddies = [];
  final _buddyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _buddyController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Cover Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildImageOption('https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800', 'Mountain'),
                _buildImageOption('https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', 'Beach'),
                _buildImageOption('https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800', 'City'),
                _buildImageOption('https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800', 'Nature'),
                _buildImageOption('https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?w=800', 'Tropical'),
                _buildImageOption('https://images.unsplash.com/photo-1504893524553-b855bce32c67?w=800', 'Northern Lights'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption(String imageUrl, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _coverImagePath = imageUrl;
        });
        Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label cover image selected!')),
          );
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: _coverImagePath == imageUrl 
              ? Border.all(color: AppColors.primaryLight, width: 3)
              : Border.all(color: Colors.grey.shade300),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: _coverImagePath == imageUrl
            ? Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 24,
                ),
              )
            : null,
      ),
    );
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

      // Create comprehensive description
      final List<String> descriptionParts = [];
      
      if (_descriptionController.text.isNotEmpty) {
        descriptionParts.add(_descriptionController.text);
      }
      
      if (_locationController.text.isNotEmpty) {
        descriptionParts.add('📍 Destination: ${_locationController.text}');
      }
      
      descriptionParts.add('🏷️ Type: ${_tripType.toLowerCase()}');
      descriptionParts.add('💰 Budget: ${_budgetRange.toLowerCase()}');
      
      if (_budgetController.text.isNotEmpty) {
        descriptionParts.add('💵 Estimated: \$${_budgetController.text}');
      }
      
      if (_travelBuddies.isNotEmpty) {
        descriptionParts.add('👥 Travel Buddies: ${_travelBuddies.join(', ')}');
      }

      // Create trip
      final newTrip = Trip(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _nameController.text,
        coverUrl: _coverImagePath ?? 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800',
        startDate: _startDate!,
        endDate: _endDate,
        visibility: _visibility,
        stats: const TripStats(),
        createdBy: '1',
        createdAt: DateTime.now(),
        description: descriptionParts.join('\n\n'),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ),
        title: Text(
          'New Trip',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Cover Photo Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: GestureDetector(
                onTap: _isLoading ? null : _pickCoverImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _coverImagePath != null ? 'Change cover photo' : 'Pick a cover photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Trip Dates Card
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Trip dates',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateField(
                                  label: 'Start date',
                                  date: _startDate,
                                  onTap: _selectStartDate,
                                  isRequired: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDateField(
                                  label: 'End date',
                                  date: _endDate,
                                  onTap: _selectEndDate,
                                  isOptional: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Trip Name Card
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.tag,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Name your trip',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'e.g., Summer Adventure in Europe',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description Card
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notes,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add a short summary',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _descriptionController,
                            enabled: !_isLoading,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Tell us about your adventure...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Travel Buddies Card
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.group_add,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Travel Buddies',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _isLoading ? null : _showAddBuddyDialog,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[600],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 20,
                                  ),
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
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        entry.value,
                                        style: TextStyle(
                                          color: Colors.blue[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: _isLoading ? null : () => _removeTravelBuddy(entry.key),
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.blue[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Travel Tracker Card
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Travel Tracker',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.info,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Location services are turned off - you\'ll need to enable them to track your trip.',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.warning,
                                color: Colors.red[400],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: false,
                                onChanged: (value) {
                                  // TODO: Handle location services toggle
                                },
                                activeColor: Colors.blue[600],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Create Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create trip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
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

  Widget _buildTripTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trip Type',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTripTypeChip('LEISURE', 'Leisure', Icons.beach_access),
            const SizedBox(width: 8),
            _buildTripTypeChip('BUSINESS', 'Business', Icons.business),
            const SizedBox(width: 8),
            _buildTripTypeChip('ADVENTURE', 'Adventure', Icons.hiking),
          ],
        ),
      ],
    );
  }

  Widget _buildTripTypeChip(String value, String label, IconData icon) {
    final isSelected = _tripType == value;
    
    return Expanded(
      child: ChoiceChip(
        selected: isSelected,
        onSelected: _isLoading ? null : (selected) {
          if (selected) {
            setState(() {
              _tripType = value;
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

  Widget _buildBudgetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Range',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildBudgetChip('LOW', 'Low', '\$'),
            const SizedBox(width: 8),
            _buildBudgetChip('MEDIUM', 'Medium', '\$\$'),
            const SizedBox(width: 8),
            _buildBudgetChip('HIGH', 'High', '\$\$\$'),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Estimated Budget (Optional)',
          hint: 'e.g., 1500',
          controller: _budgetController,
          prefixIcon: const Icon(Icons.attach_money),
          keyboardType: TextInputType.number,
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildBudgetChip(String value, String label, String symbol) {
    final isSelected = _budgetRange == value;
    
    return Expanded(
      child: ChoiceChip(
        selected: isSelected,
        onSelected: _isLoading ? null : (selected) {
          if (selected) {
            setState(() {
              _budgetRange = value;
            });
          }
        },
        avatar: Text(
          symbol,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
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

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    bool isRequired = false,
    bool isOptional = false,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: date != null ? Colors.blue[600] : Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day} ${_getMonthName(date.month)} ${date.year}'
                        : isOptional
                            ? 'Optional'
                            : 'Select date',
                    style: TextStyle(
                      color: date != null
                          ? Colors.blue[600]
                          : Colors.grey[400],
                      fontWeight: FontWeight.w500,
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

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  void _showAddBuddyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Travel Buddy'),
        content: TextField(
          controller: _buddyController,
          decoration: const InputDecoration(
            hintText: 'Enter buddy name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _buddyController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _addTravelBuddy();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}