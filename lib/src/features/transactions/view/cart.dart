import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/circle.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/features/home/controller/salesman_info_provider.dart';
import 'package:tablets/src/features/transactions/common/common_functions.dart';
import 'package:tablets/src/features/transactions/common/common_widgets.dart';
import 'package:tablets/src/features/transactions/controllers/cart_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_data_container.dart';
import 'package:tablets/src/features/transactions/model/item.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

class ShoppingCart extends ConsumerWidget {
  const ShoppingCart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(cartProvider);
    ref.watch(formDataContainerProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartItems = cartNotifier.data;
    final formDataNotifier = ref.read(formDataContainerProvider.notifier);
    final formData = formDataNotifier.data;
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
      child: Center(
        child: Container(
            padding: const EdgeInsets.all(5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: cartItems.isEmpty
                  ? [
                      _buildTransactionInfo(context, formData),
                      SizedBox(
                        width: double.infinity,
                        height: 250,
                        child: Image.asset('assets/images/empty.png', fit: BoxFit.scaleDown),
                      ),
                      VerticalGap.xl,
                      _buildButtons(
                          context, ref, totalAmount, totalProfit, totalCommission, totalWeight)
                    ]
                  : [
                      _buildTransactionInfo(context, formData),
                      Expanded(
                        child: ListView(
                          shrinkWrap:
                              true, // This allows the ListView to take only the space it needs
                          children: _buildItemList(context, ref, cartItems),
                        ),
                      ),
                      VerticalGap.s,
                      _buildReceiptTotalAmount(context, totalAmount),
                      _buildButtons(
                          context, ref, totalAmount, totalProfit, totalCommission, totalWeight)
                    ],
            )),
      ),
    );
  }

  List<Widget> _buildItemList(BuildContext context, WidgetRef ref, List<CartItem> cartItems) {
    List<Widget> items = [];
    for (int i = 0; i < cartItems.length; i++) {
      items.add(_buildItemCard(context, ref, i, cartItems[i]));
    }
    return items;
  }

  Widget _buildButtons(BuildContext context, WidgetRef ref, double totalAmount, double totalProfit,
      double totalCommission, double totalWeight) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartItems = cartNotifier.data;
    final salesmanInfoNotifier = ref.read(salesmanInfoProvider.notifier);
    final formDataNotifier = ref.read(formDataContainerProvider.notifier);
    final formData = formDataNotifier.data;
    return Container(
      width: 300,
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
              icon: const AddItem(),
              onPressed: () {
                final formDataNotifier = ref.read(formDataContainerProvider.notifier);
                if (formDataNotifier.data.isEmpty) {
                  GoRouter.of(context).goNamed(AppRoute.invoice.name);
                } else {
                  GoRouter.of(context).goNamed(AppRoute.items.name);
                }
              }),
          if (cartItems.isNotEmpty && formData.isNotEmpty)
            IconButton(
              onPressed: () {
                final transaction = Transaction(
                  dbRef: generateRandomString(len: 8),
                  name: formData['name'],
                  imageUrls: [defaultImageUrl],
                  number: 0,
                  date: formData['date'],
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
                  salesman: salesmanInfoNotifier.name,
                  salesmanDbRef: salesmanInfoNotifier.dbRef,
                  sellingPriceType: formData['sellingPriceType'],
                  isPrinted: false,
                );
                addTransactionToDb(ref, transaction);
                // after adding the transaction, we reset data and go to main menu
                formDataNotifier.reset();
                cartNotifier.reset();
                successUserMessage(context, 'تم اضافة القائمة بنجاح');
                GoRouter.of(context).goNamed(AppRoute.home.name);
              },
              icon: const SaveInvoice(),
            ),
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
        'dbRef': cartItems[i].dbRef,
        'giftQuantity': cartItems[i].giftQuantity,
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
      onTap: () => GoRouter.of(context).goNamed(AppRoute.invoice.name),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (formData['name'] != null)
              Text(
                formData['name'],
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            if (formData['date'] != null) VerticalGap.l,
            if (formData['date'] != null)
              Text(
                formatDate(formData['date']),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
          child: Card(
            color: itemsColor,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircledContainer(child: Text((sequence + 1).toString())),
                      Expanded(
                        child: Text(
                          cartItem.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, color: Colors.yellow),
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
      ),
    );
  }

  Widget _buildReceiptTotalAmount(BuildContext context, double transactionTotalAmount) {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: const BoxDecoration(
          color: itemsColor, borderRadius: BorderRadius.all(Radius.circular(6))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        const StyledTotalText('المجموع'),
        StyledTotalText(doubleToStringWithComma(transactionTotalAmount)),
      ]),
    );
  }

  Widget _buildCell(String columnName, double columnValue) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(columnName, style: const TextStyle(color: Colors.white, fontSize: 12)),
        VerticalGap.s,
        Text(doubleToStringWithComma(columnValue),
            style: const TextStyle(color: Colors.white, fontSize: 12))
      ],
    );
  }
}
