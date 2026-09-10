import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_2026/core/constants/app_strings.dart';
import 'package:kasir_2026/core/theme/app_theme.dart';
import 'package:kasir_2026/features/cashier/presentation/pages/cashier_page.dart';
import 'package:kasir_2026/features/cashier/presentation/pages/transaction_page.dart';
import 'package:kasir_2026/features/cashier/presentation/widgets/product_tile.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(theme: AppTheme.light, home: child);
  }

  testWidgets('menampilkan pencarian, kategori, dan produk', (tester) async {
    await tester.pumpWidget(wrap(const TransactionPage()));

    expect(find.text(AppStrings.searchHint), findsOneWidget);
    expect(find.text(AppStrings.categoryAll), findsOneWidget);
    expect(find.text('Manicure Klasik'), findsOneWidget);
    expect(find.text(AppStrings.cartTitle), findsOneWidget);
    expect(find.text(AppStrings.cartEmpty), findsOneWidget);
  });

  testWidgets('pencarian menyaring daftar produk', (tester) async {
    await tester.pumpWidget(wrap(const TransactionPage()));

    await tester.enterText(find.byType(TextField), 'Refill Kuku');
    await tester.pumpAndSettle();

    expect(find.byType(ProductTile), findsOneWidget);
    expect(find.text('Manicure Klasik'), findsNothing);
  });

  testWidgets('filter kategori menyaring daftar produk', (tester) async {
    await tester.pumpWidget(wrap(const TransactionPage()));

    await tester.tap(find.text('Pedicure'));
    await tester.pumpAndSettle();

    expect(find.text('Pedicure Klasik'), findsOneWidget);
    expect(find.text('Manicure Klasik'), findsNothing);
  });

  testWidgets('menambah produk ke keranjang dan menghitung total', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const TransactionPage()));

    await tester.tap(find.text('Manicure Klasik'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.cartEmpty), findsNothing);
    expect(find.text('Rp45.000'), findsWidgets);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Rp90.000'), findsWidgets);
  });

  testWidgets('metode pembayaran QRIS dan Tunai tampil di atas keranjang', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const TransactionPage()));

    expect(find.text('QRIS'), findsOneWidget);
    expect(find.text('Tunai'), findsOneWidget);
  });

  testWidgets('checkout membutuhkan metode pembayaran terpilih', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const TransactionPage()));

    await tester.tap(find.text('Manicure Klasik'));
    await tester.pumpAndSettle();

    final Finder checkoutButton = find.widgetWithText(
      ElevatedButton,
      AppStrings.cartCheckout,
    );
    expect(tester.widget<ElevatedButton>(checkoutButton).onPressed, isNull);

    await tester.tap(find.text('Tunai'));
    await tester.pumpAndSettle();

    expect(tester.widget<ElevatedButton>(checkoutButton).onPressed, isNotNull);
  });

  testWidgets('checkout menampilkan dialog verifikasi dengan PIN pegawai', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const TransactionPage()));

    await tester.tap(find.text('Manicure Klasik'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tunai'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.cartCheckout),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.verifyOrderTitle), findsOneWidget);
    expect(find.text('Manicure Klasik'), findsWidgets);

    final Finder confirmButton = find.widgetWithText(
      ElevatedButton,
      AppStrings.verifyOrderConfirm,
    );

    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.verifyOrderPinWrong), findsNothing);
    expect(find.text(AppStrings.verifyOrderTitle), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '000000');
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.verifyOrderPinWrong), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.cartEmpty), findsOneWidget);
    expect(find.textContaining(AppStrings.paymentSuccess), findsOneWidget);
  });

  testWidgets('pesanan bisa dihapus dari dialog verifikasi', (tester) async {
    await tester.pumpWidget(wrap(const TransactionPage()));

    await tester.tap(find.text('Manicure Klasik'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tunai'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.cartCheckout),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.verifyOrderTitle), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byIcon(Icons.delete_outline),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.cartEmpty), findsWidgets);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, AppStrings.verifyOrderConfirm),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('pesanan yang selesai muncul di menu Pesanan halaman kasir', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const TransactionPage()));

    await tester.enterText(find.byType(TextField), 'Refill Kuku');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ProductTile));
    await tester.pumpAndSettle();

    await tester.tap(find.text('QRIS'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.cartCheckout),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.verifyOrderConfirm),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.ok));
    await tester.pumpAndSettle();

    await tester.pumpWidget(wrap(const CashierPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.inventory_2_outlined));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.ordersEmpty), findsNothing);
    expect(find.text('Rp55.000'), findsOneWidget);

    await tester.tap(find.text('Rp55.000'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.orderDetailTitle), findsOneWidget);
    expect(find.textContaining('Refill Kuku'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Siti Aminah'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('PIN pegawai kedua tercatat sebagai kasir pada pesanan', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const TransactionPage()));

    await tester.enterText(find.byType(TextField), 'Perawatan Kutikula');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ProductTile));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tunai'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.cartCheckout),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '654321');
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.verifyOrderConfirm),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.ok));
    await tester.pumpAndSettle();

    await tester.pumpWidget(wrap(const CashierPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.inventory_2_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rp40.000'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Budi Santoso'),
      ),
      findsOneWidget,
    );
  });
}
