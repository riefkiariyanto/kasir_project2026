import 'package:flutter/foundation.dart';

import 'api_client.dart';

class StoreInfo {
  const StoreInfo({
    required this.name,
    required this.address,
    required this.phone,
  });

  final String name;
  final String address;
  final String phone;

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
    );
  }

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
  const StoreRepository({this.api = const ApiClient()});

  final ApiClient api;

  static final ValueNotifier<StoreInfo> store = ValueNotifier<StoreInfo>(
    const StoreInfo(name: '', address: '', phone: ''),
  );

  static StoreInfo get data => store.value;

  Future<StoreInfo> fetch() async {
    final dynamic data = await api.get('/api/store');
    final StoreInfo info = StoreInfo.fromJson(data as Map<String, dynamic>);
    store.value = info;
    return info;
  }

  Future<void> update(StoreInfo info) async {
    await api.put('/api/store', <String, dynamic>{
      'name': info.name,
      'address': info.address,
      'phone': info.phone,
    });
    store.value = info;
  }
}
