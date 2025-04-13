import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/common/functions/dialog_delete_confirmation.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/providers/data_loading_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/forms/edit_box.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/common/providers/salesman_info_provider.dart';
import 'package:tablets/src/common/widgets/screen_title.dart';
import 'package:tablets/src/features/gps_location/controllers/location_functions.dart';
import 'package:tablets/src/features/transactions/controllers/form_data_container.dart';
import 'package:tablets/src/features/transactions/controllers/pending_transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/features/transactions/repository/pending_transaction_repository_provider.dart';
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
      child: SingleChildScrollView(
        child: Column(
          children: [
            buildScreenTitle(context, 'وصل قبض'),
            VerticalGap.xxl,
            _buildName(context, formDataNotifier),
            VerticalGap.xl,
            _buildReceiptNumber(context, formDataNotifier),
            VerticalGap.xl,
            _buildReceivedAmount(context, formDataNotifier),
            VerticalGap.xl,
            _buildNotes(context, formDataNotifier),
            VerticalGap.xxl,
            _buildButtons(context, formDataNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildName(BuildContext context, MapStateNotifier formDataNotifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // const FormFieldLabel('الزبون'),
        // HorizontalGap.m,
        Expanded(
          child: FormInputField(
            label: 'الزبون',
            initialValue: formDataNotifier.data['name'],
            useThousandSeparator: false,
            onChangedFn: (value) {
              formDataNotifier.addProperty('name', value);
            },
            dataType: FieldDataType.text,
            name: 'name',
            isReadOnly: true,
          ),
        ),
      ],
    );
  }

  Widget _buildReceivedAmount(BuildContext context, MapStateNotifier formDataNotifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // const FormFieldLabel('التسديد'),
        // HorizontalGap.m,
        Expanded(
          child: FormInputField(
            label: 'التسديد',
            initialValue: formDataNotifier.data['subTotalAmount'],
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

  Widget _buildReceiptNumber(BuildContext context, MapStateNotifier formDataNotifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // const FormFieldLabel('رقم الوصل'),
        // HorizontalGap.m,
        Expanded(
          child: FormInputField(
            initialValue: formDataNotifier.data['number'],
            label: 'رقم الوصل',
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

  Widget _buildNotes(BuildContext context, MapStateNotifier formDataNotifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // const FormFieldLabel('رقم الوصل'),
        // HorizontalGap.m,
        Expanded(
          child: FormInputField(
            initialValue: formDataNotifier.data['notes'],
            label: 'الملاحظات',
            useThousandSeparator: false,
            onChangedFn: (value) {
              formDataNotifier.addProperty('notes', value);
            },
            dataType: FieldDataType.text,
            name: 'notes',
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, MapStateNotifier formDataNotifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const ApproveIcon(),
            onPressed: () async {
              final formData = formDataNotifier.data;
              final salesmanInfo = ref.watch(salesmanInfoProvider);
              if (!(formData.containsKey('name') &&
                  formData.containsKey('number') &&
                  formData.containsKey('nameDbRef') &&
                  formData.containsKey('totalAmount'))) {
                failureUserMessage(context, 'يرجى ملئ جميع الحقول بصورة صحيحة');
                return;
              }
              if (salesmanInfo.dbRef == null || salesmanInfo.name == null) {
                // this step is to ensure that the salesman name and dbRef will be exists
                // I think it rarely being reached, but I added it as a protection ?? maybe I will remove it in future
                await ref.read(dataLoadingController.notifier).loadSalesmanInfo();
              }
              _addRequiredProperties(ref);
              final transaction = Transaction.fromMap(formDataNotifier.data);
              final pendingTransactions =
                  await ref.read(pendingTransactionRepositoryProvider).fetchItemListAsMaps();
              ref.read(pendingTransactionsDbCache.notifier).set(pendingTransactions);
              // if pending exists update it, otherwise add new
              if (formData['dbRef'] != null &&
                  ref
                      .read(pendingTransactionsDbCache.notifier)
                      .getItemByDbRef(formData['dbRef'])
                      .isNotEmpty) {
                ref.read(pendingTransactionRepositoryProvider).updateItem(transaction);
                if (context.mounted) {
                  successUserMessage(context, 'تم تعديل الوصل بنجاح');
                }
              } else {
                ref.read(pendingTransactionRepositoryProvider).addItem(transaction);
                if (context.mounted) {
                  successUserMessage(context, 'تم اضافة الوصل بنجاح');
                }
              }
              if (context.mounted) {
                // if salesman outside customer zone, register transaction
                bool isTransactionAllowed =
                    await isInsideCustomerZone(context, ref, formData['nameDbRef']);
                if (isTransactionAllowed) {
                  registerVisit(ref, salesmanInfo.dbRef!, formData['nameDbRef'],
                      hasTransaction: true);
                }
              }
              formDataNotifier.reset();
              if (context.mounted) {
                GoRouter.of(context).goNamed(AppRoute.home.name);
              }
            },
          ),
          HorizontalGap.xl,
          IconButton(
            onPressed: () async {
              final userConfiramtion = await showUserConfirmationDialog(
                  context: context, messagePart1: '', messagePart2: 'هل ترغب بحذف القائمة');
              if (userConfiramtion == null) {
                // user didn't confirm
                return;
              }
              if (formDataNotifier.data.containsKey('dbRef')) {
                final transaction = Transaction(
                  dbRef: formDataNotifier.data['dbRef'],
                  name: formDataNotifier.data['name'] ?? '',
                  imageUrls: formDataNotifier.data['imageUrls'] ?? [],
                  number: formDataNotifier.data['number'] ?? 1111111,
                  date: formDataNotifier.data['date'] ?? DateTime.now(),
                  currency: formDataNotifier.data['date'] ?? 'دينار',
                  transactionType: formDataNotifier.data['transactionType'] ??
                      TransactionType.customerReceipt.name,
                  totalAmount: formDataNotifier.data['totalAmount'] ?? 0,
                  transactionTotalProfit: formDataNotifier.data['transactionTotalProfit'] ?? 0,
                  isPrinted: formDataNotifier.data['isPrinted'] ?? false,
                );
                ref.read(pendingTransactionRepositoryProvider).deleteItem(transaction);
              }

              if (context.mounted) {
                failureUserMessage(context, 'تم حذف القائمة');
                GoRouter.of(context).goNamed(AppRoute.home.name);
              }
              // after deleting the transaction, we reset data and go to main menu
              ref.read(formDataContainerProvider.notifier).reset();
            },
            icon: const DeleteIconReceipt(),
          )
        ],
      ),
    );
  }

  void _addRequiredProperties(WidgetRef ref) {
    final salesmanInfo = ref.watch(salesmanInfoProvider);
    final formDataNotifier = ref.read(formDataContainerProvider.notifier);
    if (!formDataNotifier.data.containsKey('dbRef')) {
      formDataNotifier.addProperty('dbRef', generateRandomString(len: 8));
    }
    formDataNotifier.addProperty('discount', 0);
    formDataNotifier.addProperty('date', DateTime.now());
    formDataNotifier.addProperty('salesmanDbRef', salesmanInfo.dbRef);
    formDataNotifier.addProperty('salesman', salesmanInfo.name);
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
    if (formDataNotifier.data['notes'] == null) {
      formDataNotifier.addProperty('notes', '');
    }
  }
}
