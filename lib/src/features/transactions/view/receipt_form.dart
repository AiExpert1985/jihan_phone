import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/forms/drop_down_with_search.dart';
import 'package:tablets/src/common/forms/edit_box.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/features/home/controller/salesman_info_provider.dart';
import 'package:tablets/src/features/transactions/common/common_functions.dart';
import 'package:tablets/src/features/transactions/controllers/customer_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_data_container.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/features/transactions/common/common_widgets.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

class ReceiptForm extends ConsumerStatefulWidget {
  const ReceiptForm({super.key});

  @override
  ConsumerState<ReceiptForm> createState() => _ReceiptFormState();
}

class _ReceiptFormState extends ConsumerState<ReceiptForm> {
  double total = 0.0; // Initialize total to 0

  @override
  Widget build(BuildContext context) {
    final formDataNotifier = ref.read(formDataContainerProvider.notifier);
    ref.watch(formDataContainerProvider);

    return MainFrame(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          width: 400,
          child: SingleChildScrollView(
            // Wrap the Column with SingleChildScrollView
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VerticalGap.l,
                buildScreenTitle(context, 'وصل قبض'),
                VerticalGap.xl,
                _buildNameSelection(context, formDataNotifier),
                // VerticalGap.l,
                // _buildDate(context, formDataNotifier),
                VerticalGap.xl,
                _buildReceiptNumber(context, formDataNotifier),
                VerticalGap.xl,
                _buildReceivedAmount(context, formDataNotifier),
                // VerticalGap.l,
                // _buildDiscountAmount(context, formDataNotifier),
                VerticalGap.xxxl,
                buildTotalAmount(context, total, 'المجموع'),
                VerticalGap.xl,
                _buildButtons(context, formDataNotifier),
                VerticalGap.l,
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
        HorizontalGap.xl,
        Expanded(
          child: DropDownWithSearch(
            onChangedFn: (customer) {
              formDataNotifier.addProperty('name', customer['name']);
              formDataNotifier.addProperty('nameDbRef', customer['dbRef']);
            },
            dbCache: salesmanCustomersDb,
          ),
        ),
      ],
    );
  }

  Widget _buildReceivedAmount(BuildContext context, MapStateNotifier formDataNotifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FormFieldLabel('التسديد'),
        HorizontalGap.xl,
        Expanded(
          child: FormInputField(
            onChangedFn: (value) {
              formDataNotifier.addProperty('subTotalAmount', value);
              final discount = formDataNotifier.data['discount'] ?? 0;
              total = value + discount; // Update total
              formDataNotifier.addProperty('totalAmount', total);
            },
            dataType: FieldDataType.num,
            name: 'subtotal',
          ),
        ),
      ],
    );
  }

  // Widget _buildDiscountAmount(BuildContext context, MapStateNotifier formDataNotifier) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       const FormFieldLabel('الخصم'),
  //       HorizontalGap.xl,
  //       Expanded(
  //         child: FormInputField(
  //           onChangedFn: (value) {
  //             formDataNotifier.addProperty('discount', value);
  //             final subtotal = formDataNotifier.data['subTotalAmount'] ?? 0;
  //             total = value + subtotal; // Update total
  //             formDataNotifier.addProperty('totalAmount', total);
  //           },
  //           dataType: FieldDataType.num,
  //           name: 'discount',
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildReceiptNumber(BuildContext context, MapStateNotifier formDataNotifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FormFieldLabel('رقم الوصل'),
        HorizontalGap.xl,
        Expanded(
          child: FormInputField(
            useThousandSeparator: false,
            onChangedFn: (value) {
              formDataNotifier.addProperty('number', value);
            },
            dataType: FieldDataType.num,
            name: 'number',
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
  //       HorizontalGap.xl,
  //       Expanded(
  //         child: FormDatePickerField(
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const ApproveIcon(),
            onPressed: () {
              final formData = formDataNotifier.data;
              if (!(formData.containsKey('name') &&
                  // formData.containsKey('date') &&
                  formData.containsKey('number') &&
                  formData.containsKey('nameDbRef') &&
                  // formData.containsKey('discount') &&
                  formData.containsKey('totalAmount'))) {
                failureUserMessage(context, 'يرجى ملئ جميع الحقول بصورة صحيحة');
                return;
              }
              _addRequiredProperties(ref, formDataNotifier);
              final transaction = Transaction.fromMap(formDataNotifier.data);
              addTransactionToDb(ref, transaction);
              formDataNotifier.reset();
              GoRouter.of(context).goNamed(AppRoute.home.name);
              successUserMessage(context, 'تم اضافة الوصل بنجاح');
            },
          ),
        ],
      ),
    );
  }

  void _addRequiredProperties(WidgetRef ref, MapStateNotifier formDataNotifier) {
    final salesmanInfoNotifier = ref.read(salesmanInfoProvider.notifier);
    final salesmanDbRef = salesmanInfoNotifier.dbRef;
    final salesmanName = salesmanInfoNotifier.name;
    formDataNotifier.addProperty('dbRef', generateRandomString(len: 8));
    formDataNotifier.addProperty('discount', 0);
    formDataNotifier.addProperty('date', DateTime.now());
    formDataNotifier.addProperty('salesmanDbRef', salesmanDbRef);
    formDataNotifier.addProperty('salesman', salesmanName);
    formDataNotifier.addProperty('imageUrls', [defaultImageUrl]);
    formDataNotifier.addProperty('items', []);
    formDataNotifier.addProperty('paymentType', 'نقدي');
    formDataNotifier.addProperty('currency', 'دينار');
    formDataNotifier.addProperty('transactionTotalProfit', 0);
    formDataNotifier.addProperty('isPrinted', false);
    formDataNotifier.addProperty('transactionType', TransactionType.customerReceipt.name);
    formDataNotifier.addProperty('itemsTotalProfit', 0);
    formDataNotifier.addProperty('salesmanTransactionComssion', 0);
    formDataNotifier.addProperty('transactionType', TransactionType.customerReceipt.name);
  }
}
