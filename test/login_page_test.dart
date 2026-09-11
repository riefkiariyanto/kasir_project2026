import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_2026/app.dart';
import 'package:kasir_2026/core/constants/app_strings.dart';
import 'package:kasir_2026/core/theme/app_colors.dart';
import 'package:kasir_2026/core/widgets/brand_title.dart';
import 'package:kasir_2026/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:kasir_2026/features/auth/presentation/pages/login_page.dart';
import 'package:kasir_2026/features/cashier/presentation/pages/cashier_page.dart';

Future<void> _loginAsPegawai(WidgetTester tester) async {
  await tester.pumpWidget(const KasirApp());
  await tester.tap(find.text(AppStrings.employeeButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('menampilkan form login dan akses pegawai', (tester) async {
    await tester.pumpWidget(const KasirApp());

    expect(find.text(AppStrings.loginSubtitle), findsOneWidget);
    expect(find.text(AppStrings.usernameLabel), findsOneWidget);
    expect(find.text(AppStrings.passwordLabel), findsOneWidget);
    expect(find.text(AppStrings.employeeButton), findsOneWidget);
  });

  testWidgets('kredensial benar membuka dashboard admin', (tester) async {
    await tester.pumpWidget(const KasirApp());

    await tester.enterText(find.byType(TextField).at(0), 'admin');
    await tester.enterText(find.byType(TextField).at(1), 'admin');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.byType(AdminDashboardPage), findsOneWidget);
    expect(find.byType(CashierPage), findsNothing);
    expect(find.text(AppStrings.adminDashboardReport), findsOneWidget);
  });

  testWidgets('kredensial salah menampilkan pesan error', (tester) async {
    await tester.pumpWidget(const KasirApp());

    await tester.enterText(find.byType(TextField).at(0), 'admin');
    await tester.enterText(find.byType(TextField).at(1), 'salah');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text(AppStrings.loginFailed), findsOneWidget);
    expect(find.byType(AdminDashboardPage), findsNothing);
  });

  testWidgets('tombol pegawai membuka beranda kasir', (tester) async {
    await _loginAsPegawai(tester);

    expect(find.byType(CashierPage), findsOneWidget);
    expect(find.byType(AdminDashboardPage), findsNothing);
    expect(find.byType(BrandTitle), findsOneWidget);
    expect(find.text(AppStrings.cashierCategories), findsOneWidget);
    expect(find.text('Manicure'), findsOneWidget);
    expect(find.text(AppStrings.adminDashboardReport), findsNothing);
  });

  testWidgets('bottom nav pindah tab', (tester) async {
    await _loginAsPegawai(tester);

    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined).last);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.cashierCategories), findsNothing);
    expect(
      find.text('${AppStrings.navFinance}: ${AppStrings.comingSoon}'),
      findsNothing,
    );
    expect(find.text(AppStrings.financeHeader), findsWidgets);
    expect(
      find.text('${AppStrings.navFinance}: ${AppStrings.comingSoon}'),
      findsNothing,
    );
  });

  testWidgets('drawer "Riwayat Pemesanan" membuka tab Pesanan', (tester) async {
    await _loginAsPegawai(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.adminOrdersNav));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.cashierCategories), findsNothing);
    expect(find.text(AppStrings.ordersEmpty), findsNothing);
    await tester.scrollUntilVisible(
      find.text('INV-001'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('INV-001'), findsOneWidget);
  });

  testWidgets(
    'tab Pesanan dari dalam halaman transaksi kembali ke tab Pesanan, bukan coming soon',
    (tester) async {
      await _loginAsPegawai(tester);

      await tester.tap(find.byIcon(Icons.receipt_long_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(CashierPage), findsOneWidget);
      expect(
        find.text('${AppStrings.navOrders}: ${AppStrings.comingSoon}'),
        findsNothing,
      );
      await tester.scrollUntilVisible(
        find.text('INV-001'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('INV-001'), findsOneWidget);
    },
  );

  testWidgets('logout dari drawer kembali ke halaman login', (tester) async {
    await _loginAsPegawai(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.logout));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(CashierPage), findsNothing);
  });

  testWidgets('tombol toggle mengubah mode gelap/terang', (tester) async {
    addTearDown(() => AppColors.setDark(false));

    await _loginAsPegawai(tester);

    expect(AppColors.isDark, isFalse);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();

    expect(AppColors.isDark, isTrue);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(find.byType(CashierPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();

    expect(AppColors.isDark, isFalse);
  });
}
