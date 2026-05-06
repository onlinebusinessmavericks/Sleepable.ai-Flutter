import 'dart:convert';

import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:html/parser.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../core/constants/shared_prefences.dart';
import '../../core/utils/library.dart';
import '../../modules/login/model/login_model.dart';

Future<void> loadLoggedInUser() async {
  if (getBoolAsync(AppSharedPreferenceKeys.isUserLoggedIn)) {
    String? jsonString = getStringAsync(AppSharedPreferenceKeys.currentUserData);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonString);
        final userData = UserDataResponseModel.fromJson(decoded);
        loggedInUser.value = userData;
        apiToken = userData.access ?? '';
        isLoggedIn(true);
      } catch (e) {
        log('Failed to decode stored user data: $e');
        isLoggedIn(false);
      }
    }
  }
}

// RxString selectedLanguageCode = DEFAULT_LANGUAGE.obs;
Rx<UserDataResponseModel> loggedInUser = UserDataResponseModel().obs;
RxBool isLoggedIn = false.obs;
String apiToken = '';



void apiPrint({
  String url = "",
  String endPoint = "",
  String headers = "",
  String request = "",
  int statusCode = 0,
  String responseBody = "",
  String methodType = "",
  bool hasRequest = false,
  bool fullLog = false,
  String responseHeader = '',
}) {
  // fullLog = statusCode.isSuccessful();
  if (fullLog) {
    debugPrint("┌───────────────────────────────────────────────────────────────────────────────────────────────────────");
    debugPrint("\u001b[93m Url: \u001B[39m $url");
    debugPrint("\u001b[93m endPoint: \u001B[39m \u001B[1m$endPoint\u001B[22m");
    debugPrint("\u001b[93m header: \u001B[39m \u001b[96m$headers\u001B[39m");
    if (hasRequest) {
      debugPrint('\u001b[93m Request: \u001B[39m \u001b[95m$request\u001B[39m');
    }
    debugPrint(statusCode.isSuccessful() ? "\u001b[32m" : "\u001b[31m");
    debugPrint("\u001b[93m Response header: \u001B[39m \u001b[96m$responseHeader\u001B[39m");
    debugPrint('\u001b[93m MethodType ($methodType) | StatusCode ($statusCode)\u001B[39m');
    debugPrint('Response : ');
    debugPrint('\x1B[32m${formatJson(responseBody)}\x1B[0m');
    debugPrint("\u001B[0m");
    debugPrint("└───────────────────────────────────────────────────────────────────────────────────────────────────────");
  } else {
    debugPrint("┌───────────────────────────────────────────────────────────────────────────────────────────────────────");
    debugPrint("\u001b[93m Url: \u001B[39m $url");
    debugPrint("\u001b[93m endPoint: \u001B[39m \u001B[1m$endPoint\u001B[22m");
    debugPrint("\u001b[93m header: \u001B[39m \u001b[96m${headers.split(',').join(',\n')}\u001B[39m");
    if (hasRequest) {
      debugPrint('\u001b[93m Request: \u001B[39m \u001b[95m$request\u001B[39m');
    }
    debugPrint(statusCode.isSuccessful() ? "\u001b[32m" : "\u001b[31m");
    debugPrint('\u001b[93m MethodType ($methodType) | statusCode: ($statusCode)\u001B[39m');
    debugPrint("\u001b[93m Response header: \u001B[39m \u001b[96m$responseHeader\u001B[39m");
    debugPrint('\u001b[93m Response \u001B[39m');
    debugPrint('$responseBody');
    debugPrint("\u001B[0m");
    debugPrint("└───────────────────────────────────────────────────────────────────────────────────────────────────────");
  }
}

String formatJson(String jsonStr) {
  try {
    final dynamic parsedJson = jsonDecode(jsonStr);
    const formatter = JsonEncoder.withIndent('  ');
    return formatter.convert(parsedJson);
  } on Exception catch (e) {
    log("\x1b[31m formatJson error ::-> ${e.toString()} \x1b[0m");
    return jsonStr;
  }
}

String parseHtmlString(String? htmlString) {
  return parse(parse(htmlString).body!.text).documentElement!.text;
}