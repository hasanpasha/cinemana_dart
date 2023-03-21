class UnknowError implements Exception {
  final String? msg;
  const UnknowError(this.msg);

  @override
  String toString() => "UnknowErrorException: $msg";
}

class NotLogged implements Exception {
  final String? msg;
  const NotLogged([this.msg]);

  @override
  String toString() => "NotLoggedException: $msg";
}

class WrongLoginInfo implements Exception {
  final String msg;
  const WrongLoginInfo(this.msg);

  @override
  String toString() => "WrongLoginInfoException: $msg";
}

class NullValue implements Exception {
  final String msg;
  const NullValue(this.msg);

  @override
  String toString() => "NullValueException: $msg";
}

class JsonCorrupted implements Exception {
  final String msg;
  const JsonCorrupted(this.msg);

  @override
  String toString() => "JsonCorruptedException: $msg";
}

class JsonEmpty implements Exception {
  final String? msg;
  const JsonEmpty(this.msg);

  @override
  String toString() => "JsonEmptyException: $msg";
}

class InvalidClient implements Exception {
  final String msg;
  const InvalidClient(this.msg);

  @override
  String toString() => "InvalidClientException: $msg";
}

class InvalidScope implements Exception {
  final String? msg;
  const InvalidScope(this.msg);

  @override
  String toString() => "InvalidScopeException: $msg";
}
