import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/utils.dart';

class LastAccessNotifier extends StateNotifier<DateTime?> {
  LastAccessNotifier() : super(null);

  // Method to set the last access date
  void setLastAccessDate() {
    state = DateTime.now();
  }

  // Method to check if a day has passed
  bool hasOneDayPassed() {
    return state == null || !isSameDay(state!, DateTime.now());
  }
}

final lastAccessProvider = StateNotifierProvider<LastAccessNotifier, DateTime?>((ref) {
  return LastAccessNotifier();
});
