import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/common/forms/date_picker.dart';
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
  dynamic customerDebt;
  dynamic latestCustomerReceiptDate;
  dynamic latestCustomerInvoiceDate;
  bool isValidUser = true;

  @override
  Widget build(BuildContext context) {
    final formDataNotifier = ref.read(formDataContainerProvider.notifier);
    ref.watch(formDataContainerProvider);
    Color customerInfoBgColor = isValidUser ? itemsColor : Colors.red;

    return MainFrame(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          width: 400,
          child: Column(
            children: [
              VerticalGap.xl,
              buildScreenTitle(context, 'قائمة بيع'),
              VerticalGap.xl,
              _buildNameSelection(context, formDataNotifier),
              VerticalGap.xl,
              _buildDate(context, formDataNotifier),
              VerticalGap.xl,
              if (customerDebt != null)
                buildTotalAmount(context, customerDebt, 'الدين الكلي',
                    bgColor: customerInfoBgColor),
              VerticalGap.m,
              if (latestCustomerReceiptDate != null)
                buildTotalAmount(context, latestCustomerInvoiceDate, 'اخر قائمة',
                    bgColor: customerInfoBgColor),
              VerticalGap.m,
              if (latestCustomerInvoiceDate != null)
                buildTotalAmount(context, latestCustomerReceiptDate, 'اخر تسديد',
                    bgColor: customerInfoBgColor),
              VerticalGap.xl,
              _buildButtons(context, formDataNotifier),
            ],
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
              formDataNotifier.addProperty('name', customer['name']);
              formDataNotifier.addProperty('nameDbRef', customer['dbRef']);
              formDataNotifier.addProperty('sellingPriceType', customer['sellingPriceType']);
              final customerDebtInfo = getCustomerDbetInfo(ref, customer['dbRef']);
              // set customer debt info
              customerDebt = customerDebtInfo['totalDebt'];
              latestCustomerReceiptDate = customerDebtInfo['lastReceiptDate'];
              latestCustomerInvoiceDate = customerDebtInfo['latestInvoiceDate'];
              _validateCustomer(customer['paymentDurationLimit'], customer['creditLimit']);
            },
            dbCache: salesmanCustomersDb,
          ),
        ),
      ],
    );
  }

  Widget _buildDate(BuildContext context, MapStateNotifier formDataNotifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FormFieldLabel('التاريخ'),
        HorizontalGap.l,
        Expanded(
          child: FormDatePickerField(
            initialValue: formDataNotifier.data['date'],
            onChangedFn: (date) {
              formDataNotifier.addProperty('date', date);
            },
            name: 'date',
          ),
        ),
      ],
    );
  }

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
              if (formDataNotifier.data.containsKey('date') &
                  formDataNotifier.data.containsKey('name') &
                  formDataNotifier.data.containsKey('nameDbRef')) {
                cartNotifier.reset();
                GoRouter.of(context).pushNamed(AppRoute.items.name);
              } else {
                failureUserMessage(context, 'يرجى ملئ جميع الحقول بصورة صحيحة');
              }
            },
          ),
        ],
      ),
    );
  }

// customer is invalid, if he has debt, and exceeded max number of days (debt limit)
  void _validateCustomer(num paymentDurationLimit, num creditLimit) {
    // if customer has zero debt, then he is a valid suer
    if (customerDebt <= 0) {
      isValidUser = true;
      return;
    }
    if (customerDebt >= creditLimit) {
      isValidUser = false;
      failureUserMessage(context, 'زبون متجاوز لحدود الدين');
      return;
    }
    // if last invoice date exceeds the paymentDurationLimit, the the customer considered invalid
    Duration difference = DateTime.now().difference(latestCustomerInvoiceDate);
    if (difference.inDays >= paymentDurationLimit) {
      isValidUser = false;
      failureUserMessage(context, 'زبون تجاوز مدة التسديد المسموحة');
      return;
    }
  }
}
