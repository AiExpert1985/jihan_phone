import 'package:flutter_riverpod/flutter_riverpod.dart';

class SalesmanInfoNotifier extends StateNotifier<SalesmanInfo> {
  SalesmanInfoNotifier()
      : super(SalesmanInfo(
            null, null, null, null)); // Initialize with null or a default SalesmanInfo instance

  void setDbRef(String value) {
    state = SalesmanInfo(state.name, value, state.email, state.privilage);
  }

  void setName(String value) {
    state = SalesmanInfo(value, state.dbRef, state.email, state.privilage);
  }

  void setEmail(String value) {
    state = SalesmanInfo(state.name, state.dbRef, value, state.privilage);
  }

  void setPrivilage(String value) {
    state = SalesmanInfo(state.name, state.dbRef, state.email, value);
  }

  SalesmanInfo get salesmanInfo => state;

  SalesmanInfo get data => state;
}

// Create a provider for the SalesmanInfoNotifier
final salesmanInfoProvider = StateNotifierProvider<SalesmanInfoNotifier, SalesmanInfo>((ref) {
  return SalesmanInfoNotifier();
});

class SalesmanInfo {
  SalesmanInfo(this.name, this.dbRef, this.email, this.privilage);

  String? name;
  String? dbRef;
  String? email;
  String? privilage;
}
