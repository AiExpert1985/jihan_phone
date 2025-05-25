// lib/src/features/home/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
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
  // initState is no longer needed here for its previous content if
  // homeScreenController.initialize() was only for loadSalesmanInfo
  // and that's now in the HomeScreenNotifier constructor.
  // If initialize() had other purposes, ensure they are covered.

  @override
  Widget build(BuildContext context) {
    final homeScreenState = ref.watch(homeScreenStateController);
    // Watching transactionDbCacheProvider might be for other parts of the screen or legacy.
    // If only used for debt calculation that's now reactive, this specific watch here might be less critical.
    ref.watch(transactionDbCacheProvider);

    return MainFrame(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround, // Or MainAxisAlignment.start for less stretching
        children: [
          _buildNameSelection(context),
          // Use a more reliable check from the controller if a customer is fully processed
          if (ref.read(homeScreenStateController.notifier).customerIsSelected() &&
              !homeScreenState.isLoadingDebt) ...[
            _buildDebtInfo(homeScreenState),
            _buildSelectionButtons(context),
          ] else if (homeScreenState.isLoadingDebt) ...[
            // Show loading for debt area if customer is selected but debt is loading
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 50.0),
              child: Center(child: CircularProgressIndicator()),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildDebtInfo(HomeScreenState uiState) {
    if (uiState.isLoadingDebt) {
      // This check is now also in the main build logic
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 50.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (uiState.debtError != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
            child: Text('خطأ في تحميل معلومات الدين: ${uiState.debtError}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16))),
      );
    }

    LinearGradient infoBgColorGradient = uiState.isValidUser
        ? itemColorGradient
        : const LinearGradient(
            colors: [Color.fromARGB(255, 243, 80, 68), Color.fromARGB(255, 238, 83, 72)]);

    return Column(
      children: [
        if (uiState.totalDebt != null)
          buildTotalAmount(context, uiState.dueDebt, 'الدين المستحق',
              bgColorGradient: infoBgColorGradient, fontColor: Colors.white),
        VerticalGap.l,
        if (uiState.totalDebt != null)
          buildTotalAmount(context, uiState.totalDebt, 'الدين الكلي',
              bgColorGradient: infoBgColorGradient, fontColor: Colors.white),
        VerticalGap.l,
        if (uiState.latestInvoiceDate != null)
          buildTotalAmount(context, uiState.latestInvoiceDate,
              'اخر قائمة', // Works if latestInvoiceDate is DateTime or String
              bgColorGradient: infoBgColorGradient,
              fontColor: Colors.white),
        VerticalGap.l,
        if (uiState.latestReceiptDate != null)
          buildTotalAmount(context, uiState.latestReceiptDate,
              'اخر تسديد', // Works if latestReceiptDate is DateTime or String
              bgColorGradient: infoBgColorGradient,
              fontColor: Colors.white),
      ],
    );
  }

  Widget _buildSelectionButtons(BuildContext context) {
    final formData = ref.read(formDataContainerProvider);
    // Ensure nameDbRef is available before enabling navigation or showing location button
    final String? customerDbRef = formData['nameDbRef'] as String?;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTransactionSelectionButton(context, 'وصل', AppRoute.receipt.name),
        HorizontalGap.xl,
        _buildTransactionSelectionButton(context, 'قائمة', AppRoute.items.name),
        HorizontalGap.xl,
        // Only show LocationButton if a customer with a dbRef is selected
        if (customerDbRef != null && customerDbRef.isNotEmpty) LocationButton(customerDbRef),
      ],
    );
  }

  Widget _buildNameSelection(BuildContext context) {
    final formData = ref.watch(formDataContainerProvider);
    // Use ref.watch to get the notifier to ensure the DropDownWithSearch gets the latest instance
    // if customerDbCacheProvider is ever recomputed.
    final customerDbCacheNotifier = ref.watch(customerDbCacheProvider.notifier);
    final cartItems = ref.watch(cartProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: DropDownWithSearch(
            label: 'الزبون',
            initialValue: formData['name'] as String?,
            onOpenFn: (currentlySelectedItemMap) async {
              // The explicit loadCustomers call was removed when DbCache became stream-backed.
              if (cartItems.isNotEmpty && context.mounted) {
                return await ref
                    .read(homeScreenStateController.notifier)
                    .resetTransactionConfirmation(context);
              }
              return true;
            },
            onChangedFn: (customerMap) {
              ref.read(homeScreenStateController.notifier).selectCustomer(ref, customerMap);
            },
            dbCache: customerDbCacheNotifier, // Pass the watched notifier instance
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionSelectionButton(BuildContext context, String label, String routeName) {
    final formData = ref.watch(formDataContainerProvider);

    return InkWell(
      onTap: () async {
        // Ensure a customer is actually selected with a dbRef
        if (formData.containsKey('nameDbRef') && (formData['nameDbRef'] as String?) != null) {
          final formDataNotifier = ref.read(formDataContainerProvider.notifier);
          final name = formData['name'];
          final nameDbRef = formData['nameDbRef'];
          final sellingPriceType = formData['sellingPriceType'];

          formDataNotifier.reset(); // This clears name, nameDbRef etc.
          ref.read(cartProvider.notifier).reset();

          // Re-add essential customer data for the new transaction
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

// LocationButton and _LocationButtonState code should be here as per your original file.
// (Copy the full LocationButton and _LocationButtonState classes from your previous version of home_screen.dart)
class LocationButton extends ConsumerStatefulWidget {
  const LocationButton(this.customerDbRef, {super.key});
  final String customerDbRef;

  @override
  ConsumerState<LocationButton> createState() => _LocationButtonState();
}

class _LocationButtonState extends ConsumerState<LocationButton> {
  bool _isOnCooldown = false;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _isOnCooldown = true;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _isOnCooldown = false;
        });
      }
    });
  }

  Future<void> _performTapAction() async {
    try {
      String? salesmanDbRef = ref.read(salesmanInfoProvider.notifier).data.dbRef;

      if (salesmanDbRef == null) {
        await ref.read(dataLoadingController.notifier).loadSalesmanInfo();
        salesmanDbRef = ref.read(salesmanInfoProvider).dbRef;
        if (salesmanDbRef == null) {
          if (mounted) {
            failureUserMessage(context, 'لا يمكن تحديد معلومات المندوب');
          }
          return;
        }
      }

      bool isTransactionAllowed = false;
      if (mounted) {
        isTransactionAllowed = await isInsideCustomerZone(context, ref, widget.customerDbRef);
      }

      if (!isTransactionAllowed) {
        if (mounted) {
          failureUserMessage(context, 'انت خارج نطاق الزبون');
        }
        return;
      }

      final bool success = await registerVisit(ref, salesmanDbRef, widget.customerDbRef);

      if (success && mounted) {
        successUserMessage(context, 'تم تسجيل الزيارة');
      } else if (!success && mounted) {
        failureUserMessage(context, 'لم يتم تسجيل الزيارة');
      }
    } catch (e, s) {
      errorPrint("Error during location button tap action: $e Stack: $s");
      if (mounted) {
        failureUserMessage(context, 'حدث خطأ غير متوقع');
      }
    }
  }

  void _handleTap() {
    if (_isOnCooldown) {
      tempPrint("Button on cooldown. Tap ignored.");
      return;
    }
    _startCooldown();
    _performTapAction();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isOnCooldown ? null : _handleTap,
      child: Opacity(
        opacity: _isOnCooldown ? 0.5 : 1.0,
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
      ),
    );
  }
}
