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
  late PagifyAsyncCallStatus currentState;
  late PagifyAsyncCallStatus lastStateBeforeNetworkError;
  late final StreamController<PagifyAsyncCallStatus> _controller;

  void _init(){
    currentState = PagifyAsyncCallStatus.initial;
    lastStateBeforeNetworkError = PagifyAsyncCallStatus.initial;
    _controller = StreamController<PagifyAsyncCallStatus>();
  }

  AsyncCallStatusInterceptor(){
    _init();
  }


  void updateAllStatues(PagifyAsyncCallStatus newStatus){
    updateStatus(newStatus);
    setLastStatus(newStatus);
  }

  void updateStatus(PagifyAsyncCallStatus newStatus){
    currentState = newStatus;
    _controller.add(newStatus);
  }

  void setLastStatus(PagifyAsyncCallStatus newStatus){
    if(newStatus != PagifyAsyncCallStatus.networkError){
      lastStateBeforeNetworkError = newStatus;
    }
  }

  void setLastStatusAsCurrent(){
    updateStatus(lastStateBeforeNetworkError);
  }
  Stream<PagifyAsyncCallStatus> get stream => _controller.stream;
  Stream<PagifyAsyncCallStatus> get listenStatusChanges{
    return stream;
  }

  void dispose(){
    _controller.close();
  }
}