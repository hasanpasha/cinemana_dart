import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:multiple_result/multiple_result.dart';

import 'package:cinemana/constants/exceptions.dart';
import 'package:cinemana/utils/network_service.dart';
import 'package:cinemana/models/token.dart';
import 'package:cinemana/models/user_info.dart';

class CinemanaClient {
  CinemanaClient(this.networkService);

  final NetworkService networkService;
  Token? _token;

  bool get isLogged => (_token != null);

  Future<Result<bool, Exception>> loginWithPassword(userName, password) async {
    final result = await _getToken(
        TokenGrantPassword(userName: userName, password: password));
    if (result.isError()) {
      return Error(result.tryGetError()!);
    }

    _token = result.tryGetSuccess()!;
    return Success(isLogged);
  }

  Future<Result<UserInfo, Exception>> getUserInfo() async {
    if (!isLogged) {
      return Error(Exception("User is not logged!"));
    }

    UserInfo userInfo;
    Map<String, dynamic> json;

    final u = UserInfoGet(token: _token!);
    final result = await networkService
        .perform(() => post(u.endpoint, headers: u.headers, body: u.body));

    if (result.isError()) {
      return Error(result.tryGetError()!);
    }

    final resp = result.tryGetSuccess()!;
    try {
      json = await jsonDecode(resp.body);
    } catch (e) {
      return Error(JsonCorrupted(e.toString()));
    }

    userInfo = UserInfo.fromJson(json);

    if (!userInfo.isNull) {
      return Success(userInfo);
    } else {
      return Error(NullValue("user info is null"));
    }
  }

  Future<Result<Token, Exception>> _getToken<T extends TokenGrant>(T t) async {
    Token token;
    Map json;

    final result = await networkService
        .perform(() => post(t.endpoint, headers: t.headers, body: t.body));

    if (result.isError()) {
      return Error(result.tryGetError()!);
    }

    final resp = result.tryGetSuccess()!;

    try {
      json = await jsonDecode(resp.body);
    } catch (e) {
      return Error(JsonCorrupted(e.toString()));
    }
    if (resp.statusCode == HttpStatus.ok) {
      token = Token.fromJson(json);
      if (token.isNull) {
        return Error(NullValue("The object can't be used as it is, "
            "because one of it's neccessary field is null."));
      }
      return Success(token);
    } else {
      if (resp.statusCode != HttpStatus.badRequest) {
        return Error(
            HttpException("Unhandled status_code: ${resp.statusCode}"));
      }

      if (json.isEmpty) {
        return Error(JsonEmpty("The json object is empty!"));
      }

      final String errorType = json['error'];

      switch (errorType) {
        case "invalid_grant":
          return Error(WrongLoginInfo(json["error_description"]));

        case "invalid_client":
          return Error(InvalidClient("Basic authorization_token is invalid"));

        case "invalid_scope":
          return Error(InvalidScope("Auth scope has been denied"));

        default:
          return Error(UnknowError(errorType));
      }
    }
  }
}
