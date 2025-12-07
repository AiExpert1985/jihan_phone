import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/features/transactions/controllers/product_screen_data_cache_provider.dart';

double getProductStock(WidgetRef ref, String productDbRef) {
  final screenDataCache = ref.read(productScreenDataCacheProvider.notifier);
  final screenData = screenDataCache.getItemByDbRef(productDbRef);
  if (screenData.isEmpty) return 0.0;
  return (screenData['quantity'] as num?)?.toDouble() ?? 0.0;
}
