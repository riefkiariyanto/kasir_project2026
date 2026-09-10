import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/brand_title.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../cashier/data/category_repository.dart';
import '../../../cashier/data/product_repository.dart';
import '../../../cashier/presentation/widgets/category_filter_bar.dart';
import '../../../cashier/presentation/widgets/product_search_field.dart';
import '../widgets/admin_bottom_nav.dart';

class AdminCatalogPage extends StatefulWidget {
  const AdminCatalogPage({
    super.key,
    this.productRepository = const ProductRepository(),
    this.categoryRepository = const CategoryRepository(),
  });

  final ProductRepository productRepository;
  final CategoryRepository categoryRepository;

  @override
  State<AdminCatalogPage> createState() => _AdminCatalogPageState();
}

class _AdminCatalogPageState extends State<AdminCatalogPage> {
  late final ProductRepository _repository = widget.productRepository;
  late final CategoryRepository _categoryRepository = widget.categoryRepository;
  late List<Product> _products = _repository.fetchAll();
  String? _selectedCategory;
  String _searchQuery = '';
  bool _gridView = true;
  Product? _editingProduct;
  bool _showAddForm = false;
  bool _panelCollapsed = true;

  bool get _isFormVisible => _editingProduct != null || _showAddForm;

  List<Product> get _visibleProducts => _products.where((Product product) {
    final bool matchesCategory =
        _selectedCategory == null || product.category == _selectedCategory;
    final String query = _searchQuery.trim().toLowerCase();
    final bool matchesSearch =
        query.isEmpty || product.name.toLowerCase().contains(query);
    return matchesCategory && matchesSearch;
  }).toList();

  void _openEditor({Product? product}) {
    setState(() {
      _editingProduct = product;
      _showAddForm = false;
      _panelCollapsed = false;
    });
  }

  void _startAddNew() {
    setState(() {
      _editingProduct = null;
      _showAddForm = true;
      _panelCollapsed = false;
    });
  }

  void _closeEditor() {
    setState(() {
      _editingProduct = null;
      _showAddForm = false;
      _panelCollapsed = true;
    });
  }

  void _saveProduct(Product product) {
    setState(() {
      if (_editingProduct == null) {
        _repository.add(product);
      } else {
        _repository.update(product);
      }
      _products = _repository.fetchAll();
      _editingProduct = null;
      _showAddForm = false;
      _panelCollapsed = true;
    });
  }

  Future<void> _deleteProduct(Product product) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Hapus catalog?'),
        content: Text(product.name),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _repository.delete(product.id);
      _products = _repository.fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppColors.darkNotifier,
      builder: (BuildContext context, bool isDark, _) =>
          _buildScaffold(context),
    );
  }

  void _onNavSelected(int index) {
    if (index == 2) {
      return;
    }
    Navigator.of(context).pop(index);
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.onSurface, size: 28),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: AppStrings.back,
          icon: const Icon(Icons.arrow_back),
        ),
        title: BrandTitle(text: AppStrings.adminProducts),
        actions: <Widget>[
          const ThemeToggleButton(),
          IconButton(
            onPressed: () =>
                showComingSoonDialog(context, AppStrings.cashierInbox),
            tooltip: AppStrings.cashierInbox,
            icon: const Icon(Icons.mail_outline),
          ),
        ],
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 2,
        onSelected: _onNavSelected,
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double editorWidth = constraints.maxWidth >= 700
              ? 360
              : constraints.maxWidth;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: constraints.maxWidth >= 700
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(child: _buildCatalogPanel(context)),
                      _buildPanelToggleHandle(),
                      if (!_panelCollapsed)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: SizedBox(
                            width: editorWidth,
                            child: _isFormVisible
                                ? _ProductEditorPanel(
                                    product: _editingProduct,
                                    categoryRepository: _categoryRepository,
                                    onSave: _saveProduct,
                                    onCancel: _closeEditor,
                                  )
                                : _AddProductPlaceholder(onTap: _startAddNew),
                          ),
                        ),
                    ],
                  )
                : Column(
                    children: <Widget>[
                      Expanded(child: _buildCatalogPanel(context)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 360,
                        child: _isFormVisible
                            ? _ProductEditorPanel(
                                product: _editingProduct,
                                categoryRepository: _categoryRepository,
                                onSave: _saveProduct,
                                onCancel: _closeEditor,
                              )
                            : _AddProductPlaceholder(onTap: _startAddNew),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildPanelToggleHandle() {
    if (_panelCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Center(
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _startAddNew,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.add, color: AppColors.onPanel, size: 22),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCatalogPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panelSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: <Widget>[
          _buildCategoryFilterAndToggle(context),
          const SizedBox(height: 14),
          Expanded(child: _gridView ? _buildGridView() : _buildListView()),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterAndToggle(BuildContext context) {
    final List<String> categories = _categoryRepository
        .fetchAll()
        .map((ProductCategory category) => category.name)
        .toList();

    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          Row(
            children: [
              Expanded(
                child: ProductSearchField(
                  onChanged: (String value) =>
                      setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() => _gridView = !_gridView),
                tooltip: _gridView ? 'Tampilan List' : 'Tampilan Grid',
                icon: Icon(
                  _gridView
                      ? Icons.view_list_outlined
                      : Icons.grid_view_outlined,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CategoryFilterBar(
            categories: categories,
            selected: _selectedCategory,
            onSelected: (String? category) =>
                setState(() => _selectedCategory = category),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    final List<Product> products = _visibleProducts;

    if (products.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada produk',
          style: TextStyle(color: AppColors.onSurfaceMuted),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (BuildContext context, int index) {
        final Product product = products[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
            boxShadow: AppColors.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openEditor(product: product),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: _ProductThumbnail(
                            imageAsset: product.imageAsset,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                        ),
                        if (product.tag != null)
                          Positioned(
                            left: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const <BoxShadow>[
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                product.tag!,
                                style: const TextStyle(
                                  color: AppColors.onPanel,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.6,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${product.category} • ${CurrencyFormatter.rupiah(product.price)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.2,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      IconButton(
                        iconSize: 20,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () => _openEditor(product: product),
                        icon: Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        iconSize: 20,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () => _deleteProduct(product),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    final List<Product> products = _visibleProducts;

    if (products.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada produk',
          style: TextStyle(color: AppColors.onSurfaceMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: products.length,
      itemBuilder: (BuildContext context, int index) {
        final Product product = products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openEditor(product: product),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 58,
                      height: 58,
                      child: _ProductThumbnail(
                        imageAsset: product.imageAsset,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 16.2,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${product.category} • ${CurrencyFormatter.rupiah(product.price)}',
                            style: TextStyle(
                              fontSize: 14.4,
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openEditor(product: product),
                      icon: Icon(Icons.edit_outlined, color: AppColors.primary),
                    ),
                    IconButton(
                      onPressed: () => _deleteProduct(product),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({this.imageAsset, this.borderRadius});

  final String? imageAsset;
  final BorderRadius? borderRadius;

  Widget _buildPlaceholder(IconData icon) {
    return ColoredBox(
      color: AppColors.panelSurface,
      child: Icon(icon, color: AppColors.onSurfaceMuted),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (imageAsset == null || imageAsset!.trim().isEmpty) {
      image = _buildPlaceholder(Icons.image_outlined);
    } else if (imageAsset!.startsWith('assets/')) {
      image = Image.asset(
        imageAsset!,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) =>
                _buildPlaceholder(Icons.broken_image_outlined),
      );
    } else {
      image = Image.file(
        File(imageAsset!),
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) =>
                _buildPlaceholder(Icons.broken_image_outlined),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: image,
      ),
    );
  }
}

class _AddProductPlaceholder extends StatelessWidget {
  const _AddProductPlaceholder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.onPanel, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductEditorPanel extends StatefulWidget {
  const _ProductEditorPanel({
    this.product,
    required this.categoryRepository,
    required this.onSave,
    required this.onCancel,
  });

  final Product? product;
  final CategoryRepository categoryRepository;
  final ValueChanged<Product> onSave;
  final VoidCallback onCancel;

  @override
  State<_ProductEditorPanel> createState() => _ProductEditorPanelState();
}

class _ProductEditorPanelState extends State<_ProductEditorPanel> {
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _name;
  late TextEditingController _price;
  String? _imagePath;
  String? _selectedCategory;
  late List<String> _categoryNames;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  @override
  void didUpdateWidget(covariant _ProductEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product != widget.product) {
      _name.dispose();
      _price.dispose();
      _initState();
    }
  }

  void _initState() {
    _name = TextEditingController(text: widget.product?.name);
    _price = TextEditingController(
      text: widget.product == null
          ? ''
          : CurrencyFormatter.rupiah(
              widget.product!.price,
            ).replaceFirst('Rp', ''),
    );
    _imagePath = widget.product?.imageAsset;
    _selectedCategory = widget.product?.category;
    _refreshCategoryNames();
  }

  void _refreshCategoryNames() {
    _categoryNames = widget.categoryRepository
        .fetchAll()
        .map((ProductCategory category) => category.name)
        .toList();
    final String? selected = _selectedCategory;
    if (selected != null && !_categoryNames.contains(selected)) {
      _categoryNames = <String>[..._categoryNames, selected];
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) {
      return;
    }
    setState(() => _imagePath = picked.path);
  }

  Future<void> _addNewCategory() async {
    final TextEditingController controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Kategori Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nama kategori'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) {
      return;
    }

    widget.categoryRepository.add(
      ProductCategory(name: name, icon: Icons.category_outlined),
    );
    setState(() {
      _selectedCategory = name;
      _refreshCategoryNames();
    });
  }

  void _save() {
    final String id =
        widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    widget.onSave(
      Product(
        id: id,
        name: _name.text.trim(),
        price: int.tryParse(_price.text.replaceAll('.', '')) ?? 0,
        category: _selectedCategory ?? '',
        imageAsset: _imagePath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Text(
                    widget.product == null ? 'Tambah Catalog' : 'Edit Catalog',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: Icon(Icons.close, color: AppColors.onSurface),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: <Widget>[
                _buildImagePicker(),
                const SizedBox(height: 12),
                _buildField('Nama Produk', _name),
                _buildField(
                  'Harga',
                  _price,
                  keyboardType: TextInputType.number,
                  prefixText: 'Rp ',
                  inputFormatters: <TextInputFormatter>[RupiahInputFormatter()],
                ),
                _buildCategoryField(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.inputBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(AppStrings.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPanel,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 140,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.panelSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _ProductThumbnail(imageAsset: _imagePath),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.onPanel,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Kategori',
          style: TextStyle(
            fontSize: 14.4,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ..._categoryNames.map((String name) {
              final bool isSelected = _selectedCategory == name;
              return ChoiceChip(
                label: Text(name),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedCategory = name),
                backgroundColor: AppColors.panelSurface,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.onPanel : AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 15.6,
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }),
            ActionChip(
              avatar: Icon(Icons.add, size: 16, color: AppColors.primary),
              label: const Text('Tambah'),
              onPressed: _addNewCategory,
              backgroundColor: AppColors.panelSurface,
              labelStyle: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 15.6,
              ),
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? hintText,
    String? prefixText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixText: prefixText,
          filled: true,
          fillColor: AppColors.panelSurface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
