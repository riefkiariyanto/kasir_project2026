import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_2026/core/constants/app_strings.dart';
import 'package:kasir_2026/core/theme/app_theme.dart';
import 'package:kasir_2026/features/admin/presentation/pages/admin_employees_page.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(theme: AppTheme.light, home: child);
  }

  testWidgets('menampilkan daftar pegawai awal', (tester) async {
    await tester.pumpWidget(wrap(const AdminEmployeesPage()));

    expect(find.text('Siti Aminah'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
  });

  testWidgets('tambah pegawai baru muncul di daftar', (tester) async {
    await tester.pumpWidget(wrap(const AdminEmployeesPage()));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.employeeAddTitle), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.employeeNameLabel),
      'Dewi Lestari',
    );
    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.employeePinLabel),
      '111222',
    );
    await tester.tap(find.text(AppStrings.employeeSave));
    await tester.pumpAndSettle();

    expect(find.text('Dewi Lestari'), findsOneWidget);
  });

  testWidgets('PIN yang sudah dipakai pegawai lain ditolak', (tester) async {
    await tester.pumpWidget(wrap(const AdminEmployeesPage()));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.employeeNameLabel),
      'Pegawai Baru',
    );
    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.employeePinLabel),
      '123456',
    );
    await tester.tap(find.text(AppStrings.employeeSave));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.employeePinDuplicate), findsOneWidget);
    expect(find.text(AppStrings.employeeAddTitle), findsOneWidget);
  });

  testWidgets('hapus pegawai dari daftar', (tester) async {
    await tester.pumpWidget(wrap(const AdminEmployeesPage()));

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.employeeDeleteTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.employeeDelete));
    await tester.pumpAndSettle();

    expect(find.text('Siti Aminah'), findsNothing);
  });
}
