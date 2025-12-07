import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_repository.dart';

final customerScreenDataRepositoryProvider =
    Provider<DbRepository>((ref) => DbRepository('customer_screen_data'));
