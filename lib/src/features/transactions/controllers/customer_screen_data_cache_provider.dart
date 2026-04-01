import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/features/transactions/repository/customer_screen_data_repository_provider.dart';

final customerScreenDataCacheProvider =
    StateNotifierProvider<DbCache, List<Map<String, dynamic>>>((ref) {
  final screenDataRepo = ref.watch(customerScreenDataRepositoryProvider);
  return DbCache(repository: screenDataRepo);
});
