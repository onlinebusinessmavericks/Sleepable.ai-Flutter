import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/constants/shared_prefences.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/rating_dialog.dart';

/// Coordinates Wake / Quit / force-quit so we never double-mount Home,
/// never re-fire rating, and notifications cannot remount dashboard mid-exit.
class TrackerExitGuard {
  TrackerExitGuard._();

  static bool _exitInProgress = false;
  static bool _ratingQueuedForExit = false;
  static DateTime? _suppressDashboardRemountUntil;

  static bool get isExitInProgress => _exitInProgress;

  /// True after Wake/Quit has claimed the post-exit rating slot.
  static bool get didQueueRatingForExit => _ratingQueuedForExit;

  /// True for a few seconds after intentional Home navigation from Wake/Quit.
  static bool get shouldSuppressDashboardRemount {
    final until = _suppressDashboardRemountUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  /// Call immediately before Get.offAllNamed(dashboard) on Wake/Quit.
  static void beginExitNavigation({Duration remountSuppress = const Duration(seconds: 4)}) {
    _exitInProgress = true;
    _suppressDashboardRemountUntil = DateTime.now().add(remountSuppress);
    // Prevent a cold-start pending tab from fighting this intentional Home land.
    setValue(AppSharedPreferenceKeys.pendingDashboardTab, -1);
  }

  static void endExitNavigation() {
    _exitInProgress = false;
  }

  /// Show rating at most once per Wake/Quit exit (ignores Home session-count rating).
  static Future<void> showRatingOnceAfterExit({Duration delay = const Duration(milliseconds: 700)}) async {
    if (_ratingQueuedForExit) return;
    _ratingQueuedForExit = true;
    await Future.delayed(delay);
    try {
      if (Get.isDialogOpen == true) return;
      if (Get.currentRoute != Routes.dashboard) return;
      Get.dialog(const RatingDialog(), barrierDismissible: false);
    } catch (e) {
      debugPrint("TrackerExitGuard rating error: $e");
    }
  }

  /// Reset rating gate when starting a brand-new sleep session.
  static void resetForNewSession() {
    _ratingQueuedForExit = false;
    _exitInProgress = false;
  }

  /// Minutes from [now] until today's/tomorrow's [remindAt] ("HH:mm:ss" or "HH:mm").
  /// Returns null if unparsable.
  static int? minutesUntilRemindAt(String formattedBedtime, {DateTime? now}) {
    try {
      final parts = formattedBedtime.split(':');
      if (parts.length < 2) return null;
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final n = now ?? DateTime.now();
      var target = DateTime(n.year, n.month, n.day, h, m);
      if (!target.isAfter(n.add(const Duration(minutes: 1)))) {
        target = target.add(const Duration(days: 1));
      }
      return target.difference(n).inMinutes;
    } catch (_) {
      return null;
    }
  }

  /// Enable sleepReminders only when bedtime is far enough away that the
  /// backend won't immediately push bedtime_reminder (which remounted Home).
  static bool shouldEnableSleepRemindersOnQuit(String formattedBedtime, {int minMinutesAway = 45}) {
    final mins = minutesUntilRemindAt(formattedBedtime);
    if (mins == null) return false;
    return mins >= minMinutesAway;
  }
}
