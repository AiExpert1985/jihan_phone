import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/features/home/controller/last_access_provider.dart';
import 'package:tablets/src/features/home/controller/salesman_info_provider.dart';
import 'package:tablets/src/features/login/repository/accounts_repository.dart';
import 'package:tablets/src/features/transactions/controllers/cart_provider.dart';
import 'package:tablets/src/features/transactions/controllers/customer_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/products_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_data_container.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/repository/customer_repository_provider.dart';
import 'package:tablets/src/features/transactions/repository/products_repository_provider.dart';
import 'package:tablets/src/features/transactions/repository/transactions_repository_provider.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = false; // Loading state

  @override
  Widget build(BuildContext context) {
    return MainFrame(
      includeBottomNavigation: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ButtonContainer('وصل قبض', AppRoute.receipt.name, onLoading: _setLoading),
            const SizedBox(height: 50),
            ButtonContainer('قائمة بيع', AppRoute.invoice.name, onLoading: _setLoading),
            VerticalGap.xxl,
            if (_isLoading) const CircularProgressIndicator()
          ],
        ),
      ),
    );
  }

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading; // Update loading state
    });
  }
}

class ButtonContainer extends ConsumerWidget {
  const ButtonContainer(this.label, this.routeName, {super.key, required this.onLoading});

  final String label;
  final String routeName;
  final Function(bool) onLoading; // Callback to set loading state

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        onLoading(true); // Set loading to true
        await loadData(context, ref);
        final lastAccessNotifier = ref.read(lastAccessProvider.notifier);
        final formDataNotifier = ref.read(formDataContainerProvider.notifier);
        formDataNotifier.reset();
        // when receipt or invoice is pressed, all cart items are deleted
        final cartNotifier = ref.read(cartProvider.notifier);
        cartNotifier.reset();
        // set access date to now
        lastAccessNotifier.setLastAccessDate();
        if (context.mounted) {
          GoRouter.of(context).goNamed(routeName);
        }
        onLoading(false); // Set loading to false after data is loaded
      },
      child: Container(
        width: 250,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          color: itemsColor,
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// unlike products, we set customers ones
Future<void> setSalesmanCustomersProvider(WidgetRef ref) async {
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
  final salesmanDbRef = salesmanInfoNotifier.dbRef;
  final customersRepository = ref.read(customerRepositoryProvider);
  // // directly get only salesman customers, which reduces the number of documents fetched from firestore
  // final salesmanCustomers = await customersRepository.fetchItemListAsMaps(
  //     filterKey: 'salesmanDbRef ', filterValue: salesmanDbRef);
  final customers = await customersRepository.fetchItemListAsMaps();
  final salesmanCustomers = customers.where((customer) {
    return customer['salesmanDbRef'] == salesmanDbRef;
  }).toList();
  final salesmanCustomersDb = ref.read(salesmanCustomerDbCacheProvider.notifier);
  salesmanCustomersDb.set(salesmanCustomers);
}

// with each transaction, we get fresh copy of whole products, and set the filtered products to all
// products, so that they can be filtered later
Future<void> setProductsProvider(WidgetRef ref) async {
  final productsRepository = ref.read(productsRepositoryProvider);
  final products = await productsRepository.fetchItemListAsMaps();
  final dbCache = ref.read(productsDbCacheProvider.notifier);
  dbCache.set(products);
}

Future<void> setTranasctionsProvider(WidgetRef ref) async {
  final transactionRepository = ref.read(transactionRepositoryProvider);
  final transactions = await transactionRepository.fetchItemListAsMaps();
  final transactionsDbCache = ref.read(transactionDbCacheProvider.notifier);
  transactionsDbCache.set(transactions);
}

Future<void> loadData(BuildContext context, WidgetRef ref) async {
  final customerDbCache = ref.read(salesmanCustomerDbCacheProvider.notifier);
  final transactionDbCache = ref.read(transactionDbCacheProvider.notifier);
  final lastAccessNotifier = ref.read(lastAccessProvider.notifier);
  await setProductsProvider(ref);
  // I update customers and transactions once perday for salesman, to avoid firebase expenses of loading
  // the data with each transaction
  final oneDayPassed = lastAccessNotifier.hasOneDayPassed();
  // if (context.mounted) {
  //   if (oneDayPassed) {
  //     successUserMessage(context, 'one day passed');
  //   } else {
  //     failureUserMessage(context, 'nooop');
  //   }
  // }
  if (customerDbCache.data.isEmpty || oneDayPassed) {
    await setSalesmanCustomersProvider(ref);
  }
  if (transactionDbCache.data.isEmpty || oneDayPassed) {
    await setTranasctionsProvider(ref);
  }
}
