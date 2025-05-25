// lib/src/features/transactions/controllers/selected_customer_transaction_stream_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:tablets/src/common/classes/db_repository.dart'; // Not directly needed here
import 'package:tablets/src/features/transactions/repository/transactions_repository_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_data_container.dart';

final selectedCustomerTransactionsStreamProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final formData = ref.watch(formDataContainerProvider);
  final selectedCustomerDbRef = formData['nameDbRef'] as String?;

  if (selectedCustomerDbRef == null || selectedCustomerDbRef.isEmpty) {
    return Stream.value([]);
  }

  final transactionRepo = ref.watch(transactionRepositoryProvider);
  return transactionRepo.watchItemListAsMaps(
      filterKey: 'nameDbRef', filterValue: selectedCustomerDbRef);
});
