// lib/src/common/classes/db_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tablets/src/common/interfaces/base_item.dart';
import 'package:tablets/src/common/functions/debug_print.dart';

class DbRepository {
  DbRepository(this._collectionName);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collectionName;
  final String _dbReferenceKey = 'dbRef';

  Future<void> addItem(BaseItem item) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.vpn) ||
        connectivityResult.contains(ConnectivityResult.mobile)) {
      try {
        await _firestore.collection(_collectionName).doc().set(item.toMap());
        tempPrint('Item added to live firestore successfully! ($_collectionName)');
        return;
      } catch (e) {
        errorPrint('Error adding item to live firestore ($_collectionName): $e');
        return;
      }
    }
    final docRef = _firestore.collection(_collectionName).doc();
    docRef.set(item.toMap()).then((_) {
      tempPrint('Item added to firestore cache! ($_collectionName)');
    }).catchError((e) {
      errorPrint('Error adding item to firestore cache ($_collectionName): $e');
    });
  }

  Future<void> updateItem(BaseItem updatedItem) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.vpn) ||
        connectivityResult.contains(ConnectivityResult.mobile)) {
      try {
        final query = _firestore
            .collection(_collectionName)
            .where(_dbReferenceKey, isEqualTo: updatedItem.dbRef);
        // Get from server or cache for update consistency if online
        final querySnapshot = await query.get();
        if (querySnapshot.size > 0) {
          final documentRef = querySnapshot.docs[0].reference;
          await documentRef.update(updatedItem.toMap());
          debugLog('Item updated in live firestore successfully! ($_collectionName)');
        } else {
          debugLog(
              'Item not found for update in live firestore: ${updatedItem.dbRef} ($_collectionName)');
        }
        return;
      } catch (e) {
        errorPrint('Error updating item in live firestore ($_collectionName): $e');
        return;
      }
    }
    // when offline
    final query =
        _firestore.collection(_collectionName).where(_dbReferenceKey, isEqualTo: updatedItem.dbRef);
    final querySnapshot = await query.get(const GetOptions(source: Source.cache));
    if (querySnapshot.size > 0) {
      final documentRef = querySnapshot.docs[0].reference;
      await documentRef.update(updatedItem.toMap()).then((_) {
        tempPrint('Item updated in firestore cache! ($_collectionName)');
      }).catchError((e) {
        errorPrint('Error updating item in firebase cache ($_collectionName): $e');
      });
    } else {
      tempPrint('Item not found for update in cache: ${updatedItem.dbRef} ($_collectionName)');
    }
  }

  Future<void> deleteItem(BaseItem item) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.vpn) ||
        connectivityResult.contains(ConnectivityResult.mobile)) {
      try {
        final querySnapshot = await _firestore
            .collection(_collectionName)
            .where(_dbReferenceKey, isEqualTo: item.dbRef)
            .get(); // Get from server for consistency
        if (querySnapshot.size > 0) {
          final documentRef = querySnapshot.docs[0].reference;
          await documentRef.delete();
          tempPrint('Item deleted from live firestore successfully! ($_collectionName)');
        } else {
          tempPrint(
              'Item not found for deletion in live firestore: ${item.dbRef} ($_collectionName)');
        }
        return;
      } catch (e) {
        errorPrint('Error deleting item from firestore ($_collectionName): $e');
        return;
      }
    }
    // when offline
    final querySnapshot = await _firestore
        .collection(_collectionName)
        .where(_dbReferenceKey, isEqualTo: item.dbRef)
        .get(const GetOptions(source: Source.cache));
    if (querySnapshot.size > 0) {
      final documentRef = querySnapshot.docs[0].reference;
      await documentRef.delete().then((_) {
        tempPrint('Item deleted from firestore cache! ($_collectionName)');
      }).catchError((e) {
        errorPrint('Error deleting item from firestore cache ($_collectionName): $e');
      });
    } else {
      tempPrint('Item not found for deletion in cache: ${item.dbRef} ($_collectionName)');
    }
  }

  // MODIFIED watchItemListAsMaps with optional filters and correct type casting
  Stream<List<Map<String, dynamic>>> watchItemListAsMaps({String? filterKey, dynamic filterValue}) {
    Query query = _firestore.collection(_collectionName);

    if (filterKey != null && filterValue != null) {
      if (filterValue is String && filterValue.isNotEmpty) {
        query = query.where(filterKey, isEqualTo: filterValue);
      } else if (filterValue != null && filterValue is! String) {
        // This handles non-string, non-empty values like booleans or numbers.
        query = query.where(filterKey, isEqualTo: filterValue);
      }
      // Note: Does not apply filter if filterValue is an empty string or null while filterKey is present.
      // This behavior is fine for salesmanDbRef which should always be a non-empty string if used.
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((docSnapshot) => docSnapshot.data() as Map<String, dynamic>).toList());
  }

  /// Existing watchItemListAsItems (consider if filtering is needed here too for other use cases)
  Stream<List<BaseItem>> watchItemListAsItems({String? filterKey, dynamic filterValue}) {
    // Added optional filters for consistency
    Query query = _firestore.collection(_collectionName);
    if (filterKey != null && filterValue != null) {
      // Added filter logic
      if (filterValue is String && filterValue.isNotEmpty) {
        query = query.where(filterKey, isEqualTo: filterValue);
      } else if (filterValue != null && filterValue is! String) {
        query = query.where(filterKey, isEqualTo: filterValue);
      }
    }
    final ref = query.withConverter(
      fromFirestore: (doc, _) =>
          BaseItem.fromMap(doc.data()!), // Ensure BaseItem.fromMap exists and works
      toFirestore: (BaseItem item, options) => item.toMap(),
    );
    return ref
        .snapshots()
        .map((snapshot) => snapshot.docs.map((docSnapshot) => docSnapshot.data()).toList());
  }

  // MODIFIED fetchItemListAsMaps with improved filtering for exact matches
  Future<List<Map<String, dynamic>>> fetchItemListAsMaps(
      {String? filterKey, dynamic filterValue}) async {
    try {
      Query query = _firestore.collection(_collectionName);

      if (filterKey != null && filterValue != null) {
        // Specific logic for string prefix search, typically for 'name' or similar fields
        if (filterKey == 'name' && filterValue is String && filterValue.isNotEmpty) {
          query = query
              .where(filterKey, isGreaterThanOrEqualTo: filterValue)
              .where(filterKey, isLessThan: '$filterValue\uf8ff');
        } else if (filterValue is DateTime) {
          // DateTime filter (matches within the specified day)
          DateTime startOfDay = DateTime(filterValue.year, filterValue.month, filterValue.day);
          DateTime startOfNextDay = startOfDay.add(const Duration(days: 1));
          Timestamp startTimestamp = Timestamp.fromDate(startOfDay);
          Timestamp endTimestamp = Timestamp.fromDate(startOfNextDay);
          query = query
              .where(filterKey, isGreaterThanOrEqualTo: startTimestamp)
              .where(filterKey, isLessThan: endTimestamp);
        } else {
          // Default to exact match for other types or specific string keys
          // (e.g., 'dbRef', 'salesmanDbRef')
          query = query.where(filterKey, isEqualTo: filterValue);
        }
      }

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet) ||
          connectivityResult.contains(ConnectivityResult.vpn) ||
          connectivityResult.contains(ConnectivityResult.mobile)) {
        final snapshot = await query.get();
        tempPrint('data fetched from firebase ($_collectionName) live data');
        return snapshot.docs
            .map((docSnapshot) => docSnapshot.data() as Map<String, dynamic>)
            .toList();
      } else {
        tempPrint('data fetched from cache ($_collectionName)');
        final cachedSnapshot = await query.get(const GetOptions(source: Source.cache));
        return cachedSnapshot.docs
            .map((docSnapshot) => docSnapshot.data() as Map<String, dynamic>)
            .toList();
      }
    } catch (e) {
      debugLog('Error during fetching items from Firebase ($_collectionName) - $e');
      return [];
    }
  }
}
