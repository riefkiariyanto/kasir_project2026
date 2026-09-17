import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/clay_decoration.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/brand_title.dart';
import '../../../../core/widgets/image_viewer_dialog.dart';
import '../../../../core/widgets/product_thumbnail.dart';
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
  List<Product>? _products;
  List<ProductCategory>? _categories;
  String? _selectedCategory;
  String _searchQuery = '';
  bool _gridView = true;
  Product? _editingProduct;
  bool _showAddForm = false;
  bool _panelCollapsed = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<ProductCategory> categories = await _categoryRepository
        .fetchAll();
    final List<Product> products = await _repository.fetchAll(categories);
    if (mounted) {
      setState(() {
        _categories = categories;
        _products = products;
      });
    }
  }

  bool get _isFormVisible => _editingProduct != null || _showAddForm;

  List<Product> get _visibleProducts =>
      (_products ?? const <Product>[]).where((Product product) {
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

  bool _hasImage(String? imageAsset) =>
      imageAsset != null && imageAsset.trim().isNotEmpty;

  Future<void> _saveProduct({
    required String name,
    required int price,
    required String categoryId,
    String? tag,
    Uint8List? imageBytes,
  }) async {
    if (_editingProduct == null) {
      await _repository.add(
        name: name,
        price: price,
        categoryId: categoryId,
        tag: tag,
        imageBytes: imageBytes,
      );
    } else {
      await _repository.update(
        id: _editingProduct!.id,
        name: name,
        price: price,
        categoryId: categoryId,
        tag: tag,
        imageBytes: imageBytes,
      );
    }
    await _load();
    if (mounted) {
      setState(() {
        _editingProduct = null;
        _showAddForm = false;
        _panelCollapsed = true;
      });
    }
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

    await _repository.delete(product.id);
    await _load();
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
    if (index == AdminBottomNav.catalogIndex) {
      return;
    }
    Navigator.of(context).pop(index);
  }

  Widget _buildScaffold(BuildContext context) {
    // Whenever the editor is open — regardless of screen width — it takes
    // over the whole page: no separate Scaffold app bar/bottom nav stacked
    // on top of the editor's own header, so there's exactly one scrollable
    // region (header included) and the keyboard never has to compete with a
    // pinned bar for space. A wide screen can still be short (a landscape
    // tablet), so this can't be gated on width alone.
    final bool showFullScreenEditor = _isFormVisible;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: showFullScreenEditor
          ? null
          : AppBar(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: AppColors.onSurface, size: 28),
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: AppStrings.back,
                icon: const Icon(Icons.arrow_back),
              ),
              title: BrandTitle(text: AppStrings.adminProducts),
              actions: <Widget>[const ThemeToggleButton()],
            ),
      bottomNavigationBar: showFullScreenEditor
          ? null
          : AdminBottomNav(
              currentIndex: AdminBottomNav.catalogIndex,
              onSelected: _onNavSelected,
            ),
      body: _products == null || _categories == null
          ? const Center(child: CircularProgressIndicator())
          : showFullScreenEditor
          ? SafeArea(
              child: _ProductEditorPanel(
                product: _editingProduct,
                categories: _categories ?? const <ProductCategory>[],
                categoryRepository: _categoryRepository,
                onSave: _saveProduct,
                onCategoriesChanged: _load,
                onCancel: _closeEditor,
                scrollableHeader: true,
              ),
            )
          : LayoutBuilder(
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
                            // Editing always takes over the full page (see
                            // showFullScreenEditor above), so whenever this
                            // panel is reachable, _isFormVisible is false —
                            // it only ever shows the "add" placeholder.
                            if (!_panelCollapsed)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: SizedBox(
                                  width: editorWidth,
                                  child: _AddProductPlaceholder(
                                    onTap: _startAddNew,
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Column(
                          children: <Widget>[
                            Expanded(child: _buildCatalogPanel(context)),
                            const SizedBox(height: 16),
                            // Extra bottom room clears the app's floating
                            // bottom nav pill, which would otherwise sit on
                            // top of the add button.
                            Padding(
                              padding: const EdgeInsets.only(bottom: 80),
                              child: SizedBox(
                                height: 100,
                                child: _AddProductPlaceholder(
                                  onTap: _startAddNew,
                                ),
                              ),
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
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.add, color: AppColors.onPrimary, size: 22),
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
      decoration: ClayDecoration(
        color: AppColors.panelSurface,
        borderRadius: BorderRadius.circular(20),
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
    final List<String> categories = (_categories ?? const <ProductCategory>[])
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
          decoration: ClayDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
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
                          child: _hasImage(product.imageAsset)
                              ? GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => ImageViewerDialog.show(
                                    context,
                                    imageUrl: product.imageAsset,
                                  ),
                                  child: ProductThumbnail(
                                    imageAsset: product.imageAsset,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                )
                              : ProductThumbnail(
                                  imageAsset: product.imageAsset,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
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
          decoration: ClayDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
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
                      child: _hasImage(product.imageAsset)
                          ? GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => ImageViewerDialog.show(
                                context,
                                imageUrl: product.imageAsset,
                              ),
                              child: ProductThumbnail(
                                imageAsset: product.imageAsset,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            )
                          : ProductThumbnail(
                              imageAsset: product.imageAsset,
                              borderRadius: BorderRadius.circular(16),
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

class _AddProductPlaceholder extends StatelessWidget {
  const _AddProductPlaceholder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ClayDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
              child: Icon(Icons.add, color: AppColors.onPrimary, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

typedef ProductSaveCallback =
    Future<void> Function({
      required String name,
      required int price,
      required String categoryId,
      String? tag,
      Uint8List? imageBytes,
    });

class _ProductEditorPanel extends StatefulWidget {
  const _ProductEditorPanel({
    this.product,
    required this.categories,
    required this.categoryRepository,
    required this.onSave,
    required this.onCategoriesChanged,
    required this.onCancel,
    this.scrollableHeader = false,
  });

  final Product? product;
  final List<ProductCategory> categories;
  final CategoryRepository categoryRepository;
  final ProductSaveCallback onSave;
  final Future<void> Function() onCategoriesChanged;
  final VoidCallback onCancel;

  /// When true, the "Tambah/Edit Catalog" header scrolls together with the
  /// fields instead of staying pinned above them — used on narrow layouts
  /// where the Scaffold app bar is also removed, so there's exactly one
  /// header and the whole page (header included) can scroll clear of the
  /// on-screen keyboard instead of two bars stacking on top of each other.
  final bool scrollableHeader;

  @override
  State<_ProductEditorPanel> createState() => _ProductEditorPanelState();
}

class _ProductEditorPanelState extends State<_ProductEditorPanel> {
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _name;
  late TextEditingController _price;
  String? _existingImageAsset;
  Uint8List? _pickedImageBytes;
  String? _selectedCategory;
  bool _isSaving = false;
  bool _isPickingImage = false;

  List<String> get _categoryNames {
    final List<String> names = widget.categories
        .map((ProductCategory category) => category.name)
        .toList();
    final String? selected = _selectedCategory;
    if (selected != null && !names.contains(selected)) {
      names.add(selected);
    }
    return names;
  }

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
    _existingImageAsset = widget.product?.imageAsset;
    _pickedImageBytes = null;
    _selectedCategory = widget.product?.category;
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
      // Let the OS/browser's native (hardware-accelerated) decoder downscale
      // the photo before it ever reaches our pure-Dart compressor below —
      // decoding a multi-megapixel original in pure Dart is what makes a
      // large photo feel slow.
      maxWidth: ImageCompressor.maxDimension.toDouble(),
      maxHeight: ImageCompressor.maxDimension.toDouble(),
    );
    if (picked == null) {
      return;
    }
    setState(() => _isPickingImage = true);
    // Let the spinner paint at least one frame before the (potentially
    // heavy, synchronous-on-web) compression work starts.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      final Uint8List rawBytes = await picked.readAsBytes();
      final Uint8List compressed = await compute(
        ImageCompressor.compress,
        rawBytes,
      );
      if (mounted) {
        setState(() => _pickedImageBytes = compressed);
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
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

    await widget.categoryRepository.add(name);
    await widget.onCategoriesChanged();
    if (mounted) {
      setState(() => _selectedCategory = name);
    }
  }

  Future<void> _save() async {
    final ProductCategory? category = widget.categories
        .cast<ProductCategory?>()
        .firstWhere(
          (ProductCategory? c) => c?.name == _selectedCategory,
          orElse: () => null,
        );
    if (category == null) {
      return;
    }

    setState(() => _isSaving = true);
    await widget.onSave(
      name: _name.text.trim(),
      price: int.tryParse(_price.text.replaceAll('.', '')) ?? 0,
      categoryId: category.id,
      imageBytes: _pickedImageBytes,
    );
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: widget.scrollableHeader
          ? null
          : BoxDecoration(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extra bottom padding equal to the keyboard height so the scroll view
    // has room to bring any field (or the buttons) fully above the
    // on-screen keyboard instead of it being covered.
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final Widget fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.scrollableHeader) _buildHeader(),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            widget.scrollableHeader ? 0 : 12,
            16,
            12 + bottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.inputBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(AppStrings.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving || _isPickingImage ? null : _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.scrollableHeader) {
      // Everything, header included, scrolls as one unit — nothing stays
      // pinned above the fields competing with the keyboard for space.
      return SingleChildScrollView(child: fields);
    }

    return Container(
      padding: const EdgeInsets.all(0),
      decoration: ClayDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeader(),
          Expanded(child: SingleChildScrollView(child: fields)),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _isPickingImage ? null : _pickImage,
      child: Container(
        height: 140,
        clipBehavior: Clip.antiAlias,
        decoration: ClayDecoration(
          sunken: true,
          color: AppColors.panelSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ProductThumbnail(
              imageAsset: _existingImageAsset,
              previewBytes: _pickedImageBytes,
              targetWidth: 320,
            ),
            if (_isPickingImage)
              Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: Colors.white),
              )
            else
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.onPrimary,
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
                  color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
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
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
