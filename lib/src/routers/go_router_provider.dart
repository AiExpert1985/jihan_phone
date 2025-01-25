import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/features/home/view/home_screen.dart';
import 'package:tablets/src/features/login/view/login_screen.dart';
import 'package:tablets/src/features/transactions/model/item.dart';
import 'package:tablets/src/features/transactions/view/add_item.dart';
import 'package:tablets/src/features/transactions/view/cart.dart';
import 'package:tablets/src/features/transactions/view/invoice_form.dart';
import 'package:tablets/src/features/transactions/view/items_grid.dart';
import 'package:tablets/src/features/transactions/view/receipt_form.dart';
import 'package:tablets/src/routers/go_router_refresh_stream.dart';

import 'package:tablets/src/routers/not_found_screen.dart';

enum AppRoute { home, login, receipt, invoice, items, add, cart }

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final goRouterProvider = Provider<GoRouter>(
  (ref) {
    final firebaseAuth = ref.watch(firebaseAuthProvider);
    return GoRouter(
      initialLocation: '/login',
      debugLogDiagnostics: true, // print route in the console
      redirect: (context, state) {
        final bool isLoggedIn = firebaseAuth.currentUser != null;
        final String currentLocation = state.uri.path;
        // if user isn't logged in, redirect to login page
        if (!isLoggedIn) {
          return '/login';
        }
        // if user is just logged in, redirect to home page
        if (currentLocation == '/login') {
          return '/home';
        }
        // otherwise, no redirection is needed, user will go as he intended
        return null;
        // i didn't use and redirect to signup, because user can't signup
        // only addmin can create new accounts
      },
      refreshListenable: GoRouterRefreshStream(firebaseAuth.authStateChanges()),
      routes: <GoRoute>[
        GoRoute(
          path: '/home',
          name: AppRoute.home.name,
          builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/login',
          name: AppRoute.login.name,
          builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/receipt',
          name: AppRoute.receipt.name,
          builder: (BuildContext context, GoRouterState state) => const ReceiptForm(),
        ),
        GoRoute(
          path: '/invoice',
          name: AppRoute.invoice.name,
          builder: (BuildContext context, GoRouterState state) => const InvoiceForm(),
        ),
        GoRoute(
          path: '/items',
          name: AppRoute.items.name,
          builder: (BuildContext context, GoRouterState state) => const ItemsGrid(),
        ),
        GoRoute(
          path: '/add',
          name: AppRoute.add.name,
          builder: (BuildContext context, GoRouterState state) {
            final CartItem item = state.extra as CartItem;
            return AddItem(item);
          },
        ),
        GoRoute(
          path: '/cart',
          name: AppRoute.cart.name,
          builder: (BuildContext context, GoRouterState state) => const ShoppingCart(),
        ),
      ],
      errorBuilder: (context, state) => const NotFoundScreen(),
    );
  },
);
