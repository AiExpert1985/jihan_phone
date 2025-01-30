import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
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
import 'package:tablets/src/features/transactions/common/common_widgets.dart';
import 'package:tablets/src/common/forms/drop_down_with_search.dart';
import 'package:tablets/src/features/transactions/common/customer_debt_info.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  num? totalDebt;
  num? dueDebt;
  dynamic latestReceiptDate;
  dynamic latestInvoiceDate;
  bool isValidUser = true;
  bool _isLoading = false; // Loading state

  @override
  Widget build(BuildContext context) {
    ref.watch(formDataContainerProvider);
    final formDataNotifier = ref.read(formDataContainerProvider.notifier);

    return MainFrame(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          width: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNameSelection(context, formDataNotifier),
              if (formDataNotifier.data.containsKey('name')) _buildDebtInfo(),
              if (formDataNotifier.data.containsKey('name')) _buildSelectionButtons(),
              if (_isLoading) _buildLoadingIndicator()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebtInfo() {
    Color infoBgColor = isValidUser ? itemsColor : Colors.red;
    return Column(
      children: [
        if (totalDebt != null)
          buildTotalAmount(context, dueDebt, 'الدين المستحق', bgColor: infoBgColor),
        VerticalGap.l,
        if (totalDebt != null)
          buildTotalAmount(context, totalDebt, 'الدين الكلي', bgColor: infoBgColor),
        VerticalGap.l,
        if (latestReceiptDate != null)
          buildTotalAmount(context, latestInvoiceDate, 'اخر قائمة', bgColor: infoBgColor),
        VerticalGap.l,
        if (latestInvoiceDate != null)
          buildTotalAmount(context, latestReceiptDate, 'اخر تسديد', bgColor: infoBgColor),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Column(children: [
      CircularProgressIndicator(),
      VerticalGap.xl,
      Text('مزامنة البيانات', style: TextStyle(color: Colors.white, fontSize: 14))
    ]);
  }

  Widget _buildSelectionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        TransactionSelectionButton('وصل قبض', AppRoute.receipt.name),
        const SizedBox(width: 50),
        TransactionSelectionButton('قائمة بيع', AppRoute.items.name),
      ],
    );
  }

  Widget _buildNameSelection(BuildContext context, MapStateNotifier formDataNotifier) {
    final salesmanCustomersDb = ref.read(salesmanCustomerDbCacheProvider.notifier);
    final formDataNotifier = ref.read(formDataContainerProvider.notifier);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FormFieldLabel('الزبون'),
        HorizontalGap.l,
        Expanded(
          child: DropDownWithSearch(
            initialValue: formDataNotifier.data['name'],
            onChangedFn: (customer) {
              // we reset form data because customer has been changed
              formDataNotifier.reset();
              // we also reset cart context
              cartNotifier.reset();
              // now process customer data, and debt data
              num paymentDurationLimit = customer['paymentDurationLimit'];
              formDataNotifier.addProperty('name', customer['name']);
              formDataNotifier.addProperty('nameDbRef', customer['dbRef']);
              formDataNotifier.addProperty('sellingPriceType', customer['sellingPriceType']);
              final customerDebtInfo =
                  getCustomerDbetInfo(ref, customer['dbRef'], paymentDurationLimit);
              // set customer debt info
              totalDebt = customerDebtInfo['totalDebt'];
              dueDebt = customerDebtInfo['dueDebt'];
              latestReceiptDate = customerDebtInfo['lastReceiptDate'] ?? 'لا يوجد';
              latestInvoiceDate = customerDebtInfo['latestInvoiceDate'] ?? 'لا يوجد';
              _validateCustomer(paymentDurationLimit, customer['creditLimit']);
            },
            dbCache: salesmanCustomersDb,
          ),
        ),
        HorizontalGap.l,
        DataRefreshButton(_setLoading),
      ],
    );
  }

// customer is invalid, if he has debt, and exceeded max number of days (debt limit)
  void _validateCustomer(num paymentDurationLimit, num creditLimit) {
    if (totalDebt == null || dueDebt == null) return;
    // if customer has zero debt, then he is a valid suer
    if (totalDebt! <= 0) {
      isValidUser = true;
      return;
    }
    if (totalDebt! >= creditLimit) {
      isValidUser = false;
      // failureUserMessage(context, 'زبون متجاوز لحدود الدين');
      return;
    }
    if (dueDebt! > 0) {
      isValidUser = false;
      // failureUserMessage(context, 'زبون تجاوز مدة التسديد المسموحة');
      return;
    }
  }

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading; // Update loading state
    });
  }
}

class TransactionSelectionButton extends ConsumerWidget {
  const TransactionSelectionButton(this.label, this.routeName, {super.key});

  final String label;
  final String routeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataNotifier = ref.read(formDataContainerProvider.notifier);

    return InkWell(
      onTap: () async {
        if (formDataNotifier.data.containsKey('name') &
            formDataNotifier.data.containsKey('nameDbRef')) {
          if (context.mounted) {
            GoRouter.of(context).goNamed(routeName);
          }
        } else if (context.mounted) {
          failureUserMessage(context, 'يرجى اختيار اسم الزبون');
        }
      },
      child: Container(
        width: 150,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          color: itemsColor,
        ),
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class DataRefreshButton extends ConsumerWidget {
  const DataRefreshButton(this.onLoading, {super.key});

  final Function(bool) onLoading; // Callback to set loading state

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastAccessNotifier = ref.read(lastAccessProvider.notifier);
    return IconButton(
        onPressed: () async {
          onLoading(true); // Set loading to true
          await loadData(context, ref);
          if (!_isAllDataLoaded(ref)) {
            if (context.mounted) {
              failureUserMessage(context, 'لم يتم مزامنة البيانات بصورة كاملة');
            }
            return;
          }
          // set access date to now
          lastAccessNotifier.setLastAccessDate();
          onLoading(false); // Set loading to false after data is loaded
        },
        icon: const Icon(
          Icons.refresh,
          color: Colors.white,
        ));
  }
}

/// ensure all database (transactions, customers, products) loaded before proceeding
/// if any of the dbCaches is empty, it returns false, otherwise it returns true
bool _isAllDataLoaded(WidgetRef ref) {
  bool isAllDataLoaded = true;
  final transactionsDbCache = ref.read(transactionDbCacheProvider.notifier);
  final productsDbCache = ref.read(productsDbCacheProvider.notifier);
  final customersDbCache = ref.read(salesmanCustomerDbCacheProvider.notifier);
  if (transactionsDbCache.data.isEmpty ||
      productsDbCache.data.isEmpty ||
      customersDbCache.data.isEmpty) {
    isAllDataLoaded = false;
  }
  return isAllDataLoaded;
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
  if (customerDbCache.data.isEmpty || oneDayPassed) {
    await setSalesmanCustomersProvider(ref);
  }
  if (transactionDbCache.data.isEmpty || oneDayPassed) {
    await setTranasctionsProvider(ref);
  }
}
