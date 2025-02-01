import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/features/transactions/controllers/customer_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';

Map<String, dynamic> getCustomerDbetInfo(
    WidgetRef ref, String customerDbRef, num paymentDurationLimit) {
  Map<String, dynamic> customerDebtInfo = {};
  final transactionsDbCache = ref.read(transactionDbCacheProvider.notifier);
  final transactions = transactionsDbCache.data;
  final customerDbCache = ref.read(customerDbCacheProvider.notifier);
  // first calculate the total debt
  final customerData = customerDbCache.getItemByDbRef(customerDbRef);
  final initialDebt = customerData['initialCredit'];
  double totalDebt = initialDebt;
  final customerTransactions =
      transactions.where((transaction) => transaction['nameDbRef'] == customerDbRef);
  List<Transaction> customerInvoices = [];
  List<Transaction> customerReceipts = [];
  for (var transaction in customerTransactions) {
    if (transaction['transactionType'] == TransactionType.customerInvoice.name) {
      totalDebt += transaction['totalAmount'] ?? 0;
      customerInvoices.add(Transaction.fromMap(transaction));
    } else if (transaction['transactionType'] == TransactionType.customerReceipt.name) {
      totalDebt -= transaction['totalAmount'] ?? 0;
      customerReceipts.add(Transaction.fromMap(transaction));
    } else if (transaction['transactionType'] == TransactionType.customerReturn.name) {
      totalDebt -= transaction['totalAmount'] ?? 0;
    }
  }

  // then calculate latest receipt & invoice
  customerInvoices.sort((a, b) => b.date.compareTo(a.date));
  customerReceipts.sort((a, b) => b.date.compareTo(a.date));
  DateTime? latestReceiptDate = customerReceipts.isEmpty ? null : customerReceipts[0].date;
  DateTime? latestInvoiceDate = customerInvoices.isEmpty ? null : customerInvoices[0].date;

  // then caculate due debt
  // the idea is to remove invoices that didn't exceed the time limit, so the remaining are due invoices
  double dueDebt = totalDebt;
  for (var invoice in customerInvoices) {
    Duration difference = DateTime.now().difference(invoice.date);
    if (difference.inDays < paymentDurationLimit) {
      dueDebt -= invoice.totalAmount;
    }
  }

  // finally store results
  customerDebtInfo['totalDebt'] = totalDebt;
  customerDebtInfo['dueDebt'] = dueDebt;
  customerDebtInfo['lastReceiptDate'] = latestReceiptDate;
  customerDebtInfo['latestInvoiceDate'] = latestInvoiceDate;
  return customerDebtInfo;
}

    // // if last invoice date exceeds the paymentDurationLimit, the the customer considered invalid
    // Duration difference = DateTime.now().difference(latestCustomerInvoiceDate);
    // if (difference.inDays >= paymentDurationLimit) {
    //   isValidUser = false;
    //   // failureUserMessage(context, 'زبون تجاوز مدة التسديد المسموحة');
    //   return;
    // }
