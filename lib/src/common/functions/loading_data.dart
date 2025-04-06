import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/providers/salesman_info_provider.dart';
import 'package:tablets/src/features/home/controller/last_access_provider.dart';
import 'package:tablets/src/features/login/repository/accounts_repository.dart';
import 'package:tablets/src/features/transactions/controllers/customer_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/products_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/repository/customer_repository_provider.dart';
import 'package:tablets/src/features/transactions/repository/products_repository_provider.dart';
import 'package:tablets/src/features/transactions/repository/transactions_repository_provider.dart';

Future<void> setCustomersProvider(WidgetRef ref) async {
  final salesmanInfoNotifier = ref.read(salesmanInfoProvider.notifier);
  final email = FirebaseAuth.instance.currentUser!.email;
  final repository = ref.read(accountsRepositoryProvider);
  final accounts = await repository.fetchItemListAsMaps();
  var matchingAccounts = accounts.where((account) => account['email'] == email);
  if (matchingAccounts.isNotEmpty) {
    final dbRef = matchingAccounts.first['dbRef'];
    salesmanInfoNotifier.setDbRef(dbRef);
    final name = matchingAccounts.first['name'];
    salesmanInfoNotifier.setName(name);
  }
  final salesmanDbRef = salesmanInfoNotifier.data.dbRef;
  final customersRepository = ref.read(customerRepositoryProvider);
  final customers = await customersRepository.fetchItemListAsMaps(
      filterKey: 'salesmanDbRef', filterValue: salesmanDbRef);
  final salesmanCustomersDb = ref.read(customerDbCacheProvider.notifier);
  salesmanCustomersDb.set(customers);
}

Future<void> setProductsProvider(WidgetRef ref) async {
  final productsRepository = ref.read(productsRepositoryProvider);
  final products = await productsRepository.fetchItemListAsMaps();
  final dbCache = ref.read(productsDbCacheProvider.notifier);
  dbCache.set(products);
}

// // if customer dbRef is provided, we only load transactions for the customer
// // when we want to calculate product quantity, we need all transactions
// // I separated them, to make it easier to load at begining of the app
// // given the idea that we may need to just calculate the debt of customer
// // not creating new invoice, so in this case we don't need to load all transactions
// Future<void> setTranasctionsProvider(WidgetRef ref, {String? customerDbRef}) async {
//   final transactionRepository = ref.read(transactionRepositoryProvider);
//   final List<Map<String, dynamic>> transactions;
//   if (customerDbRef != null) {
//     transactions = await transactionRepository.fetchItemListAsMaps(
//         filterKey: 'nameDbRef', filterValue: customerDbRef);
//   } else {
//     transactions = await transactionRepository.fetchItemListAsMaps(
//         filterKey: 'nameDbRef', filterValue: customerDbRef);
//   }
//   final transactionsDbCache = ref.read(transactionDbCacheProvider.notifier);
//   transactionsDbCache.set(transactions);
// }

// we keep a copy of transaction data, because it is expensive in loading (about 1000 document)
// which makes loading slow, and cost money in firebase, I update the cache once a day
// loadingFreshData is used for refresh button, which salesman might need if the customer data where updated
// during the day, because in our app, the data is only updated onces a day at the first app access
Future<void> setTranasctionsProvider(WidgetRef ref, {bool loadFreshData = false}) async {
  final transactionsDbCache = ref.read(transactionDbCacheProvider.notifier);
  final lastAccessNotifier = ref.read(lastAccessProvider.notifier);
  final oneDayPassed = lastAccessNotifier.hasOneDayPassed();
  if (transactionsDbCache.data.isEmpty || oneDayPassed || loadFreshData) {
    final transactionRepository = ref.read(transactionRepositoryProvider);
    final transactions = await transactionRepository.fetchItemListAsMaps();
    transactionsDbCache.set(transactions);
    lastAccessNotifier.setLastAccessDate();
  }
}
