import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/forms/edit_box.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/custom_icons.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/features/transactions/controllers/cart_provider.dart';
import 'package:tablets/src/features/transactions/model/item.dart';

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
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTitle(),
            VerticalGap.xl,
            _buildImageSlider(),
            VerticalGap.xl,
            _buildPrice(),
            VerticalGap.l,
            _buildQuantity(),
            VerticalGap.l,
            _buildGift(),
            VerticalGap.l,
            _buildButtons(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlider() {
    final imageUrls = cartItem.imageUrls;
    // int displayedUrlIndex = imageUrls.isNotEmpty ? imageUrls.length - 1 : 0;
    return CarouselSlider(
      items: imageUrls
          .map(
            (url) => CachedNetworkImage(
              fit: BoxFit.cover,
              height: MediaQuery.of(context).size.height,
              imageUrl: url,
              progressIndicatorBuilder: (context, url, downloadProgress) =>
                  CircularProgressIndicator(value: downloadProgress.progress),
              errorWidget: (context, url, error) {
                errorPrint('Error loading image: $error');
                return const Icon(Icons.error);
              },
            ),
          )
          .toList(),
      options: CarouselOptions(
        // onPageChanged: (index, reason) => displayedUrlIndex = index,
        height: 175,
        autoPlay: true,
        initialPage: imageUrls.isNotEmpty ? imageUrls.length - 1 : 0,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      cartItem.name,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 20,
        // fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPrice() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // const FormFieldLabel('السعر'),
        // HorizontalGap.xl,
        Expanded(
          child: FormInputField(
            label: 'السعر',
            initialValue: doubleToStringWithComma(cartItem.sellingPrice),
            onChangedFn: (value) {
              setState(() {
                cartItem.sellingPrice = value;
                cartItem.totalAmount = value * cartItem.soldQuantity ?? 0;
              });
            },
            isReadOnly: true,
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
        // const FormFieldLabel('العدد'),
        // HorizontalGap.xl,
        Expanded(
          child: FormInputField(
            label: 'العدد',
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
        // const FormFieldLabel('الهدية'),
        // HorizontalGap.xl,
        Expanded(
          child: FormInputField(
            label: 'الهدية',
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const ApproveIcon(),
            onPressed: () {
              if (_isInValidateQuantity()) {
                // failureUserMessage(context, 'المخزون اقل من العدد المطلوب');
                // return;
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
              ref.read(cartProvider.notifier).addItem(cartItem);
              // we pop because we need to return to the previous screen caller, whethe it is the ItemGrid
              // or Cart
              Navigator.of(context).pop();
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
