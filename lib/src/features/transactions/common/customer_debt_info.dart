import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/features/transactions/controllers/customer_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_db_cache_provider.dart';

Map<String, dynamic> getCustomerDbetInfo(WidgetRef ref, String customerDbRef) {
  Map<String, dynamic> customerDebtInfo = {};
  final transactionsDbCache = ref.read(transactionDbCacheProvider.notifier);
  final transactions = transactionsDbCache.data;
  final customerDbCache = ref.read(salesmanCustomerDbCacheProvider.notifier);
  final customerData = customerDbCache.getItemByDbRef(customerDbRef);
  final initialDebt = customerData['initialCredit'];
  double totalDebt = initialDebt;
  final customerTransactions =
      transactions.where((transaction) => transaction['nameDbRef'] == customerDbRef);
  final invoiceDates = [];
  final receiptDates = [];
  for (var transaction in customerTransactions) {
    if (transaction['transactionType'] == TransactionType.customerInvoice.name) {
      totalDebt += transaction['totalAmount'] ?? 0;
      invoiceDates.add(
          transaction['date'] is DateTime ? transaction['date'] : transaction['date'].toDate());
    } else if (transaction['transactionType'] == TransactionType.customerReceipt.name) {
      totalDebt -= transaction['totalAmount'] ?? 0;
      receiptDates.add(
          transaction['date'] is DateTime ? transaction['date'] : transaction['date'].toDate());
    } else if (transaction['transactionType'] == TransactionType.customerReturn.name) {
      totalDebt -= transaction['totalAmount'] ?? 0;
    }
  }
  dynamic latestReceiptDate;
  if (receiptDates.isNotEmpty) {
    latestReceiptDate = receiptDates.reduce((a, b) => a.isAfter(b) ? a : b);
  } else {
    latestReceiptDate = 'لا يوجد';
  }
  dynamic latestInvoiceDate;
  if (invoiceDates.isNotEmpty) {
    latestInvoiceDate = invoiceDates.reduce((a, b) => a.isAfter(b) ? a : b);
  } else {
    latestInvoiceDate = 'لا يوجد';
  }
  customerDebtInfo['totalDebt'] = totalDebt;
  customerDebtInfo['lastReceiptDate'] = latestReceiptDate;
  customerDebtInfo['latestInvoiceDate'] = latestInvoiceDate;
  return customerDebtInfo;
}
