/// Base failure class for clean error propagation through layers.
abstract class Failure {
  final String message;

  const Failure({required this.message});

  @override
  String toString() => '$runtimeType(message: $message)';
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}
