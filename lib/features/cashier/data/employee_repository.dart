import 'employee.dart';

class EmployeeRepository {
  const EmployeeRepository();

  static const int pinLength = 6;

  static final List<Employee> _employees = <Employee>[
    const Employee(
      id: 'e1',
      name: 'Siti Aminah',
      pin: '123456',
      phone: '081234567890',
    ),
    const Employee(
      id: 'e2',
      name: 'Budi Santoso',
      pin: '654321',
      phone: '081298765432',
    ),
  ];

  List<Employee> fetchAll() => List<Employee>.from(_employees);

  Employee? findByPin(String pin) {
    for (final Employee employee in _employees) {
      if (employee.pin == pin) {
        return employee;
      }
    }
    return null;
  }

  void add(Employee employee) {
    _employees.add(employee);
  }

  void update(Employee updatedEmployee) {
    final int index = _employees.indexWhere(
      (Employee e) => e.id == updatedEmployee.id,
    );
    if (index != -1) {
      _employees[index] = updatedEmployee;
    }
  }

  void delete(String id) {
    _employees.removeWhere((Employee e) => e.id == id);
  }
}
