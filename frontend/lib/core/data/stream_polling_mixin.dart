/// Mixin for creating polling streams with consistent behavior.
/// 
/// This mixin provides a reusable pattern for polling-based streams
/// that need to update periodically (e.g., every 5 seconds).
/// 
/// Usage:
/// ```dart
/// class MyRepository with StreamPollingMixin {
///   Stream<List<Item>> watchItems() {
///     return createPollingStream<List<Item>>(
///       loadData: () async {
///         // Load data logic
///         return items;
///       },
///       pollInterval: const Duration(seconds: 5),
///     );
///   }
/// }
/// ```
import 'dart:async';
import 'package:openon_app/core/utils/logger.dart';

mixin StreamPollingMixin {
  /// Creates a polling stream that loads data immediately and then polls at intervals.
  /// 
  /// The stream will:
  /// - Load data immediately when first listened to
  /// - Poll for updates at the specified interval
  /// - Automatically cancel the timer when the stream is closed
  /// - Handle errors gracefully
  Stream<T> createPollingStream<T>({
    required Future<T> Function() loadData,
    Duration pollInterval = const Duration(seconds: 5),
  }) {
    final controller = StreamController<T>.broadcast();
    
    // Load data immediately
    _loadDataWithErrorHandling(controller, loadData);
    
    // Poll for updates at intervals
    Timer? timer;
    timer = Timer.periodic(pollInterval, (t) {
      if (controller.isClosed) {
        t.cancel();
        return;
      }
      _loadDataWithErrorHandling(controller, loadData);
    });
    
    // Cancel timer when stream is closed
    controller.onCancel = () {
      timer?.cancel();
    };
    
    return controller.stream;
  }
  
  /// Helper method to load data with error handling.
  Future<void> _loadDataWithErrorHandling<T>(
    StreamController<T> controller,
    Future<T> Function() loadData,
  ) async {
    try {
      final data = await loadData();
      if (!controller.isClosed) {
        controller.add(data);
      }
    } catch (e, stackTrace) {
      Logger.error('Error loading data in polling stream', error: e, stackTrace: stackTrace);
      if (!controller.isClosed) {
        controller.addError(e, stackTrace);
      }
    }
  }
}
