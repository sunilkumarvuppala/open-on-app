import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';

class AddRecipientScreen extends ConsumerStatefulWidget {
  final Recipient? recipient;
  
  const AddRecipientScreen({super.key, this.recipient});
  
  @override
  ConsumerState<AddRecipientScreen> createState() => _AddRecipientScreenState();
}

class _AddRecipientScreenState extends ConsumerState<AddRecipientScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _relationshipController;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipient?.name);
    _relationshipController = TextEditingController(
      text: widget.recipient?.relationship,
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }
  
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.asData?.value;
      
      if (user == null) {
        throw Exception('User not found');
      }
      
      final repo = ref.read(recipientRepositoryProvider);
      
      if (widget.recipient != null) {
        // Update existing recipient
        final updated = widget.recipient!.copyWith(
          name: _nameController.text.trim(),
          relationship: _relationshipController.text.trim(),
        );
        await repo.updateRecipient(updated);
      } else {
        // Create new recipient
        final newRecipient = Recipient(
          userId: user.id,
          name: _nameController.text.trim(),
          relationship: _relationshipController.text.trim(),
        );
        await repo.createRecipient(newRecipient);
      }
      
      // Invalidate recipients cache
      ref.invalidate(recipientsProvider(user.id));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.recipient != null
                  ? 'Recipient updated successfully'
                  : 'Recipient added successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save recipient'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recipient != null;
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Recipient' : 'Add Recipient'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppTheme.spacingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppTheme.spacingLg),
                
                // Avatar section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: colorScheme.primary1.withOpacity(0.1),
                        child: Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: colorScheme.primary1,
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(AppTheme.spacingXs),
                          decoration: BoxDecoration(
                            color: colorScheme.primary1,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingSm),
                
                Center(
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement photo picker
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Photo picker coming soon'),
                        ),
                      );
                    },
                    child: const Text('Change Photo'),
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingXl),
                
                // Name field
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'e.g., Priya, Mom, Raj',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  onChanged: (value) {
                    // Update avatar preview
                    setState(() {});
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: AppTheme.spacingMd),
                
                // Relationship field
                TextFormField(
                  controller: _relationshipController,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Relationship *',
                    hintText: 'e.g., Partner, Daughter, Best Friend',
                    prefixIcon: Icon(Icons.favorite_outline),
                  ),
                  onFieldSubmitted: (_) => _handleSave(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a relationship';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: AppTheme.spacingSm),
                
                Text(
                  '* Required fields',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textGrey,
                      ),
                ),
                
                SizedBox(height: AppTheme.spacingXl),
                
                // Save button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          )
                        : Text(isEditing ? 'Update Recipient' : 'Add Recipient'),
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingLg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
