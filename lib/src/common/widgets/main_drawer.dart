import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/common/functions/dialog_delete_confirmation.dart';
import 'package:tablets/src/common/providers/data_loading_provider.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/providers/salesman_info_provider.dart';
import 'package:tablets/src/features/transactions/controllers/cart_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_data_container.dart';
import 'package:tablets/src/routers/go_router_provider.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.65,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB76A45),
              Color.fromARGB(255, 248, 231, 223),
            ],
          ),
        ),
        child: Column(
          children: [
            const MainDrawerHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('القوائم'),
                      leading: const Icon(Icons.view_list_outlined),
                      onTap: () async {
                        Navigator.pop(context);
                        ref.read(dataLoadingController.notifier).loadPendingTransactions();
                        GoRouter.of(context).goNamed(AppRoute.pendingInvoices.name);
                      },
                    ),
                    ListTile(
                      title: const Text('الوصولات'),
                      leading: const Icon(Icons.view_list),
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(dataLoadingController.notifier).loadPendingTransactions();
                        GoRouter.of(context).goNamed(AppRoute.pendingReceipts.name);
                      },
                    ),
                    ListTile(
                      title: const Text('مزامنة البيانات'),
                      leading: const Icon(Icons.refresh),
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(dataLoadingController.notifier).loadCustomers(loadFreshData: true);
                        ref.read(dataLoadingController.notifier).loadProducts(loadFreshData: true);
                        ref.read(formDataContainerProvider.notifier).reset();
                        ref.read(cartProvider.notifier).reset();
                      },
                    ),
                    ListTile(
                      title: const Text('حول التطبيق'),
                      leading: const Icon(Icons.info_outline),
                      onTap: () {
                        Navigator.pop(context);
                        GoRouter.of(context).pushNamed(AppRoute.about.name);
                      },
                    ),
                    const Spacer(),
                    ListTile(
                      title: const Text('تسجيل خروج'),
                      leading: const Icon(Icons.logout),
                      onTap: () async {
                        Navigator.pop(context);
                        final confiramtion = await showUserConfirmationDialog(
                            context: context,
                            messagePart1: '',
                            messagePart2: 'هل ترغب بالخروج من البرنامج؟');
                        if (confiramtion != null) {
                          FirebaseAuth.instance.signOut();
                        }
                      },
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class MainDrawerHeader extends ConsumerWidget {
  const MainDrawerHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesmanInfo = ref.watch(salesmanInfoProvider);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      child: DrawerHeader(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB76A45), // Replace with your itemsColor
              Color(0xFF573419), // Replace with your bgColor
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              height: 170,
              child: Image.asset('assets/images/logo.png', fit: BoxFit.scaleDown),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('المندوب', style: TextStyle(fontSize: 18, color: Colors.white)),
                HorizontalGap.s,
                Text(salesmanInfo.name ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.white)),
              ],
            ),
            VerticalGap.m,
          ],
        ),
      ),
    );
  }
}
