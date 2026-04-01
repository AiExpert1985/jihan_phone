import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/features/transactions/repository/products_repository_provider.dart';

final productsDbCacheProvider = StateNotifierProvider<DbCache, List<Map<String, dynamic>>>((ref) {
  final productsRepo = ref.watch(productsRepositoryProvider);
  return DbCache(repository: productsRepo);
});
