import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/features/transactions/repository/transaction_repository_provider.dart';

void addTransactionToDb(WidgetRef ref, Transaction transaction) {
  final repository = ref.read(transactionRepositoryProvider);
  repository.addItem(transaction);
}
