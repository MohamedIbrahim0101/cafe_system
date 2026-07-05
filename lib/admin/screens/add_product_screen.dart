import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:premium_store/app/sidebar.dart';
import 'package:premium_store/core/models/product_model.dart';
import 'package:premium_store/core/services/cloudinary_service.dart';
import 'package:premium_store/core/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../state/category_provider.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  
  // Controllers for sizes
  late TextEditingController _smallPriceController;
  late TextEditingController _mediumPriceController;
  late TextEditingController _largePriceController;

  String? _selectedCategoryId;
  String? _imageUrl;
  bool _isUploading = false;
  bool _hasSizes = false; // متغير للتحكم في ظهور الأحجام

  // اللون الموحد للبراند
  final Color brandColor = const Color(0xFF00B686);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? "");
    _priceController =
        TextEditingController(text: widget.product?.price.toString() ?? "");
    _descController =
        TextEditingController(text: widget.product?.description ?? "");
    
    // استرجاع حالة الأحجام إذا كنا في وضع التعديل
    _hasSizes = widget.product?.hasSizes ?? false;
    
    // استرجاع أسعار الأحجام إذا كانت موجودة
    _smallPriceController = TextEditingController(
        text: widget.product?.sizes?['Small']?.toString() ?? "");
    _mediumPriceController = TextEditingController(
        text: widget.product?.sizes?['Medium']?.toString() ?? "");
    _largePriceController = TextEditingController(
        text: widget.product?.sizes?['Large']?.toString() ?? "");

    _selectedCategoryId = widget.product?.categoryId;
    _imageUrl = widget.product?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _smallPriceController.dispose();
    _mediumPriceController.dispose();
    _largePriceController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (file != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await file.readAsBytes();
        final url = await CloudinaryService.uploadImage(
            bytes, file.name, "restaurant/products");
        if (mounted) {
          setState(() {
            _imageUrl = url;
            _isUploading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isUploading = false);
        debugPrint("Upload failed: $e");
      }
    }
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please upload a product image first",
                  style: TextStyle(color: Colors.white))),
        );
        return;
      }

      // إظهار مؤشر تحميل أثناء الحفظ
      setState(() => _isUploading = true);

      // تجهيز البيانات الأساسية
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'categoryId': _selectedCategoryId,
        'imageUrl': _imageUrl,
        'isAvailable': widget.product?.isAvailable ?? true,
        'updatedAt': DateTime.now(),
        'hasSizes': _hasSizes, // حفظ حالة الأحجام
      };

      // التحقق من الأسعار بناءً على حالة الأحجام
      if (_hasSizes) {
        productData['price'] = 0.0; // السعر الافتراضي لأن الاعتماد هيكون على الأحجام
        productData['sizes'] = {
          'Small': double.tryParse(_smallPriceController.text) ?? 0.0,
          'Medium': double.tryParse(_mediumPriceController.text) ?? 0.0,
          'Large': double.tryParse(_largePriceController.text) ?? 0.0,
        };
      } else {
        productData['price'] = double.tryParse(_priceController.text) ?? 0.0;
        productData['sizes'] = {}; // تفريغ الأحجام لو مفيش
      }

      try {
        if (widget.product == null) {
          productData['createdAt'] = DateTime.now();
          await FirebaseService.products.add(productData);
        } else {
          await FirebaseService.products
              .doc(widget.product!.id)
              .update(productData);
        }

        if (mounted) {
          setState(() => _isUploading = false);
          // رسالة النجاح والانتظار
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
              content: const Text("Product saved successfully!", textAlign: TextAlign.center),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/admin/products');
                  },
                  child: const Text("Done"),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) setState(() => _isUploading = false);
        debugPrint("Error saving product: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final bool isEdit = widget.product != null;
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 1100;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: !isDesktop ? const Drawer(child: AdminSidebar()) : null,
      body: Row(
        children: [
          if (isDesktop) const SizedBox(width: 260, child: AdminSidebar()),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 40.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(isDesktop, isEdit),
                    const SizedBox(height: 20),
                    _buildMainForm(isDesktop, isEdit, categoryProvider),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDesktop, bool isEdit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (!isDesktop)
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.black),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            TextButton.icon(
              onPressed: () => context.go('/admin/products'),
              icon: const Icon(Icons.arrow_back, size: 16, color: Colors.black),
              label: const Text("Back to Products",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            isEdit ? "Edit Product" : "Inventory Management",
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildMainForm(
      bool isDesktop, bool isEdit, CategoryProvider categoryProvider) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 40 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)
        ],
      ),
      child: Form(
        key: _formKey,
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 2,
                      child: _buildFormFields(
                          isEdit, categoryProvider, isDesktop)),
                  const SizedBox(width: 50),
                  Expanded(flex: 1, child: _buildImagePickerSection()),
                ],
              )
            : Column(
                children: [
                  _buildImagePickerSection(),
                  const SizedBox(height: 30),
                  _buildFormFields(isEdit, categoryProvider, isDesktop),
                ],
              ),
      ),
    );
  }

  Widget _buildFormFields(
      bool isEdit, CategoryProvider provider, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEdit ? "Modify Item Details" : "Add New Inventory",
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 30),
        _buildTextField("Item name :", _nameController),
        _buildCategoryDropdown("Category :", provider),
        
        // --- إضافة التحكم في الأحجام ---
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Product has multiple sizes?",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              Switch(
                value: _hasSizes,
                activeColor: brandColor,
                onChanged: (val) {
                  setState(() {
                    _hasSizes = val;
                  });
                },
              ),
            ],
          ),
        ),

        // عرض خانات السعر بناءً على اختيار الأحجام
        if (!_hasSizes)
          _buildTextField("Price :", _priceController, isNumber: true)
        else ...[
          _buildTextField("Small Size Price :", _smallPriceController, isNumber: true),
          _buildTextField("Medium Size Price :", _mediumPriceController, isNumber: true),
          _buildTextField("Large Size Price :", _largePriceController, isNumber: true),
        ],
        // -----------------------------

        _buildDescriptionField("Description :", _descController),
        const SizedBox(height: 40),
        SizedBox(
          width: isDesktop ? 180 : double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isUploading ? null : _saveProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: brandColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isUploading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
              isEdit ? "Update" : "Upload",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickAndUploadImage,
          child: Container(
            height: 320,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: brandColor, width: 1.5),
            ),
            child: _isUploading
                ? Center(child: CircularProgressIndicator(color: brandColor))
                : _imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.network(_imageUrl!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              size: 65, color: brandColor),
                          const SizedBox(height: 12),
                          const Text("Upload Product Image",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
          ),
        ),
        const SizedBox(height: 12),
        const Text("Tap to change product image",
            style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            validator: (v) => v!.isEmpty ? "This field is required" : null,
            decoration: InputDecoration(
              isDense: true,
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: brandColor, width: 2)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: brandColor, width: 3)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(String label, CategoryProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            isExpanded: true,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.w600, fontSize: 16),
            dropdownColor: Colors.white,
            hint: const Text("Select Category",
                style: TextStyle(color: Colors.grey)),
            validator: (v) => v == null ? "Required" : null,
            items: provider.categories.map((category) {
              return DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name,
                      style: const TextStyle(color: Colors.black)));
            }).toList(),
            onChanged: (val) => setState(() => _selectedCategoryId = val),
            decoration: InputDecoration(
              isDense: true,
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: brandColor, width: 2)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: brandColor, width: 3)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: brandColor, width: 1.5)),
          child: TextField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(15),
                border: InputBorder.none,
                hintText: "Enter product details...",
                hintStyle: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }
}