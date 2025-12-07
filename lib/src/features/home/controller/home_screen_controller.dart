// lib/src/features/home/controller/home_screen_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/providers/data_loading_provider.dart';
import 'package:tablets/src/features/transactions/controllers/cart_provider.dart';
import 'package:tablets/src/features/transactions/controllers/customer_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/customer_screen_data_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_data_container.dart';
import 'package:tablets/src/common/functions/dialog_delete_confirmation.dart';

String _formatTimestamp(dynamic value) {
  if (value == null) return 'لا يوجد';
  if (value is Timestamp) return formatDate(value.toDate());
  if (value is DateTime) return formatDate(value);
  return value.toString();
}

class HomeScreenState {
  final num? totalDebt;
  final num? dueDebt;
  final dynamic latestReceiptDate;
  final dynamic latestInvoiceDate;
  final bool isValidUser;
  final bool isLoading;

  HomeScreenState({
    this.totalDebt,
    this.dueDebt,
    this.latestReceiptDate,
    this.latestInvoiceDate,
    this.isValidUser = true,
    this.isLoading = false,
  });

  HomeScreenState copyWith({
    num? totalDebt,
    num? dueDebt,
    dynamic latestReceiptDate,
    dynamic latestInvoiceDate,
    bool? isValidUser,
    bool? isLoading,
  }) {
    return HomeScreenState(
      totalDebt: totalDebt ?? this.totalDebt,
      dueDebt: dueDebt ?? this.dueDebt,
      latestReceiptDate: latestReceiptDate ?? this.latestReceiptDate,
      latestInvoiceDate: latestInvoiceDate ?? this.latestInvoiceDate,
      isValidUser: isValidUser ?? this.isValidUser,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HomeScreenNotifier extends StateNotifier<HomeScreenState> {
  HomeScreenNotifier(this._ref) : super(HomeScreenState()) {
    _initializeData();
    // Listen for screen data changes and retry debt lookup when data arrives
    _ref.listen<List<Map<String, dynamic>>>(customerScreenDataCacheProvider, (_, __) {
      _retryDebtLookupIfNeeded();
    });
  }

  Future<void> _initializeData() async {
    final loader = _ref.read(dataLoadingController.notifier);
    await loader.loadSalesmanInfo();
    await loader.loadCustomers();
  }

  final Ref _ref;

  void _retryDebtLookupIfNeeded() {
    if (!state.isLoading) return;
    final formData = _ref.read(formDataContainerProvider);
    final customerDbRef = formData['nameDbRef'] as String?;
    if (customerDbRef != null && customerDbRef.isNotEmpty) {
      _loadDebtFromCache(customerDbRef);
    }
  }

  void selectCustomer(WidgetRef ref, Map<String, dynamic> customer) {
    final formDataNotifier = _ref.read(formDataContainerProvider.notifier);
    formDataNotifier.reset();
    _ref.read(cartProvider.notifier).reset();

    final customerDbRef = customer['dbRef'] as String?;

    formDataNotifier.addProperty('name', customer['name']);
    formDataNotifier.addProperty('nameDbRef', customerDbRef);
    formDataNotifier.addProperty('sellingPriceType', customer['sellingPriceType']);
    formDataNotifier.addProperty('isEditable', true);

    if (customerDbRef != null && customerDbRef.isNotEmpty) {
      _loadDebtFromCache(customerDbRef);
    }
  }

  void _loadDebtFromCache(String customerDbRef) {
    final screenDataCache = _ref.read(customerScreenDataCacheProvider.notifier);
    final screenData = screenDataCache.getItemByDbRef(customerDbRef);

    if (screenData.isEmpty) {
      // Data not loaded yet, show loading state
      if (mounted) {
        state = HomeScreenState(isLoading: true);
      }
      return;
    }

    final totalDebt = screenData['totalDebt'] as num? ?? 0;
    final dueDebt = screenData['dueDebt'] as num? ?? 0;

    // Get customer data for validation
    final customerDbCache = _ref.read(customerDbCacheProvider.notifier);
    final customerData = customerDbCache.getItemByDbRef(customerDbRef);
    final creditLimit = customerData['creditLimit'] as num? ?? 0;

    if (mounted) {
      state = HomeScreenState(
        totalDebt: totalDebt,
        dueDebt: dueDebt,
        latestReceiptDate: _formatTimestamp(screenData['lastReceiptDate']),
        latestInvoiceDate: _formatTimestamp(screenData['lastInvoiceDate']),
        isValidUser: _isValidCustomer(totalDebt, dueDebt, creditLimit),
        isLoading: false,
      );
    }
  }

  bool _isValidCustomer(num totalDebt, num dueDebt, num creditLimit) {
    return totalDebt <= 0 || (totalDebt < creditLimit && dueDebt <= 0);
  }

  bool customerIsSelected() {
    return _ref.read(formDataContainerProvider).containsKey('nameDbRef');
  }

  Future<bool> resetTransactionConfirmation(BuildContext context) async {
    final formDataNotifier = _ref.read(formDataContainerProvider.notifier);
    final cartNotifier = _ref.read(cartProvider.notifier);
    final currentFormData = formDataNotifier.data;

    if (currentFormData['nameDbRef'] == null) {
      formDataNotifier.reset();
      cartNotifier.reset();
      if (mounted) state = HomeScreenState();
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
      if (mounted) state = HomeScreenState();
      return true;
    }
    return false;
  }
}

final homeScreenStateController =
    StateNotifierProvider.autoDispose<HomeScreenNotifier, HomeScreenState>((ref) {
  return HomeScreenNotifier(ref);
});
