import 'package:openon_app/core/data/repositories.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/utils/uuid_utils.dart';
import 'package:openon_app/core/errors/app_exceptions.dart';

/// Utility class for resolving recipient UUIDs from various sources
/// Ensures consistent recipient ID resolution across the application
class RecipientResolver {
  RecipientResolver._();

  /// Resolves the correct recipient UUID from the provided recipient ID
  /// 
  /// This method handles cases where:
  /// - The recipient ID is already a valid UUID (returns as-is)
  /// - The recipient ID is a linked user ID (finds matching recipient)
  /// - The recipient ID doesn't match any recipient (tries name matching)
  /// 
  /// Returns the validated recipient UUID
  /// Throws RepositoryException if recipient cannot be found
  static Future<String> resolveRecipientId({
    required String recipientId,
    required String currentUserId,
    required RecipientRepository recipientRepo,
    String? recipientName,
  }) async {
    // Step 1: Validate UUID format
    if (UuidUtils.isValidUuid(recipientId)) {
      Logger.debug('Recipient ID is already a valid UUID: $recipientId');
      // Continue to verification step
    } else {
      Logger.warning('Recipient ID is not a valid UUID format: $recipientId');
      // Will try to resolve by linkedUserId or name
    }

    // Step 2: Get recipients list
    final recipients = await recipientRepo.getRecipients(currentUserId);
    Logger.debug('Retrieved ${recipients.length} recipients for resolution');

    // Step 3: Try to find recipient by ID or linkedUserId
    Recipient? matchingRecipient = _findRecipientById(
      recipients: recipients,
      recipientId: recipientId,
    );

    // Step 4: If not found by ID, try by name (fallback)
    if (matchingRecipient == null && recipientName != null) {
      Logger.warning('Recipient not found by ID, trying by name: $recipientName');
      matchingRecipient = _findRecipientByName(
        recipients: recipients,
        recipientName: recipientName,
      );
    }

    // Step 5: Validate and return
    if (matchingRecipient == null) {
      final availableRecipients = recipients.map((r) => 
        'id=${r.id}, linkedUserId=${r.linkedUserId}, name=${r.name}'
      ).join('; ');
      
      Logger.error(
        'Recipient not found: recipientId=$recipientId, '
        'recipientName=$recipientName, totalRecipients=${recipients.length}'
      );
      Logger.debug('Available recipients: $availableRecipients');
      
      throw RepositoryException(
        'Recipient not found. Please refresh the recipients list and try again.',
      );
    }

    // Step 6: Validate the resolved recipient ID is a valid UUID
    final resolvedId = UuidUtils.validateRecipientId(matchingRecipient.id);
    
    if (resolvedId != recipientId) {
      Logger.info(
        'Recipient ID resolved: $recipientId -> $resolvedId '
        '(name: ${matchingRecipient.name})'
      );
    }

    return resolvedId;
  }

  /// Finds a recipient by ID or linkedUserId
  static Recipient? _findRecipientById({
    required List<Recipient> recipients,
    required String recipientId,
  }) {
    try {
      return recipients.firstWhere(
        (r) => r.id == recipientId || r.linkedUserId == recipientId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Finds a recipient by name (case-insensitive)
  static Recipient? _findRecipientByName({
    required List<Recipient> recipients,
    required String recipientName,
  }) {
    try {
      final normalizedName = recipientName.trim().toLowerCase();
      return recipients.firstWhere(
        (r) => r.name.trim().toLowerCase() == normalizedName,
      );
    } catch (e) {
      return null;
    }
  }
}
