// lib/src/features/home/controller/home_screen_controller.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/providers/data_loading_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/features/transactions/controllers/cart_provider.dart';
import 'package:tablets/src/features/transactions/controllers/customer_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_data_container.dart';
import 'package:tablets/src/features/transactions/controllers/selected_customer_transaction_stream_provider.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/common/functions/dialog_delete_confirmation.dart';

class HomeScreenState {
  final num? totalDebt;
  final num? dueDebt;
  final dynamic latestReceiptDate;
  final dynamic latestInvoiceDate;
  final bool isValidUser;
  final bool isLoadingDebt; // For debt calculation loading state
  final String? debtError; // For debt calculation errors

  HomeScreenState({
    this.totalDebt,
    this.dueDebt,
    this.latestReceiptDate,
    this.latestInvoiceDate,
    this.isValidUser = true,
    this.isLoadingDebt = false,
    this.debtError,
  });

  HomeScreenState copyWith({
    num? totalDebt,
    num? dueDebt,
    dynamic latestReceiptDate,
    dynamic latestInvoiceDate,
    bool? isValidUser,
    bool? isLoadingDebt,
    String? debtError,
    bool clearDebtError = false, // Flag to explicitly clear error
  }) {
    return HomeScreenState(
      totalDebt: totalDebt ?? this.totalDebt,
      dueDebt: dueDebt ?? this.dueDebt,
      latestReceiptDate: latestReceiptDate ?? this.latestReceiptDate,
      latestInvoiceDate: latestInvoiceDate ?? this.latestInvoiceDate,
      isValidUser: isValidUser ?? this.isValidUser,
      isLoadingDebt: isLoadingDebt ?? this.isLoadingDebt,
      debtError: clearDebtError ? null : debtError ?? this.debtError,
    );
  }
}

class HomeScreenNotifier extends StateNotifier<HomeScreenState> {
  HomeScreenNotifier(this._ref) : super(HomeScreenState()) {
    // Load salesman info on initialization
    _ref.read(dataLoadingController.notifier).loadSalesmanInfo();
    // Start listening to transaction changes for the selected customer
    _listenToSelectedCustomerTransactions();
  }

  final Ref _ref;
  // No longer need _transactionsSubscription here as ref.listen handles lifecycle.
  String? _currentProcessingCustomerDbRef;

  void _listenToSelectedCustomerTransactions() {
    _ref.listen<AsyncValue<List<Map<String, dynamic>>>>(selectedCustomerTransactionsStreamProvider,
        (previous, next) {
      // Optionally, manage a broader loading state if needed,
      // but HomeScreenState.isLoadingDebt is more specific.
      // _ref.read(dataLoadingController.notifier).startLoading();

      next.when(
        data: (transactionsMaps) {
          final formData = _ref.read(formDataContainerProvider);
          final customerDbRef = formData['nameDbRef'] as String?;

          // Process only if the transactions are for the currently selected customer
          if (customerDbRef != null &&
              customerDbRef.isNotEmpty &&
              customerDbRef == _currentProcessingCustomerDbRef) {
            final customerDataMap =
                _ref.read(customerDbCacheProvider.notifier).getItemByDbRef(customerDbRef);
            if (customerDataMap.isNotEmpty) {
              final paymentDurationLimit = customerDataMap['paymentDurationLimit'] as num? ?? 0;
              final creditLimit = customerDataMap['creditLimit'] as num? ?? 0;
              final initialCredit = customerDataMap['initialCredit']?.toDouble() ?? 0.0;

              final debtInfo = _calculateDebtWithGivenTransactions(
                  transactionsMaps, initialCredit, paymentDurationLimit);

              if (mounted) {
                state = state.copyWith(
                  totalDebt: debtInfo['totalDebt'],
                  dueDebt: debtInfo['dueDebt'],
                  latestReceiptDate: debtInfo['lastReceiptDate'] ?? 'لا يوجد',
                  latestInvoiceDate: debtInfo['latestInvoiceDate'] ?? 'لا يوجد',
                  isLoadingDebt: false,
                  clearDebtError: true, // Clear any previous error on new data
                );
                _validateCustomer(paymentDurationLimit, creditLimit);
              }
            } else {
              if (mounted) {
                state = state.copyWith(
                    isLoadingDebt: false,
                    debtError: "بيانات الزبون غير متوفرة",
                    clearDebtError: false);
              }
            }
          } else if (customerDbRef == null || customerDbRef.isEmpty) {
            // No customer is selected, or selection cleared
            if (mounted) {
              state = HomeScreenState(); // Reset to initial, non-loading, no-error state
            }
          }
          // _ref.read(dataLoadingController.notifier).stopLoading();
        },
        loading: () {
          if (mounted) state = state.copyWith(isLoadingDebt: true, clearDebtError: true);
        },
        error: (err, stack) {
          errorPrint("Error in selectedCustomerTransactionsStreamProvider listener: $err");
          if (mounted) state = state.copyWith(isLoadingDebt: false, debtError: err.toString());
          // _ref.read(dataLoadingController.notifier).stopLoading();
        },
      );
    }, fireImmediately: true // Process current value immediately upon listen
        );
  }

  Map<String, dynamic> _calculateDebtWithGivenTransactions(
      List<Map<String, dynamic>> customerTransactionsMaps,
      double initialDebt,
      num paymentDurationLimit) {
    double currentTotalDebt = initialDebt;
    List<Transaction> customerInvoices = [];
    List<Transaction> customerReceipts = [];

    for (var transactionMap in customerTransactionsMaps) {
      final transactionType = transactionMap['transactionType'];
      final totalAmount = transactionMap['totalAmount']?.toDouble() ?? 0.0;

      if (transactionType == TransactionType.customerInvoice.name) {
        currentTotalDebt += totalAmount;
        customerInvoices.add(Transaction.fromMap(transactionMap));
      } else if (transactionType == TransactionType.customerReceipt.name) {
        currentTotalDebt -= totalAmount;
        customerReceipts.add(Transaction.fromMap(transactionMap));
      } else if (transactionType == TransactionType.customerReturn.name) {
        currentTotalDebt -= totalAmount;
      }
    }

    customerInvoices.sort((a, b) => b.date.compareTo(a.date));
    customerReceipts.sort((a, b) => b.date.compareTo(a.date));

    DateTime? latestReceiptDate = customerReceipts.isNotEmpty ? customerReceipts.first.date : null;
    DateTime? latestInvoiceDate = customerInvoices.isNotEmpty ? customerInvoices.first.date : null;
    double dueDebt = calculateDueDebt(customerInvoices, paymentDurationLimit, currentTotalDebt);

    return {
      'totalDebt': currentTotalDebt,
      'dueDebt': dueDebt,
      'lastReceiptDate': latestReceiptDate,
      'latestInvoiceDate': latestInvoiceDate,
    };
  }

  void selectCustomer(WidgetRef ref, Map<String, dynamic> customer) {
    final formDataNotifier = _ref.read(formDataContainerProvider.notifier);
    formDataNotifier.reset();
    _ref.read(cartProvider.notifier).reset();

    final customerDbRef = customer['dbRef'] as String?;
    _currentProcessingCustomerDbRef = customerDbRef;

    formDataNotifier.addProperty('name', customer['name']);
    formDataNotifier.addProperty('nameDbRef', customerDbRef);
    formDataNotifier.addProperty('sellingPriceType', customer['sellingPriceType']);
    formDataNotifier.addProperty('isEditable', true);

    // Set initial loading state. Debt info will be updated by the stream listener.
    // This change in formDataContainerProvider (nameDbRef) will trigger
    // selectedCustomerTransactionsStreamProvider to update.
    if (mounted) {
      state = state.copyWith(
          totalDebt: null,
          dueDebt: null,
          latestReceiptDate: null,
          latestInvoiceDate: null,
          isValidUser: true,
          isLoadingDebt: true,
          clearDebtError: true);
    }
  }

  bool customerIsSelected() {
    // Use nameDbRef for a more reliable check if a customer is selected
    return _ref.read(formDataContainerProvider).containsKey('nameDbRef');
  }

  Future<bool> resetTransactionConfirmation(BuildContext context) async {
    final formDataNotifier = _ref.read(formDataContainerProvider.notifier);
    final cartNotifier = _ref.read(cartProvider.notifier);
    final currentFormData = formDataNotifier.data; // Read data once

    if (currentFormData['nameDbRef'] == null) {
      // Check if a customer is truly selected
      formDataNotifier.reset();
      cartNotifier.reset();
      _currentProcessingCustomerDbRef = null;
      if (mounted) state = HomeScreenState(); // Reset to initial state
      return true;
    }

    final confirmation = await showUserConfirmationDialog(
      context: context,
      messagePart1: "هل أنت متأكد؟",
      messagePart2: 'سيتم إلغاء المعاملة الحالية للزبون ${currentFormData['name']} ؟',
    );

    if (confirmation == true) {
      formDataNotifier.reset();
      cartNotifier.reset();
      _currentProcessingCustomerDbRef = null; // Clear the ref
      if (mounted) state = HomeScreenState(); // Reset to initial state
      return true;
    }
    return false;
  }

  void _validateCustomer(num paymentDurationLimit, num creditLimit) {
    if (!mounted) return;
    if (state.totalDebt == null || state.dueDebt == null) {
      state = state.copyWith(isValidUser: true); // Default if no debt info
      return;
    }
    // A customer is valid if:
    // 1. They have no debt (or credit).
    // 2. Or, their total debt is within the credit limit AND their due debt is zero or less.
    bool isValid = state.totalDebt! <= 0 || (state.totalDebt! < creditLimit && state.dueDebt! <= 0);
    state = state.copyWith(isValidUser: isValid);
  }

  double calculateDueDebt(List<Transaction> invoices, num paymentDurationLimit, double totalDebt) {
    double dueDebtAmount = totalDebt; // Start with total debt
    // Iterate through invoices. If an invoice is NOT YET past its payment duration,
    // its amount is subtracted from the total debt to determine what's "currently due"
    // (meaning, what portion of the debt is from older, unpaid invoices).
    for (var invoice in invoices) {
      if (dueDebtAmount <= 0) break; // No more debt to consider as due

      if (DateTime.now().difference(invoice.date).inDays < paymentDurationLimit) {
        // This invoice is still within its allowed payment period, so its amount is not "due" yet.
        dueDebtAmount -= invoice.totalAmount;
      }
    }
    return max(0.0, dueDebtAmount); // Due debt cannot be negative
  }

  // Removed initialize() as its primary task (loadSalesmanInfo) moved to constructor.
  // Removed old _setCustomerDebtVariables and getCustomerDebtInfo as their logic is now
  // part of the reactive flow with _listenToSelectedCustomerTransactions and _calculateDebtWithGivenTransactions.

  @override
  void dispose() {
    // _transactionsSubscription is no longer used with ref.listen,
    // Riverpod handles listener cleanup when the notifier is disposed.
    super.dispose();
  }
}

final homeScreenStateController =
    StateNotifierProvider.autoDispose<HomeScreenNotifier, HomeScreenState>((ref) {
  return HomeScreenNotifier(ref);
});
