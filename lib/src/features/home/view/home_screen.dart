import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/common/functions/loading_data.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/loading_spinner.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/features/transactions/controllers/cart_provider.dart';
import 'package:tablets/src/features/transactions/controllers/customer_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_data_container.dart';
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
  void initState() {
    super.initState();
    final customerDbCache = ref.read(customerDbCacheProvider.notifier);
    if (customerDbCache.data.isEmpty) {
      _setLoading(true); // Set loading to true
      setCustomersProvider(ref);
      _setLoading(false); // Set loading to false after data is loaded
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(formDataContainerProvider);
    ref.watch(customerDbCacheProvider);
    final formDataNotifier = ref.read(formDataContainerProvider.notifier);
    final customerDbCache = ref.read(customerDbCacheProvider.notifier);

    return MainFrame(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          width: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (customerDbCache.data.isNotEmpty) _buildNameSelection(context, formDataNotifier),
              if (!_isLoading && formDataNotifier.data.containsKey('name')) _buildDebtInfo(),
              if (!_isLoading && formDataNotifier.data.containsKey('name'))
                _buildSelectionButtons(),
              if (_isLoading || customerDbCache.data.isEmpty)
                const LoadingSpinner('تحميل بيانات الزبائن')
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
          buildTotalAmount(context, dueDebt, 'الدين المستحق',
              bgColor: infoBgColor, fontColor: Colors.white),
        VerticalGap.l,
        if (totalDebt != null)
          buildTotalAmount(context, totalDebt, 'الدين الكلي',
              bgColor: infoBgColor, fontColor: Colors.white),
        VerticalGap.l,
        if (latestReceiptDate != null)
          buildTotalAmount(context, latestInvoiceDate, 'اخر قائمة',
              bgColor: infoBgColor, fontColor: Colors.white),
        VerticalGap.l,
        if (latestInvoiceDate != null)
          buildTotalAmount(context, latestReceiptDate, 'اخر تسديد',
              bgColor: infoBgColor, fontColor: Colors.white),
      ],
    );
  }

  Widget _buildSelectionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTransactionSelectionButton(context, 'وصل قبض', AppRoute.receipt.name),
        _buildTransactionSelectionButton(context, 'قائمة بيع', AppRoute.items.name),
      ],
    );
  }

  Widget _buildNameSelection(BuildContext context, MapStateNotifier formDataNotifier) {
    final salesmanCustomersDb = ref.read(customerDbCacheProvider.notifier);
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
            onChangedFn: (customer) async {
              // we reset form data because customer has been changed
              formDataNotifier.reset();
              // we also reset cart context
              cartNotifier.reset();
              // now process customer data, and debt data
              num paymentDurationLimit = customer['paymentDurationLimit'];
              formDataNotifier.addProperty('name', customer['name']);
              formDataNotifier.addProperty('nameDbRef', customer['dbRef']);
              formDataNotifier.addProperty('sellingPriceType', customer['sellingPriceType']);
              // load transactions of selected customer, to be used for calculating debt
              _setLoading(true);
              await setTranasctionsProvider(ref);
              _setLoading(false);
              // now calculating debt
              final customerDebtInfo =
                  getCustomerDebtInfo(ref, customer['dbRef'], paymentDurationLimit);
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
        _buildLoadCustomersButton(),
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
      return;
    }
    if (dueDebt! > 0) {
      isValidUser = false;
      return;
    }
  }

  Widget _buildLoadCustomersButton() {
    return IconButton(
        onPressed: () async {
          _setLoading(true); // Set loading to true
          await setCustomersProvider(ref);
          _setLoading(false); // Set loading to false after data is loaded
        },
        icon: const Icon(
          Icons.refresh,
          color: Colors.white,
        ));
  }

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading; // Update loading state
    });
  }

  Widget _buildTransactionSelectionButton(BuildContext context, String label, String routeName) {
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
        width: 140,
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
