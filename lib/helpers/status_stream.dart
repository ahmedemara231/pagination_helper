import 'dart:async';

/// Represents the different states of an asynchronous paginated API call.
enum PagifyAsyncCallStatus {
  /// The initial state before any request is made.
  initial,

  /// Indicates that a request is currently loading.
  loading,

  /// Indicates that the request was successful.
  success,

  /// Indicates that an error occurred during the request.
  error,

  /// Indicates that the request failed due to network connectivity issues.
  networkError,
}

/// Extension methods to simplify checking the current [PagifyAsyncCallStatus].
extension AsyncCallStatusExtension on PagifyAsyncCallStatus {
  /// Returns `true` if the status is [PagifyAsyncCallStatus.loading].
  bool get isLoading => this == PagifyAsyncCallStatus.loading;

  /// Returns `true` if the status is [PagifyAsyncCallStatus.error].
  bool get isError => this == PagifyAsyncCallStatus.error;

  /// Returns `true` if the status is [PagifyAsyncCallStatus.networkError].
  bool get isNetworkError => this == PagifyAsyncCallStatus.networkError;

  /// Returns `true` if the status is [PagifyAsyncCallStatus.success].
  bool get isSuccess => this == PagifyAsyncCallStatus.success;
}

/// A singleton service that manages and broadcasts updates
/// to the current [PagifyAsyncCallStatus].
///
/// This class is used by [Pagify] to keep track of and notify
/// listeners when the API call status changes.
class AsyncCallStatusInterceptor {
  static AsyncCallStatusInterceptor? _instance;

  /// Returns the singleton instance of [AsyncCallStatusInterceptor].
  static AsyncCallStatusInterceptor get instance =>
      _instance ??= AsyncCallStatusInterceptor();

  /// The current async call status.
  late PagifyAsyncCallStatus currentState;

  /// The last status before a network error occurred.
  late PagifyAsyncCallStatus lastStateBeforeNetworkError;

  /// Stream controller to broadcast status changes.
  late final StreamController<PagifyAsyncCallStatus> _controller;

  /// Initializes the interceptor with default values.
  void _init() {
    currentState = PagifyAsyncCallStatus.initial;
    lastStateBeforeNetworkError = PagifyAsyncCallStatus.initial;
    _controller = StreamController<PagifyAsyncCallStatus>.broadcast();
  }

  /// Creates a new [AsyncCallStatusInterceptor] and initializes it.
  AsyncCallStatusInterceptor() {
    _init();
  }

  /// Updates both the current and last statuses.
  void updateAllStatues(PagifyAsyncCallStatus newStatus) {
    if(_controller.hasListener && !_controller.isClosed){
      updateStatus(newStatus);
      setLastStatus(newStatus);
    }
  }

  /// Updates the current status and notifies listeners.
  void updateStatus(PagifyAsyncCallStatus newStatus) {
    currentState = newStatus;
    _controller.add(newStatus);
  }

  /// Sets the last status before a network error occurred.
  void setLastStatus(PagifyAsyncCallStatus newStatus) {
    if (newStatus != PagifyAsyncCallStatus.networkError) {
      lastStateBeforeNetworkError = newStatus;
    }
  }

  /// Restores the last status before network error as the current status.
  ///
  /// If the last status was [PagifyAsyncCallStatus.loading], the provided
  /// [ifLastIsLoading] callback will be invoked.
  void setLastStatusAsCurrent({
    required Future<void> Function() ifLastIsLoading,
  }) {
    if (lastStateBeforeNetworkError == PagifyAsyncCallStatus.loading) {
      ifLastIsLoading.call();
    } else {
      updateStatus(lastStateBeforeNetworkError);
    }
  }

  /// Returns the broadcast stream of status changes.
  Stream<PagifyAsyncCallStatus> get stream => _controller.stream;

  /// Alias for [stream], used for semantic clarity.
  Stream<PagifyAsyncCallStatus> get listenStatusChanges {
    return stream;
  }

  /// Closes the stream and resets the singleton instance.
  void dispose() {
    _controller.close();
    _instance = null;
  }
}
