import 'dart:async';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:interact/interact.dart';

import 'package:cinemana/models/user_info.dart';
import 'package:cinemana/constants/exceptions.dart';
import 'package:cinemana/cinemana.dart';
import 'package:cinemana/utils/network_service.dart';
import 'package:path/path.dart';

String programDir() => dirname(Platform.resolvedExecutable);
String dataDir() => join(programDir(), 'data/');

Future<Box> getRefreshBox() async {
  final savePath = dataDir();
  Hive.init(savePath);
  return Hive.openBox('token');
}

Future<Result<String, Exception>> getRefreshToken() async {
  final tokenBox = await getRefreshBox();
  final token = tokenBox.get('refresh_token');
  tokenBox.close();
  if (token != null) {
    return Success(token);
  }
  return Error(Exception("No token"));
}

Future<bool> saveRefreshToken(String token, [bool force = false]) async {
  final tokenBox = await getRefreshBox();

  bool cleanAndReturn(bool state) {
    tokenBox.flush();
    tokenBox.close();
    return state;
  }

  if ((tokenBox.get('refresh_token') == null) || force) {
    await tokenBox.put('refresh_token', token);
    return cleanAndReturn(true);
  }
  return cleanAndReturn(false);
}

Future<void> doWithLoading(Future<void> Function() callback) async {
  final loader = Spinner(
    icon: '✅',
    rightPrompt: (done) => done ? "done" : "loading",
  ).interact();

  // function body
  await callback();

  loader.done();
}

FutureOr<void> onRetryFunc(Exception exception) async {
  print(exception);
}

Future<Result<UserInfo, Exception>> getUserInfo(CinemanaClient client) async {
  if (!(await client.isLogged())) {
    return Error(NotLogged());
  }

  final completer = Completer<Result<UserInfo, Exception>>();
  await doWithLoading(() async {
    completer.complete(await client.getUserInfo());
  });
  return completer.future;
}

Future<Result<bool, Exception>> loginWithPassword(CinemanaClient client) async {
  final username = Input(prompt: "Enter your username").interact();
  final password = Password(prompt: "Enter your password").interact();

  final completer = Completer<Result<bool, Exception>>();
  await doWithLoading(() async {
    completer.complete(await client.loginWithPassword(username, password));
  });
  return completer.future;
}

Future<Result<bool, Exception>> tryLoginWithRefreshToken(
    CinemanaClient client) async {
  final refreshTokenResult = await getRefreshToken();
  if (refreshTokenResult.isSuccess()) {
    final result =
        await client.loginWithRefreshToken(refreshTokenResult.tryGetSuccess()!);
    if (result.isSuccess()) {
      return Success(result.tryGetSuccess()!);
    } else {
      return Error(result.tryGetError()!);
    }
  }
  return Error(refreshTokenResult.tryGetError()!);
}

Future<bool> handleUserLogin(CinemanaClient client) async {
  Result result;

  result = await tryLoginWithRefreshToken(client);
  if (result.isSuccess()) {
    return result.tryGetSuccess()!;
  }

  var confirmation = Confirm(
      prompt: 'Do you want to login?',
      defaultValue: true,
      waitForNewLine: true);

  while (confirmation.interact()) {
    result = await loginWithPassword(client);

    if (result.isSuccess()) {
      bool saveLogin = Confirm(
              prompt: 'Do you want to login?',
              defaultValue: true,
              waitForNewLine: true)
          .interact();
      if (saveLogin) {
        saveRefreshToken(client.getRefreshToken());
      }
      return true;
    }

    Exception error = result.tryGetError()!;
    print(error);
    if (error is WrongLoginInfo) {
      continue;
    }
    break;
  }
  return false;
}

void main(List<String> arguments) async {
  final client = CinemanaClient(NetworkService(onRetryFunc));

  if (!await handleUserLogin(client)) {
    print("failed to login..");
    print("Will proceed without login!");
  }
  final userInfoResult = await getUserInfo(client);
  if (userInfoResult.isSuccess()) {
    print(userInfoResult.tryGetSuccess()!);
  }
}
