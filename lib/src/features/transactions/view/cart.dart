import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/common/forms/edit_box.dart';
import 'package:tablets/src/common/functions/dialog_delete_confirmation.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/providers/data_loading_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/circle.dart';
import 'package:tablets/src/common/widgets/cool_down_button.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/common/providers/salesman_info_provider.dart';
import 'package:tablets/src/common/widgets/common_transaction_widgets.dart';
import 'package:tablets/src/features/gps_location/controllers/location_functions.dart';
import 'package:tablets/src/features/transactions/controllers/cart_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_data_container.dart';
import 'package:tablets/src/features/transactions/controllers/pending_transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/products_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/model/item.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/features/transactions/repository/pending_transaction_repository_provider.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

class ShoppingCart extends ConsumerWidget {
  const ShoppingCart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(cartProvider);
    ref.watch(formDataContainerProvider);
    final cartItems = ref.watch(cartProvider);
    final formData = ref.watch(formDataContainerProvider);
    double totalAmount = 0;
    double totalCommission = 0;
    double totalProfit = 0;
    double totalWeight = 0;
    for (var item in cartItems) {
      totalAmount += item.totalAmount ?? 0;
      totalCommission += item.salesmanTotalCommission ?? 0;
      totalProfit += item.itemTotalProfit ?? 0;
      totalWeight += item.totalWeight ?? 0;
    }
    return MainFrame(
      includeBottomNavigation: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: cartItems.isEmpty
            ? [
                VerticalGap.xl,
                _buildTransactionInfo(context, formData),
                SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: Image.asset('assets/images/empty.png', fit: BoxFit.scaleDown),
                ),
                VerticalGap.xl,
                _buildButtons(context, ref, totalAmount, totalProfit, totalCommission, totalWeight)
              ]
            : [
                _buildTransactionInfo(context, formData),
                VerticalGap.l,
                Expanded(
                  child: ListView(
                    shrinkWrap: true, // This allows the ListView to take only the space it needs
                    children: _buildItemList(context, ref, cartItems),
                  ),
                ),
                VerticalGap.l,
                buildTotalAmount(context, totalAmount, 'المجموع'),
                if (formData['isEditable']) ...[
                  VerticalGap.l,
                  _buildButtons(
                      context, ref, totalAmount, totalProfit, totalCommission, totalWeight),
                ]
              ],
      ),
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

  List<Widget> _buildItemList(BuildContext context, WidgetRef ref, List<CartItem> cartItems) {
    final formDataNotifier = ref.read(formDataContainerProvider.notifier);
    List<Widget> items = [];
    for (int i = 0; i < cartItems.length; i++) {
      items.add(_buildItemCard(context, ref, i, cartItems[i]));
      items.add(VerticalGap.m);
    }
    items.add(VerticalGap.m);
    items.add(_buildNotes(context, formDataNotifier));
    return items;
  }

  Widget _buildButtons(BuildContext context, WidgetRef ref, double totalAmount, double totalProfit,
      double totalCommission, double totalWeight) {
    final cartItems = ref.watch(cartProvider);
    final formData = ref.watch(formDataContainerProvider);
    final salesmanInfo = ref.watch(salesmanInfoProvider);
    return Container(
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
              icon: const AddItem(),
              onPressed: () {
                final productDbCache = ref.read(productsDbCacheProvider.notifier);
                if (formData.isEmpty) {
                  GoRouter.of(context).goNamed(AppRoute.home.name);
                } else {
                  GoRouter.of(context).goNamed(AppRoute.items.name);
                }
                if (productDbCache.data.isEmpty) {
                  ref.read(dataLoadingController.notifier).loadProducts();
                }
              }),
          if (cartItems.isNotEmpty &&
              formData.isNotEmpty &&
              salesmanInfo.name != null &&
              salesmanInfo.dbRef != null)
// Make sure to import the file where CooldownWrapperIconButton is defined.

            CooldownWrapperIconButton(
              icon: const SaveInvoice(), // Your existing icon widget
              onPressed: () async {
                // Your existing onPressed async function
                final transaction =
                    _createTransaction(ref, totalAmount, totalCommission, totalProfit, totalWeight);
                final pendingTransactions =
                    await ref.read(pendingTransactionRepositoryProvider).fetchItemListAsMaps();
                ref.read(pendingTransactionsDbCache.notifier).set(pendingTransactions);
                // if pending exists update it, otherwise add new
                if (formData['dbRef'] != null &&
                    ref
                        .read(pendingTransactionsDbCache.notifier)
                        .getItemByDbRef(formData['dbRef'])
                        .isNotEmpty) {
                  await ref.read(pendingTransactionRepositoryProvider).updateItem(transaction);
                  if (context.mounted) {
                    successUserMessage(context, 'تم تعديل القائمة بنجاح');
                  }
                } else {
                  await ref.read(pendingTransactionRepositoryProvider).addItem(transaction);
                  if (context.mounted) {
                    successUserMessage(context, 'تم اضافة القائمة بنجاح');
                  }
                }

                bool insideCustomerZone = false;
                if (context.mounted) {
                  insideCustomerZone =
                      await isInsideCustomerZone(context, ref, formData['nameDbRef']);
                }

                registerVisit(ref, salesmanInfo.dbRef!, formData['nameDbRef'],
                    isInvoice: true, insideCustomerZone: insideCustomerZone);

                // after adding the transaction, we reset data and go to main menu
                ref.read(formDataContainerProvider.notifier).reset();
                ref.read(cartProvider.notifier).reset();
                if (context.mounted) {
                  GoRouter.of(context).goNamed(AppRoute.home.name);
                }
              },
              // cooldownDuration: const Duration(seconds: 10), // This is the default, you can omit or change it
            ),
          if (cartItems.isNotEmpty && formData.isNotEmpty)
            IconButton(
              onPressed: () async {
                final transaction =
                    _createTransaction(ref, totalAmount, totalCommission, totalProfit, totalWeight);
                final userConfiramtion = await showUserConfirmationDialog(
                    context: context, messagePart1: '', messagePart2: 'هل ترغب بحذف القائمة');
                if (userConfiramtion == null) {
                  // user didn't confirm
                  return;
                }
                if (formData['dbRef'] != null) {
                  ref.read(pendingTransactionRepositoryProvider).deleteItem(transaction);
                }
                if (context.mounted) {
                  failureUserMessage(context, 'تم حذف القائمة');
                  GoRouter.of(context).goNamed(AppRoute.home.name);
                }
                // after deleting the transaction, we reset data and go to main menu
                ref.read(formDataContainerProvider.notifier).reset();
                ref.read(cartProvider.notifier).reset();
              },
              icon: const DeleteIcon(),
            )
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getItemsList(List<CartItem> cartItems) {
    List<Map<String, dynamic>> itemsList = [];
    for (var i = 0; i < cartItems.length; i++) {
      itemsList.add({
        'buyingPrice': cartItems[i].buyingPrice,
        'code': cartItems[i].code,
        'dbRef': cartItems[i].productDbRef,
        'giftQuantity': cartItems[i].giftQuantity,
        'imageUrls': cartItems[i].imageUrls,
        'itemTotalAmount': cartItems[i].totalAmount,
        'itemTotalProfit': cartItems[i].itemTotalProfit,
        'itemTotalWeight': cartItems[i].totalWeight,
        'name': cartItems[i].name,
        'salesmanCommission': cartItems[i].salesmanCommission,
        'salesmanTotalCommission': cartItems[i].salesmanTotalCommission,
        'sellingPrice': cartItems[i].sellingPrice,
        'soldQuantity': cartItems[i].soldQuantity,
        'weight': cartItems[i].weight,
      });
    }
    return itemsList;
  }

  Widget _buildTransactionInfo(BuildContext context, Map<String, dynamic> formData) {
    return InkWell(
      onTap: () => GoRouter.of(context).goNamed(AppRoute.home.name),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (formData['name'] != null)
              Text(
                formData['name'],
                style: const TextStyle(
                  fontSize: 20,
                  // fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, WidgetRef ref, int sequence, CartItem cartItem) {
    final cartNotifier = ref.read(cartProvider.notifier);
    return Dismissible(
      key: Key(generateRandomString(len: 4)), // Use a unique key for each item
      background: Container(
        color: Colors.red, // Background color when swiping
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        cartNotifier.removeItem(sequence); // Call the method to remove the item
        successUserMessage(context, 'تم ازالة ${cartItem.name}');
      },
      child: Center(
        child: InkWell(
          onTap: () {
            GoRouter.of(context).pushNamed(AppRoute.add.name, extra: cartItem);
          },
          child: Container(
            padding: const EdgeInsets.all(10.0),
            decoration: const BoxDecoration(
                gradient: itemColorGradient, borderRadius: BorderRadius.all(Radius.circular(6))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CircledContainer(child: Text((sequence + 1).toString())),
                    Expanded(
                      child: Text(
                        cartItem.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17, color: Colors.yellow),
                        overflow: TextOverflow.visible, // Optional: Control overflow behavior
                      ),
                    ),
                  ],
                ),
                VerticalGap.s,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCell('السعر', cartItem.sellingPrice!),
                    _buildCell('العدد', cartItem.soldQuantity!),
                    _buildCell('الهدية', cartItem.giftQuantity!),
                    _buildCell('المبلغ الكلي', cartItem.totalAmount!),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String columnName, double columnValue) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(columnName, style: const TextStyle(color: Colors.white, fontSize: 15)),
        VerticalGap.s,
        Text(doubleToStringWithComma(columnValue),
            style: const TextStyle(color: Colors.white, fontSize: 15))
      ],
    );
  }

  Transaction _createTransaction(WidgetRef ref, double totalAmount, double totalCommission,
      double totalProfit, double totalWeight) {
    final cartItems = ref.watch(cartProvider);
    final salesmanInfo = ref.watch(salesmanInfoProvider);
    final formData = ref.read(formDataContainerProvider);
    final dbRef = formData['dbRef'] ?? generateRandomString(len: 8);
    return Transaction(
      dbRef: dbRef,
      name: formData['name'],
      imageUrls: [defaultImageUrl],
      number: 0,
      date: DateTime.now(),
      currency: 'دينار',
      transactionType: TransactionType.customerInvoice.name,
      subTotalAmount: totalAmount,
      totalAmount: totalAmount,
      itemsTotalProfit: totalProfit,
      transactionTotalProfit: totalProfit,
      salesmanTransactionComssion: totalCommission,
      discount: 0,
      items: _getItemsList(cartItems),
      paymentType: 'اجل',
      totalWeight: totalWeight,
      nameDbRef: formData['nameDbRef'],
      salesman: salesmanInfo.name,
      salesmanDbRef: salesmanInfo.dbRef,
      sellingPriceType: formData['sellingPriceType'],
      isPrinted: false,
      notes: formData['notes'] ?? '',
    );
  }
}
