import 'dart:async';

enum PagifyAsyncCallStatus {
  initial,
  loading,
  success,
  error,
  networkError,
}

extension AsyncCallStatusExtension on PagifyAsyncCallStatus {
  bool get isLoading => this == PagifyAsyncCallStatus.loading;
  bool get isError => this == PagifyAsyncCallStatus.error;
  bool get isNetworkError => this == PagifyAsyncCallStatus.networkError;
  bool get isSuccess => this == PagifyAsyncCallStatus.success;
}

class AsyncCallStatusInterceptor{
  PagifyAsyncCallStatus currentState;

  AsyncCallStatusInterceptor(this.currentState);

  final StreamController<PagifyAsyncCallStatus> _controller = StreamController<PagifyAsyncCallStatus>();
  void updateStatus(PagifyAsyncCallStatus newStatus){
    currentState = newStatus;
    _controller.add(newStatus);
  }

  Stream<PagifyAsyncCallStatus> get stream => _controller.stream;
  Stream<PagifyAsyncCallStatus> get listenStatusChanges{
    return stream;
  }

  void dispose(){
    _controller.close();
  }
}