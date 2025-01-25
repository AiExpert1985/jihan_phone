import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/common/forms/edit_box.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/image_titled.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/features/transactions/controllers/filtered_products_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_data_container.dart';
import 'package:tablets/src/features/transactions/model/item.dart';
import 'package:tablets/src/features/transactions/model/product.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

class ItemsGrid extends ConsumerStatefulWidget {
  const ItemsGrid({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ItemsGridState createState() => _ItemsGridState();
}

class _ItemsGridState extends ConsumerState<ItemsGrid> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Watch the filtered products provider
    final filteredItemsNotifier = ref.read(filteredProductsProvider.notifier);
    List<Map<String, dynamic>> filteredProducts = filteredItemsNotifier.data;

    // Filter products based on the search query
    List<Map<String, dynamic>> displayedProducts = _searchQuery.isEmpty
        ? filteredProducts // Show all products if search query is empty
        : filteredProducts.where((product) {
            return product['name'].toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
    final formDataNotifier = ref.read(formDataContainerProvider.notifier);
    final sellingPriceType = formDataNotifier.data['sellingPriceType'];
    return MainFrame(
      includeBottomNavigation: true,
      child: Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VerticalGap.xl,
            FormInputField(
              onChangedFn: (value) {
                setState(() {
                  _searchQuery = value; // Update the search query
                });
              },
              label: 'بحث',
              dataType: FieldDataType.text,
              name: 'product-name',
            ),
            VerticalGap.xl,
            Expanded(
              child: GridView.builder(
                itemCount: displayedProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.25),
                itemBuilder: (ctx, index) {
                  final product = Product.fromMap(displayedProducts[index]);
                  // price depends on customer
                  final price = sellingPriceType == 'retail'
                      ? product.sellRetailPrice
                      : product.sellWholePrice;
                  return InkWell(
                    onTap: () {
                      final item = CartItem(
                        code: product.code,
                        name: product.name,
                        dbRef: generateRandomString(len: 4),
                        productDbRef: product.dbRef,
                        weight: product.packageWeight,
                        imageUrls: product.imageUrls,
                        buyingPrice: product.buyingPrice,
                        salesmanCommission: product.salesmanCommission,
                        sellingPrice: price,
                        giftQuantity: 0,
                      );
                      GoRouter.of(context).pushNamed(AppRoute.add.name, extra: item);
                    },
                    hoverColor: const Color.fromARGB(255, 173, 170, 170),
                    child: TitledImage(
                        imageUrl: product.coverImageUrl, title: product.name, price: price),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
