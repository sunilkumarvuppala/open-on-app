import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/error_handler.dart';
import 'package:openon_app/core/utils/validation.dart';
import 'package:openon_app/core/errors/app_exceptions.dart';
import 'package:openon_app/core/data/api_repositories.dart';
import 'package:openon_app/core/data/supabase_config.dart';
import 'package:openon_app/core/data/token_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/utils/logger.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _passwordsMatch = false;
  bool _showPasswordMatchFeedback = false;
  String? _selectedImagePath;
  String? _originalImagePath;
  XFile? _newImageFile;
  
  // Username validation state
  bool _isCheckingUsername = false;
  bool? _usernameAvailable;
  String? _usernameMessage;
  Timer? _usernameDebounce;
  String? _originalUsername;
  
  final ApiUserService _userService = ApiUserService();
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _newPasswordController.addListener(_checkPasswordMatch);
    _confirmPasswordController.addListener(_checkPasswordMatch);
    _usernameController.addListener(_checkUsernameAvailability);
  }
  
  @override
  void dispose() {
    _newPasswordController.removeListener(_checkPasswordMatch);
    _confirmPasswordController.removeListener(_checkPasswordMatch);
    _usernameController.removeListener(_checkUsernameAvailability);
    _usernameDebounce?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    final userAsync = ref.read(currentUserProvider);
    userAsync.whenData((user) {
      if (user != null && mounted) {
        // Split name into first and last
        final nameParts = user.name.split(' ');
        _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
        _lastNameController.text = nameParts.length > 1 
            ? nameParts.sublist(1).join(' ') 
            : '';
        _usernameController.text = user.username;
        _originalUsername = user.username;
        _originalImagePath = user.avatarUrl ?? user.localAvatarPath;
        _selectedImagePath = _originalImagePath;
      }
    });
  }
  
  void _checkPasswordMatch() {
    if (!mounted) return;
    
    final password = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    
    setState(() {
      if (confirmPassword.isNotEmpty) {
        _showPasswordMatchFeedback = true;
        _passwordsMatch = password == confirmPassword && password.isNotEmpty;
      } else {
        _showPasswordMatchFeedback = false;
        _passwordsMatch = false;
      }
    });
    
    if (_formKey.currentState != null) {
      _formKey.currentState!.validate();
    }
  }
  
  void _checkUsernameAvailability() {
    _usernameDebounce?.cancel();
    
    final username = _usernameController.text.trim();
    
    // If username hasn't changed, mark as available
    if (username == _originalUsername) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _usernameAvailable = true;
          _usernameMessage = null;
        });
      }
      return;
    }
    
    if (username.isEmpty) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _usernameAvailable = null;
          _usernameMessage = null;
        });
      }
      return;
    }
    
    // Validate format first
    try {
      Validation.validateUsername(username);
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _usernameAvailable = false;
          _usernameMessage = e.message;
        });
      }
      return;
    }
    
    if (mounted) {
      setState(() {
        _isCheckingUsername = true;
        _usernameAvailable = null;
        _usernameMessage = null;
      });
    }
    
    _usernameDebounce = Timer(const Duration(milliseconds: AppConstants.searchDebounceMs), () async {
      if (!mounted) return;
      
      try {
        final result = await _userService.checkUsernameAvailability(username);
        if (mounted) {
          setState(() {
            _isCheckingUsername = false;
            _usernameAvailable = result['available'] as bool;
            _usernameMessage = result['message'] as String;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isCheckingUsername = false;
            _usernameAvailable = false;
            _usernameMessage = 'Unable to check username availability';
          });
        }
      }
    });
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null && mounted) {
        setState(() {
          _newImageFile = image;
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to pick image'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    }
  }
  
  Future<void> _handleSave() async {
    print('[_handleSave] Starting save process');
    
    if (!_formKey.currentState!.validate()) {
      print('[_handleSave] Form validation failed');
      return;
    }
    
    // Check password match if changing password
    if (_newPasswordController.text.isNotEmpty) {
      if (!_passwordsMatch) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Passwords do not match';
          });
        }
        return;
      }
    }
    
    // Ensure username is available if changed
    if (_usernameController.text.trim() != _originalUsername) {
      if (_usernameAvailable != true) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Please choose an available username';
          });
        }
        return;
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    
    try {
      print('[_handleSave] Reading auth repository');
      final authRepo = ref.read(authRepositoryProvider);
      
      // Upload image to Supabase storage if a new image was selected
      String? avatarUrl;
      
      print('[_handleSave] Checking image state - _newImageFile: ${_newImageFile != null}, _selectedImagePath: $_selectedImagePath, _originalImagePath: $_originalImagePath');
      
      // Check if a new image was selected (different from original)
      final hasNewImage = _newImageFile != null || 
          (_selectedImagePath != null && 
           _selectedImagePath != _originalImagePath &&
           _selectedImagePath!.isNotEmpty);
      
      print('[_handleSave] hasNewImage: $hasNewImage');
      
      if (hasNewImage && _selectedImagePath != null && _selectedImagePath!.isNotEmpty) {
        print('[_handleSave] Processing new image: $_selectedImagePath');
        // If it's already a URL, use it directly
        if (_selectedImagePath!.startsWith('http')) {
          avatarUrl = _selectedImagePath;
          print('[_handleSave] Using existing avatar URL: $avatarUrl');
          Logger.info('Using existing avatar URL: $avatarUrl');
        } else {
          print('[_handleSave] Need to upload image to Supabase');
          // Need to upload to Supabase storage
          if (!SupabaseConfig.isInitialized) {
            throw Exception('Supabase not initialized');
          }
          
          final user = ref.read(currentUserProvider).value;
          if (user == null) {
            throw const AuthenticationException('No user logged in');
          }
          
          // Set Supabase session using refresh token for RLS policies
          // The FastAPI backend returns Supabase JWT tokens that work with RLS
          final tokenStorage = TokenStorage();
          final refreshToken = await tokenStorage.getRefreshToken();
          
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              // Set Supabase session with refresh token from FastAPI backend
              // This will establish the session needed for RLS policies
              await SupabaseConfig.client.auth.setSession(refreshToken);
              Logger.info('Supabase session set for avatar upload');
            } catch (e) {
              Logger.warning('Failed to set Supabase session, continuing anyway: $e');
              // Continue - the token might already be valid or we'll get a clearer error
            }
          } else {
            Logger.warning('No refresh token available for Supabase session');
          }
          
          // Read the image file
          final imageFile = File(_selectedImagePath!);
          if (!await imageFile.exists()) {
            throw Exception('Selected image file does not exist: $_selectedImagePath');
          }
          
          final imageBytes = await imageFile.readAsBytes();
          
          // Get file extension and determine content type
          final extension = _selectedImagePath!.split('.').last.toLowerCase();
          final fileName = 'avatar.$extension';
          final storagePath = '${user.id}/$fileName';
          
          // Determine content type based on extension
          String contentType = 'image/jpeg'; // default
          switch (extension) {
            case 'png':
              contentType = 'image/png';
              break;
            case 'webp':
              contentType = 'image/webp';
              break;
            case 'gif':
              contentType = 'image/gif';
              break;
            case 'jpg':
            case 'jpeg':
            default:
              contentType = 'image/jpeg';
              break;
          }
          
          // Upload to Supabase storage
          Logger.info('Uploading avatar to Supabase storage: $storagePath (${imageBytes.length} bytes)');
          try {
            await SupabaseConfig.client.storage
                .from('avatars')
                .uploadBinary(
                  storagePath,
                  imageBytes,
                  fileOptions: FileOptions(
                    upsert: true, // Replace existing file
                    contentType: contentType,
                  ),
                );
            
            // Get public URL
            final publicUrl = SupabaseConfig.client.storage
                .from('avatars')
                .getPublicUrl(storagePath);
            
            if (publicUrl.isEmpty) {
              throw Exception('Failed to get public URL for uploaded avatar');
            }
            
            avatarUrl = publicUrl;
            print('[_handleSave] Avatar uploaded successfully: $avatarUrl');
            Logger.info('Avatar uploaded successfully: $avatarUrl');
            
            // Verify avatarUrl is set
            if (avatarUrl.isEmpty) {
              throw Exception('Avatar URL is empty after upload');
            }
          } catch (e, stackTrace) {
            print('[_handleSave] ERROR uploading avatar: $e');
            Logger.error('Failed to upload avatar to Supabase storage', error: e, stackTrace: stackTrace);
            throw Exception('Failed to upload avatar: ${e.toString()}');
          }
        }
      }
      
      print('[_handleSave] Final avatarUrl after processing: $avatarUrl');
      
      // Prepare update values
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final username = _usernameController.text.trim();
      
      // Check if we have at least one field to update
      final hasFirstName = firstName.isNotEmpty;
      final hasLastName = lastName.isNotEmpty;
      final hasUsername = username.isNotEmpty && username != _originalUsername;
      final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
      
      print('[_handleSave] Field check - hasFirstName: $hasFirstName, hasLastName: $hasLastName, hasUsername: $hasUsername, hasAvatar: $hasAvatar');
      print('[_handleSave] Values - firstName: "$firstName", lastName: "$lastName", username: "$username", avatarUrl: "$avatarUrl"');
      
      // Log what we're sending BEFORE validation
      Logger.info('Profile update check - firstName: ${hasFirstName ? "set ($firstName)" : "null"}, '
          'lastName: ${hasLastName ? "set ($lastName)" : "null"}, '
          'username: ${hasUsername ? "set ($username)" : "null"}, '
          'avatarUrl: ${hasAvatar ? "set ($avatarUrl)" : "null"}, '
          '_newImageFile: ${_newImageFile != null ? "set" : "null"}, '
          '_selectedImagePath: $_selectedImagePath, '
          '_originalImagePath: $_originalImagePath');
      
      if (!hasFirstName && !hasLastName && !hasUsername && !hasAvatar) {
        final errorMsg = 'Please make at least one change to update your profile. '
            'Image selected: ${_newImageFile != null}, '
            'Selected path: $_selectedImagePath, '
            'Original path: $_originalImagePath';
        print('[_handleSave] ERROR: $errorMsg');
        Logger.warning(errorMsg);
        if (mounted) {
          setState(() {
            _errorMessage = 'Please make at least one change to update your profile';
          });
        }
        return;
      }
      
      print('[_handleSave] Calling updateProfile with - firstName: ${hasFirstName ? firstName : null}, '
          'lastName: ${hasLastName ? lastName : null}, '
          'username: ${hasUsername ? username : null}, '
          'avatarUrl: ${hasAvatar ? avatarUrl : null}');
      
      // Log what we're sending to API
      Logger.info('Calling updateProfile API with - firstName: ${hasFirstName ? firstName : "null"}, '
          'lastName: ${hasLastName ? lastName : "null"}, '
          'username: ${hasUsername ? username : "null"}, '
          'avatarUrl: ${hasAvatar ? avatarUrl : "null"}');
      
      // Update profile
      await authRepo.updateProfile(
        firstName: hasFirstName ? firstName : null,
        lastName: hasLastName ? lastName : null,
        username: hasUsername ? username : null,
        avatarUrl: hasAvatar ? avatarUrl : null,
      );
      
      print('[_handleSave] Profile update successful');
      
      // Change password if provided
      if (_newPasswordController.text.isNotEmpty) {
        if (!SupabaseConfig.isInitialized) {
          throw Exception('Supabase not initialized');
        }
        
        await SupabaseConfig.client.auth.updateUser(
          UserAttributes(password: _newPasswordController.text),
        );
      }
      
      // Invalidate user provider to refresh
      ref.invalidate(currentUserProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
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
      final errorMsg = ErrorHandler.getErrorMessage(
        e,
        defaultMessage: ErrorHandler.getDefaultErrorMessage('update profile'),
      );
      
      if (mounted) {
        setState(() {
          _errorMessage = errorMsg;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final userAsync = ref.watch(currentUserProvider);
    
    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Not authenticated')),
          );
        }
        
        final titleColor = DynamicTheme.getPrimaryTextColor(colorScheme);
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Profile'),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: DynamicTheme.getPrimaryIconColor(colorScheme),
              ),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacingLg),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: AppTheme.spacingLg),
                    
                    // Profile picture section
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              UserAvatar(
                                imageUrl: _selectedImagePath?.startsWith('http') == true 
                                    ? _selectedImagePath 
                                    : null,
                                imagePath: _selectedImagePath?.startsWith('http') != true 
                                    ? _selectedImagePath 
                                    : null,
                                name: user.name,
                                size: 100,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: DynamicTheme.getCardBackgroundColor(colorScheme),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: DynamicTheme.getPrimaryIconColor(colorScheme),
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.camera_alt,
                                      color: DynamicTheme.getPrimaryIconColor(colorScheme),
                                      size: 20,
                                    ),
                                    onPressed: _pickImage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppTheme.spacingSm),
                          TextButton(
                            onPressed: _pickImage,
                            child: Text(
                              'Change Picture',
                              style: TextStyle(
                                color: DynamicTheme.getPrimaryTextColor(colorScheme),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: AppTheme.spacingXl),
                    
                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.error, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingLg),
                    ],
                    
                    // First Name field
                    TextFormField(
                      controller: _firstNameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(
                        color: DynamicTheme.getInputTextColor(colorScheme),
                      ),
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        hintText: 'John',
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: DynamicTheme.getInputHintColor(colorScheme),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty && value.trim().length < 2) {
                          return 'First name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: AppTheme.spacingMd),
                    
                    // Last Name field
                    TextFormField(
                      controller: _lastNameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(
                        color: DynamicTheme.getInputTextColor(colorScheme),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        hintText: 'Doe',
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: DynamicTheme.getInputHintColor(colorScheme),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty && value.trim().length < 2) {
                          return 'Last name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: AppTheme.spacingMd),
                    
                    // Username field with real-time validation
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9]')),
                      ],
                      style: TextStyle(
                        color: DynamicTheme.getInputTextColor(colorScheme),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'johndoe',
                        prefixIcon: Icon(
                          Icons.alternate_email,
                          color: DynamicTheme.getInputHintColor(colorScheme),
                        ),
                        suffixIcon: _isCheckingUsername
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      DynamicTheme.getInputTextColor(colorScheme),
                                    ),
                                  ),
                                ),
                              )
                            : _usernameAvailable == true
                                ? const Icon(Icons.check_circle, color: AppColors.success)
                                : _usernameAvailable == false
                                    ? const Icon(Icons.cancel, color: AppColors.error)
                                    : null,
                        helperText: _usernameMessage,
                        helperMaxLines: 2,
                        helperStyle: TextStyle(
                          color: DynamicTheme.getSecondaryTextColor(colorScheme),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a username';
                        }
                        
                        final trimmedValue = value.trim();
                        
                        try {
                          Validation.validateUsername(trimmedValue);
                        } on ValidationException catch (e) {
                          return e.message;
                        }
                        
                        if (trimmedValue != _originalUsername) {
                          if (_usernameAvailable == false) {
                            return _usernameMessage ?? 'Username is not available';
                          }
                          if (_isCheckingUsername) {
                            return 'Checking username availability...';
                          }
                          if (_usernameAvailable != true) {
                            return 'Please wait for username validation';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: AppTheme.spacingXl),
                    
                    // Password change section
                    Text(
                      'Change Password',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                    ),
                    
                    SizedBox(height: AppTheme.spacingMd),
                    
                    // Current password field
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrentPassword,
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(
                        color: DynamicTheme.getInputTextColor(colorScheme),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        hintText: 'Enter current password',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: DynamicTheme.getInputHintColor(colorScheme),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrentPassword 
                                ? Icons.visibility_outlined 
                                : Icons.visibility_off_outlined,
                            color: DynamicTheme.getInputHintColor(colorScheme),
                          ),
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                _obscureCurrentPassword = !_obscureCurrentPassword;
                              });
                            }
                          },
                        ),
                      ),
                      validator: (value) {
                        if (_newPasswordController.text.isNotEmpty && 
                            (value == null || value.trim().isEmpty)) {
                          return 'Please enter your current password';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: AppTheme.spacingMd),
                    
                    // New password field
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(
                        color: DynamicTheme.getInputTextColor(colorScheme),
                      ),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Enter new password',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: DynamicTheme.getInputHintColor(colorScheme),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword 
                                ? Icons.visibility_outlined 
                                : Icons.visibility_off_outlined,
                            color: DynamicTheme.getInputHintColor(colorScheme),
                          ),
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            }
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          try {
                            Validation.validatePassword(value);
                          } on ValidationException catch (e) {
                            return e.message;
                          }
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: AppTheme.spacingMd),
                    
                    // Confirm password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(
                        color: DynamicTheme.getInputTextColor(colorScheme),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        hintText: 'Confirm new password',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: DynamicTheme.getInputHintColor(colorScheme),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword 
                                ? Icons.visibility_outlined 
                                : Icons.visibility_off_outlined,
                            color: DynamicTheme.getInputHintColor(colorScheme),
                          ),
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            }
                          },
                        ),
                        helperText: _showPasswordMatchFeedback
                            ? (_passwordsMatch 
                                ? 'Passwords match' 
                                : 'Passwords do not match')
                            : null,
                        helperMaxLines: 1,
                        helperStyle: TextStyle(
                          color: _showPasswordMatchFeedback
                              ? (_passwordsMatch 
                                  ? AppColors.success 
                                  : AppColors.error)
                              : DynamicTheme.getSecondaryTextColor(colorScheme),
                        ),
                      ),
                      validator: (value) {
                        if (_newPasswordController.text.isNotEmpty) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: AppTheme.spacingXl),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    DynamicTheme.getPrimaryTextColor(colorScheme),
                                  ),
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
