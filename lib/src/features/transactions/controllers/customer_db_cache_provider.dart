// lib/src/features/transactions/controllers/customer_db_cache_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/features/transactions/repository/customer_repository_provider.dart';
import 'package:tablets/src/common/providers/salesman_info_provider.dart';

final customerDbCacheProvider =
    StateNotifierProvider.autoDispose<DbCache, List<Map<String, dynamic>>>((ref) {
  final customerRepo = ref.watch(customerRepositoryProvider);
  final salesmanInfo = ref.watch(salesmanInfoProvider);
  final salesmanDbRef = salesmanInfo.dbRef;

  final dbCacheInstance = DbCache(
    repository: customerRepo,
    streamFilterKey: 'salesmanDbRef',
    streamFilterValue: salesmanDbRef,
  );
  return dbCacheInstance;
});
