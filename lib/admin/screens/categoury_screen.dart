import 'package:flutter/material.dart';
import 'package:premium_store/app/sidebar.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

// Localization
import 'package:premium_store/localization/app_translations.dart';
import 'package:premium_store/state/language_provider.dart';

// استدعاء المكونات والخدمات
import '../../state/category_provider.dart';
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

  // ============================================================
  // Translation helper
  // ============================================================

  String _tr(String key) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return AppTranslations.get(
      languageProvider.locale.languageCode,
      key,
    );
  }

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

      drawer: isMobile
          ? const Drawer(
              child: AdminSidebar(),
            )
          : null,

      body: Row(
        children: [
          // Sidebar for desktop
          if (!isMobile) const AdminSidebar(),

          Expanded(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 32,
                  vertical: isMobile ? 16 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(context, isMobile),

                    const SizedBox(height: 32),

                    // Categories
                    Expanded(
                      child: categoryProvider.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF00B686),
                              ),
                            )
                          : _buildCategoryGrid(
                              categoryProvider,
                              isMobile,
                            ),
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
  // Header
  // ============================================================

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Row(
      children: [
        // Mobile menu button
        if (isMobile)
          IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              size: 28,
              color: Colors.black,
            ),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page title
              Text(
                _tr('categories'),
                style: TextStyle(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1C1E),
                ),
              ),

              // Page description
              if (!isMobile)
                Text(
                  _tr('manage_menu_categories_and_images'),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),

        // Add category button
        ElevatedButton.icon(
          onPressed: () {
            _showCategoryDialog(context, null);
          },
          icon: const Icon(
            Icons.add_rounded,
            size: 20,
          ),
          label: Text(
            isMobile
                ? _tr('add')
                : _tr('add_category'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B686),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 15 : 20,
              vertical: isMobile ? 12 : 18,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Categories Grid
  // ============================================================

  Widget _buildCategoryGrid(
    CategoryProvider provider,
    bool isMobile,
  ) {
    // No categories
    if (provider.categories.isEmpty) {
      return Center(
        child: Text(
          _tr('no_categories_added_yet'),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

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
          itemBuilder: (context, index) {
            return _buildCategoryCard(
              provider.categories[index],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // Category Card
  // ============================================================

  Widget _buildCategoryCard(CategoryModel category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category image
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  shape: BoxShape.circle,

                  image: category.imageUrl != null &&
                          category.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(
                            category.imageUrl!,
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),

                // Default category icon
                child: category.imageUrl == null ||
                        category.imageUrl!.isEmpty
                    ? const Icon(
                        Icons.category_rounded,
                        size: 40,
                        color: Colors.grey,
                      )
                    : null,
              ),
            ),
          ),

          // Category name
          Text(
            category.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          // Edit & Delete buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Edit
              IconButton(
                icon: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.blueGrey,
                ),
                onPressed: () {
                  _showCategoryDialog(
                    context,
                    category,
                  );
                },
              ),

              // Delete
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                onPressed: () {
                  _confirmDelete(category);
                },
              ),
            ],
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ============================================================
  // Add / Edit Category Dialog
  // ============================================================

  void _showCategoryDialog(
    BuildContext context,
    CategoryModel? category,
  ) {
    final bool isEdit = category != null;

    // Fill existing data when editing
    _nameController.text = isEdit ? category.name : "";
    _uploadedImageUrl = isEdit ? category.imageUrl : null;

    // Reset upload state
    _isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          // Dialog title
          title: Text(
            isEdit
                ? _tr('edit_category')
                : _tr('add_new_category'),
          ),

          content: SingleChildScrollView(
            child: SizedBox(
              width: 350,

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ==================================================
                  // Category Image
                  // ==================================================

                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();

                      final file = await picker.pickImage(
                        source: ImageSource.gallery,
                      );

                      if (file != null) {
                        setDialogState(() {
                          _isUploading = true;
                        });

                        try {
                          final bytes = await file.readAsBytes();

                          final url =
                              await CloudinaryService.uploadImage(
                            bytes,
                            file.name,
                            "categories",
                          );

                          setDialogState(() {
                            _uploadedImageUrl = url;
                            _isUploading = false;
                          });
                        } catch (e) {
                          setDialogState(() {
                            _isUploading = false;
                          });

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "${_tr('failed_to_upload_image')}: $e",
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },

                    child: Container(
                      height: 100,
                      width: 100,

                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[300]!,
                        ),
                      ),

                      child: _isUploading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF00B686),
                              ),
                            )

                          : _uploadedImageUrl != null &&
                                  _uploadedImageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(50),
                                  child: Image.network(
                                    _uploadedImageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )

                              : const Icon(
                                  Icons.add_a_photo,
                                  color: Colors.grey,
                                ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // Category Name
                  // ==================================================

                  TextField(
                    controller: _nameController,

                    decoration: InputDecoration(
                      labelText: _tr('category_name'),

                      border: const OutlineInputBorder(),

                      focusedBorder:
                          const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF00B686),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ========================================================
          // Dialog Actions
          // ========================================================

          actions: [
            // Cancel
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text(
                _tr('cancel'),
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),

            // Save
            ElevatedButton(
              onPressed: _isUploading
                  ? null
                  : () async {
                      final name =
                          _nameController.text.trim();

                      // Don't save empty name
                      if (name.isNotEmpty) {
                        try {
                          final provider =
                              Provider.of<CategoryProvider>(
                            context,
                            listen: false,
                          );

                          // ========================================
                          // Edit existing category
                          // ========================================

                          if (isEdit) {
                            // تأكد من تمرير رابط الصورة المحدث
                            await provider.updateCategory(
                              category.id,
                              name,
                              imageUrl: _uploadedImageUrl,
                            );
                          }

                          // ========================================
                          // Add new category
                          // ========================================

                          else {
                            // تأكد من تمرير رابط الصورة عند الإضافة
                            await provider.addCategory(
                              name,
                              imageUrl: _uploadedImageUrl,
                            );
                          }

                          // Close dialog
                          if (mounted) {
                            Navigator.pop(ctx);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  "${_tr('error_saving_category')}: $e",
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B686),
                foregroundColor: Colors.white,
              ),

              child: Text(
                _tr('save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Delete Confirmation
  // ============================================================

  void _confirmDelete(CategoryModel category) {
    showDialog(
      context: context,

      builder: (ctx) => AlertDialog(
        // Dialog title
        title: Text(
          _tr('delete_category'),
        ),

        // Confirmation message
        content: Text(
          "${_tr('are_you_sure_delete_category')} "
          "'${category.name}'?",
        ),

        actions: [
          // Cancel
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: Text(
              _tr('cancel'),
            ),
          ),

          // Delete
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),

            onPressed: () async {
              try {
                await Provider.of<CategoryProvider>(
                  context,
                  listen: false,
                ).deleteCategory(
                  category.id,
                );

                if (mounted) {
                  Navigator.pop(ctx);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "${_tr('error_deleting_category')}: $e",
                      ),
                    ),
                  );
                }
              }
            },

            child: Text(
              _tr('delete'),
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}