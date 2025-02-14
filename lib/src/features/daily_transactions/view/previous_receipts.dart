import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/providers/data_loading_provider.dart';
import 'package:tablets/src/common/providers/salesman_info_provider.dart';
import 'package:tablets/src/common/values/constants.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/circle.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/features/transactions/controllers/form_data_container.dart';
import 'package:tablets/src/features/transactions/controllers/pending_transaction_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/model/transaction.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

class PreviousReceipts extends ConsumerWidget {
  const PreviousReceipts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesmanInfo = ref.watch(salesmanInfoProvider);
    final pendingTransactions = ref.watch(pendingTransactionsDbCache);
    final pendingReceipts = pendingTransactions
        .where((trans) =>
            trans['transactionType'] == TransactionType.customerReceipt.name &&
            trans['salesmanDbRef'] == salesmanInfo.dbRef &&
            isSameDay(trans['date'].toDate(), DateTime.now()))
        .toList();
    return MainFrame(
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const Text('الوصولات اليومية', style: TextStyle(color: Colors.white, fontSize: 20)),
              if (pendingReceipts.isEmpty) ...[
                const SizedBox(height: 150),
                SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: Image.asset('assets/images/empty.png', fit: BoxFit.scaleDown),
                ),
              ],
              VerticalGap.xl,
              ..._buildPendingTransactions(context, ref, pendingReceipts),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPendingTransactions(
      BuildContext context, WidgetRef ref, List<Map<String, dynamic>> pendingReceipts) {
    List<Widget> invoiceWidgets = [];
    for (int i = 0; i < pendingReceipts.length; i++) {
      final invoice = Transaction.fromMap(pendingReceipts[i]);
      invoiceWidgets.add(_buildTransactionCard(context, ref, i, invoice, true));
      invoiceWidgets.add(VerticalGap.m);
    }
    return invoiceWidgets;
  }

  Widget _buildTransactionCard(
      BuildContext context, WidgetRef ref, int sequence, Transaction invoice, bool isEditable) {
    return Center(
      child: InkWell(
        onTap: () async {
          await ref.read(dataLoadingController.notifier).loadProducts();
          _loadCart(ref, invoice, isEditable);
          if (context.mounted) {
            GoRouter.of(context).pushNamed(AppRoute.receipt.name);
          }
        },
        child: Container(
          height: 70,
          padding: const EdgeInsets.all(10.0),
          decoration: const BoxDecoration(
              gradient: itemColorGradient, borderRadius: BorderRadius.all(Radius.circular(6))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircledContainer(child: Text((sequence + 1).toString())),
              HorizontalGap.l,
              SizedBox(
                  width: 140,
                  child: Text(invoice.name, style: const TextStyle(color: Colors.white))),
              const Spacer(),
              SizedBox(
                width: 100,
                child: Text(doubleToStringWithComma(invoice.totalAmount),
                    textAlign: TextAlign.end, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadCart(WidgetRef ref, Transaction transaction, bool isEditable) {
    _loadFormData(ref, transaction, isEditable);
  }

  void _loadFormData(WidgetRef ref, Transaction transaction, bool isEditable) {
    final formDataNotifier = ref.read(formDataContainerProvider.notifier);
    formDataNotifier.addProperty('name', transaction.name);
    formDataNotifier.addProperty('nameDbRef', transaction.nameDbRef);
    formDataNotifier.addProperty('dbRef', transaction.dbRef);
    formDataNotifier.addProperty('isEditable', isEditable);
    formDataNotifier.addProperty('subTotalAmount', transaction.subTotalAmount);
    formDataNotifier.addProperty('totalAmount', transaction.totalAmount);
    formDataNotifier.addProperty('number', transaction.number);
    formDataNotifier.addProperty('notes', transaction.notes);
  }
}
