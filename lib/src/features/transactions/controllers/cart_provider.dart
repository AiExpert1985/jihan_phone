import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/features/transactions/model/item.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem item) {
    List<CartItem> stateCopy = state;
    bool itemExists = false;
    for (var i = 0; i < state.length; i++) {
      if (state[i].dbRef == item.dbRef) {
        stateCopy[i] == item;
        itemExists = true;
      }
    }
    if (itemExists) {
      state = [...stateCopy];
    } else {
      state = [...state, item];
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < state.length) {
      state = [
        ...state.sublist(0, index),
        ...state.sublist(index + 1),
      ];
    }
  }

  List<CartItem> get data => state;

  void reset() => state = [];
}

// Create a provider for the CartNotifier
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
