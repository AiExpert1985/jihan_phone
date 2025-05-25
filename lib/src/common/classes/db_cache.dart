// lib/src/common/classes/db_cache.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/classes/db_repository.dart'; // Ensure this import is correct

enum DbCacheOperationTypes { add, edit, delete }

class DbCache extends StateNotifier<List<Map<String, dynamic>>> {
  final DbRepository? _repository; // For stream-based updates
  final String? _streamFilterKey;
  final dynamic _streamFilterValue;
  StreamSubscription<List<Map<String, dynamic>>>? _streamSubscription;
  final String _collectionNameForLogging = "unknown_collection"; // For better logging

  DbCache({
    DbRepository? repository,
    String? streamFilterKey,
    dynamic streamFilterValue,
    // You could optionally pass the collection name for logging if DbRepository doesn't expose it
    // String? collectionNameForLogging,
  })  : _repository = repository,
        _streamFilterKey = streamFilterKey,
        _streamFilterValue = streamFilterValue,
        // _collectionNameForLogging = collectionNameForLogging ?? repository?.getCollectionName() ?? "unknown", // Example
        super([]) {
    _initStreamListener(); // Start listening if repository is provided
  }

  void _initStreamListener() {
    if (_repository != null) {
      // If the stream is specifically for a filtered list (e.g., by salesmanDbRef)
      // and the filter value isn't available yet, subscribe to an empty stream to avoid errors/unintended full loads.
      if (_streamFilterKey == 'salesmanDbRef' &&
          (_streamFilterValue == null ||
              (_streamFilterValue is String && _streamFilterValue.isEmpty))) {
        tempPrint(
            'DbCache for $_collectionNameForLogging: Filter value for $_streamFilterKey is null/empty. Listening to empty stream.');
        _streamSubscription?.cancel(); // Cancel any old one
        _streamSubscription = Stream.value(<Map<String, dynamic>>[]).listen((newData) {
          if (mounted) state = newData;
        });
        return; // Exit early
      }

      _streamSubscription?.cancel(); // Cancel any existing subscription before starting a new one
      _streamSubscription = _repository
          .watchItemListAsMaps(filterKey: _streamFilterKey, filterValue: _streamFilterValue)
          .listen(
        (newData) {
          if (mounted) state = newData; // Update state when stream emits new data
        },
        onError: (error) {
          errorPrint(
              'Error in DbCache stream for $_collectionNameForLogging (filter: $_streamFilterKey): $error');
          if (mounted) state = []; // Optionally, set state to an error state or an empty list
        },
      );
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    tempPrint(
        'DbCache stream listener disposed for $_collectionNameForLogging (filter: $_streamFilterKey).');
    super.dispose();
  }

  // --- Your existing methods for manual cache manipulation ---
  // These methods will operate on the current 'state', which is now stream-populated.
  // Be mindful that manual calls to `set`, `_addData`, etc., will be overwritten
  // by the next emission from the stream if the cache is stream-backed.

  void _addData(Map<String, dynamic> newData) {
    if (mounted) state = [...state, newData];
  }

  void _updateData(int index, Map<String, dynamic> newData) {
    if (mounted && index >= 0 && index < state.length) {
      final stateCopy = [...state];
      stateCopy[index] = newData;
      state = [...stateCopy];
    }
  }

  void _removeData(int index) {
    if (mounted && index >= 0 && index < state.length) {
      final stateCopy = [...state];
      stateCopy.removeAt(index);
      state = [...stateCopy];
    }
  }

  // CAUTION: If this DbCache is stream-backed from a provider,
  // calling set() manually will temporarily overwrite the stream's data
  // until the stream emits its next value.
  void set(List<Map<String, dynamic>> newData) {
    if (mounted) state = newData;
  }

  void update(Map<String, dynamic> newData, DbCacheOperationTypes operationType) {
    if (!mounted) return;
    if (operationType == DbCacheOperationTypes.add) {
      _addData(newData);
      return;
    }
    final index = _getItemIndex(newData);
    if (index == -1) return; // Item not found
    if (operationType == DbCacheOperationTypes.edit) {
      _updateData(index, newData);
    } else if (operationType == DbCacheOperationTypes.delete) {
      _removeData(index);
    } else {
      errorPrint('Unknown operation in DbCache update');
    }
  }

  int _getItemIndex(Map<String, dynamic> newData) {
    // Safety check: ensure state is not empty before accessing state[0]
    if (state.isEmpty || !newData.containsKey('dbRef')) {
      // If newData doesn't have dbRef, we can't find it.
      // If state is empty, no item can be found.
      // The check `state[0].containsKey('dbRef')` is problematic if state is empty.
      errorPrint('DbCache _getItemIndex: State is empty or newData is missing dbRef.');
      return -1;
    }
    // Ensure all items in state are expected to have 'dbRef' if this is the comparison key
    for (int index = 0; index < state.length; index++) {
      if (state[index].containsKey('dbRef') && state[index]['dbRef'] == newData['dbRef']) {
        return index;
      }
    }
    errorPrint('DbCache _getItemIndex: Item with dbRef ${newData['dbRef']} not found.');
    return -1;
  }

  Map<String, dynamic> getItemByDbRef(String itemDbRef) {
    return getItemByProperty('dbRef', itemDbRef);
  }

  Map<String, dynamic> getItemByProperty(String propertyKey, dynamic propertyValue) {
    if (!mounted) return {}; // Or handle as appropriate if accessed after disposal
    try {
      return state
          .firstWhere((item) => item.containsKey(propertyKey) && item[propertyKey] == propertyValue,
              orElse: () {
        // errorPrint('Item not found in dbCache by $propertyKey = $propertyValue');
        return {}; // Return empty map if not found
      });
    } catch (e) {
      errorPrint(
          'Error in getItemByProperty ($propertyKey = $propertyValue): $e. State length: ${state.length}');
      return {};
    }
  }

  List<Map<String, dynamic>> get data => mounted ? state : []; // Return empty list if not mounted

  FutureOr<List<Map<String, dynamic>>> getSearchableList(
      {required String filterKey, required String filterValue}) {
    if (!mounted || state.isEmpty) {
      return Future.value([]); // Return empty list if not mounted or no data
    }

    List<Map<String, dynamic>> currentData = deepCopyDbCache(state); // Work on a copy

    if (filterValue.isNotEmpty) {
      return Future.value(currentData.where((map) {
        final value = map[filterKey];
        if (value == null) return false;
        return value.toString().toLowerCase().contains(filterValue.toLowerCase());
      }).toList());
    }
    return Future.value(currentData); // Return all data if filter is empty
  }
}

List<Map<String, dynamic>> deepCopyDbCache(List<Map<String, dynamic>> original) {
  return original.map((map) => Map<String, dynamic>.from(map)).toList();
}
