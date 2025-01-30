import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/common/forms/drop_down_with_search.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/features/transactions/common/common_functions.dart';
import 'package:tablets/src/features/transactions/common/customer_debt_info.dart';
import 'package:tablets/src/features/transactions/controllers/cart_provider.dart';
import 'package:tablets/src/features/transactions/controllers/customer_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_data_container.dart';
import 'package:tablets/src/features/transactions/common/common_widgets.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

class InvoiceForm extends ConsumerStatefulWidget {
  const InvoiceForm({super.key});

  @override
  ConsumerState<InvoiceForm> createState() => _ReceiptFormState();
}

class _ReceiptFormState extends ConsumerState<InvoiceForm> {
  num? totalDebt;
  num? dueDebt;
  dynamic latestReceiptDate;
  dynamic latestInvoiceDate;
  bool isValidUser = true;

  @override
  Widget build(BuildContext context) {
    final formDataNotifier = ref.read(formDataContainerProvider.notifier);
    ref.watch(formDataContainerProvider);
    Color infoBgColor = isValidUser ? itemsColor : Colors.red;

    return MainFrame(
      child: Center(
        child: SingleChildScrollView(
          // Wrap the Column with SingleChildScrollView
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            width: 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VerticalGap.xl,
                buildScreenTitle(context, 'قائمة بيع'),
                VerticalGap.xl,
                _buildNameSelection(context, formDataNotifier),
                VerticalGap.xl,

                // _buildDate(context, formDataNotifier),
                // VerticalGap.xl,
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
                VerticalGap.xl,
                _buildButtons(context, formDataNotifier),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameSelection(BuildContext context, MapStateNotifier formDataNotifier) {
    final salesmanCustomersDb = ref.read(salesmanCustomerDbCacheProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FormFieldLabel('الزبون'),
        HorizontalGap.l,
        Expanded(
          child: DropDownWithSearch(
            initialValue: formDataNotifier.data['name'],
            onChangedFn: (customer) {
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
      ],
    );
  }

  // Widget _buildDate(BuildContext context, MapStateNotifier formDataNotifier) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       const FormFieldLabel('التاريخ'),
  //       HorizontalGap.l,
  //       Expanded(
  //         child: FormDatePickerField(
  //           initialValue: formDataNotifier.data['date'],
  //           onChangedFn: (date) {
  //             formDataNotifier.addProperty('date', date);
  //           },
  //           name: 'date',
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildButtons(BuildContext context, MapStateNotifier formDataNotifier) {
    final cartNotifier = ref.read(cartProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const AddItem(),
            onPressed: () {
              if (formDataNotifier.data.containsKey('name') &
                  // formDataNotifier.data.containsKey('date') &

                  formDataNotifier.data.containsKey('nameDbRef')) {
                cartNotifier.reset();
                GoRouter.of(context).pushNamed(AppRoute.items.name);
              } else {
                failureUserMessage(context, 'يرجى اختيار اسم الزبون');
              }
            },
          ),
        ],
      ),
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
}
