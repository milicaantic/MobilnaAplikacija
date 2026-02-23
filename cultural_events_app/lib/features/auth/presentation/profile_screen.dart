import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/validation/app_validators.dart';
import '../data/auth_repository.dart';
import '../data/user_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _editFormKey = GlobalKey<FormState>();
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _photoUrlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _photoUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  void _setupControllers(dynamic user) {
    if (user != null && !_isEditing) {
      _nameController.text = user.name;
      _photoUrlController.text = user.photoUrl ?? '';
    }
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
      return 'Profile photo URL could not be loaded.';
    } finally {
      imageStream.removeListener(listener);
    }
  }

  Future<void> _saveProfile(String uid) async {
    if (!_editFormKey.currentState!.validate()) return;

    final photoUrl = _photoUrlController.text.trim();
    if (photoUrl.isNotEmpty) {
      final imageValidationError = await _validateImageAccessibility(photoUrl);
      if (imageValidationError != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(imageValidationError)));
        }
        return;
      }
    }

    await ref
        .read(userRepositoryProvider)
        .updateUserProfile(
          uid,
          name: _nameController.text.trim(),
          photoUrl: photoUrl,
        );
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found.'));
          }
          _setupControllers(user);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          onBackgroundImageError: (_, __) {},
                          child: user.photoUrl == null
                              ? const Icon(Icons.person, size: 48)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        if (!_isEditing) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit profile',
                                onPressed: () =>
                                    setState(() => _isEditing = true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Chip(
                            label: Text(user.role.name.toUpperCase()),
                            avatar: const Icon(Icons.verified_user_outlined),
                            backgroundColor: colorScheme.primaryContainer
                              .withValues(alpha: 0.8),
                          ),
                        ],
                        if (_isEditing) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline),
                                tooltip: 'Save profile',
                                onPressed: () => _saveProfile(user.uid),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Chip(
                            label: Text(user.role.name.toUpperCase()),
                            avatar: const Icon(Icons.verified_user_outlined),
                            backgroundColor: colorScheme.primaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isEditing) ...[
                  Form(
                    key: _editFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          maxLength: AppValidators.nameMax,
                          validator: AppValidators.validateName,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _photoUrlController,
                          validator: AppValidators.validateImageUrl,
                          decoration: const InputDecoration(
                            labelText: 'Photo URL',
                            prefixIcon: Icon(Icons.image_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap the check icon next to your name to save changes.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(authRepositoryProvider).signOut();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
