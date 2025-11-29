import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/providers/providers.dart';

void main() {
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
