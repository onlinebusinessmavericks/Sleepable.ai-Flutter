import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart' as get_state;
import 'package:http/http.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/shared_prefences.dart';
import '../../localization/lang_extension.dart';
import '../../routes/app_pages.dart';
import '../../widgets/ai_consent_dialog.dart';
import 'api_end_point.dart';
import 'api_sevices.dart';
import 'common.dart';
import 'config.dart';
import 'session_clear.dart';

Map<String, String> defaultHeaders() {
  Map<String, String> header = {};

  header.putIfAbsent(HttpHeaders.cacheControlHeader, () => 'no-cache');
  header.putIfAbsent('Access-Control-Allow-Headers', () => '*');
  header.putIfAbsent('Access-Control-Allow-Origin', () => '*');

  return header;
}

// Map<String, String> buildHeaderTokens() {
//   Map<String, String> header = {};
//
//   if (isLoggedIn.value) {
//     final headerToken = loggedInUser.value.access!.isNotEmpty
//         ? loggedInUser.value.access
//         : getStringAsync(AppSharedPreferenceKeys.apiToken).isNotEmpty
//         ? getStringAsync(AppSharedPreferenceKeys.apiToken)
//         : '';
//     if (headerToken!.isNotEmpty) header.putIfAbsent(HttpHeaders.authorizationHeader, () => 'Bearer ${headerToken}');
//   }
//
//   header.putIfAbsent(HttpHeaders.contentTypeHeader, () => 'application/json; charset=utf-8');
//   header.putIfAbsent(HttpHeaders.acceptHeader, () => 'application/json; charset=utf-8');
//   header.addAll(defaultHeaders());
//
//   return header;
// }
Map<String, String> buildHeaderTokens({bool isAuthRequired = true}) {
  Map<String, String> header = {};

  if (isAuthRequired && getStringAsync(AppSharedPreferenceKeys.apiToken).isNotEmpty) {
    header[HttpHeaders.authorizationHeader] = 'Bearer ${getStringAsync(AppSharedPreferenceKeys.apiToken)}';
  }

  header[HttpHeaders.contentTypeHeader] = 'application/json';
  header[HttpHeaders.acceptHeader] = 'application/json';
  header['X-App-Language'] = currentAppLanguageCode();

  return header;
}

/// Language the UI is currently showing.
///
/// Sent on every request as X-App-Language so sound names, category names and
/// AI responses come back in the same language as the UI. The backend gives
/// this header priority over the stored profile language, so it stays correct
/// even when the profile sync failed.
String currentAppLanguageCode() {
  // 'language_code' is always written (including on first launch from the
  // device locale); 'selected_language_code' only on an explicit change.
  String code = getStringAsync('language_code');
  if (code.isEmpty) code = getStringAsync('selected_language_code');
  return code.isEmpty ? 'en' : code;
}

Uri buildBaseUrl(String endPoint) {
  if (!endPoint.startsWith('http')) {
    return Uri.parse('$BASE_URL$endPoint');
  } else {
    return Uri.parse(endPoint);
  }
}
Future<dynamic> buildHttpResponse({
  required String endPoint,
  MethodType method = MethodType.get,
  Map? request,
  Map<String, String>? header,
  bool retrying = false,
  bool allowTokenRefresh = true,
}) async {

  /// 🌐 INTERNET CHECK FIRST
  if (!await isNetworkAvailable()) {
    toast('Please check your internet connection');
    throw errorInternetNotAvailable;
  }

  final Uri url = buildBaseUrl(endPoint);
  final Map<String, String> headers =
      header ?? buildHeaderTokens(isAuthRequired: allowTokenRefresh);
  final String? sentToken = headers[HttpHeaders.authorizationHeader];

  Response response;

  try {
    const timeoutDuration = Duration(seconds: 30);

    if (method == MethodType.post) {
      response = await post(url, body: jsonEncode(request), headers: headers)
          .timeout(timeoutDuration);
    } else if (method == MethodType.put || method == MethodType.patch) {
      response = await put(url, body: jsonEncode(request), headers: headers)
          .timeout(timeoutDuration);
    } else if (method == MethodType.delete) {
      response = await delete(url, headers: headers)
          .timeout(timeoutDuration);
    } else {
      response = await get(url, headers: headers)
          .timeout(timeoutDuration);
    }

    apiPrint(
      url: url.toString(),
      headers: jsonEncode(headers),
      request: request != null ? jsonEncode(request) : '',
      hasRequest: request != null,
      statusCode: response.statusCode,
      responseBody: response.body,
      methodType: method.name.toUpperCase(),
    );

    if (response.statusCode == 401 && !retrying && _canRefreshFor(endPoint, sentToken)) {
      if (await _refreshAfterUnauthorized(sentToken)) {
        return await buildHttpResponse(
          endPoint: endPoint,
          method: method,
          request: request,
          header: header == null ? null : _withCurrentToken(header),
          retrying: true,
          allowTokenRefresh: allowTokenRefresh,
        );
      }
      await _signOutToLogin();
    }

    return await handleResponse(response);

  } on SocketException {
    toast('No internet connection');
    throw errorInternetNotAvailable;
  } on TimeoutException {
    // toast('Request timeout');
    throw Exception("Request timeout. Please try again.");
  }
}


/// Multipart request

Future<dynamic> buildMultipartHttpResponse({
  required String endPoint,
  required Map<String, dynamic> fields,
  File? file,
  String fileKey = 'file',
  MethodType method = MethodType.post,
  Map<String, String>? header,
  bool retrying = false,
}) async {

  /// 🌐 INTERNET CHECK FIRST
  if (!await isNetworkAvailable()) {
    toast('Please check your internet connection');
    throw errorInternetNotAvailable;
  }

  final uri = buildBaseUrl(endPoint);

  final request = MultipartRequest(
    method == MethodType.put ? 'PUT' : 'POST',
    uri,
  );

  request.headers.addAll(
    header ?? buildHeaderTokens(isAuthRequired: true),
  );
  final String? sentToken = request.headers[HttpHeaders.authorizationHeader];

  fields.forEach((key, value) {
    request.fields[key] = value.toString();
  });

  if (file != null && file.path.isNotEmpty) {
    request.files.add(
      await MultipartFile.fromPath(fileKey, file.path),
    );
  }

  final streamedResponse = await request.send();
  final response = await Response.fromStream(streamedResponse);

  apiPrint(
    url: request.url.toString(),
    headers: jsonEncode(request.headers),
    request: jsonEncode({
      'fields': request.fields,
      'files': request.files.map((f) => {
        'field': f.field,
        'filename': f.filename,
        'length': f.length,
      }).toList(),
    }),
    hasRequest: true,
    statusCode: response.statusCode,
    responseBody: response.body,
    methodType: "MultiPart",
  );

  if (response.statusCode == 401 && !retrying && _canRefreshFor(endPoint, sentToken)) {
    if (await _refreshAfterUnauthorized(sentToken)) {
      return buildMultipartHttpResponse(
        endPoint: endPoint,
        fields: fields,
        file: file,
        fileKey: fileKey,
        method: method,
        header: header == null ? null : _withCurrentToken(header),
        retrying: true,
      );
    }
    await _signOutToLogin();
  }

  return handleResponse(response);
}

//region Token refresh

/// Endpoints that must never trigger a refresh: the refresh call itself, and
/// the sign-in / sign-up / logout calls, where a 401 is an answer for the user
/// rather than an expired session.
const Set<String> _noRefreshEndpoints = {
  APIEndPoints.refreshToken,
  APIEndPoints.socialLogin,
  APIEndPoints.logOut,
  APIEndPoints.forgotPassword,
  APIEndPoints.resetPassword,
  'users/email-login/',
  'users/email-verify-otp/',
  'users/email-register/',
};

bool _canRefreshFor(String endPoint, String? sentToken) {
  // Only a request that carried an access token can have an expired one.
  if (sentToken == null || sentToken.isEmpty) return false;
  final path = endPoint.startsWith(BASE_URL) ? endPoint.substring(BASE_URL.length) : endPoint;
  final bare = path.split('?').first;
  return !_noRefreshEndpoints.contains(bare);
}

Map<String, String> _withCurrentToken(Map<String, String> header) {
  final token = getStringAsync(AppSharedPreferenceKeys.apiToken);
  return {
    ...header,
    if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
  };
}

/// The refresh in progress, shared by every request that hit a 401 meanwhile.
Future<bool>? _refreshInFlight;
bool _signingOut = false;

/// Gets a new access token after a 401. Returns true when the request should
/// be retried.
Future<bool> _refreshAfterUnauthorized(String? sentToken) {
  // Another request already refreshed while this one was on the wire.
  final current = getStringAsync(AppSharedPreferenceKeys.apiToken);
  if (current.isNotEmpty && 'Bearer $current' != sentToken) {
    return Future.value(true);
  }
  return _refreshInFlight ??= _refreshAccessToken().whenComplete(() => _refreshInFlight = null);
}

/// POST /users/refresh-token/ with {"refresh"} and no Authorization header -
/// the backend rejects the call when an expired access token is attached.
Future<bool> _refreshAccessToken() async {
  final refresh = getStringAsync(AppSharedPreferenceKeys.refreshToken);
  if (refresh.isEmpty) return false;
  try {
    final response = await post(
      buildBaseUrl(APIEndPoints.refreshToken),
      body: jsonEncode({'refresh': refresh}),
      headers: buildHeaderTokens(isAuthRequired: false),
    ).timeout(const Duration(seconds: 30));

    apiPrint(
      url: buildBaseUrl(APIEndPoints.refreshToken).toString(),
      headers: '',
      request: '',
      hasRequest: false,
      statusCode: response.statusCode,
      responseBody: '',
      methodType: 'POST',
    );

    if (!response.statusCode.isSuccessful()) return false;
    final body = jsonDecode(response.body);
    if (body is! Map) return false;
    // Accept the tokens flat, under `data`, or under `data.tokens`.
    Map source = body;
    if (source['data'] is Map) source = source['data'];
    if (source['tokens'] is Map) source = source['tokens'];

    final access = (source['access'] ?? '').toString();
    if (access.isEmpty) return false;
    await setValue(AppSharedPreferenceKeys.apiToken, access);
    final newRefresh = (source['refresh'] ?? '').toString();
    if (newRefresh.isNotEmpty) {
      await setValue(AppSharedPreferenceKeys.refreshToken, newRefresh);
    }
    return true;
  } catch (e) {
    log('Token refresh failed: $e');
    return false;
  }
}

/// The session cannot be renewed: clear it and send the user to sign in.
Future<void> _signOutToLogin() async {
  if (_signingOut) return;
  _signingOut = true;
  try {
    toast(get_state.Get.context?.lang.sessionExpired ?? 'Your session has expired. Please sign in again.');
    await SessionClear.clearForLogout();
    get_state.Get.offAllNamed(Routes.login);
  } finally {
    _signingOut = false;
  }
}

//endregion



/// A failed request, with the body the backend sent for it.
///
/// [toString] is the message to show, so callers that display `e.toString()`
/// keep working. Callers that need the detail of a 403 - `is_trial`, how much
/// of a limit was used - read [body] from the error of their own request.
class ApiError implements Exception {
  final int statusCode;

  /// The backend's `message`, or a localized generic line when it sent none.
  final String message;

  /// Whether [message] came from the backend.
  final bool hasBackendMessage;
  final Map<String, dynamic>? body;

  const ApiError(this.statusCode, this.message, {this.body, this.hasBackendMessage = false});

  bool get isForbidden => statusCode == 403;
  String? get code => body?['code']?.toString();

  @override
  String toString() => message;
}

Map<String, dynamic>? _decodeMap(String raw) {
  try {
    final body = jsonDecode(raw);
    return body is Map ? Map<String, dynamic>.from(body) : null;
  } catch (_) {
    return null;
  }
}

String? _backendMessage(Map<String, dynamic>? body) {
  final message = body?['message'] ?? body?['detail'];
  if (message is! String) return null;
  final text = message.trim();
  return text.isEmpty ? null : text;
}
Future handleResponse(Response response, {HttpResponseType httpResponseType = HttpResponseType.JSON}) async {
  if (!await isNetworkAvailable()) {
    throw errorInternetNotAvailable;
  }
  // if (response.statusCode == 403) {
  //   throw 'Page not found';
  // }
  // Inside your handleResponse function
  if (response.statusCode == 403) {
    final body = _decodeMap(response.body);
    final backendMessage = _backendMessage(body);
    // Apple Guideline 5.1.1(i) / 5.1.2(i): the backend refuses AI requests until
    // the user consents.
    if (body?['code'] == 'AI_CONSENT_REQUIRED') {
      final consentMessage = backendMessage ?? 'AI consent required';
      handleAiConsentRequired(consentMessage);
      throw ApiError(403, consentMessage, body: body, hasBackendMessage: backendMessage != null);
    }
    throw ApiError(
      403,
      backendMessage ?? get_state.Get.context?.lang.requestNotAllowed ?? "You don't have access to this right now.",
      body: body,
      hasBackendMessage: backendMessage != null,
    );
  }
  else if (response.statusCode == 429) {
    throw 'Too many requests';
  } else if (response.statusCode == 500) {
    // With DEBUG off the server returns an HTML error page rather than JSON,
    // so the decode has to be allowed to fail - otherwise the user is shown a
    // FormatException instead of a readable message.
    try {
      var body = jsonDecode(response.body);
      if (body is Map && body.containsKey('status') && body['status'] is bool && !body['status']) {
        throw parseHtmlString(body['message'] ?? 'Internal server error');
      }
    } on FormatException {
      // Body was not JSON; fall through to the generic message.
    }
    throw 'Internal server error';
  } else if (response.statusCode == 502) {
    throw 'Bad gateway';
  } else if (response.statusCode == 503) {
    throw 'Service unavailable';
  } else if (response.statusCode == 504) {
    throw 'Gateway timeout';
  } else {
    if (response.statusCode.isSuccessful()) {
      var body = jsonDecode(response.body);
      if (body is Map && body.containsKey('status') && body['status'] is bool && !body['status']) {
        throw parseHtmlString(body['message'] ?? errorSomethingWentWrong);
      } else {
        return body;
      }
    } else {
      Map body = jsonDecode(response.body.trim());
      Map<String, dynamic> errorData = {'status_code': response.statusCode, 'status': false, "response": body, "message": body['message'] ?? body['error'] ?? errorSomethingWentWrong};

      // Handle validation errors if present
      if (body.containsKey('errors') && body['errors'] is Map) {
        List<String> errorMessages = [];
        body['errors'].forEach((key, value) {
          if (value is List) {
            errorMessages.addAll(value.map((e) => e.toString()));
          }
        });
        if (errorMessages.isNotEmpty) {
          errorData["message"] = errorMessages.join("\n");
        }
      }
      throw errorData["message"];
    }
  }
}

//region CommonFunctions
Future<Map<String, String>> getMultipartFields({required Map<String, dynamic> val}) async {
  Map<String, String> data = {};

  val.forEach((key, value) {
    data[key] = '$value';
  });

  return data;
}

String getEndPoint({required String endPoint, int? perPages, int? page, List<String>? params}) {
  List<String> queryParams = [];

  // Add perPage and page only if they exist

  // Append params if they exist

  if (params != null && params.isNotEmpty) {
    queryParams.addAll(params);
  }
  if (perPages != null) queryParams.add("per_page=${perPages}");
  if (page != null) queryParams.add("page=$page");

  return "$endPoint${queryParams.isNotEmpty ? '?${queryParams.join('&')}' : ''}";
}

//endregion
