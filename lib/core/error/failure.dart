abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}


class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NotFoundFailure extends Failure{
  const NotFoundFailure(super.message);
}

class NetworkFailure extends Failure{
  const NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class UnknownFailure extends Failure{
  const UnknownFailure(super.message);
}