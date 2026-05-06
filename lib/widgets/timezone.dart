//
// import 'package:flutter_timezone/flutter_timezone.dart';
//
// import '../core/utils/library.dart';
//
// Future<String> getCurrentTimezone() async {
//   try {
//     var rawTz = await FlutterTimezone.getLocalTimezone();
//     String tzString = rawTz.toString(); // "TimezoneInfo(Asia/Kolkata, ...)"
//
//     if (tzString.contains('(')) {
//       // "TimezoneInfo(Asia/Kolkata, ..." -> "Asia/Kolkata, ..."
//       String step1 = tzString.split('(')[1];
//       // "Asia/Kolkata, ..." -> "Asia/Kolkata"
//       String finalTz = step1.split(',')[0];
//       return finalTz.trim();
//     }
//
//     return tzString;
//   } catch (e) {
//     return "Asia/Kolkata";
//   }
// }

import 'package:flutter_timezone/flutter_timezone.dart';

import '../core/utils/library.dart';

Future<String> getCurrentTimezone() async {
  try {
    // Official code ke mutabiq ye TimezoneInfo object return karta hai
    final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();

    // 🔥 Identifier hi aapka "Asia/Kolkata" hai
    return info.identifier;
  } catch (e) {
    debugPrint("⚠️ Timezone Error: $e");
    return "Asia/Kolkata"; // Safe fallback
  }
}