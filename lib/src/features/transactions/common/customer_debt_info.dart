import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/features/transactions/controllers/customer_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';

Map<String, dynamic> getCustomerDebtInfo(
    WidgetRef ref, String customerDbRef, num paymentDurationLimit) {
  final transactionsDbCache = ref.read(transactionDbCacheProvider.notifier);
  final transactions = transactionsDbCache.data;
  final customerDbCache = ref.read(customerDbCacheProvider.notifier);

  final customerData = customerDbCache.getItemByDbRef(customerDbRef);
  final double initialDebt = customerData['initialCredit'] ?? 0.0;

  double totalDebt = initialDebt;
  List<Transaction> customerInvoices = [];
  List<Transaction> customerReceipts = [];

  // Process transactions to calculate total debt and categorize them
  transactions
      .where((transaction) => transaction['nameDbRef'] == customerDbRef)
      .forEach((transaction) {
    final transactionType = transaction['transactionType'];
    final totalAmount = transaction['totalAmount'] ?? 0.0;

    if (transactionType == TransactionType.customerInvoice.name) {
      totalDebt += totalAmount ?? 0;
      customerInvoices.add(Transaction.fromMap(transaction));
    } else if (transactionType == TransactionType.customerReceipt.name) {
      totalDebt -= totalAmount ?? 0;
      customerReceipts.add(Transaction.fromMap(transaction));
    } else if (transactionType == TransactionType.customerReturn.name) {
      totalDebt -= totalAmount ?? 0;
    }
  });

  // Sort invoices and receipts by date
  customerInvoices.sort((a, b) => b.date.compareTo(a.date));
  customerReceipts.sort((a, b) => b.date.compareTo(a.date));

  DateTime? latestReceiptDate = customerReceipts.isNotEmpty ? customerReceipts.first.date : null;
  DateTime? latestInvoiceDate = customerInvoices.isNotEmpty ? customerInvoices.first.date : null;

  // Calculate due debt
  double dueDebt = calculateDueDebt(customerInvoices, paymentDurationLimit, totalDebt);

  // Store results
  return {
    'totalDebt': totalDebt,
    'dueDebt': dueDebt,
    'lastReceiptDate': latestReceiptDate,
    'latestInvoiceDate': latestInvoiceDate,
  };
}

// the idea is to remove invoices that didn't exceed the time limit, so the remaining are due invoices
double calculateDueDebt(List<Transaction> invoices, num paymentDurationLimit, double totalDebt) {
  double dueDebt = totalDebt;
  for (var invoice in invoices) {
    if (dueDebt <= 0 || DateTime.now().difference(invoice.date).inDays >= paymentDurationLimit) {
      break;
    }
    dueDebt -= invoice.totalAmount;
  }
  return max(dueDebt, 0.0);
}
