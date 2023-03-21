import 'dart:io';

import 'package:cinemana/constants/website.dart';

mixin TokenScope {
  final String scope = "openid earthlink.profile offline_access fileservice";
}

abstract class TokenGrant {
  String get grantType;
  Uri endpoint = Uri.https(Website.accountBaseUrl, "/core/connect/token/");

  Map<String, String> get headers;
  Map<String, String> get body;
}

class TokenGrantPassword extends TokenGrant with TokenScope {
  @override
  String grantType = "password";

  final String userName;
  final String password;

  TokenGrantPassword({required this.userName, required this.password});

  @override
  Map<String, String> get headers => {
        HttpHeaders.authorizationHeader: Website.basicAuth,
      };

  @override
  Map<String, String> get body => {
        "grant_type": grantType,
        "scope": scope,
        "username": userName,
        "password": password,
      };
}

class TokenGrantRefresh extends TokenGrant with TokenScope {
  @override
  String grantType = "refresh_token";

  final String refreshToken;

  TokenGrantRefresh({required this.refreshToken});

  @override
  Map<String, String> get headers => {
        HttpHeaders.authorizationHeader: Website.basicAuth,
      };

  @override
  Map<String, String> get body => {
        "grant_type": grantType,
        "scope": scope,
        "refresh_token": refreshToken,
      };
}

class Token {
  final String? idToken;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresIn;
  final String type;

  Token.fromJson(Map json)
      : idToken = json["id_token"],
        accessToken = json["access_token"],
        refreshToken = json["refresh_token"],
        expiresIn = DateTime.now().add(Duration(seconds: json["expires_in"])),
        type = json["token_type"];

  bool get isValid =>
      DateTime.now().difference(expiresIn) > Duration(minutes: 5);
}
