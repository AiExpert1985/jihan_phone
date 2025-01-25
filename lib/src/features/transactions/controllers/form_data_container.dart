import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapStateNotifier extends StateNotifier<Map<String, dynamic>> {
  MapStateNotifier() : super({}); // Initialize with an empty map

  // Function to add a property to the map
  void addProperty(String key, dynamic value) {
    state = {
      ...state, // Spread the current state
      key: value, // Add the new key-value pair
    };
  }

  // Function to reset the map to an empty state
  void reset() {
    state = {}; // Reset to an empty map
  }

  Map<String, dynamic> get data => state;
}

// Create a provider for the MapStateNotifier
final formDataContainerProvider =
    StateNotifierProvider<MapStateNotifier, Map<String, dynamic>>((ref) {
  return MapStateNotifier();
});
