import 'package:flutter/foundation.dart';

class StoreInfo {
  const StoreInfo({
    required this.name,
    required this.address,
    required this.phone,
  });

  final String name;
  final String address;
  final String phone;

  StoreInfo copyWith({String? name, String? address, String? phone}) {
    return StoreInfo(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StoreInfo &&
        other.name == name &&
        other.address == address &&
        other.phone == phone;
  }

  @override
  int get hashCode => Object.hash(name, address, phone);
}

class StoreRepository {
  StoreRepository._();

  static final ValueNotifier<StoreInfo> store =
      ValueNotifier<StoreInfo>(const StoreInfo(
    name: 'Nail Art',
    address: 'Jl. Melati No. 12, Jakarta',
    phone: '0812-3456-7890',
  ));

  static StoreInfo get data => store.value;

  static void update(StoreInfo info) => store.value = info;
}