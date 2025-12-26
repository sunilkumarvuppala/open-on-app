import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/error_handler.dart';
import 'package:openon_app/core/utils/validation.dart';
import 'package:openon_app/core/errors/app_exceptions.dart';
import 'package:openon_app/core/data/api_repositories.dart';
import 'package:openon_app/core/data/api_client.dart';
import 'package:openon_app/core/data/api_config.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/constants/app_constants.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final String? inviteToken;
  
  const SignupScreen({
    super.key,
    this.inviteToken,
  });
  
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _passwordsMatch = false;
  bool _showPasswordMatchFeedback = false;
  
  // Username validation state
  bool _isCheckingUsername = false;
  bool? _usernameAvailable;
  String? _usernameMessage;
  Timer? _usernameDebounce;
  
  final ApiUserService _userService = ApiUserService();
  
  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordMatch);
    _confirmPasswordController.addListener(_checkPasswordMatch);
    _usernameController.addListener(_checkUsernameAvailability);
  }
  
  @override
  void dispose() {
    _passwordController.removeListener(_checkPasswordMatch);
    _confirmPasswordController.removeListener(_checkPasswordMatch);
    _usernameController.removeListener(_checkUsernameAvailability);
    _usernameDebounce?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  void _checkPasswordMatch() {
    final password = _passwordController.text;
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
    
    if (username.isEmpty) {
      setState(() {
        _isCheckingUsername = false;
        _usernameAvailable = null;
        _usernameMessage = null;
      });
      return;
    }
    
    // Validate format first
    try {
      Validation.validateUsername(username);
    } on ValidationException catch (e) {
      setState(() {
        _isCheckingUsername = false;
        _usernameAvailable = false;
        _usernameMessage = e.message;
      });
      return;
    }
    
    setState(() {
      _isCheckingUsername = true;
      _usernameAvailable = null;
      _usernameMessage = null;
    });
    
    _usernameDebounce = Timer(const Duration(milliseconds: AppConstants.searchDebounceMs), () async {
      try {
        final result = await _userService.checkUsernameAvailability(username);
        if (mounted) {
          setState(() {
            _isCheckingUsername = false;
            _usernameAvailable = result['available'] as bool;
            _usernameMessage = result['message'] as String;
          });
          
          // Trigger validation only for the username field
          // The autovalidateMode.onUserInteraction will handle this automatically
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
  
  Future<void> _handleSignup() async {
    // Check password match before form validation
    if (!_passwordsMatch && _confirmPasswordController.text.isNotEmpty) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }
    
    if (!_formKey.currentState!.validate()) return;
    
    // Ensure username is available before submitting
    if (_usernameAvailable != true) {
      setState(() {
        _errorMessage = 'Please choose an available username';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
      );
      
      ref.invalidate(currentUserProvider);
      
      // Claim invite if present
      String? letterId;
      if (widget.inviteToken != null && widget.inviteToken!.isNotEmpty) {
        try {
          final apiClient = ApiClient();
          final claimResponse = await apiClient.post(
            ApiConfig.claimInvite(widget.inviteToken!),
            {},
          );
          letterId = claimResponse['letter_id'] as String?;
          Logger.info('Invite claimed successfully: letter_id=$letterId');
        } catch (e) {
          Logger.warning('Failed to claim invite: $e');
          // Don't fail signup if invite claiming fails
        }
      }
      
      await Future.delayed(AppConstants.routerNavigationDelay);
      
      if (mounted) {
        // Navigate to letter if invite was claimed, otherwise go to home
        if (letterId != null) {
          // Navigate directly to the claimed letter
          context.go('/capsule/$letterId');
        } else {
          context.go(Routes.home);
        }
      }
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(
        e,
        defaultMessage: ErrorHandler.getDefaultErrorMessage('create account'),
      );
      
      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    // Theme-aware text colors
    final titleColor = DynamicTheme.getPrimaryTextColor(colorScheme);
    final bodyColor = DynamicTheme.getSecondaryTextColor(colorScheme);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: DynamicTheme.getPrimaryIconColor(
              ref.watch(selectedColorSchemeProvider),
            ),
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
                
                // Title
                Text(
                  'Create account',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                ),
                
                SizedBox(height: AppTheme.spacingSm),
                
                Text(
                  'Start creating meaningful moments',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: bodyColor,
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
                    labelText: 'First Name *',
                    hintText: 'John',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: DynamicTheme.getInputHintColor(colorScheme),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your first name';
                    }
                    if (value.trim().length < 2) {
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
                    labelText: 'Last Name *',
                    hintText: 'Doe',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: DynamicTheme.getInputHintColor(colorScheme),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your last name';
                    }
                    if (value.trim().length < 2) {
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
                  // Input formatter to restrict to lowercase letters and numbers only
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9]')),
                  ],
                  style: TextStyle(
                    color: DynamicTheme.getInputTextColor(colorScheme),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Username *',
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
                    
                    // Validate using Validation class
                    try {
                      Validation.validateUsername(trimmedValue);
                    } on ValidationException catch (e) {
                      return e.message;
                    }
                    
                    if (_usernameAvailable == false) {
                      return _usernameMessage ?? 'Username is not available';
                    }
                    if (_isCheckingUsername) {
                      return 'Checking username availability...';
                    }
                    if (_usernameAvailable != true) {
                      return 'Please wait for username validation';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: AppTheme.spacingMd),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    color: DynamicTheme.getInputTextColor(colorScheme),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    hintText: 'your@email.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: DynamicTheme.getInputHintColor(colorScheme),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: AppTheme.spacingMd),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) => _checkPasswordMatch(),
                  style: TextStyle(
                    color: DynamicTheme.getInputTextColor(colorScheme),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    hintText: 'At least 8 characters',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: DynamicTheme.getInputHintColor(colorScheme),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: DynamicTheme.getInputHintColor(colorScheme),
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < AppConstants.minPasswordLength) {
                      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
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
                  onFieldSubmitted: (_) => _handleSignup(),
                  onChanged: (_) => _checkPasswordMatch(),
                  style: TextStyle(
                    color: DynamicTheme.getInputTextColor(colorScheme),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    hintText: 'Re-enter your password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: DynamicTheme.getInputHintColor(colorScheme),
                    ),
                    suffixIcon: _showPasswordMatchFeedback
                        ? Icon(
                            _passwordsMatch ? Icons.check_circle : Icons.error,
                            color: _passwordsMatch ? AppColors.success : AppColors.error,
                          )
                        : IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: DynamicTheme.getInputHintColor(colorScheme),
                            ),
                            onPressed: () {
                              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                            },
                          ),
                    // Suppress error text when real-time feedback is showing to avoid duplication
                    errorText: _showPasswordMatchFeedback && _confirmPasswordController.text.isNotEmpty
                        ? null
                        : null, // Will be set by validator, but we'll handle it
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    // Check if passwords match
                    if (value != _passwordController.text) {
                      // If real-time feedback is showing, don't show validator error to avoid duplication
                      // The real-time feedback below already shows "Passwords do not match"
                      if (_showPasswordMatchFeedback && _confirmPasswordController.text.isNotEmpty) {
                        // Return null to suppress error display, but validation will still fail
                        // because we check _passwordsMatch in _handleSignup
                        return null;
                      }
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                
                // Real-time password match feedback
                if (_showPasswordMatchFeedback && _confirmPasswordController.text.isNotEmpty) ...[
                  SizedBox(height: AppTheme.spacingXs),
                  Row(
                    children: [
                      Icon(
                        _passwordsMatch ? Icons.check_circle_outline : Icons.error_outline,
                        size: 16,
                        color: _passwordsMatch ? AppColors.success : AppColors.error,
                      ),
                      SizedBox(width: AppTheme.spacingXs),
                      Text(
                        _passwordsMatch ? 'Passwords match' : 'Passwords do not match',
                        style: TextStyle(
                          fontSize: 12,
                          color: _passwordsMatch ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
                
                SizedBox(height: AppTheme.spacingXl),
                
                // Sign up button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _usernameAvailable != true) ? null : _handleSignup,
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
                              valueColor: AlwaysStoppedAnimation<Color>(DynamicTheme.getButtonTextColor(colorScheme)),
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingLg),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DynamicTheme.getSecondaryTextColor(colorScheme),
                          ),
                    ),
                    TextButton(
                      onPressed: () => context.go(Routes.login),
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          color: DynamicTheme.getPrimaryTextColor(colorScheme),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: AppTheme.spacingMd),
                
                // Terms text
                Text(
                  'By creating an account, you agree to our Terms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: bodyColor,
                        fontSize: 12,
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
