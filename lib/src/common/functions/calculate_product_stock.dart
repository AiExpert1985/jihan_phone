import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/features/transactions/controllers/products_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_db_cache_provider.dart';

double calculateProductStock(WidgetRef ref, String productDbRef) {
  final productDbCache = ref.read(productsDbCacheProvider.notifier);
  final targetProduct = productDbCache.getItemByDbRef(productDbRef);
  final initialStock = targetProduct['initialQuantity'];
  double stock = initialStock.toDouble();
  final transactionDbRef = ref.read(transactionDbCacheProvider.notifier);
  final transactions = transactionDbRef.data;
  for (var transaction in transactions) {
    final transactionType = transaction['transactionType'];
    if (transactionType == TransactionType.customerReceipt.name ||
        transactionType == TransactionType.vendorReceipt.name ||
        transactionType == TransactionType.expenditures.name) {
      continue;
    }
    for (var item in transaction['items'] ?? []) {
      if (item['dbRef'] != productDbRef) continue;
      if (transactionType == TransactionType.customerInvoice.name ||
          transactionType == TransactionType.vendorReturn.name ||
          transactionType == TransactionType.gifts.name ||
          transactionType == TransactionType.damagedItems.name) {
        stock -= item['soldQuantity'] ?? 0;
        stock -= item['giftQuantity'] ?? 0;
      } else if (transactionType == TransactionType.vendorInvoice.name ||
          transactionType == TransactionType.customerReturn.name) {
        stock += item['soldQuantity'] ?? 0;
        stock += item['giftQuantity'] ?? 0;
      } else {
        errorPrint('wrong transaction type');
      }
    }
  }
  return stock;
}
