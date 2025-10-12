class AppException implements Exception {
  final String message;
  AppException([this.message = "Ocurrió un error"]);
  @override
  String toString() => "AppException: $message";
}
