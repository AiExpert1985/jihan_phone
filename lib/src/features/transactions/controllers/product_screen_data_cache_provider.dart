import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/features/transactions/repository/product_screen_data_repository_provider.dart';

final productScreenDataCacheProvider =
    StateNotifierProvider<DbCache, List<Map<String, dynamic>>>((ref) {
  final screenDataRepo = ref.watch(productScreenDataRepositoryProvider);
  return DbCache(repository: screenDataRepo);
});
