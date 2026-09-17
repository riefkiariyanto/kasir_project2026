import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/clay_decoration.dart';
import 'receipt_printer.dart';

/// "Footer Struk" settings card: previews the text printed under the
/// receipt total and opens an editor for it. Stored on this device only.
class ReceiptFooterTile extends StatefulWidget {
  const ReceiptFooterTile({super.key, this.printer = const ReceiptPrinter()});

  final ReceiptPrinter printer;

  @override
  State<ReceiptFooterTile> createState() => _ReceiptFooterTileState();
}

class _ReceiptFooterTileState extends State<ReceiptFooterTile> {
  String? _footer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String footer = await widget.printer.footer();
    if (mounted) {
      setState(() => _footer = footer);
    }
  }

  Future<void> _openEditor(String current) async {
    final String? edited = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _FooterEditorDialog(initial: current),
    );
    if (edited == null) {
      return;
    }
    await widget.printer.saveFooter(edited);
    if (mounted) {
      setState(() => _footer = edited);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? footer = _footer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Footer Struk',
          style: TextStyle(
            fontSize: 14.4,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: ClayDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            onTap: footer == null ? null : () => _openEditor(footer),
            leading: Icon(Icons.notes_outlined, color: AppColors.primary),
            title: Text(
              'Teks di bawah struk',
              style: TextStyle(
                fontSize: 15.6,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            subtitle: Text(
              footer ?? '',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterEditorDialog extends StatefulWidget {
  const _FooterEditorDialog({required this.initial});

  final String initial;

  @override
  State<_FooterEditorDialog> createState() => _FooterEditorDialogState();
}

class _FooterEditorDialogState extends State<_FooterEditorDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Footer Struk'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _controller,
              minLines: 4,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: 'Satu baris teks = satu baris di struk',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tulis ${ReceiptPrinter.phonePlaceholder} untuk nomor HP toko. '
              'Tersimpan di perangkat ini saja.',
              style: TextStyle(fontSize: 12.5, color: AppColors.onSurfaceMuted),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    _controller.text = ReceiptPrinter.defaultFooter,
                child: const Text('Kembalikan default'),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
