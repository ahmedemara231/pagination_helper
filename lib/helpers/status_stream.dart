import 'dart:async';

enum AsyncCallStatus {
  initial,
  loading,
  success,
  error,
  networkError,
}

extension AsyncCallStatusExtension on AsyncCallStatus {
  bool get isLoading => this == AsyncCallStatus.loading;
  bool get isError => this == AsyncCallStatus.error;
  bool get isNetworkError => this == AsyncCallStatus.networkError;
  bool get isSuccess => this == AsyncCallStatus.success;
}

class AsyncCallStatusInterceptor{
  AsyncCallStatus currentState;

  AsyncCallStatusInterceptor(this.currentState);

  final StreamController<AsyncCallStatus> _controller = StreamController<AsyncCallStatus>();
  void updateStatus(AsyncCallStatus newStatus){
    currentState = newStatus;
    _controller.add(newStatus);
  }

  Stream<AsyncCallStatus> get stream => _controller.stream;
  Stream<AsyncCallStatus> get listenStatusChanges{
    return stream;
  }

  void dispose(){
    _controller.close();
  }
}