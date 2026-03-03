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
    final authProvider = context.watch<AuthProvider>();

    // تحديد إذا كانت الشاشة موبايل (أصغر من 900 بكسل)
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      key: _scaffoldKey, // المفتاح لفتح الـ Drawer برمجياً
      backgroundColor: const Color(0xFFF8F9FA),

      // السايد بار يظهر كـ Drawer فقط في الموبايل
      drawer:
          isMobile ? Drawer(child: _buildSidebar(context, authProvider)) : null,

      body: Row(
        children: [
          // السايد بار يظهر ثابت فقط في شاشات الكمبيوتر
          if (!isMobile) _buildSidebar(context, authProvider),

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

  // الهيدر المحتوي على زر الـ Hamburger Menu للموبايل
  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Row(
      children: [
        if (isMobile)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              // أيقونة المنيو (التي سألت عنها)
              icon:
                  const Icon(Icons.menu_rounded, size: 28, color: Colors.black),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
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

  Widget _buildCategoryGrid(CategoryProvider provider, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 5;
        } else if (constraints.maxWidth > 850) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth < 450) {
          crossAxisCount = 1;
        }

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

  // ميثود القائمة الجانبية (Sidebar)
  Widget _buildSidebar(BuildContext context, AuthProvider authProvider) {
    final String location = GoRouterState.of(context).uri.toString();

    return Container(
      width: 260,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text("Romdol.",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B686))),
          ),
          Expanded(
            child: Column(
              children: [
                _sidebarItem(
                    context,
                    authProvider,
                    Icons.grid_view_rounded,
                    "Dashboard",
                    "/admin/dashboard",
                    location.contains("dashboard")),
                _sidebarItem(context, authProvider, Icons.shopping_bag_outlined,
                    "Orders", "/admin/orders", location.contains("orders")),
                _sidebarItem(
                    context,
                    authProvider,
                    Icons.fastfood_outlined,
                    "Products",
                    "/admin/products",
                    location.contains("products")),
                _sidebarItem(
                    context,
                    authProvider,
                    Icons.category_rounded,
                    "Categories",
                    "/admin/categories",
                    location.contains("categories")),
              ],
            ),
          ),
          const Divider(indent: 20, endIndent: 20),
          _sidebarItem(context, authProvider, Icons.logout_rounded, "Logout",
              "/admin/login", false,
              isLogout: true),
          const SizedBox(height: 20),
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
            if (mounted) context.go(route);
          } else {
            // إغلاق المنيو في الموبايل عند اختيار صفحة
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.pop(context);
            }
            context.go(route);
          }
        },
        leading: Icon(icon,
            color: isActive ? const Color(0xFF00B686) : Colors.grey[400],
            size: 22),
        title: Text(label,
            style: TextStyle(
                color: isActive ? const Color(0xFF00B686) : Colors.grey[700],
                fontSize: 15,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
        tileColor: isActive
            ? const Color(0xFF00B686).withOpacity(0.08)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
      ),
    );
  }

  // --- دوال العمليات (Dialog & Delete) ---

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
                          ? const Center(child: CircularProgressIndicator())
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
                        border: OutlineInputBorder()),
                  ),
                ],
              ),
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

  void _confirmDelete(CategoryModel category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Category"),
        content: Text("Delete '${category.name}'?"),
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
