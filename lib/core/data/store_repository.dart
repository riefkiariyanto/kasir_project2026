import 'package:flutter/foundation.dart';

import 'api_client.dart';

class StoreInfo {
  const StoreInfo({
    required this.name,
    required this.address,
    required this.phone,
    this.hasPrintPin = false,
  });

  final String name;
  final String address;
  final String phone;

  /// True when reprinting a receipt asks for the admin's print PIN.
  final bool hasPrintPin;

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      hasPrintPin: json['has_print_pin'] as bool? ?? false,
    );
  }

  StoreInfo copyWith({
    String? name,
    String? address,
    String? phone,
    bool? hasPrintPin,
  }) {
    return StoreInfo(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      hasPrintPin: hasPrintPin ?? this.hasPrintPin,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StoreInfo &&
        other.name == name &&
        other.address == address &&
        other.phone == phone &&
        other.hasPrintPin == hasPrintPin;
  }

  @override
  int get hashCode => Object.hash(name, address, phone, hasPrintPin);
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
    store.value = info.copyWith(hasPrintPin: store.value.hasPrintPin);
  }

  /// Sets the PIN asked for when reprinting a receipt; an empty [pin]
  /// removes it and leaves reprinting unlocked.
  Future<void> setPrintPin(String pin) async {
    final dynamic data = await api.put(
      '/api/store/print-pin',
      <String, dynamic>{'pin': pin},
    );
    final bool has = (data as Map<String, dynamic>)['has_print_pin'] as bool;
    store.value = store.value.copyWith(hasPrintPin: has);
  }

  /// True when [pin] matches, or when no print PIN is set at all.
  Future<bool> verifyPrintPin(String pin) async {
    try {
      await api.post('/api/store/verify-print-pin', <String, dynamic>{
        'pin': pin,
      });
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        return false;
      }
      rethrow;
    }
  }
}
