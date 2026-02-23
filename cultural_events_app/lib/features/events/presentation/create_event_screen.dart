import 'dart:async';

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
import '../../../core/validation/app_validators.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  final String? editingEventId;
  final EventModel? initialEvent;

  const CreateEventScreen({
    super.key,
    this.editingEventId,
    this.initialEvent,
  });

  bool get isEditMode =>
      (editingEventId?.trim().isNotEmpty ?? false) || initialEvent != null;

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
  bool _didPopulateForm = false;
  bool _networkImageFailed = false;
  EventModel? _editingBaseEvent;

  bool _isValidImageUrl(String? value) {
    final url = value?.trim();
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  Future<String?> _validateImageAccessibility(String imageUrl) async {
    final formatValidation = AppValidators.validateImageUrl(imageUrl);
    if (formatValidation != null) {
      return formatValidation;
    }

    final completer = Completer<void>();
    final imageStream = NetworkImage(imageUrl).resolve(
      const ImageConfiguration(),
    );

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (image, synchronousCall) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );

    imageStream.addListener(listener);
    try {
      await completer.future.timeout(const Duration(seconds: 8));
      return null;
    } catch (_) {
      return 'Image could not be loaded from this URL.';
    } finally {
      imageStream.removeListener(listener);
    }
  }

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
    final dateValidation = AppValidators.validateUpcomingDate(_selectedDate);
    if (dateValidation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(dateValidation)));
      return;
    }

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
    final editingId =
        _editingBaseEvent?.eventId ??
        widget.editingEventId?.trim() ??
        widget.initialEvent?.eventId;
    final isEditMode = editingId != null && editingId.isNotEmpty;
    final shouldResetRejectedToPending =
        isEditMode && _editingBaseEvent?.status == EventStatus.rejected;

    final imageUrl = _imageUrlController.text.trim();
    if (!isEditMode && imageUrl.isNotEmpty) {
      final imageValidationError = await _validateImageAccessibility(imageUrl);
      if (imageValidationError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(imageValidationError)),
          );
          setState(() => _isLoading = false);
        }
        return;
      }
    }

    if (isEditMode) {
      _editingBaseEvent ??= widget.initialEvent;

      if (_editingBaseEvent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load the event for editing.')),
        );
        setState(() => _isLoading = false);
        return;
      }
      final canEdit =
          _editingBaseEvent!.creatorId == user.uid || userProfile.role.isAdmin;
      if (!canEdit) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only the event owner or an admin can edit this event.'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    final existingLat = (_editingBaseEvent?.location['lat'] as num?)?.toDouble();
    final existingLng = (_editingBaseEvent?.location['lng'] as num?)?.toDouble();
    double? lat = existingLat;
    double? lng = existingLng;

    try {
      final coords = await ref
          .read(locationServiceProvider)
          .getCoordinates(_locationController.text.trim());
      lat = coords['lat'];
      lng = coords['lng'];
      if (lat == null || lng == null) {
        throw Exception('Location not found');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid location. Please enter a valid location that can be geocoded.',
            ),
          ),
        );
      }
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final event = EventModel(
      eventId: editingId ?? '', 
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      categoryId: _selectedCategoryId!,
      time: _selectedDate,
      location: {
        'name': _locationController.text.trim(),
      },
      creatorId: _editingBaseEvent?.creatorId ?? user.uid,
      creatorName: _editingBaseEvent?.creatorName ?? userProfile.name,
      creatorPhotoUrl: _editingBaseEvent?.creatorPhotoUrl ?? userProfile.photoUrl,
      status: shouldResetRejectedToPending
          ? EventStatus.pending
          : (_editingBaseEvent?.status ??
                (isAdmin ? EventStatus.approved : EventStatus.pending)),
      approvedBy: _editingBaseEvent?.approvedBy,
      approvedAt: _editingBaseEvent?.approvedAt,
      rejectedReason: _editingBaseEvent?.rejectedReason,
      imageUrl: _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      createdAt: _editingBaseEvent?.createdAt ?? DateTime.now(),
    );

    try {
      final finalImageUrl = _imageUrlController.text.trim();
      final eventToSave = event.copyWith(
        imageUrl: finalImageUrl.isEmpty ? null : finalImageUrl,
      );

      if (isEditMode) {
        await ref.read(eventRepositoryProvider).updateEvent(eventToSave);
        if (shouldResetRejectedToPending && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This rejected event is now pending and awaiting approval.',
              ),
            ),
          );
        }
      } else {
        await ref.read(eventRepositoryProvider).createEvent(eventToSave);
      }
      if (mounted) {
        setState(() {
          _imageUrlController.text = finalImageUrl;
        });
      }
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
    final role = ref.watch(currentUserProvider).value?.role;
    final isEditMode = widget.isEditMode;
    final editingEventId = widget.editingEventId?.trim();
    EventModel? editingEvent;

    if (isEditMode) {
      if (editingEventId != null && editingEventId.isNotEmpty) {
        final eventAsync = ref.watch(eventStreamProvider(editingEventId));
        editingEvent = eventAsync.value ?? widget.initialEvent;

        if (editingEvent == null) {
          if (eventAsync.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return const Scaffold(body: Center(child: Text('Event not found.')));
        }
      } else {
        editingEvent = widget.initialEvent;
      }

      if (editingEvent == null) {
        return const Scaffold(body: Center(child: Text('Event not found.')));
      }

      if (!_didPopulateForm) {
        _didPopulateForm = true;
        _editingBaseEvent = editingEvent;
        _titleController.text = editingEvent.title;
        _descriptionController.text = editingEvent.description;
        _locationController.text = (editingEvent.location['name'] as String?) ?? '';
        _imageUrlController.text = editingEvent.imageUrl ?? '';
        _networkImageFailed = false;
        _selectedDate = editingEvent.time;
        _selectedCategoryId = editingEvent.categoryId;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Edit Event' : 'Create Event')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Builder(
                      builder: (context) {
                        final url = _imageUrlController.text.trim();
                        final ImageProvider<Object>? imageProvider =
                            !_networkImageFailed && _isValidImageUrl(url)
                            ? NetworkImage(url)
                            : null;

                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: SizedBox(
                            height: 180,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                              child: imageProvider == null
                                  ? Icon(
                                      Icons.image_outlined,
                                      size: 42,
                                      color: Theme.of(context).colorScheme.outline,
                                    )
                                  : Ink.image(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                      child: const SizedBox.expand(),
                                      onImageError: (_, __) {
                                        if (mounted) {
                                          setState(() => _networkImageFailed = true);
                                        }
                                      },
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          isEditMode
                              ? 'Update event details and save your changes.'
                              : role == UserRole.admin
                              ? 'Admin events are published immediately.'
                              : 'New events are submitted for admin approval.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      maxLength: AppValidators.titleMax,
                      validator: AppValidators.validateTitle,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                      maxLength: AppValidators.descriptionMax,
                      maxLines: 4,
                      validator: AppValidators.validateDescription,
                    ),
                    const SizedBox(height: 14),
                    categoriesAsync.when(
                      data: (categories) {
                        final selectedExists = _selectedCategoryId != null &&
                            categories.any(
                              (c) => c.categoryId == _selectedCategoryId,
                            );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String>(
                              value: selectedExists ? _selectedCategoryId : null,
                              hint: const Text('Select Category'),
                              items: categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.categoryId,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedCategoryId = val),
                              validator: (val) => val == null ? 'Required' : null,
                            ),
                            if (_selectedCategoryId != null && !selectedExists)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'This event category is unavailable. Please select another category.',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading categories'),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.schedule_rounded),
                        title: const Text('Event Date & Time'),
                        subtitle: Text(_selectedDate.toString().split('.')[0]),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
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
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location Name',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      maxLength: AppValidators.locationMax,
                      validator: AppValidators.validateLocation,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL (optional)',
                        hintText: 'https://example.com/image.jpg',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                      keyboardType: TextInputType.url,
                      validator: AppValidators.validateImageUrl,
                      onChanged: (_) {
                        if (_networkImageFailed) {
                          setState(() => _networkImageFailed = false);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox.shrink()
                          : const Icon(Icons.send_rounded),
                      label: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isEditMode
                                  ? 'Save Changes'
                                  : role == UserRole.admin
                                  ? 'Create Event'
                                  : 'Submit for Approval',
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
