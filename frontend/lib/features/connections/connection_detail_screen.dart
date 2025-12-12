import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openon_app/core/models/connection_models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/utils/validation.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/models/models.dart';

/// Connection Detail Screen
/// 
/// Displays relationship context between two connected users.
/// This is NOT a chat screen - it shows aggregate statistics and
/// provides a primary action to write a letter.
/// 
/// Design philosophy: Minimal, respectful, non-social.
/// No chat history, no activity feeds, no social features.
class ConnectionDetailScreen extends ConsumerWidget {
  final String connectionId;

  const ConnectionDetailScreen({
    super.key,
    required this.connectionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Validate connectionId for security
    try {
      Validation.validateConnectionId(connectionId);
    } catch (e) {
      Logger.error('Invalid connection ID', error: e);
      return Scaffold(
        backgroundColor: ref.watch(selectedColorSchemeProvider).secondary2,
        appBar: AppBar(
          backgroundColor: ref.watch(selectedColorSchemeProvider).secondary2,
          elevation: 0,
        ),
        body: ErrorDisplay(
          message: AppConstants.connectionNotFoundMessage,
          onRetry: () => context.pop(),
        ),
      );
    }

    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final connectionDetailAsync = ref.watch(
      connectionDetailProvider(connectionId),
    );

    return Scaffold(
      backgroundColor: colorScheme.secondary2,
      appBar: AppBar(
        backgroundColor: colorScheme.secondary2,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: DynamicTheme.getPrimaryIconColor(colorScheme),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppConstants.connectionDetailTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: DynamicTheme.getPrimaryTextColor(colorScheme),
              ),
        ),
        actions: [
          ProfileAvatarButton(),
        ],
      ),
      body: connectionDetailAsync.when(
        data: (detail) => _buildContent(context, ref, detail, colorScheme),
        loading: () => Center(
          child: CircularProgressIndicator(
            color: DynamicTheme.getPrimaryIconColor(colorScheme),
          ),
        ),
        error: (error, stack) {
          Logger.error('Error loading connection detail', error: error, stackTrace: stack);
          final errorMessage = error.toString().replaceAll('Exception: ', '');
          return ErrorDisplay(
            message: errorMessage.isNotEmpty 
                ? errorMessage 
                : AppConstants.failedToLoadConnectionDetailsMessage,
            onRetry: () {
              ref.invalidate(connectionDetailProvider(connectionId));
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ConnectionDetail detail,
    AppColorScheme colorScheme,
  ) {
    final connection = detail.connection;
    final profile = connection.otherUserProfile;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section - Minimal
          _buildHeader(context, profile, connection, colorScheme),
          
          SizedBox(height: AppTheme.spacingXl),
          
          // Relationship Summary Card
          _buildRelationshipSummary(context, detail, colorScheme),
          
          SizedBox(height: AppTheme.spacingXl),
          
          // Primary Action
          _buildPrimaryAction(context, ref, connection, colorScheme),
          
          SizedBox(height: AppTheme.spacingXl),
          
          // Empty State Placeholder (NOT a letter list)
          _buildEmptyStatePlaceholder(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ConnectionUserProfile profile,
    Connection connection,
    AppColorScheme colorScheme,
  ) {
    return Row(
      children: [
        // Avatar with initials fallback
        UserAvatar(
          name: profile.displayName,
          imageUrl: profile.avatarUrl,
          size: AppConstants.connectionDetailAvatarSize,
        ),
        SizedBox(width: AppTheme.spacingMd),
        
        // Name and metadata
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display name
              Text(
                profile.displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: DynamicTheme.getPrimaryTextColor(colorScheme),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              
              // Username (optional, subtle)
              if (profile.username != null) ...[
                SizedBox(height: AppTheme.spacingXs),
                Text(
                  '@${profile.username}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DynamicTheme.getSecondaryTextColor(colorScheme),
                      ),
                ),
              ],
              
              // Connected since date (small, muted)
              SizedBox(height: AppTheme.spacingXs),
              Text(
                '${AppConstants.connectedSincePrefix} ${_formatDate(connection.connectedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DynamicTheme.getSecondaryTextColor(colorScheme),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRelationshipSummary(
    BuildContext context,
    ConnectionDetail detail,
    AppColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: DynamicTheme.getCardBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: DynamicTheme.getTabContainerBorder(colorScheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            AppConstants.relationshipSummaryTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: DynamicTheme.getPrimaryTextColor(colorScheme),
                  fontWeight: FontWeight.w600,
                ),
          ),
          
          SizedBox(height: AppTheme.spacingLg),
          
          // Two metrics in a row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                AppConstants.lettersSentLabel,
                detail.lettersSent.toString(),
                colorScheme,
              ),
              Container(
                width: AppConstants.connectionDetailStatDividerWidth,
                height: AppConstants.connectionDetailStatDividerHeight,
                color: DynamicTheme.getSecondaryTextColor(colorScheme)
                    .withOpacity(AppTheme.opacityLow),
              ),
              _buildStatItem(
                context,
                AppConstants.lettersReceivedLabel,
                detail.lettersReceived.toString(),
                colorScheme,
              ),
            ],
          ),
          
          SizedBox(height: AppTheme.spacingLg),
          
          // Optional copy (static text)
          Text(
            AppConstants.relationshipSummaryMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DynamicTheme.getSecondaryTextColor(colorScheme),
                  fontStyle: FontStyle.normal,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds a stat item widget (memoized for performance)
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    AppColorScheme colorScheme,
  ) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: DynamicTheme.getPrimaryTextColor(colorScheme),
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: AppTheme.spacingXs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DynamicTheme.getSecondaryTextColor(colorScheme),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction(
    BuildContext context,
    WidgetRef ref,
    Connection connection,
    AppColorScheme colorScheme,
  ) {
    return SizedBox(
      width: double.infinity,
      height: AppConstants.connectionDetailButtonHeight,
      child: ElevatedButton(
        onPressed: () async {
        // Navigate to write letter flow with recipient prefilled
        try {
          final userAsync = ref.read(currentUserProvider);
          final user = await userAsync.when(
            data: (data) => Future.value(data),
            loading: () => Future.value(null),
            error: (_, __) => Future.value(null),
          );

          if (user == null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppConstants.pleaseLogInMessage,
                    style: TextStyle(
                      color: DynamicTheme.getSnackBarTextColor(colorScheme),
                    ),
                  ),
                  backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
                ),
              );
            }
            return;
          }

          // Validate connection ID for security
          try {
            Validation.validateConnectionId(connection.otherUserId);
          } catch (e) {
            Logger.error('Invalid connection user ID', error: e);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppConstants.connectionNotFoundMessage,
                    style: TextStyle(
                      color: DynamicTheme.getSnackBarTextColor(colorScheme),
                    ),
                  ),
                  backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
                ),
              );
            }
            return;
          }

          // Find recipient for this connection
          // Note: Recipients should be auto-created when connections are established
          // If not found, refresh the recipients list (backend will create missing ones)
          Recipient? recipient;
          
          try {
            // First attempt: Try to find existing recipient
            final recipientsAsync = ref.read(recipientsProvider(user.id));
            var recipients = await recipientsAsync.when(
              data: (data) => Future.value(data),
              loading: () => Future.value(<Recipient>[]),
              error: (_, __) => Future.value(<Recipient>[]),
            );

            // Try to find existing recipient by linkedUserId
            try {
              recipient = recipients.firstWhere(
                (r) => r.linkedUserId == connection.otherUserId,
              );
              Logger.info('Found existing recipient: ${recipient.id}');
            } catch (e) {
              // Recipient not found - refresh recipients list
              // Backend's list_recipients endpoint will auto-create missing recipients
              Logger.info('Recipient not found, refreshing recipients list to trigger auto-creation');
              ref.invalidate(recipientsProvider(user.id));
              
              // Wait a bit for the refresh to complete
              await Future.delayed(const Duration(milliseconds: 500));
              
              // Try again after refresh
              final refreshedRecipientsAsync = ref.read(recipientsProvider(user.id));
              recipients = await refreshedRecipientsAsync.when(
                data: (data) => Future.value(data),
                loading: () => Future.value(<Recipient>[]),
                error: (_, __) => Future.value(<Recipient>[]),
              );
              
              try {
                recipient = recipients.firstWhere(
                  (r) => r.linkedUserId == connection.otherUserId,
                );
                Logger.info('Found recipient after refresh: ${recipient.id}');
              } catch (e2) {
                // Still not found - create temporary recipient for draft
                // Backend will create the actual recipient when needed
                Logger.warning(
                  'Recipient still not found after refresh. Using temporary recipient. '
                  'Backend will create it when needed.'
                );
                final sanitizedName = Validation.sanitizeString(
                  connection.otherUserProfile.displayName,
                );
                recipient = Recipient(
                  userId: user.id,
                  name: sanitizedName,
                  relationship: AppConstants.defaultRelationshipType,
                  avatar: connection.otherUserProfile.avatarUrl ?? '',
                  linkedUserId: connection.otherUserId,
                );
              }
            }

            // Set recipient in draft and navigate
            // Note: recipient is guaranteed to be non-null due to fallback logic above
            ref.read(draftCapsuleProvider.notifier).setRecipient(recipient);
          } catch (e, stackTrace) {
            Logger.error('Error finding recipient', error: e, stackTrace: stackTrace);
            // Don't rethrow - show user-friendly error instead
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Unable to prepare letter. Please try again.',
                    style: TextStyle(
                      color: DynamicTheme.getSnackBarTextColor(colorScheme),
                    ),
                  ),
                  backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
                ),
              );
            }
            return; // Exit early instead of navigating
          }

          if (context.mounted) {
            context.push(Routes.createCapsule);
          }
        } catch (e) {
          Logger.error('Error navigating to write letter', error: e);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppConstants.failedToPrepareLetterMessage,
                  style: TextStyle(
                    color: DynamicTheme.getSnackBarTextColor(colorScheme),
                  ),
                ),
                backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
              ),
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary1,
        foregroundColor: DynamicTheme.getButtonTextColor(colorScheme),
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
        side: DynamicTheme.getButtonBorderSide(colorScheme),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppConstants.writeLetterButtonText,
            style: const TextStyle(
              fontSize: AppConstants.connectionDetailButtonTextSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppConstants.connectionDetailButtonIconSpacing),
          Icon(
            Icons.send_outlined,
            size: AppConstants.connectionDetailButtonIconSize,
            color: DynamicTheme.getButtonTextColor(colorScheme),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyStatePlaceholder(
    BuildContext context,
    AppColorScheme colorScheme,
  ) {
    // This is intentionally NOT a letter list
    // It's a subtle placeholder explaining that letters will appear
    // when opened (in their respective inbox/outbox screens)
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: DynamicTheme.getCardBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: DynamicTheme.getTabContainerBorder(colorScheme),
      ),
      child: Center(
        child: Text(
          AppConstants.lettersPlaceholderText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DynamicTheme.getSecondaryTextColor(colorScheme),
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat(AppConstants.connectionDateFormat).format(date);
  }
}

