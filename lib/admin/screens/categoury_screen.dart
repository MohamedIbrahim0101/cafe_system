import 'package:flutter/material.dart';
import 'package:premium_store/app/sidebar.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

// استدعاء المكونات والخدمات
import '../../state/category_provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/models/category_model.dart';
// استدعاء السايد بار الموحد

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _nameController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isUploading = false;
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final bool isMobile = MediaQuery.of(context).size.width < 1100;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      // الدرور يظهر فقط في الشاشات الصغيرة ويستخدم السايد بار الموحد
      drawer: isMobile ? const Drawer(child: AdminSidebar()) : null,
      body: Row(
        children: [
          // السايد بار ثابت في الشاشات الكبيرة
          if (!isMobile) const AdminSidebar(),

          Expanded(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 32,
                    vertical: isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, isMobile),
                    const SizedBox(height: 32),
                    Expanded(
                      child: categoryProvider.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF00B686)))
                          : _buildCategoryGrid(categoryProvider, isMobile),
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

  // --- الهيدر (العنوان + زر الإضافة) ---
  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Row(
      children: [
        if (isMobile)
          IconButton(
            icon: const Icon(Icons.menu_rounded, size: 28, color: Colors.black),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Categories",
                style: TextStyle(
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1C1E)),
              ),
              if (!isMobile)
                const Text("Manage your menu categories and images",
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showCategoryDialog(context, null),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(isMobile ? "Add" : "Add Category"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B686),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 15 : 20, vertical: isMobile ? 12 : 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // --- شبكة التصنيفات (Responsive Grid) ---
  Widget _buildCategoryGrid(CategoryProvider provider, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1200
            ? 5
            : (constraints.maxWidth > 850
                ? 3
                : (constraints.maxWidth < 450 ? 1 : 2));

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: provider.categories.length,
          itemBuilder: (context, index) =>
              _buildCategoryCard(provider.categories[index]),
        );
      },
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  shape: BoxShape.circle,
                  image: category.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(category.imageUrl!),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: category.imageUrl == null
                    ? const Icon(Icons.category_rounded,
                        size: 40, color: Colors.grey)
                    : null,
              ),
            ),
          ),
          Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon:
                    const Icon(Icons.edit_note_rounded, color: Colors.blueGrey),
                onPressed: () => _showCategoryDialog(context, category),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                onPressed: () => _confirmDelete(category),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- ديالوج الإضافة والتعديل ---
  void _showCategoryDialog(BuildContext context, CategoryModel? category) {
    final bool isEdit = category != null;
    _nameController.text = isEdit ? category.name : "";
    _uploadedImageUrl = isEdit ? category.imageUrl : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? "Edit Category" : "Add New Category"),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final file =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (file != null) {
                        setDialogState(() => _isUploading = true);
                        final bytes = await file.readAsBytes();
                        final url = await CloudinaryService.uploadImage(
                            bytes, file.name, "categories");
                        setDialogState(() {
                          _uploadedImageUrl = url;
                          _isUploading = false;
                        });
                      }
                    },
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _isUploading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF00B686)))
                          : _uploadedImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.network(_uploadedImageUrl!,
                                      fit: BoxFit.cover))
                              : const Icon(Icons.add_a_photo,
                                  color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: "Category Name",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00B686)))),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text("Cancel", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: _isUploading
                  ? null
                  : () async {
                      if (_nameController.text.isNotEmpty) {
                        final data = {
                          'name': _nameController.text,
                          'imageUrl': _uploadedImageUrl,
                          'updatedAt': DateTime.now()
                        };
                        if (isEdit) {
                          await FirebaseService.categories
                              .doc(category.id)
                              .update(data);
                        } else {
                          await FirebaseService.categories
                              .add({...data, 'createdAt': DateTime.now()});
                        }
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B686),
                  foregroundColor: Colors.white),
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  // --- تأكيد الحذف ---
  void _confirmDelete(CategoryModel category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Category"),
        content: Text("Are you sure you want to delete '${category.name}'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseService.categories.doc(category.id).delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}