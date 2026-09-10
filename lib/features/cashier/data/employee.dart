class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.pin,
    this.phone,
  });

  final String id;
  final String name;
  final String pin;
  final String? phone;

  Employee copyWith({String? id, String? name, String? pin, String? phone}) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      pin: pin ?? this.pin,
      phone: phone ?? this.phone,
    );
  }
}
