import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../categories/data/category_repository.dart';
import '../data/event_repository.dart';
import '../domain/event_model.dart';
import '../domain/event_status.dart';
import '../../auth/domain/user_role.dart';
import '../../../core/services/location_service.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageUrlController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null)
      return;

    setState(() => _isLoading = true);

    final user = ref.read(authRepositoryProvider).currentUser;
    final userProfile = ref.read(currentUserProvider).value;

    if (user == null || userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to create events')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final isAdmin = userProfile.role == UserRole.admin;

    double? lat;
    double? lng;

    try {
      final coords = await ref
          .read(locationServiceProvider)
          .getCoordinates(_locationController.text);
      lat = coords['lat'];
      lng = coords['lng'];
    } catch (e) {
      // Allow event creation but warn the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Weather info might be unavailable. $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    final event = EventModel(
      eventId: '', // Firestore sets this
      title: _titleController.text,
      description: _descriptionController.text,
      categoryId: _selectedCategoryId!,
      time: _selectedDate,
      location: {
        'name': _locationController.text,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
      creatorId: user.uid,
      creatorName: userProfile.name,
      creatorPhotoUrl: userProfile.photoUrl,
      status: isAdmin ? EventStatus.approved : EventStatus.pending,
      imageUrl: _imageUrlController.text.isEmpty
          ? null
          : _imageUrlController.text,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(eventRepositoryProvider).createEvent(event);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (categories) => DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  hint: const Text('Select Category'),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.categoryId,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading categories'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Event Date & Time'),
                subtitle: Text(_selectedDate.toString()),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDate),
                    );
                    if (time != null) {
                      setState(() {
                        _selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location Name'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                  hintText: 'https://example.com/image.jpg',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        ref.read(currentUserProvider).value?.role ==
                                UserRole.admin
                            ? 'Create Event'
                            : 'Submit for Approval',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
