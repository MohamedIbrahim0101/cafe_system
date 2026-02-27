import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../state/category_provider.dart';
import '../../state/auth_brovider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/models/category_model.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _nameController = TextEditingController();
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
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          _buildSidebar(context, authProvider),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  Expanded(
                    child: categoryProvider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF00B686)))
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              // حساب عدد الأعمدة بناءً على المساحة المتاحة
                              int crossAxisCount = constraints.maxWidth > 1200
                                  ? 5
                                  : constraints.maxWidth > 800
                                      ? 3
                                      : 2;
                              return GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 0.85,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                ),
                                itemCount: categoryProvider.categories.length,
                                itemBuilder: (context, index) {
                                  return _buildCategoryCard(
                                      categoryProvider.categories[index]);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Categories",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1E))),
            Text("Manage your menu categories and images",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showCategoryDialog(context, null),
          icon: const Icon(Icons.add),
          label: const Text("Add Category"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B686),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                shape: BoxShape.circle,
                image: category.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(category.imageUrl!),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: category.imageUrl == null
                  ? const Center(
                      child: Icon(Icons.category_outlined,
                          size: 30, color: Colors.grey))
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          // Name with protection against overflow
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(category.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 8),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: Colors.blueGrey),
                onPressed: () => _showCategoryDialog(context, category),
              ),
              const SizedBox(width: 12),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.redAccent),
                onPressed: () => _confirmDelete(category),
              ),
            ],
          )
        ],
      ),
    );
  }

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
          content: SizedBox(
            width: 400, // Fixed width for dialog on web/desktop
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
                        ? const Center(child: CircularProgressIndicator())
                        : _uploadedImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.network(_uploadedImageUrl!,
                                    fit: BoxFit.cover))
                            : const Icon(Icons.add_a_photo, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Category Name",
                    border: OutlineInputBorder(),
                    hintText: "e.g. Burgers, Pizza...",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: _isUploading
                  ? null
                  : () async {
                      if (_nameController.text.isNotEmpty) {
                        final data = {
                          'name': _nameController.text,
                          'imageUrl': _uploadedImageUrl,
                          'updatedAt': DateTime.now(),
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
              child: const Text("Save Category"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(CategoryModel category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Category"),
        content: Text("Delete '${category.name}'? This cannot be undone."),
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

  Widget _buildSidebar(BuildContext context, AuthProvider authProvider) {
    final String location = GoRouterState.of(context).uri.toString();
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text("Romdol.",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B686))),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _sidebarItem(
                      context,
                      authProvider,
                      Icons.grid_view_rounded,
                      "Dashboard",
                      "/admin/dashboard",
                      location == "/admin/dashboard"),
                  _sidebarItem(
                      context,
                      authProvider,
                      Icons.shopping_cart_outlined,
                      "Orders",
                      "/admin/orders",
                      location == "/admin/orders"),
                  _sidebarItem(
                      context,
                      authProvider,
                      Icons.fastfood_outlined,
                      "Products",
                      "/admin/products",
                      location == "/admin/products"),
                  _sidebarItem(
                      context,
                      authProvider,
                      Icons.category_outlined,
                      "Categories",
                      "/admin/categories",
                      location == "/admin/categories"),
                ],
              ),
            ),
          ),
          const Divider(),
          _sidebarItem(context, authProvider, Icons.logout_rounded, "Logout",
              "/admin/login", false,
              isLogout: true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, AuthProvider authProvider,
      IconData icon, String label, String route, bool isActive,
      {bool isLogout = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () async {
          if (isLogout) {
            await authProvider.logout();
            if (context.mounted) context.go(route);
          } else {
            context.go(route);
          }
        },
        leading: Icon(icon,
            color: isActive ? const Color(0xFF00B686) : Colors.grey[400],
            size: 20),
        title: Text(label,
            style: TextStyle(
                color: isActive ? Colors.black : Colors.grey[600],
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        tileColor: isActive
            ? const Color(0xFF00B686).withOpacity(0.08)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
      ),
    );
  }
}
