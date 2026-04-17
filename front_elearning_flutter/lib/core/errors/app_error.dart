class AppError {
  const AppError({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AppError(statusCode: $statusCode, message: $message)';
}
