import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/app_theme.dart' show AppColors;
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/data/api_repositories.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/utils/error_handler.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';

class AddRecipientScreen extends ConsumerStatefulWidget {
  final Recipient? recipient;
  
  const AddRecipientScreen({super.key, this.recipient});
  
  @override
  ConsumerState<AddRecipientScreen> createState() => _AddRecipientScreenState();
}

class _AddRecipientScreenState extends ConsumerState<AddRecipientScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _searchController;
  final ApiUserService _userService = ApiUserService();
  bool _isLoading = false;
  User? _selectedUser;
  List<User> _searchResults = [];
  Timer? _searchDebounce;
  bool _isSearching = false;
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.recipient?.name ?? '');
    // If editing, try to find the user
    if (widget.recipient != null) {
      _selectedUser = null; // We'll need to load this from recipient data if available
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }
  
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    
    if (query.length < AppConstants.minSearchQueryLength) {
      setState(() {
        _searchResults = [];
        _selectedUser = null;
      });
      return;
    }
    
    setState(() => _isSearching = true);
    
    _searchDebounce = Timer(const Duration(milliseconds: AppConstants.searchDebounceMs), () async {
      try {
        final results = await _userService.searchUsers(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
            // If only one result matches exactly, auto-select it
            final queryLower = query.toLowerCase();
            if (results.length == 1 && 
                (results[0].email.toLowerCase() == queryLower ||
                 results[0].name.toLowerCase() == queryLower ||
                 results[0].username.toLowerCase() == queryLower)) {
              _selectedUser = results[0];
              _searchController.text = results[0].name;
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
          // Log error for debugging
          // Error logged by API client
          // Show error to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Search failed: ${e.toString()}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }
  
  void _selectUser(User user) {
    setState(() {
      _selectedUser = user;
      _searchController.text = user.name;
      _searchResults = [];
    });
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
      
      if (_selectedUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a registered user'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      if (widget.recipient != null) {
        // Update existing recipient
        final updated = widget.recipient!.copyWith(
          name: _selectedUser!.name,
          username: _selectedUser!.username,
        );
        await repo.updateRecipient(updated);
      } else {
        // Create new recipient
        // CRITICAL: Include email from selected user (needed for inbox matching)
        final newRecipient = Recipient(
          userId: user.id, // Owner ID
          name: _selectedUser!.name,
          username: _selectedUser!.username,
          linkedUserId: _selectedUser!.id,
          email: _selectedUser!.email, // Include email for inbox matching
        );
        await repo.createRecipient(newRecipient, linkedUserId: _selectedUser!.id);
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
        context.pop();
      }
          } catch (e) {
            if (mounted) {
              final errorMsg = ErrorHandler.getErrorMessage(
                e,
                defaultMessage: ErrorHandler.getDefaultErrorMessage('save recipient'),
              );
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMsg),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
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
    // Theme-aware text colors
    final bodyColor = DynamicTheme.getSecondaryTextColor(colorScheme);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Recipient' : 'Add Recipient'),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: DynamicTheme.getPrimaryIconColor(
              ref.watch(selectedColorSchemeProvider),
            ),
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          ProfileAvatarButton(),
        ],
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
                        radius: AppConstants.avatarRadius,
                        backgroundColor: DynamicTheme.getButtonBackgroundColor(colorScheme, opacity: AppTheme.opacityMediumHigh),
                        child: Text(
                          _selectedUser != null
                              ? _selectedUser!.name[0].toUpperCase()
                              : _searchController.text.isNotEmpty
                                  ? _searchController.text[0].toUpperCase()
                                  : '?',
                          style: TextStyle(
                            color: DynamicTheme.getDialogTitleColor(colorScheme),
                            fontSize: AppConstants.avatarIconSize,
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
                              color: DynamicTheme.getCardBackgroundColor(colorScheme),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: DynamicTheme.getPrimaryIconColor(colorScheme),
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
                      final colorScheme = ref.read(selectedColorSchemeProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Photo picker coming soon',
                            style: TextStyle(
                              color: DynamicTheme.getSnackBarTextColor(colorScheme),
                            ),
                          ),
                          backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                      );
                    },
                    child: const Text('Change Photo'),
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingXl),
                
                    // User search field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _searchController,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(
                        color: DynamicTheme.getInputTextColor(colorScheme),
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Search Registered User *',
                        hintText: 'Search by username, name, or email',
                        helperText: 'Only registered users can be added as recipients',
                        filled: true,
                        fillColor: DynamicTheme.getInputBackgroundColor(colorScheme),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        labelStyle: TextStyle(
                          color: DynamicTheme.getInputHintColor(colorScheme),
                        ),
                        hintStyle: TextStyle(
                          color: DynamicTheme.getInputHintColor(colorScheme),
                        ),
                        helperStyle: TextStyle(
                          color: DynamicTheme.getSecondaryTextColor(colorScheme),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: DynamicTheme.getInputHintColor(colorScheme),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: BorderSide(
                            color: DynamicTheme.getInputBorderColor(colorScheme),
                            width: AppTheme.borderWidthStandard,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: BorderSide(
                            color: DynamicTheme.getInputBorderColor(colorScheme, isFocused: true),
                            width: AppTheme.borderWidthStandard,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: BorderSide(
                            color: DynamicTheme.getInputBorderColor(colorScheme),
                            width: AppTheme.borderWidthStandard,
                          ),
                        ),
                        suffixIcon: _isSearching
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: AppConstants.searchIndicatorSize,
                                  height: AppConstants.searchIndicatorSize,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      DynamicTheme.getButtonTextColor(colorScheme),
                                    ),
                                  ),
                                ),
                              )
                            : _selectedUser != null
                                ? IconButton(
                                    icon: const Icon(Icons.check_circle, color: AppColors.success),
                                    onPressed: () {
                                      setState(() {
                                        _selectedUser = null;
                                        _searchController.clear();
                                        _searchResults = [];
                                      });
                                    },
                                  )
                                : null,
                      ),
                      onChanged: _onSearchChanged,
                      validator: (value) {
                        if (_selectedUser == null) {
                          return 'Please select a registered user';
                        }
                        return null;
                      },
                    ),
                    // Search results dropdown
                    if (_searchResults.isNotEmpty && _selectedUser == null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: DynamicTheme.getCardBackgroundColor(colorScheme),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: DynamicTheme.getBorderColor(colorScheme),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: DynamicTheme.getNavBarShadowColor(colorScheme),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(maxHeight: AppConstants.searchResultsMaxHeight),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: DynamicTheme.getButtonBackgroundColor(colorScheme, opacity: 0.2),
                                child: Text(
                                  user.name[0].toUpperCase(),
                                  style: TextStyle(
                                    color: DynamicTheme.getButtonTextColor(colorScheme),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              title: Text(
                                user.name,
                                style: TextStyle(
                                  color: DynamicTheme.getInputTextColor(colorScheme),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '@${user.username}', 
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                    ),
                                  ),
                                  Text(
                                    user.email, 
                                    style: TextStyle(
                                      fontSize: 12, 
                                      color: DynamicTheme.getSecondaryTextColor(colorScheme),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _selectUser(user),
                            );
                          },
                        ),
                      ),
                    if (_selectedUser != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected: ${_selectedUser!.name}',
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '@${_selectedUser!.username}',
                                    style: TextStyle(
                                      color: AppColors.success.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                SizedBox(height: AppTheme.spacingMd),
                
                Text(
                  '* Required fields',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: bodyColor,
                      ),
                ),
                
                SizedBox(height: AppTheme.spacingXl),
                
                // Save button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      side: DynamicTheme.getButtonBorderSide(colorScheme),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(DynamicTheme.getPrimaryIconColor(colorScheme)),
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
