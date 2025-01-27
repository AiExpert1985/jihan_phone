import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/forms/edit_box.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/features/transactions/common/common_widgets.dart';
import 'package:tablets/src/features/transactions/controllers/cart_provider.dart';
import 'package:tablets/src/features/transactions/model/item.dart';
import 'package:transparent_image/transparent_image.dart';

class AddItem extends ConsumerStatefulWidget {
  const AddItem(this.item, {super.key});
  final CartItem item;

  @override
  // ignore: library_private_types_in_public_api
  _AddItemState createState() => _AddItemState();
}

class _AddItemState extends ConsumerState<AddItem> {
  late CartItem cartItem;

  @override
  void initState() {
    super.initState();
    cartItem = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    return MainFrame(
      includeBottomNavigation: true,
      child: Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTitle(),
            VerticalGap.xl,
            _buildImage(),
            VerticalGap.xl,
            _buildPrice(),
            VerticalGap.l,
            _buildQuantity(),
            VerticalGap.l,
            _buildGift(),
            const Spacer(),
            _buildButtons(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return CachedNetworkImage(
      fit: BoxFit.cover,
      height: 150,
      width: 200,
      imageUrl: cartItem.coverImageUrl,
      progressIndicatorBuilder: (context, url, downloadProgress) => Image.memory(kTransparentImage),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );
  }

  Widget _buildTitle() {
    return Text(
      cartItem.name,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _buildPrice() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FormFieldLabel('السعر'),
        HorizontalGap.xl,
        Expanded(
          child: FormInputField(
            initialValue: doubleToStringWithComma(cartItem.sellingPrice),
            onChangedFn: (value) {
              setState(() {
                cartItem.sellingPrice = value;
                cartItem.totalAmount = value * cartItem.soldQuantity ?? 0;
              });
            },
            dataType: FieldDataType.num,
            name: 'price',
          ),
        ),
      ],
    );
  }

  Widget _buildQuantity() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FormFieldLabel('العدد'),
        HorizontalGap.xl,
        Expanded(
          child: FormInputField(
            initialValue: cartItem.soldQuantity,
            onChangedFn: (value) {
              if (cartItem.stock < value) {
                failureUserMessage(context, 'المخزون اقل من العدد المطلوب');
              }
              setState(() {
                cartItem.soldQuantity = value;
                cartItem.totalAmount = value * cartItem.sellingPrice ?? 0;
              });
            },
            dataType: FieldDataType.num,
            name: 'Quantity',
          ),
        ),
      ],
    );
  }

  Widget _buildGift() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FormFieldLabel('الهدية'),
        HorizontalGap.xl,
        Expanded(
          child: FormInputField(
            initialValue: cartItem.giftQuantity,
            onChangedFn: (value) {
              setState(() {
                cartItem.giftQuantity = value; // Update gift in the map
              });
            },
            dataType: FieldDataType.num,
            name: 'gift',
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.read(cartProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const ApproveIcon(),
            onPressed: () {
              if (_isInValidateQuantity()) {
                failureUserMessage(context, 'المخزون اقل من العدد المطلوب');
                return;
              }
              // all fields must be filled
              if (cartItem.sellingPrice == null ||
                  cartItem.soldQuantity == null ||
                  cartItem.giftQuantity == null) {
                failureUserMessage(context, 'يجب ملئ جميع الحقول');
                return;
              }
              cartItem.totalWeight = cartItem.weight * cartItem.soldQuantity!;
              final giftLoss = cartItem.giftQuantity! * cartItem.buyingPrice;
              final sellingProfit =
                  (cartItem.sellingPrice! - cartItem.buyingPrice) * cartItem.soldQuantity!;
              cartItem.itemTotalProfit = sellingProfit - giftLoss;
              cartItem.salesmanTotalCommission =
                  cartItem.salesmanCommission * cartItem.soldQuantity!;
              cartNotifier.addItem(cartItem);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  bool _isInValidateQuantity() {
    final requiredQuantity = (cartItem.soldQuantity ?? 0) + (cartItem.giftQuantity ?? 0);
    if (cartItem.stock < requiredQuantity) {
      return true;
    }
    return false;
  }
}
