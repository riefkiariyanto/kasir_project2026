class Employee {
  const Employee({required this.id, required this.name, this.phone});

  final String id;
  final String name;
  final String? phone;

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
    );
  }

  Employee copyWith({String? id, String? name, String? phone}) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }
}
