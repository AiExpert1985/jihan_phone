import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tablets/src/common/classes/db_repository.dart';
import 'package:tablets/src/common/functions/debug_print.dart';
import 'package:tablets/src/common/functions/dialog_delete_confirmation.dart';
import 'package:tablets/src/common/functions/utils.dart';
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
  const double allowedDistance = 6; // meters allowed to be away form the gps point
  await requestLocationPermission();
  Position position = await Geolocator.getCurrentPosition();

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
      filterKey: 'salesmanDbRef', filterValue: salesmanDbRef);
  if (salesPoints.isEmpty) {
    return null;
  }
  final today = DateTime.now();
  final todaySalesPoints = salesPoints
      .where((item) =>
          item['customerDbRef'] == customerDbRef && isSameDay(item['date'].toDate(), today))
      .toList();
  if (todaySalesPoints.isEmpty) {
    return null;
  }
  return SalesPoint.fromMap(todaySalesPoints.first);
}

Future<bool> registerVisit(WidgetRef ref, String salesmanDbRef, String customerDbRef,
    {bool hasTransaction = false}) async {
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
  salesPoint.isVisited = true;
  if (hasTransaction) {
    salesPoint.hasTransaction = true;
    salesPoint.transactionDate = DateTime.now();
    salesPoint.visitDate ??= salesPoint.transactionDate; // maybe never reached !
  } else {
    salesPoint.visitDate = DateTime.now();
  }

  await taskRepositoryProvider.updateItem(salesPoint);
  return true;
}
