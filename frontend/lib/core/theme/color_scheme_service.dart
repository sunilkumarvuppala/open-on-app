import 'package:shared_preferences/shared_preferences.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/utils/logger.dart';

class ColorSchemeService {
  static const String _schemeKey = 'selected_color_scheme_id';

  /// Get the saved color scheme ID
  static Future<String?> getSavedSchemeId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_schemeKey);
    } catch (e) {
      Logger.error('Error getting saved scheme ID', error: e);
      return null; // Return null on error, will use default
    }
  }

  /// Save the selected color scheme ID
  static Future<void> saveSchemeId(String schemeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_schemeKey, schemeId);
    } catch (e) {
      Logger.error('Error saving scheme ID', error: e);
      // Silently fail - user can still use the app, just won't persist preference
    }
  }

  /// Get the current color scheme (defaults to galaxy aurora)
  static Future<AppColorScheme> getCurrentScheme() async {
    try {
      final schemeId = await getSavedSchemeId();
      if (schemeId != null) {
        final scheme = AppColorScheme.fromId(schemeId);
        if (scheme != null) return scheme;
      }
    } catch (e) {
      Logger.error('Error getting current scheme', error: e);
    }
    return AppColorScheme.galaxyAurora; // Default
  }
}

