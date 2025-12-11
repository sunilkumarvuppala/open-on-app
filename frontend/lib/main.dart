import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/data/supabase_config.dart';
import 'package:openon_app/core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file (bundled as asset)
  try {
    await dotenv.load(fileName: '.env');
    Logger.info('Environment variables loaded from .env file');
    Logger.info('SUPABASE_URL: ${dotenv.env['SUPABASE_URL']?.substring(0, 20) ?? 'not found'}...');
    Logger.info('SUPABASE_ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY']?.substring(0, 20) ?? 'not found'}...');
  } catch (e) {
    Logger.warning(
      'Could not load .env file. Using default values or compile-time constants. '
      'Error: ${e.toString()}'
    );
  }
  
  // Initialize Supabase for connection features
  // Note: Supabase URL and anon key can be set via environment variables:
  //   SUPABASE_URL=http://localhost:54321
  //   SUPABASE_ANON_KEY=your-anon-key
  // Or pass them directly to initialize()
  try {
    await SupabaseConfig.initialize();
    if (SupabaseConfig.isInitialized) {
      Logger.info('Supabase initialized successfully');
    } else {
      Logger.warning(
        'Supabase initialization returned without error but is not initialized. '
        'Check that SUPABASE_URL and SUPABASE_ANON_KEY are set correctly.'
      );
    }
  } catch (e, stackTrace) {
    Logger.error(
      'Failed to initialize Supabase. Connection features will not work. '
      'Error: ${e.toString()}',
      error: e,
      stackTrace: stackTrace,
    );
    // Continue app startup even if Supabase fails (for development)
    // In production, you might want to handle this differently
  }
  
  runApp(
    const ProviderScope(
      child: OpenOnApp(),
    ),
  );
}

class OpenOnApp extends ConsumerWidget {
  const OpenOnApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return MaterialApp.router(
      title: 'OpenOn',
      debugShowCheckedModeBanner: false,
      theme: DynamicTheme.buildTheme(colorScheme),
      routerConfig: router,
      builder: (context, child) {
        // Force consistent text scaling across platforms
        // Use a fixed textScaleFactor of 1.0 to ensure iOS and Android have identical font sizes
        final mediaQuery = MediaQuery.of(context);
        
        return MediaQuery(
          data: mediaQuery.copyWith(
            // Set fixed textScaleFactor to ensure consistent font sizes across iOS and Android
            textScaleFactor: 1.0,
          ),
          child: child!,
        );
      },
    );
  }
}
