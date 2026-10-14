import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:premium_store/app/sidebar.dart';
import 'package:premium_store/core/models/product_model.dart';
import 'package:premium_store/core/services/cloudinary_service.dart';
import 'package:premium_store/localization/app_translations.dart';
import 'package:premium_store/state/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../state/category_provider.dart';
import '../../state/product_brovider.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({
    super.key,
    this.product,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  // ============================================================
  // FORM
  // ============================================================

  final _formKey = GlobalKey<FormState>();

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;

  late TextEditingController _smallPriceController;
  late TextEditingController _mediumPriceController;
  late TextEditingController _largePriceController;

  // ============================================================
  // SIDE DISH CONTROLLERS
  // ============================================================

  final TextEditingController _sideDishNameController =
      TextEditingController();

  final TextEditingController _sideDishPriceController =
      TextEditingController();

  // ============================================================
  // PRODUCT DATA
  // ============================================================

  String? _selectedCategoryId;

  // ============================================================
  // PRODUCT TYPE
  // food = Food
  // drink = Drink
  // ============================================================

  String _selectedProductType = 'food';

  String? _imageUrl;

  bool _isUploading = false;

  bool _hasSizes = false;

  // ============================================================
  // SIDE DISHES
  // ============================================================

  final List<SideDish> _sideDishes = [];

  // ============================================================
  // BRAND COLOR
  // ============================================================

  final Color brandColor = const Color(0xFF00B686);

  // ============================================================
  // TRANSLATION
  // ============================================================

  String get _languageCode =>
      context.read<LanguageProvider>().locale.languageCode;

  String _tr(String key) {
    return AppTranslations.get(
      _languageCode,
      key,
    );
  }

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.product?.name ?? '',
    );

    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );

    _descController = TextEditingController(
      text: widget.product?.description ?? '',
    );

    // ==========================================================
    // SIZES
    // ==========================================================

    _hasSizes = widget.product?.hasSizes ?? false;

    // Small / Medium / Large are database keys.
    // Do NOT translate these values.

    _smallPriceController = TextEditingController(
      text: widget.product?.sizes?['Small']?.toString() ?? '',
    );

    _mediumPriceController = TextEditingController(
      text: widget.product?.sizes?['Medium']?.toString() ?? '',
    );

    _largePriceController = TextEditingController(
      text: widget.product?.sizes?['Large']?.toString() ?? '',
    );

    // ==========================================================
    // CATEGORY
    // ==========================================================

    _selectedCategoryId = widget.product?.categoryId;

    // ==========================================================
    // PRODUCT TYPE
    // ==========================================================

    _selectedProductType =
        widget.product?.productType ?? 'food';

    // ==========================================================
    // IMAGE
    // ==========================================================

    _imageUrl = widget.product?.imageUrl;

    // ==========================================================
    // SIDE DISHES
    // ==========================================================

    _sideDishes.addAll(
      widget.product?.sideDishes ?? [],
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();

    _smallPriceController.dispose();
    _mediumPriceController.dispose();
    _largePriceController.dispose();

    _sideDishNameController.dispose();
    _sideDishPriceController.dispose();

    super.dispose();
  }

  // ============================================================
  // ADD SIDE DISH
  // ============================================================

  void _addSideDish() {
    final String name =
        _sideDishNameController.text.trim();

    final double? price = double.tryParse(
      _sideDishPriceController.text.trim(),
    );

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr('side_dish_name_error'),
          ),
        ),
      );

      return;
    }

    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr('side_dish_price_error'),
          ),
        ),
      );

      return;
    }

    setState(() {
      _sideDishes.add(
        SideDish(
          name: name,
          price: price,
        ),
      );
    });

    _sideDishNameController.clear();
    _sideDishPriceController.clear();
  }

  // ============================================================
  // REMOVE SIDE DISH
  // ============================================================

  void _removeSideDish(int index) {
    setState(() {
      _sideDishes.removeAt(index);
    });
  }

  // ============================================================
  // NAVIGATION TO PRODUCTS
  // ============================================================

  void _goToProducts() {
    debugPrint(
      '==========================================',
    );

    debugPrint(
      'BACK TO PRODUCTS BUTTON PRESSED',
    );

    debugPrint(
      'Current route: ${GoRouter.of(context).routeInformationProvider.value.uri}',
    );

    try {
      GoRouter.of(context).go(
        '/admin/products',
      );

      debugPrint(
        'Navigation command sent successfully',
      );
    } catch (e) {
      debugPrint(
        'GoRouter navigation error: $e',
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/admin/products',
        );
      }
    }

    debugPrint(
      '==========================================',
    );
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();

    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (file == null) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final bytes = await file.readAsBytes();

      final url = await CloudinaryService.uploadImage(
        bytes,
        file.name,
        'restaurant/products',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _imageUrl = url;
        _isUploading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }

      debugPrint(
        'Upload failed: $e',
      );
    }
  }

  // ============================================================
  // SAVE PRODUCT
  // ============================================================

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ==========================================================
    // IMAGE VALIDATION
    // ==========================================================

    if (_imageUrl == null || _imageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr('image_required'),
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );

      return;
    }

    setState(() {
      _isUploading = true;
    });

    // ==========================================================
    // SIZES
    // ==========================================================

    final Map<String, double> sizesMap = {};

    if (_hasSizes) {
      // Keep these database keys unchanged.

      sizesMap['Small'] = double.tryParse(
            _smallPriceController.text,
          ) ??
          0.0;

      sizesMap['Medium'] = double.tryParse(
            _mediumPriceController.text,
          ) ??
          0.0;

      sizesMap['Large'] = double.tryParse(
            _largePriceController.text,
          ) ??
          0.0;
    }

    // ==========================================================
    // MAIN PRICE
    // ==========================================================

    final double mainPrice = _hasSizes
        ? 0.0
        : double.tryParse(
              _priceController.text,
            ) ??
            0.0;

    // ==========================================================
    // PRODUCT PROVIDER
    // ==========================================================

    final productProvider =
        context.read<ProductProvider>();

    // ==========================================================
    // PRODUCT DATA
    // ==========================================================

    final Product productData = Product(
      createdAt:
          widget.product?.createdAt ?? DateTime.now(),

      id: widget.product?.id ?? '',

      name: _nameController.text.trim(),

      description: _descController.text.trim(),

      price: mainPrice,

      categoryId: _selectedCategoryId ?? '',

      // ========================================================
      // PRODUCT TYPE
      // ========================================================

      productType: _selectedProductType,

      imageUrl: _imageUrl!,

      isAvailable:
          widget.product?.isAvailable ?? true,

      hasSizes: _hasSizes,

      sizes: sizesMap,

      sideDishes: _sideDishes,
    );

    // ==========================================================
    // SAVE
    // ==========================================================

    try {
      if (widget.product == null) {
        await productProvider.addProduct(
          productData,
        );
      } else {
        await productProvider.updateProduct(
          productData,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isUploading = false;
      });

      // ========================================================
      // SUCCESS DIALOG
      // ========================================================

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),

            title: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 50,
            ),

            content: Text(
              _tr('product_saved_successfully'),
              textAlign: TextAlign.center,
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop();
                },
                child: Text(
                  _tr('done'),
                ),
              ),
            ],
          );
        },
      );

      // ========================================================
      // AFTER DIALOG
      // ========================================================

      if (!mounted) {
        return;
      }

      _goToProducts();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUploading = false;
      });

      debugPrint(
        'Error saving product: $e',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_tr('error')}: ${e.toString()}',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // Watch language so the screen rebuilds
    // immediately when language changes.
    context.watch<LanguageProvider>();

    final categoryProvider =
        context.watch<CategoryProvider>();

    final bool isEdit =
        widget.product != null;

    final size =
        MediaQuery.of(context).size;

    final bool isDesktop =
        size.width > 1100;

    return Scaffold(
      key: _scaffoldKey,

      backgroundColor:
          const Color(0xFFF8F9FA),

      // ========================================================
      // MOBILE DRAWER
      // ========================================================

      drawer: !isDesktop
          ? const Drawer(
              child: AdminSidebar(),
            )
          : null,

      // ========================================================
      // BODY
      // ========================================================

      body: Row(
        children: [
          // ======================================================
          // DESKTOP SIDEBAR
          // ======================================================

          if (isDesktop)
            const SizedBox(
              width: 260,
              child: AdminSidebar(),
            ),

          // ======================================================
          // CONTENT
          // ======================================================

          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  isDesktop ? 40.0 : 16.0,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    _buildTopBar(
                      isDesktop,
                      isEdit,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildMainForm(
                      isDesktop,
                      isEdit,
                      categoryProvider,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(
    bool isDesktop,
    bool isEdit,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            // ==================================================
            // MOBILE MENU
            // ==================================================

            if (!isDesktop)
              IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.black,
                ),

                onPressed: () {
                  _scaffoldKey.currentState
                      ?.openDrawer();
                },
              ),

            // ==================================================
            // BACK BUTTON
            // ==================================================

            TextButton.icon(
              onPressed: _goToProducts,

              icon: const Icon(
                Icons.arrow_back,
                size: 16,
                color: Colors.black,
              ),

              label: Text(
                _tr('back_to_products'),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 10,
        ),

        // ======================================================
        // TITLE
        // ======================================================

        Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
          ),

          child: Text(
            isEdit
                ? _tr('edit_product')
                : _tr('inventory_management'),

            style: const TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MAIN FORM
  // ============================================================

  Widget _buildMainForm(
    bool isDesktop,
    bool isEdit,
    CategoryProvider categoryProvider,
  ) {
    return Container(
      padding: EdgeInsets.all(
        isDesktop ? 40 : 20,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.05),
            blurRadius: 20,
          ),
        ],
      ),

      child: Form(
        key: _formKey,

        child: isDesktop
            ? Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Expanded(
                    flex: 2,

                    child:
                        _buildFormFields(
                      isEdit,
                      categoryProvider,
                      isDesktop,
                    ),
                  ),

                  const SizedBox(
                    width: 50,
                  ),

                  Expanded(
                    flex: 1,

                    child:
                        _buildImagePickerSection(),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildImagePickerSection(),

                  const SizedBox(
                    height: 30,
                  ),

                  _buildFormFields(
                    isEdit,
                    categoryProvider,
                    isDesktop,
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // FORM FIELDS
  // ============================================================

  Widget _buildFormFields(
    bool isEdit,
    CategoryProvider provider,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          isEdit
              ? _tr('modify_item_details')
              : _tr('add_new_inventory'),

          style: const TextStyle(
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
            color: Colors.black,
          ),
        ),

        const SizedBox(
          height: 30,
        ),

        // Name
        _buildTextField(
          '${_tr('item_name')} :',
          _nameController,
        ),

        // Category
        _buildCategoryDropdown(
          '${_tr('category')} :',
          provider,
        ),

        // ======================================================
        // PRODUCT TYPE
        // ======================================================

        _buildProductTypeDropdown(),

        // ======================================================
        // SIZES SWITCH
        // ======================================================

        Padding(
          padding: const EdgeInsets.only(
            bottom: 20.0,
          ),

          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: [
              Text(
                _tr('multiple_sizes'),

                // العنوان فقط أسود
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              Switch(
                value: _hasSizes,

                activeColor:
                    brandColor,

                onChanged: (value) {
                  setState(() {
                    _hasSizes = value;
                  });
                },
              ),
            ],
          ),
        ),

        // ======================================================
        // PRICE
        // ======================================================

        if (!_hasSizes)
          _buildTextField(
            '${_tr('price')} :',
            _priceController,
            isNumber: true,
          )

        // ======================================================
        // SIZES PRICES
        // ======================================================

        else ...[
          _buildTextField(
            '${_tr('small_size_price')} :',
            _smallPriceController,
            isNumber: true,
          ),

          _buildTextField(
            '${_tr('medium_size_price')} :',
            _mediumPriceController,
            isNumber: true,
          ),

          _buildTextField(
            '${_tr('large_size_price')} :',
            _largePriceController,
            isNumber: true,
          ),
        ],

        // ======================================================
        // DESCRIPTION
        // ======================================================

        _buildDescriptionField(
          '${_tr('description')} :',
          _descController,
        ),

        const SizedBox(
          height: 30,
        ),

        // ======================================================
        // SIDE DISHES
        // ======================================================

        _buildSideDishesSection(),

        const SizedBox(
          height: 40,
        ),

        // ======================================================
        // SAVE BUTTON
        // ======================================================

        SizedBox(
          width: isDesktop
              ? 180
              : double.infinity,

          height: 55,

          child: ElevatedButton(
            onPressed:
                _isUploading
                    ? null
                    : _saveProduct,

            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  brandColor,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              elevation: 0,
            ),

            child:
                _isUploading
                    ? const CircularProgressIndicator(
                        color:
                            Colors.white,
                      )
                    : Text(
                        isEdit
                            ? _tr('update')
                            : _tr('upload'),

                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRODUCT TYPE DROPDOWN
  // ============================================================

  Widget _buildProductTypeDropdown() {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 30.0,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ======================================================
          // PRODUCT TYPE LABEL
          // ======================================================

          const Text(
            'Product Type :',

            style:
                TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          DropdownButtonFormField<String>(
            value: _selectedProductType,

            isExpanded: true,

            style:
                const TextStyle(
              color: Colors.black,
              fontWeight:
                  FontWeight.w600,
              fontSize: 16,
            ),

            dropdownColor:
                Colors.black87,

            items: const [
              DropdownMenuItem<String>(
                value: 'food',

                child: Text(
                  'Food',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                  ),
                ),
              ),

              DropdownMenuItem<String>(
                value: 'drink',

                child: Text(
                  'Drink',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                  ),
                ),
              ),
            ],

            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedProductType =
                    value;
              });
            },

            decoration:
                InputDecoration(
              isDense: true,

              enabledBorder:
                  UnderlineInputBorder(
                borderSide:
                    BorderSide(
                  color:
                      brandColor,
                  width: 2,
                ),
              ),

              focusedBorder:
                  UnderlineInputBorder(
                borderSide:
                    BorderSide(
                  color:
                      brandColor,
                  width: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SIDE DISHES SECTION
  // ============================================================

  Widget _buildSideDishesSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        // ========================================================
        // TITLE
        // ========================================================

        Text(
          _tr('side_dishes'),

          // العنوان أسود
          style: const TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
            color: Colors.black,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          _tr('side_dishes_hint'),

          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        // ========================================================
        // INPUT ROW
        // ========================================================

        Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,

          children: [
            // ====================================================
            // NAME
            // ====================================================

            Expanded(
              flex: 3,

              child: TextFormField(
                controller:
                    _sideDishNameController,

                // لم يتم تغيير لون النص داخل الـ TextField
                style:
                    const TextStyle(
                  color: Colors.white,
                ),

                decoration:
                    InputDecoration(
                  // الـ label فقط
                  labelText:
                      _tr('side_dish_name'),

                  labelStyle:
                      const TextStyle(
                    color: Colors.black,
                  ),

                  hintText:
                      _tr('fries_example'),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),

                    borderSide:
                        BorderSide(
                      color:
                          brandColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            // ====================================================
            // PRICE
            // ====================================================

            Expanded(
              flex: 2,

              child: TextFormField(
                controller:
                    _sideDishPriceController,

                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),

                // لم يتم تغيير لون النص داخل الـ TextField
                style:
                    const TextStyle(
                  color: Colors.white,
                ),

                decoration:
                    InputDecoration(
                  // الـ label فقط
                  labelText:
                      _tr('price'),

                  labelStyle:
                      const TextStyle(
                    color: Colors.black,
                  ),

                  hintText:
                      '30',

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),

                    borderSide:
                        BorderSide(
                      color:
                          brandColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            // ====================================================
            // ADD BUTTON
            // ====================================================

            SizedBox(
              height: 55,

              child:
                  ElevatedButton(
                onPressed:
                    _addSideDish,

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      brandColor,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),

                child:
                    const Icon(
                  Icons.add,
                  color:
                      Colors.white,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 20,
        ),

        // ========================================================
        // SIDE DISH LIST
        // ========================================================

        if (_sideDishes.isEmpty)
          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.all(
              20,
            ),

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF8F9FA,
              ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),

              border: Border.all(
                color:
                    Colors.grey.shade300,
              ),
            ),

            child:
                Text(
              _tr('no_side_dishes'),

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                color:
                    Colors.grey,
              ),
            ),
          )
        else
          Column(
            children:
                List.generate(
              _sideDishes.length,
              (index) {
                final side =
                    _sideDishes[index];

                return Container(
                  margin:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),

                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFF8F9FA,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),

                    border: Border.all(
                      color:
                          Colors.grey.shade300,
                    ),
                  ),

                  child: Row(
                    children: [
                      // ==========================================
                      // ICON
                      // ==========================================

                      Container(
                        padding:
                            const EdgeInsets.all(
                          8,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              brandColor
                                  .withOpacity(
                            0.1,
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            8,
                          ),
                        ),

                        child:
                            Icon(
                          Icons.restaurant,
                          color:
                              brandColor,
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      // ==========================================
                      // NAME
                      // ==========================================

                      Expanded(
                        child:
                            Text(
                          side.name,

                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,

                            color:
                                Colors.black,

                            fontSize:
                                15,
                          ),
                        ),
                      ),

                      // ==========================================
                      // PRICE
                      // ==========================================

                      Text(
                        '${side.price.toStringAsFixed(2)} EGP',

                        style:
                            TextStyle(
                          color:
                              brandColor,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      // ==========================================
                      // DELETE
                      // ==========================================

                      IconButton(
                        onPressed: () =>
                            _removeSideDish(
                          index,
                        ),

                        icon:
                            const Icon(
                          Icons
                              .delete_outline,
                          color:
                              Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Widget _buildImagePickerSection() {
    return Column(
      children: [
        GestureDetector(
          onTap:
              _pickAndUploadImage,

          child: Container(
            height: 320,

            width:
                double.infinity,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF1F3F5,
              ),

              borderRadius:
                  BorderRadius.circular(
                15,
              ),

              border:
                  Border.all(
                color:
                    brandColor,
                width: 1.5,
              ),
            ),

            child: _isUploading
                ? Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          brandColor,
                    ),
                  )
                : _imageUrl != null &&
                        _imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),

                        child:
                            Image.network(
                          _imageUrl!,
                          fit:
                              BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,

                        children: [
                          Icon(
                            Icons
                                .add_photo_alternate_rounded,
                            size: 65,
                            color:
                                brandColor,
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Text(
                            _tr(
                              'upload_product_image',
                            ),

                            style:
                                const TextStyle(
                              color:
                                  Colors.black,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        Text(
          _tr('change_product_image'),

          style:
              const TextStyle(
            color:
                Colors.black54,
            fontSize: 13,
            fontWeight:
                FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 30.0,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ======================================================
          // LABEL ONLY
          // ======================================================

          Text(
            label,

            style:
                const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,

              // العنوان فقط أسود
              color: Colors.black,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          // ======================================================
          // TEXT FIELD
          // ======================================================

          TextFormField(
            controller:
                controller,

            // لم يتم تغيير لون النص داخل TextField
            style:
                const TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w600,
            ),

            keyboardType: isNumber
                ? const TextInputType
                    .numberWithOptions(
                    decimal: true,
                  )
                : TextInputType.text,

            validator: (value) {
              if (value == null ||
                  value.isEmpty) {
                return _tr(
                  'field_required',
                );
              }

              return null;
            },

            decoration:
                InputDecoration(
              isDense: true,

              enabledBorder:
                  UnderlineInputBorder(
                borderSide:
                    BorderSide(
                  color:
                      brandColor,
                  width: 2,
                ),
              ),

              focusedBorder:
                  UnderlineInputBorder(
                borderSide:
                    BorderSide(
                  color:
                      brandColor,
                  width: 3,
                ),
              ),

              contentPadding:
                  const EdgeInsets
                      .symmetric(
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORY DROPDOWN
  // ============================================================

  Widget _buildCategoryDropdown(
    String label,
    CategoryProvider provider,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 30.0,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ======================================================
          // CATEGORY LABEL
          // ======================================================

          Text(
            label,

            style:
                const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,

              // العنوان أسود
              color: Colors.black,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          DropdownButtonFormField<String>(
            value:
                provider.categories.any(
              (category) =>
                  category.id ==
                  _selectedCategoryId,
            )
                    ? _selectedCategoryId
                    : null,

            isExpanded: true,

            style:
                const TextStyle(
              color: Colors.black,
              fontWeight:
                  FontWeight.w600,
              fontSize: 16,
            ),

            dropdownColor:
                Colors.black87,

            hint:
                Text(
              _tr('select_category'),

              style:
                  const TextStyle(
                color: Colors.grey,
              ),
            ),

            validator: (value) {
              if (value == null) {
                return _tr(
                  'required',
                );
              }

              return null;
            },

            items:
                provider.categories.map(
              (category) {
                return DropdownMenuItem<String>(
                  value:
                      category.id,

                  child:
                      Text(
                    category.name,

                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                    ),
                  ),
                );
              },
            ).toList(),

            onChanged: (value) {
              setState(() {
                _selectedCategoryId =
                    value;
              });
            },

            decoration:
                InputDecoration(
              isDense: true,

              enabledBorder:
                  UnderlineInputBorder(
                borderSide:
                    BorderSide(
                  color:
                      brandColor,
                  width: 2,
                ),
              ),

              focusedBorder:
                  UnderlineInputBorder(
                borderSide:
                    BorderSide(
                  color:
                      brandColor,
                  width: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _buildDescriptionField(
    String label,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        // ======================================================
        // DESCRIPTION LABEL ONLY
        // ======================================================

        Text(
          label,

          style:
              const TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.bold,

            // العنوان أسود
            color: Colors.black,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        Container(
          decoration:
              BoxDecoration(
            color:
                Colors.white,

            borderRadius:
                BorderRadius.circular(
              12,
            ),

            border:
                Border.all(
              color:
                  brandColor,
              width: 1.5,
            ),
          ),

          child: TextField(
            controller:
                controller,

            maxLines: 4,

            // لم يتم تغيير لون النص داخل TextField
            style:
                const TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w500,
            ),

            decoration:
                InputDecoration(
              contentPadding:
                  const EdgeInsets.all(
                15,
              ),

              border:
                  InputBorder.none,

              hintText:
                  _tr(
                'enter_product_details',
              ),

              hintStyle:
                  const TextStyle(
                color:
                    Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
