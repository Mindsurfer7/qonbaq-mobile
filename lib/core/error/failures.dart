import '../../data/models/validation_error.dart';

/// Базовые классы для обработки ошибок
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

/// Ошибки сервера
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Ошибки валидации с деталями
class ValidationFailure extends Failure {
  final List<ValidationError> errors;
  final String? serverMessage;

  const ValidationFailure(
    super.message,
    this.errors, {
    this.serverMessage,
  });
}

/// Ошибки кэша
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Ошибки сети
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Общие ошибки
class GeneralFailure extends Failure {
  const GeneralFailure(super.message);
}

/// Ошибки доступа (403 Forbidden)
class ForbiddenFailure extends Failure {
  const ForbiddenFailure(super.message);
}
