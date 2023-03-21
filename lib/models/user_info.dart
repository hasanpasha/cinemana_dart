import 'dart:io';
import 'package:intl/intl.dart';

import 'package:cinemana/models/token.dart';
import 'package:cinemana/constants/website.dart';

class UserInfoGet {
  Uri endpoint = Uri.https(Website.accountBaseUrl, "/core/connect/userinfo/");
  final Token token;

  UserInfoGet({required this.token});

  Map<String, String> get headers => {
        HttpHeaders.authorizationHeader: "${token.type} ${token.accessToken}",
      };

  Map<String, String> get body => {};
}

enum Gender { male, female }

class UserInfo {
  final String sub;
  final String name;
  final String preferredUsername;
  final String? firstName;
  final String? lastName;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final String? mobileNo;

  @override
  String toString() =>
      "UserInfo:\nuser: $name ($firstName $lastName)\ngender: $gender\nbirth date: $dateOfBirth";

  UserInfo.fromJson(Map<String, dynamic> json)
      : sub = json["sub"],
        name = json["name"],
        preferredUsername = json["preferred_username"],
        firstName = json["FirstName"],
        lastName = json["LastName"],
        gender = json["Gender"] == null
            ? null
            : (json["Gender"] == "Male" ? Gender.male : Gender.female),
        dateOfBirth = json["DateOfBirth"] == null
            ? null
            : DateFormat("EEE MMM d y H:m:s Z").parse(json["DateOfBirth"]),
        mobileNo = json["MobileNo"];
}
