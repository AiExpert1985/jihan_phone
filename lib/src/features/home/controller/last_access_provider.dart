import 'package:flutter_riverpod/flutter_riverpod.dart';

class LastAccessNotifier extends StateNotifier<DateTime?> {
  LastAccessNotifier() : super(null);

  // Method to set the last access date
  void setLastAccessDate() {
    state = DateTime.now();
  }

  // Method to check if a day has passed
  bool hasOneDayPassed() {
    if (state == null) {
      return true; // If there's no last access date, consider it as a day passed
    }
    final now = DateTime.now();
    final lastAccessDate =
        DateTime(state!.year, state!.month, state!.day); // Normalize to date only
    return now.isAfter(lastAccessDate.add(const Duration(days: 1)));
  }
}

final lastAccessProvider = StateNotifierProvider<LastAccessNotifier, DateTime?>((ref) {
  return LastAccessNotifier();
});
