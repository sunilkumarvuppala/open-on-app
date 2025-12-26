/// Utility functions for name-based filtering of letters
/// 
/// Provides efficient, case-insensitive matching that supports:
/// - Partial substring matching
/// - Initials matching
/// - Multi-token matching (all tokens must be present)
/// 
/// Security: Input validation and length limits to prevent DoS attacks
library;

import 'package:openon_app/core/constants/app_constants.dart';

/// Maximum length for search queries to prevent performance issues
const int _maxQueryLength = AppConstants.maxFilterQueryLength;

/// Extracts initials from a name string
/// 
/// Examples:
/// - "John Doe" -> "JD"
/// - "Mary" -> "M"
/// - "John Michael Smith" -> "JM"
/// 
/// Performance: Optimized for hot path with early returns
String getInitials(String name) {
  if (name.isEmpty) return '';
  
  // Fast path for single character
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  
  // Find first space efficiently
  final spaceIndex = trimmed.indexOf(' ');
  if (spaceIndex == -1) {
    // Single word - return first character
    return trimmed[0].toUpperCase();
  }
  
  // Two or more words - return first char of first two words
  return '${trimmed[0]}${trimmed[spaceIndex + 1]}'.toUpperCase();
}

/// Normalizes a string for search matching
/// 
/// - Trims whitespace
/// - Converts to lowercase
/// - Normalizes multiple spaces to single space
/// 
/// Performance: Uses efficient regex with precompiled pattern
/// Security: Limits input length to prevent DoS
String normalizeForSearch(String input) {
  // Security: Limit input length to prevent DoS attacks
  if (input.length > _maxQueryLength * 2) {
    input = input.substring(0, _maxQueryLength * 2);
  }
  
  // Performance: Pre-compile regex pattern (Flutter optimizes this)
  return input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');
}

/// Checks if a query matches a display name and/or initials
/// 
/// Matching rules:
/// - Case-insensitive
/// - Partial substring matching in display name
/// - Initials matching
/// - Multi-token matching: if query has multiple tokens (split by space),
///   all tokens must be present in the display name (in any order)
/// 
/// Examples:
/// - query: "john", name: "John Doe" -> true
/// - query: "jd", name: "John Doe" -> true (matches initials)
/// - query: "doe john", name: "John Doe" -> true (all tokens present)
/// - query: "john smith", name: "John Doe" -> false (smith not present)
/// 
/// Security: Validates and limits query length
/// Performance: Early returns, efficient string operations
bool matchesNameQuery(String query, String displayName) {
  // Early return for empty query (matches everything)
  if (query.isEmpty || query.trim().isEmpty) return true;
  
  // Security: Limit query length to prevent DoS
  if (query.length > _maxQueryLength) {
    query = query.substring(0, _maxQueryLength);
  }
  
  // Early return for empty display name
  if (displayName.isEmpty || displayName.trim().isEmpty) return false;
  
  // Normalize inputs once
  final normalizedQuery = normalizeForSearch(query);
  final normalizedName = normalizeForSearch(displayName);
  
  // Fast path: exact substring match
  if (normalizedName.contains(normalizedQuery)) return true;
  
  // Check initials match (only if query is short, likely initials)
  if (normalizedQuery.length <= 3) {
    final initials = getInitials(displayName).toLowerCase();
    if (normalizedQuery == initials) return true;
  }
  
  // Multi-token matching: split query into tokens
  final queryTokens = normalizedQuery.split(' ').where((t) => t.isNotEmpty).toList();
  if (queryTokens.length > 1) {
    // All tokens must be present in the name (early exit on first mismatch)
    for (final token in queryTokens) {
      if (!normalizedName.contains(token)) {
        return false;
      }
    }
    return true;
  }
  
  return false;
}

