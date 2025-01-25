import 'package:flutter_riverpod/flutter_riverpod.dart';

class SalesmanInfo extends StateNotifier<Map<String, dynamic>> {
  SalesmanInfo() : super({}); // Initialize with an empty map

  void setDbRef(dynamic value) {
    const key = 'dbRef';
    state = {
      ...state, // Spread the current state
      key: value, // Add the new key-value pair
    };
  }

  void setName(dynamic value) {
    const key = 'name';
    state = {
      ...state, // Spread the current state
      key: value, // Add the new key-value pair
    };
  }

  String? get name => state['name'];
  String? get dbRef => state['dbRef'];

  void reset() => state = {};
}

// Create a provider for the MapStateNotifier
final salesmanInfoProvider = StateNotifierProvider<SalesmanInfo, Map<String, dynamic>>((ref) {
  return SalesmanInfo();
});
