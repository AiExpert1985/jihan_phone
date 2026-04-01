// lib/src/common/classes/db_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tablets/src/common/interfaces/base_item.dart';
import 'package:tablets/src/common/functions/debug_print.dart';

class DbRepository {
  DbRepository(this._collectionName);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collectionName;
  final String _dbReferenceKey = 'dbRef';

  /// Uses dbRef as document ID to ensure idempotency (prevents duplicates on retry)
  /// With persistence enabled, writes go to local cache first and sync in background
  Future<void> addItem(BaseItem item) async {
    try {
      await _firestore.collection(_collectionName).doc(item.dbRef).set(item.toMap());
      tempPrint('Item added successfully! ($_collectionName)');
    } catch (e) {
      errorPrint('Error adding item to firestore ($_collectionName): $e');
    }
  }

  Future<void> updateItem(BaseItem updatedItem) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where(_dbReferenceKey, isEqualTo: updatedItem.dbRef)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update(updatedItem.toMap());
        debugLog('Item updated successfully! ($_collectionName)');
      } else {
        debugLog('Item not found for update: ${updatedItem.dbRef} ($_collectionName)');
      }
    } catch (e) {
      errorPrint('Error updating item in firestore ($_collectionName): $e');
    }
  }

  Future<void> deleteItem(BaseItem item) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where(_dbReferenceKey, isEqualTo: item.dbRef)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
        tempPrint('Item deleted successfully! ($_collectionName)');
      } else {
        tempPrint('Item not found for deletion: ${item.dbRef} ($_collectionName)');
      }
    } catch (e) {
      errorPrint('Error deleting item from firestore ($_collectionName): $e');
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

      final snapshot = await query.get();
      tempPrint('data fetched from firebase ($_collectionName)');
      return snapshot.docs
          .map((docSnapshot) => docSnapshot.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugLog('Error during fetching items from Firebase ($_collectionName) - $e');
      return [];
    }
  }
}
