import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart' as get_state;
import 'package:http/http.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/shared_prefences.dart';
import '../../widgets/ai_consent_dialog.dart';
import 'api_end_point.dart';
import 'api_sevices.dart';
import 'common.dart';
import 'config.dart';

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

    // if (response.statusCode == 401 &&
    //     allowTokenRefresh &&
    //     !retrying) {
    //
    //   final refreshed = await refreshAccessToken();
    //
    //   if (refreshed) {
    //     return await buildHttpResponse(
    //       endPoint: endPoint,
    //       method: method,
    //       request: request,
    //       header: null,
    //       retrying: true,
    //       allowTokenRefresh: false,
    //     );
    //   } else {
    //     toast('Session expired. Please login again');
    //     throw 'Unauthorized';
    //   }
    // }
// after response is received

    apiPrint(
      url: url.toString(),
      headers: jsonEncode(headers),
      request: request != null ? jsonEncode(request) : '',
      hasRequest: request != null,
      statusCode: response.statusCode,
      responseBody: response.body,
      methodType: method.name.toUpperCase(),
    );


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

  return handleResponse(response);
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
    // Apple Guideline 5.1.1(i) / 5.1.2(i): the backend refuses AI requests until
    // the user consents. That case must keep its own message, because callers
    // treat a plain "Access forbidden" as the premium-limit error.
    bool consentRequired = false;
    String consentMessage = 'AI consent required';
    try {
      var body = jsonDecode(response.body);
      if (body is Map && body['code'] == 'AI_CONSENT_REQUIRED') {
        consentRequired = true;
        consentMessage = body['message']?.toString() ?? consentMessage;
      }
    } catch (_) {
      // Body was not JSON; fall through to the generic message below.
    }

    if (consentRequired) {
      handleAiConsentRequired(consentMessage);
      throw consentMessage;
    }

    throw 'Access forbidden';
  }
  else if (response.statusCode == 429) {
    throw 'Too many requests';
  } else if (response.statusCode == 500) {
    var body = jsonDecode(response.body);
    if (body is Map && body.containsKey('status') && body['status'] is bool && !body['status']) {
      throw parseHtmlString(body['message'] ?? 'Internal server error');
    } else {
      throw 'Internal server error';
    }
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
