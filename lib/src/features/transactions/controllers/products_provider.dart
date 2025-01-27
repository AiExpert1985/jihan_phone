// import 'package:flutter_riverpod/flutter_riverpod.dart';

// // Define a StateNotifier to manage the list of maps
// class ItemNotifier extends StateNotifier<List<Map<String, dynamic>>> {
//   ItemNotifier() : super([]);

//   void setItems(List<Map<String, dynamic>> items) {
//     state = items; // Add a new item to the list
//   }

//   List<Map<String, dynamic>> get data => state;
// }

// // Create a StateNotifierProvider for the ItemNotifier
// final productsProvider = StateNotifierProvider<ItemNotifier, List<Map<String, dynamic>>>((ref) {
//   return ItemNotifier();
// });
