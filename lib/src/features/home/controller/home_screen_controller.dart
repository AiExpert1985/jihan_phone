import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/providers/data_loading_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/features/transactions/controllers/cart_provider.dart';
import 'package:tablets/src/features/transactions/controllers/customer_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_data_container.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/common/functions/dialog_delete_confirmation.dart';

class HomeScreenNotifier extends StateNotifier<HomeScreenState> {
  HomeScreenNotifier(this._ref) : super(HomeScreenState());

  final Ref _ref;

  void initialize() {
    // Load salesman info
    _ref.read(dataLoadingController.notifier).loadSalesmanInfo();

    // Load customer debt info if a customer is selected
    final formData = _ref.read(formDataContainerProvider);
    final customerSelectedName = formData['name'];
    if (customerSelectedName != null) {
      final customerDbCache = _ref.read(customerDbCacheProvider.notifier);
      final customer = customerDbCache.getItemByProperty('name', customerSelectedName);
      _setCustomerDebtVariables(customer);
    }
  }

  void selectCustomer(WidgetRef ref, Map<String, dynamic> customer) async {
    final formDataNotifier = _ref.read(formDataContainerProvider.notifier);
    formDataNotifier.reset();
    _ref.read(cartProvider.notifier).reset();
    formDataNotifier.addProperty('name', customer['name']);
    formDataNotifier.addProperty('nameDbRef', customer['dbRef']);
    formDataNotifier.addProperty('sellingPriceType', customer['sellingPriceType']);
    formDataNotifier.addProperty('isEditable', true);
    ref.read(dataLoadingController.notifier).startLoading();
    await _setCustomerDebtVariables(customer);
    ref.read(dataLoadingController.notifier).stopLoading();
  }

  bool customerIsSelected() {
    return _ref.read(formDataContainerProvider).containsKey('name');
  }

  Future<bool> resetTransactionConfirmation(BuildContext context) async {
    final formDataNotifier = _ref.read(formDataContainerProvider.notifier);
    final cartNotifier = _ref.read(cartProvider.notifier);

    final formData = formDataNotifier.data;
    if (formData['name'] == null) {
      formDataNotifier.reset();
      cartNotifier.reset();
      return true;
    }

    final confirmation = await showDeleteConfirmationDialog(
      context: context,
      messagePart1: "",
      messagePart2: 'سوف يتم حذف قائمة ${formData['name']} ؟',
    );

    if (confirmation != null) {
      formDataNotifier.reset();
      cartNotifier.reset();
      return true;
    }
    return false;
  }

  Future<void> _setCustomerDebtVariables(Map<String, dynamic> customer) async {
    num paymentDurationLimit = customer['paymentDurationLimit'];
    final customerDebtInfo = await getCustomerDebtInfo(customer['dbRef'], paymentDurationLimit);

    state.totalDebt = customerDebtInfo['totalDebt'];
    state.dueDebt = customerDebtInfo['dueDebt'];
    state.latestReceiptDate = customerDebtInfo['lastReceiptDate'] ?? 'لا يوجد';
    state.latestInvoiceDate = customerDebtInfo['latestInvoiceDate'] ?? 'لا يوجد';
    _validateCustomer(paymentDurationLimit, customer['creditLimit']);
  }

  void _validateCustomer(num paymentDurationLimit, num creditLimit) {
    if (state.totalDebt == null || state.dueDebt == null) return;

    state.isValidUser =
        state.totalDebt! <= 0 || (state.totalDebt! < creditLimit && state.dueDebt! <= 0);
  }

  Future<Map<String, dynamic>> getCustomerDebtInfo(
      String customerDbRef, num paymentDurationLimit) async {
    await _ref.read(dataLoadingController.notifier).loadTransactions();
    final transactionsDbCache = _ref.read(transactionDbCacheProvider);
    final customerData = _ref.read(customerDbCacheProvider.notifier).getItemByDbRef(customerDbRef);
    final double initialDebt = customerData['initialCredit'] ?? 0.0;
    double totalDebt = initialDebt;
    List<Transaction> customerInvoices = [];
    List<Transaction> customerReceipts = [];
    final customerTransactions = transactionsDbCache
        .where((transaction) => transaction['nameDbRef'] == customerDbRef)
        .toList();

    for (var transaction in customerTransactions) {
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
    }

    customerInvoices.sort((a, b) => b.date.compareTo(a.date));
    customerReceipts.sort((a, b) => b.date.compareTo(a.date));

    DateTime? latestReceiptDate = customerReceipts.isNotEmpty ? customerReceipts.first.date : null;
    DateTime? latestInvoiceDate = customerInvoices.isNotEmpty ? customerInvoices.first.date : null;

    double dueDebt = calculateDueDebt(customerInvoices, paymentDurationLimit, totalDebt);

    return {
      'totalDebt': totalDebt,
      'dueDebt': dueDebt,
      'lastReceiptDate': latestReceiptDate,
      'latestInvoiceDate': latestInvoiceDate,
    };
  }

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
}

class HomeScreenState {
  num? totalDebt;
  num? dueDebt;
  dynamic latestReceiptDate;
  dynamic latestInvoiceDate;
  bool isValidUser = true;
}

final homeScreenStateController = StateNotifierProvider<HomeScreenNotifier, HomeScreenState>((ref) {
  return HomeScreenNotifier(ref);
});
