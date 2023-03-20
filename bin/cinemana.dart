import 'dart:async';
import 'package:multiple_result/multiple_result.dart';
import 'package:interact/interact.dart';

import 'package:cinemana/models/user_info.dart';
import 'package:cinemana/constants/exceptions.dart';
import 'package:cinemana/cinemana.dart';
import 'package:cinemana/utils/network_service.dart';

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
  if (!client.isLogged) {
    return Error(Exception("user is not logged"));
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

Future<bool> handleUserLogin(CinemanaClient client) async {
  var confirmation = Confirm(
      prompt: 'Do you want to login?',
      defaultValue: true,
      waitForNewLine: true);

  while (confirmation.interact()) {
    final result = await loginWithPassword(client);

    if (result.isSuccess()) {
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
}
