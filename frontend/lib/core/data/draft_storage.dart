import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/utils/logger.dart';

/// Local storage service for drafts
/// 
/// Provides crash-safe persistence of drafts using SharedPreferences.
/// This ensures drafts survive app crashes, phone shutdowns, and navigation.
/// 
/// Storage Strategy:
/// - Each draft is stored as a JSON string under a key: "draft_<draftId>"
/// - Draft list is stored as a JSON array under "drafts_<userId>"
/// - Local saves happen immediately (synchronous)
/// - Remote sync can be added later without changing this interface
class DraftStorage {
  static const String _draftPrefix = 'draft_';
  static const String _draftsListPrefix = 'drafts_';
  
  // Lock to prevent concurrent updates to draft lists (per user)
  // Uses a queue of completers to ensure sequential processing
  static final Map<String, List<Completer<void>>> _updateQueues = {};

  /// Save a draft locally (immediate, synchronous)
  /// 
  /// This is crash-safe and happens immediately to prevent data loss.
  /// Never blocks the UI thread.
  /// 
  /// [isNewDraft] - If true, adds draft to list. If false, assumes draft already in list.
  static Future<void> saveDraft(String userId, Draft draft, {bool isNewDraft = false}) async {
    try {
      Logger.debug('Saving draft: ${draft.id} for user: $userId, content length: ${draft.body.length}, isNew: $isNewDraft');
      final prefs = await SharedPreferences.getInstance();
      
      // Save individual draft
      final draftKey = '$_draftPrefix${draft.id}';
      final draftJson = _draftToJson(draft);
      final saved = await prefs.setString(draftKey, draftJson);
      Logger.debug('Draft saved to key: $draftKey, success: $saved');
      
      // Verify it was saved
      final verification = prefs.getString(draftKey);
      if (verification == null) {
        Logger.error('Draft save verification failed - draft was not saved!');
        throw Exception('Draft save verification failed');
      }
      Logger.debug('Draft save verified successfully');
      
      // Only update draft list if this is a new draft
      // For updates, the draft ID should already be in the list
      if (isNewDraft) {
        await _updateDraftList(userId, draft.id);
      } else {
        // For updates, verify the draft is in the list (safety check)
        final listKey = '$_draftsListPrefix$userId';
        final draftIdsJson = prefs.getString(listKey);
        if (draftIdsJson != null) {
          final draftIds = List<String>.from(jsonDecode(draftIdsJson));
          if (!draftIds.contains(draft.id)) {
            Logger.warning('Draft ${draft.id} not in list during update, adding it');
            await _updateDraftList(userId, draft.id);
          }
        } else {
          Logger.warning('Draft list not found during update, creating it');
          await _updateDraftList(userId, draft.id);
        }
      }
      
      Logger.info('Draft saved locally: ${draft.id} for user: $userId');
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to save draft locally',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - local save failures should be silent
      // Remote sync will retry if needed
    }
  }

  /// Get a draft by ID
  static Future<Draft?> getDraft(String draftId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = '$_draftPrefix$draftId';
      final draftJson = prefs.getString(draftKey);
      
      if (draftJson == null) return null;
      
      return _draftFromJson(draftJson);
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get draft',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get all drafts for a user
  static Future<List<Draft>> getAllDrafts(String userId) async {
    try {
      Logger.debug('Getting all drafts for user: $userId');
      final prefs = await SharedPreferences.getInstance();
      final listKey = '$_draftsListPrefix$userId';
      final draftIdsJson = prefs.getString(listKey);
      
      Logger.debug('Draft list key: $listKey, JSON: $draftIdsJson');
      
      if (draftIdsJson == null) {
        Logger.debug('No draft list found for user: $userId');
        return [];
      }
      
      final draftIds = List<String>.from(jsonDecode(draftIdsJson));
      Logger.debug('Found ${draftIds.length} draft IDs: ${draftIds.join(", ")}');
      
      // Deduplicate draft IDs (remove duplicates from list)
      final uniqueDraftIds = <String>{};
      final deduplicatedIds = <String>[];
      for (final draftId in draftIds) {
        if (!uniqueDraftIds.contains(draftId)) {
          uniqueDraftIds.add(draftId);
          deduplicatedIds.add(draftId);
        } else {
          Logger.warning('Found duplicate draft ID in list: $draftId');
        }
      }
      
      // If we found duplicates, clean up the list in storage
      if (deduplicatedIds.length != draftIds.length) {
        Logger.info(
          'Cleaning up duplicate draft IDs: ${draftIds.length} -> ${deduplicatedIds.length}'
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(listKey, jsonEncode(deduplicatedIds));
      }
      
      // Load all drafts in parallel for better performance
      // This is much faster than sequential loading
      final draftFutures = deduplicatedIds.map((draftId) => getDraft(draftId));
      final draftResults = await Future.wait(draftFutures);
      
      final drafts = <Draft>[];
      final seenDraftIds = <String>{}; // Track by ID to prevent duplicates
      
      for (final draft in draftResults) {
        if (draft == null) continue;
        
        // Final deduplication check: ensure we don't add the same draft twice
        if (!seenDraftIds.contains(draft.id)) {
          seenDraftIds.add(draft.id);
          Logger.debug('Loaded draft: ${draft.id}, content length: ${draft.body.length}');
          drafts.add(draft);
        } else {
          Logger.warning('Draft with ID ${draft.id} already loaded (duplicate)');
        }
      }
      
      Logger.debug('Returning ${drafts.length} unique drafts for user: $userId');
      
      // Sort by lastEdited (most recent first)
      drafts.sort((a, b) => b.lastEdited.compareTo(a.lastEdited));
      
      return drafts;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get all drafts for user: $userId',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Delete a draft
  static Future<void> deleteDraft(String userId, String draftId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove draft
      final draftKey = '$_draftPrefix$draftId';
      await prefs.remove(draftKey);
      
      // Remove from list
      final listKey = '$_draftsListPrefix$userId';
      final draftIdsJson = prefs.getString(listKey);
      
      if (draftIdsJson != null) {
        final draftIds = List<String>.from(jsonDecode(draftIdsJson));
        draftIds.remove(draftId);
        await prefs.setString(listKey, jsonEncode(draftIds));
      }
      
      Logger.debug('Draft deleted locally: $draftId');
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to delete draft',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - deletion failures should be handled gracefully
    }
  }

  /// Update the user's draft list (atomic operation with queue-based locking)
  /// 
  /// Uses a per-user queue to ensure sequential processing and prevent race conditions
  /// when multiple saves happen simultaneously for the same user.
  static Future<void> _updateDraftList(String userId, String draftId) async {
    // Create completer for this operation
    final completer = Completer<void>();
    
    // Add to queue for this user
    if (!_updateQueues.containsKey(userId)) {
      _updateQueues[userId] = [];
    }
    _updateQueues[userId]!.add(completer);
    
    // If this is not the first item in queue, wait for previous operations
    if (_updateQueues[userId]!.length > 1) {
      // Wait for the previous operation (second-to-last in queue)
      final previousIndex = _updateQueues[userId]!.length - 2;
      try {
        await _updateQueues[userId]![previousIndex].future;
      } catch (e) {
        // Ignore errors from previous operations
      }
    }
    
    try {
      Logger.debug('Updating draft list for user: $userId, adding draft: $draftId');
      final prefs = await SharedPreferences.getInstance();
      final listKey = '$_draftsListPrefix$userId';
      
      // Read current list (atomic read)
      final draftIdsJson = prefs.getString(listKey);
      
      List<String> draftIds;
      if (draftIdsJson == null) {
        Logger.debug('Creating new draft list for user: $userId');
        draftIds = [draftId];
      } else {
        draftIds = List<String>.from(jsonDecode(draftIdsJson));
        Logger.debug('Existing draft list has ${draftIds.length} drafts');
        
        // Deduplicate existing list first (clean up any existing duplicates)
        final uniqueIds = <String>{};
        final cleanedIds = <String>[];
        for (final id in draftIds) {
          if (!uniqueIds.contains(id)) {
            uniqueIds.add(id);
            cleanedIds.add(id);
          }
        }
        draftIds = cleanedIds;
        
        // Now add the new draft ID if it doesn't exist
        if (!draftIds.contains(draftId)) {
          draftIds.add(draftId);
          Logger.debug('Added draft $draftId to list');
        } else {
          Logger.debug('Draft $draftId already in list - skipping update');
          completer.complete();
          _updateQueues[userId]!.remove(completer);
          if (_updateQueues[userId]!.isEmpty) {
            _updateQueues.remove(userId);
          }
          return; // Early return - no need to write if already present
        }
      }
      
      // Write updated list (atomic write)
      final saved = await prefs.setString(listKey, jsonEncode(draftIds));
      Logger.debug('Draft list saved: $saved, total drafts: ${draftIds.length}');
      
      // Verify and clean up any duplicates that might have been created
      final verification = prefs.getString(listKey);
      if (verification == null) {
        Logger.error('Draft list save verification failed!');
      } else {
        final verifiedIds = List<String>.from(jsonDecode(verification));
        Logger.debug('Draft list verified: ${verifiedIds.length} drafts');
        
        // Check for duplicates in verification
        final uniqueVerified = <String>{};
        final cleanedVerified = <String>[];
        for (final id in verifiedIds) {
          if (!uniqueVerified.contains(id)) {
            uniqueVerified.add(id);
            cleanedVerified.add(id);
          } else {
            Logger.warning('Found duplicate draft ID in storage: $id');
          }
        }
        
        // If duplicates found, clean them up immediately
        if (verifiedIds.length != cleanedVerified.length) {
          Logger.info(
            'Cleaning up duplicates in draft list: ${verifiedIds.length} -> ${cleanedVerified.length}'
          );
          await prefs.setString(listKey, jsonEncode(cleanedVerified));
        }
      }
      
      completer.complete();
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to update draft list for user: $userId',
        error: e,
        stackTrace: stackTrace,
      );
      completer.completeError(e, stackTrace);
    } finally {
      // Remove from queue
      _updateQueues[userId]?.remove(completer);
      if (_updateQueues[userId]?.isEmpty ?? false) {
        _updateQueues.remove(userId);
      }
    }
  }

  /// Convert Draft to JSON
  static String _draftToJson(Draft draft) {
    return jsonEncode({
      'id': draft.id,
      'userId': draft.userId,
      'title': draft.title,
      'content': draft.body,
      'recipientName': draft.recipientName,
      'recipientAvatar': draft.recipientAvatar,
      'lastEdited': draft.lastEdited.toIso8601String(),
    });
  }

  /// Convert JSON to Draft
  static Draft _draftFromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return Draft(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String?,
      body: map['content'] as String? ?? '',
      recipientName: map['recipientName'] as String?,
      recipientAvatar: map['recipientAvatar'] as String?,
      lastEdited: DateTime.parse(map['lastEdited'] as String),
    );
  }

  /// Clear all drafts for a user (useful for testing or logout)
  static Future<void> clearAllDrafts(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listKey = '$_draftsListPrefix$userId';
      final draftIdsJson = prefs.getString(listKey);
      
      if (draftIdsJson != null) {
        final draftIds = List<String>.from(jsonDecode(draftIdsJson));
        
        // Delete all draft entries
        for (final draftId in draftIds) {
          final draftKey = '$_draftPrefix$draftId';
          await prefs.remove(draftKey);
        }
        
        // Clear the list
        await prefs.remove(listKey);
      }
      
      Logger.debug('All drafts cleared for user: $userId');
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to clear all drafts',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

