mixin Lifecycle {
  bool _disposed = false;
  int _generation = 0;
  bool get isDisposed => _disposed;
  // Starting a newer request invalidates older results even if transport
  // cancellation loses a race; disposal invalidates every outstanding result.
  int beginRequest() => ++_generation;
  bool isCurrent(int request) => !_disposed && request == _generation;
  void dispose() {
    _disposed = true;
    _generation++;
  }
}
