import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/features/home/controller/salesman_info_provider.dart';
import 'package:tablets/src/features/login/repository/accounts_repository.dart';
import 'package:tablets/src/features/transactions/controllers/cart_provider.dart';
import 'package:tablets/src/features/transactions/controllers/customer_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/filtered_products_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_data_container.dart';
import 'package:tablets/src/features/transactions/repository/customer_repository_provider.dart';
import 'package:tablets/src/features/transactions/repository/products_repository_provider.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MainFrame(
      includeBottomNavigation: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ButtonContainer('وصل قبض', AppRoute.receipt.name),
            const SizedBox(height: 40),
            ButtonContainer('قائمة زبون', AppRoute.invoice.name),
          ],
        ),
      ),
    );
  }
}

class ButtonContainer extends ConsumerWidget {
  const ButtonContainer(this.label, this.routeName, {super.key});

  final String label;
  final String routeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        await setFilteredProductsProvider(ref);
        final customerDbCache = ref.read(salesmanCustomerDbCacheProvider.notifier);
        if (customerDbCache.data.isEmpty) {
          await setSalesmanCustomers(ref);
        }
        final formDataNotifier = ref.read(formDataContainerProvider.notifier);
        formDataNotifier.reset();
        if (context.mounted) {
          GoRouter.of(context).goNamed(routeName);
        }
        // when receipt or invoice is pressed, all cart items are deleted
        final cartNotifier = ref.read(cartProvider.notifier);
        cartNotifier.reset();
      },
      child: Container(
        width: 200,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          color: itemsColor,
        ),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// unlike products, we set customers ones
Future<void> setSalesmanCustomers(WidgetRef ref) async {
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
Future<void> setFilteredProductsProvider(WidgetRef ref) async {
  final productsRepository = ref.read(productsRepositoryProvider);
  final products = await productsRepository.fetchItemListAsMaps();
  final filteredItemsNotifier = ref.read(filteredProductsProvider.notifier);
  filteredItemsNotifier.setItems(products);
}
