import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tablets/src/common/classes/db_repository.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/dialog_delete_confirmation.dart';
import 'package:tablets/src/features/customers/model/customer.dart';
import 'package:tablets/src/features/gps_location/model/location.dart';
import 'package:tablets/src/features/gps_location/model/salespoint.dart';
import 'package:tablets/src/features/gps_location/repository/tasks_repository_provider.dart';
import 'package:tablets/src/features/transactions/repository/customer_repository_provider.dart';

Future<void> requestLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
}

Future<bool> isInsideCustomerZone(BuildContext context, WidgetRef ref, String customerDbRef) async {
  const double allowedDistance = 70; // meters allowed to be away form the gps point
  await requestLocationPermission();
  //! it is important to add desiredAccuracy (althought it is noted as depricated by IDE)
  //! without it, the distance to customer location was wrongly calculated, and caused issues with salesmen
  // ignore: deprecated_member_use
  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

  final customer = await getCustomer(ref, customerDbRef);

  Location? customerLocation = await getCustomerLocation(customer);

  if (customerLocation == null && context.mounted) {
    // if location is not register, return or register current location if salesman approves it
    final userConfiramtion = await showUserConfirmationDialog(
        context: context,
        messagePart1: '',
        messagePart2: 'موقع الزبون غير مسجل مسبقا, هل انت حاليا في موقع الزبون');
    if (userConfiramtion == null) {
      // user didn't confirm
      return false;
    }

    // add customer location to database
    customer.x = position.latitude;
    customer.y = position.longitude;
    final customerRepo = ref.read(customerRepositoryProvider);
    customerRepo.updateItem(customer);

    // update customerLocation
    customerLocation = Location(x: customer.x!, y: customer.y!);
  }

  double distance = Geolocator.distanceBetween(
      position.latitude, position.longitude, customerLocation!.x, customerLocation.y);
  // if (context.mounted) {
  //   successUserMessage(context, 'distance is $distance');
  // }

  if (distance > allowedDistance) {
    return false;
  }
  return true;
}

Future<Customer> getCustomer(WidgetRef ref, String customerDbRef) async {
  final customerRepo = ref.read(customerRepositoryProvider);
  final customers =
      await customerRepo.fetchItemListAsMaps(filterKey: 'dbRef', filterValue: customerDbRef);
  return Customer.fromMap(customers.first);
}

Future<Location?> getCustomerLocation(Customer customer) async {
  if (customer.x == null || customer.x == 0 || customer.y == null || customer.y == 0) {
    return null;
  }
  return Location(x: customer.x!, y: customer.y!);
}

Future<SalesPoint?> getSalesPoint(
    DbRepository taskRepositoryProvider, String salesmanDbRef, String customerDbRef) async {
  final salesPoints = await taskRepositoryProvider.fetchItemListAsMaps(
      filterKey: 'date', filterValue: DateTime.now());
  tempPrint(salesPoints.length);
  if (salesPoints.isEmpty) {
    return null;
  }
  final todaySalesPoints = salesPoints
      .where((item) =>
          item['customerDbRef'] == customerDbRef && item['salesmanDbRef'] == salesmanDbRef)
      .toList();
  if (todaySalesPoints.isEmpty) {
    return null;
  }
  return SalesPoint.fromMap(todaySalesPoints.first);
}

Future<bool> registerVisit(WidgetRef ref, String salesmanDbRef, String customerDbRef,
    {bool isInvoice = false, bool insideCustomerZone = false}) async {
  final taskRepositoryProvider = ref.read(tasksRepositoryProvider);
  final salesPoint = await getSalesPoint(taskRepositoryProvider, salesmanDbRef, customerDbRef);
  if (salesPoint == null) {
    errorPrint('no task found');
    return false;
  }
  if (salesPoint.x == null || salesPoint.x == 0 || salesPoint.y == null || salesPoint.y == 0) {
    final customer = await getCustomer(ref, customerDbRef);
    salesPoint.x = customer.x;
    salesPoint.y = customer.y;
  }
  final time = DateTime.now();
  await updateTask(ref, salesPoint, isInvoice, time, insideCustomerZone);

  // This code will execute after 2 minutes.
  // It runs independently of the registerVisit function's return value.
  // this function is to register the visit again, as a temp fix for the reported problem of
  // visits not registered even after receiving confirmation user message
  // it is a bad solution, but I wanted a quick fix since I am incapable for finding the root cause of the issue
  Future.delayed(const Duration(seconds: 120), () async {
    try {
      await updateTask(ref, salesPoint, isInvoice, time, insideCustomerZone);
    } catch (e) {
      errorPrint('can not verify registerVisit');
    }
  });
  return true;
}

Future<void> updateTask(WidgetRef ref, SalesPoint salesPoint, bool isInvoice, DateTime time,
    bool insideCustomerZone) async {
  final taskRepositoryProvider = ref.read(tasksRepositoryProvider);
  if (isInvoice) {
    salesPoint.hasTransaction = salesPoint.isVisited || insideCustomerZone;
    salesPoint.transactionDate = time;
    if (insideCustomerZone && !salesPoint.isVisited) {
      salesPoint.isVisited = true;
    }
    if (insideCustomerZone && salesPoint.visitDate == null) {
      salesPoint.visitDate = time;
    }
  } else {
    salesPoint.isVisited = true;
    salesPoint.visitDate = time;
  }

  await taskRepositoryProvider.updateItem(salesPoint);
}
