import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tablets/src/common/providers/salesman_info_provider.dart';
import 'package:tablets/src/features/login/repository/accounts_repository.dart';
import 'package:tablets/src/features/transactions/controllers/pending_transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/repository/pending_transaction_repository_provider.dart';

// Create a provider for the LoadingNotifier

final dataLoadingController = StateNotifierProvider<LoadingNotifier, bool>((ref) {
  return LoadingNotifier(ref); // Pass the ref to the LoadingNotifier
});

class LoadingNotifier extends StateNotifier<bool> {
  LoadingNotifier(this._ref) : super(false); // Initial state is not loading

  final Ref _ref;

  void startLoading() {
    state = true; // Set loading to true
  }

  void stopLoading() {
    state = false; // Set loading to false
  }

  // Customer data is now loaded automatically via Firestore streams in customerDbCacheProvider
  // and customerScreenDataCacheProvider. This method is kept for API compatibility.
  Future<void> loadCustomers({bool loadFreshData = false}) async {
    // No-op: streams handle data loading automatically
  }

  Future<void> loadPendingTransactions() async {
    _ref.read(dataLoadingController.notifier).startLoading();
    final pendingTransactions =
        await _ref.read(pendingTransactionRepositoryProvider).fetchItemListAsMaps();
    _ref.read(pendingTransactionsDbCache.notifier).set(pendingTransactions);
    _ref.read(dataLoadingController.notifier).stopLoading();
  }

  Future<void> loadSalesmanInfo() async {
    final accountsRepository = _ref.read(accountsRepositoryProvider);
    final email = FirebaseAuth.instance.currentUser!.email;
    final accounts = await accountsRepository.fetchItemListAsMaps();
    final salesmanInfoNotifier = _ref.read(salesmanInfoProvider.notifier);
    var matchingAccounts = accounts.where((account) => account['email'] == email);
    if (matchingAccounts.isNotEmpty) {
      final dbRef = matchingAccounts.first['dbRef'];
      salesmanInfoNotifier.setDbRef(dbRef);
      final name = matchingAccounts.first['name'];
      salesmanInfoNotifier.setName(name);
      final email = matchingAccounts.first['email'];
      salesmanInfoNotifier.setEmail(email);
      final privilage = matchingAccounts.first['privilage'];
      salesmanInfoNotifier.setPrivilage(privilage);
    }
  }

  // Product data is now loaded automatically via Firestore streams in productsDbCacheProvider
  // and productScreenDataCacheProvider. This method is kept for API compatibility.
  Future<void> loadProducts({bool loadFreshData = false}) async {
    // No-op: streams handle data loading automatically
  }
}

// LoadingWrapper widget with a dark background and spinner
class LoadingWrapper extends ConsumerWidget {
  final Widget child;

  const LoadingWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(dataLoadingController);

    return Stack(
      children: [
        child, // The main content
        if (isLoading) ...[
          // Dark background with opacity
          Container(
            padding: const EdgeInsets.all(0),
            color: Colors.black54, // Semi-transparent black
          ),
          const Center(
            child: LoadingSpinner(
              text: 'جاري تحميل البيانات',
            ),
          ),
        ],
      ],
    );
  }
}

class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({this.text, super.key, this.fontColor = Colors.white});
  final String? text;
  final Color fontColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.white),
        if (text != null) ...[
          VerticalGap.xl,
          Text(
            text!,
            style: TextStyle(color: fontColor, fontSize: 14),
          ),
        ]
      ],
    );
  }
}
