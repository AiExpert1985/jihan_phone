import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_repository.dart';

final transactionRepositoryProvider = Provider<DbRepository>((ref) => DbRepository('transactions'));
