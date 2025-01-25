import 'package:tablets/src/common/values/constants.dart';

class CartItem {
  int code;
  String name;
  String dbRef;
  String productDbRef;
  double weight;
  List<String> imageUrls;
  double buyingPrice;
  double salesmanCommission;
  double? sellingPrice;
  double? soldQuantity;
  double? giftQuantity;
  double? totalAmount;
  double? totalWeight;
  double? itemTotalProfit;
  double? salesmanTotalCommission;

  // Constructor
  CartItem({
    required this.code,
    required this.name,
    required this.dbRef,
    required this.productDbRef,
    required this.weight,
    required this.imageUrls,
    required this.buyingPrice,
    required this.salesmanCommission,
    this.sellingPrice,
    this.soldQuantity,
    this.giftQuantity,
    this.totalAmount,
    this.totalWeight,
    this.itemTotalProfit,
    this.salesmanTotalCommission,
  });

  String get coverImageUrl => imageUrls[imageUrls.length - 1];

  // Method to convert CartItem to a Map (for serialization)
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'dbRef': dbRef,
      'productDbRef': productDbRef,
      'weight': weight,
      'imageUrls': imageUrls,
      'buyingPrice': buyingPrice,
      'salesmanCommission': salesmanCommission,
      'sellingPrice': sellingPrice,
      'soldQuantity': soldQuantity,
      'giftQuantity': giftQuantity,
      'totalAmount': totalAmount,
      'totalWeigt': totalWeight,
      'itemTotalProfit': itemTotalProfit,
      'salesmanTotalProfit': salesmanTotalCommission,
    };
  }

  // Factory constructor to create a CartItem from a Map (for deserialization)
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      code: map['code'] ?? 0,
      name: map['name'] ?? 'unnamed',
      dbRef: map['dbRef'] ?? 'xxxx',
      productDbRef: map['productDbRef'] ?? 'yyyy',
      weight: map['weight'] ?? 0,
      imageUrls: map['imageUrls'] ?? [defaultImageUrl],
      buyingPrice: map['buyingPrice'] ?? 0,
      salesmanCommission: map['salesmanCommission'] ?? 0,
      sellingPrice: map['sellingPrice'],
      soldQuantity: map['soldQuantity'],
      giftQuantity: map['giftQuantity'],
      totalAmount: map['totalAmount'],
      totalWeight: map['totalWeigt'],
      itemTotalProfit: map['itemTotalProfit'],
      salesmanTotalCommission: map['salesmanTotalProfit'],
    );
  }
}
