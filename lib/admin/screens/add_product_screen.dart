import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:premium_store/core/models/product_model.dart';
import 'package:premium_store/core/models/category_model.dart';
import 'package:premium_store/core/services/cloudinary_service.dart';
import 'package:premium_store/core/services/firebase_service.dart';
import 'package:provider/provider.dart';
import '../../state/category_provider.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;

  String? _selectedCategoryId;
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? "");
    _priceController =
        TextEditingController(text: widget.product?.price.toString() ?? "");
    _descController =
        TextEditingController(text: widget.product?.description ?? "");
    _selectedCategoryId = widget.product?.categoryId;
    _imageUrl = widget.product?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (file != null) {
      setState(() => _isUploading = true);
      final bytes = await file.readAsBytes();

      final url = await CloudinaryService.uploadImage(
        bytes,
        file.name,
        "restaurant/products",
      );

      setState(() {
        _imageUrl = url;
        _isUploading = false;
      });
    }
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload a product image first")),
        );
        return;
      }

      final productData = {
        'name': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'description': _descController.text.trim(),
        'categoryId': _selectedCategoryId,
        'imageUrl': _imageUrl,
        'isAvailable': widget.product?.isAvailable ?? true,
        'updatedAt': DateTime.now(),
      };

      try {
        if (widget.product == null) {
          productData['createdAt'] = DateTime.now();
          await FirebaseService.products.add(productData);
        } else {
          await FirebaseService.products
              .doc(widget.product!.id)
              .update(productData);
        }

        if (mounted) Navigator.pop(context);
      } catch (e) {
        debugPrint("Error saving product: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final bool isEdit = widget.product != null;
    final size = MediaQuery.of(context).size;
    // تحديد ما إذا كانت الشاشة موبايل أم كمبيوتر
    final bool isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 40.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon:
                    const Icon(Icons.arrow_back, size: 16, color: Colors.grey),
                label: const Text("Back Home",
                    style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 10),
              Text(
                isEdit ? "Edit Product" : "Inventory Management",
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(isDesktop ? 40 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 20)
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
                            Expanded(
                                flex: 1, child: _buildImagePickerSection()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildImagePickerSection(),
                            const SizedBox(height: 30),
                            _buildFormFields(
                                isEdit, categoryProvider, isDesktop),
                          ],
                        ),
                ),
              ),
            ],
          ),
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
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        _buildTextField("Item name :", _nameController),
        _buildCategoryDropdown("Category :", provider),
        _buildTextField("Price :", _priceController, isNumber: true),
        _buildDescriptionField("Description", _descController),
        const SizedBox(height: 30),
        SizedBox(
          width: isDesktop ? 150 : double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _saveProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B686),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isEdit ? "Update" : "Upload",
              style: const TextStyle(color: Colors.white, fontSize: 18),
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
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE9ECEF),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: _isUploading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00B686)))
                : _imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(_imageUrl!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("Upload Product Image",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Tap to change product image",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: LayoutBuilder(builder: (context, constraints) {
        // إذا كانت المساحة صغيرة جداً نجعل الليبل فوق التكست فيلد
        bool stackLabel = constraints.maxWidth < 400;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stackLabel) ...[
              Text(label, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                if (!stackLabel)
                  SizedBox(
                      width: 100,
                      child: Text(label, style: const TextStyle(fontSize: 16))),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType:
                        isNumber ? TextInputType.number : TextInputType.text,
                    validator: (v) => v!.isEmpty ? "Required" : null,
                    decoration: const InputDecoration(
                      isDense: true,
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00B686))),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCategoryDropdown(String label, CategoryProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: LayoutBuilder(builder: (context, constraints) {
        bool stackLabel = constraints.maxWidth < 400;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stackLabel) ...[
              Text(label, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                if (!stackLabel)
                  SizedBox(
                      width: 100,
                      child: Text(label, style: const TextStyle(fontSize: 16))),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    isExpanded: true, // يمنع خروج النص عن الحواف
                    hint: const Text("Select Category"),
                    validator: (v) => v == null ? "Required" : null,
                    items: provider.categories.map<DropdownMenuItem<String>>(
                        (CategoryModel category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name,
                            overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategoryId = val),
                    decoration: const InputDecoration(
                      isDense: true,
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDescriptionField(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(15),
              border: InputBorder.none,
              hintText: "Enter product details...",
            ),
          ),
        ),
      ],
    );
  }
}
