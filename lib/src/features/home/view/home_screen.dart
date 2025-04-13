import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/common/functions/user_messages.dart';
import 'package:tablets/src/common/providers/data_loading_provider.dart';
import 'package:tablets/src/common/providers/salesman_info_provider.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:tablets/src/features/gps_location/controllers/location_functions.dart';
import 'package:tablets/src/features/home/controller/home_screen_controller.dart';
import 'package:tablets/src/features/transactions/controllers/cart_provider.dart';
import 'package:tablets/src/features/transactions/controllers/customer_db_cache_provider.dart';
import 'package:tablets/src/features/transactions/controllers/form_data_container.dart';
import 'package:tablets/src/features/transactions/controllers/transaction_db_cache_provider.dart';
import 'package:tablets/src/routers/go_router_provider.dart';
import 'package:tablets/src/common/widgets/common_transaction_widgets.dart';
import 'package:tablets/src/common/forms/drop_down_with_search.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(homeScreenStateController.notifier).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final homeScreenState = ref.watch(homeScreenStateController);
    ref.watch(transactionDbCacheProvider);

    return MainFrame(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNameSelection(context),
          if (ref.read(homeScreenStateController.notifier).customerIsSelected()) ...[
            _buildDebtInfo(homeScreenState),
            _buildSelectionButtons(context),
          ]
        ],
      ),
    );
  }

  Widget _buildDebtInfo(HomeScreenState state) {
    LinearGradient infoBgColorGradient = state.isValidUser
        ? itemColorGradient
        : const LinearGradient(
            colors: [Color.fromARGB(255, 243, 80, 68), Color.fromARGB(255, 238, 83, 72)]);
    return Column(
      children: [
        if (state.totalDebt != null)
          buildTotalAmount(context, state.dueDebt, 'الدين المستحق',
              bgColorGradient: infoBgColorGradient, fontColor: Colors.white),
        VerticalGap.l,
        if (state.totalDebt != null)
          buildTotalAmount(context, state.totalDebt, 'الدين الكلي',
              bgColorGradient: infoBgColorGradient, fontColor: Colors.white),
        VerticalGap.l,
        if (state.latestReceiptDate != null)
          buildTotalAmount(context, state.latestInvoiceDate, 'اخر قائمة',
              bgColorGradient: infoBgColorGradient, fontColor: Colors.white),
        VerticalGap.l,
        if (state.latestInvoiceDate != null)
          buildTotalAmount(context, state.latestReceiptDate, 'اخر تسديد',
              bgColorGradient: infoBgColorGradient, fontColor: Colors.white),
      ],
    );
  }

  Widget _buildSelectionButtons(BuildContext context) {
    final formData = ref.read(formDataContainerProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTransactionSelectionButton(context, 'وصل', AppRoute.receipt.name),
        HorizontalGap.xl,
        _buildTransactionSelectionButton(context, 'قائمة', AppRoute.items.name),
        HorizontalGap.xl,
        LocationButton(formData['nameDbRef']),
      ],
    );
  }

  Widget _buildNameSelection(BuildContext context) {
    final formData = ref.watch(formDataContainerProvider);
    final customerDbCache = ref.watch(customerDbCacheProvider);
    final cartItems = ref.watch(cartProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: DropDownWithSearch(
            label: 'الزبون',
            initialValue: formData['name'],
            onOpenFn: (p0) async {
              if (customerDbCache.isEmpty) {
                await ref.read(dataLoadingController.notifier).loadCustomers();
              }
              if (cartItems.isNotEmpty && context.mounted) {
                return await ref
                    .read(homeScreenStateController.notifier)
                    .resetTransactionConfirmation(context);
              }
              return true;
            },
            onChangedFn: (customer) {
              ref.read(homeScreenStateController.notifier).selectCustomer(ref, customer);
            },
            dbCache: ref.read(customerDbCacheProvider.notifier),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionSelectionButton(BuildContext context, String label, String routeName) {
    final formData = ref.watch(formDataContainerProvider);

    return InkWell(
      onTap: () async {
        if (formData.containsKey('name') && formData.containsKey('nameDbRef')) {
          // before going to new receipt or new invoice we must reset the form and cart
          // maybe we were in home screen after loading previou transaction
          final formDataNotifier = ref.read(formDataContainerProvider.notifier);
          final name = formData['name'];
          final nameDbRef = formData['nameDbRef'];
          final sellingPriceType = formData['sellingPriceType'];
          formDataNotifier.reset();
          ref.read(cartProvider.notifier).reset();

          // now store customer data in the new transaction
          formDataNotifier.addProperty('name', name);
          formDataNotifier.addProperty('nameDbRef', nameDbRef);
          formDataNotifier.addProperty('sellingPriceType', sellingPriceType);
          formDataNotifier.addProperty('isEditable', true);
          if (context.mounted) {
            GoRouter.of(context).pushNamed(routeName);
            if (routeName == AppRoute.items.name) {
              ref.read(dataLoadingController.notifier).loadProducts();
            }
          }
        } else if (context.mounted) {
          failureUserMessage(context, 'يرجى اختيار اسم الزبون');
        }
      },
      child: Container(
        width: 75,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          gradient: itemColorGradient,
        ),
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class LocationButton extends ConsumerWidget {
  const LocationButton(this.customerDbRef, {super.key});
  final String customerDbRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        String? salesmanDbRef = ref.read(salesmanInfoProvider.notifier).data.dbRef;
        if (salesmanDbRef == null) {
          await ref.read(dataLoadingController.notifier).loadSalesmanInfo();
        }
        if (context.mounted) {
          bool isTransactionAllowed = await isInsideCustomerZone(context, ref, customerDbRef);
          if (!isTransactionAllowed && context.mounted) {
            // if out of customer zone, visit is not registered
            failureUserMessage(context, 'انت خارج نطاق الزبون');
            return;
          }
        }

        bool success = await registerVisit(ref, salesmanDbRef!, customerDbRef);
        if (success && context.mounted) {
          successUserMessage(context, 'تم تسجيل الزيارة بنجاح');
        } else if (!success && context.mounted) {
          failureUserMessage(context, 'لم يتم تسجيل الزيارة');
        }
      },
      child: Container(
        width: 75,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          gradient: itemColorGradient,
        ),
        padding: const EdgeInsets.all(12),
        child: const Center(
          child: Text(
            'زيارة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
