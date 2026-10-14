
import 'package:flutter/material.dart';
import 'package:premium_store/core/models/restaurant_model.dart'
    hide Restaurant;
import 'package:premium_store/state/super_admin_provider.dart';
import 'package:premium_store/super_admin/screens/add_restaurant_screen.dart';
import 'package:provider/provider.dart';

class RestaurantsListScreen extends StatelessWidget {
  const RestaurantsListScreen({super.key});

  final Color primaryColor = const Color(0xFF6200EE);
  final Color backgroundColor = const Color(0xFFF8F9FA);

  // نافذة تعديل اسم المطعم وعنوانه
  Future<void> _showEditRestaurantDialog(
    BuildContext context,
    Restaurant restaurant,
    SuperAdminProvider provider,
  ) async {
    final nameController = TextEditingController(text: restaurant.name);
    final locationController =
        TextEditingController(text: restaurant.location);

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: const Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        color: Color(0xFF6200EE),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'تعديل بيانات المطعم',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: nameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'اسم المطعم',
                              hintText: 'اكتب اسم المطعم',
                              prefixIcon:
                                  const Icon(Icons.storefront_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6200EE),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'من فضلك أدخل اسم المطعم';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: locationController,
                            maxLines: 2,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'عنوان المطعم',
                              hintText: 'اكتب عنوان المطعم والفرع',
                              prefixIcon:
                                  const Icon(Icons.location_on_outlined),
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6200EE),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'من فضلك أدخل عنوان المطعم';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('إلغاء'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }

                                    setDialogState(() {
                                      isSaving = true;
                                    });

                                    try {
                                      await provider.updateRestaurantDetails(
                                        restaurantId: restaurant.id,
                                        name: nameController.text,
                                        location: locationController.text,
                                      );

                                      if (!dialogContext.mounted) return;

                                      Navigator.pop(dialogContext);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'تم تعديل اسم المطعم وعنوانه بنجاح',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                      }
                                    } catch (e) {
                                      if (!dialogContext.mounted) return;

                                      setDialogState(() {
                                        isSaving = false;
                                      });

                                      ScaffoldMessenger.of(dialogContext)
                                        ..hideCurrentSnackBar()
                                        ..showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'فشل حفظ التعديلات: $e',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                    }
                                  },
                            icon: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.save_rounded,
                                    size: 19,
                                  ),
                            label: Text(isSaving ? 'جاري الحفظ' : 'حفظ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  primaryColor.withOpacity(0.6),
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    } finally {
      nameController.dispose();
      locationController.dispose();
    }
  }

  // نافذة تفاصيل المطعم والتحكم في الاشتراك
  void _showRestaurantDetailsDialog(
    BuildContext context,
    Restaurant restaurant,
    SuperAdminProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (restaurant.isActive
                                  ? Colors.green
                                  : Colors.red)
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          color: restaurant.isActive
                              ? Colors.green
                              : Colors.red,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              restaurant.isActive
                                  ? 'الاشتراك نشط وعامل'
                                  : 'الاشتراك معطل وموقوف',
                              style: TextStyle(
                                color: restaurant.isActive
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 30),

                  _buildDetailTile(
                    Icons.alternate_email_rounded,
                    'حساب المدير (الإيميل)',
                    restaurant.adminEmail,
                  ),
                  _buildDetailTile(
                    Icons.lock_outline_rounded,
                    'كلمة المرور',
                    restaurant.adminPassword,
                  ),
                  _buildDetailTile(
                    Icons.phone_outlined,
                    'رقم التواصل',
                    restaurant.phoneNumber,
                  ),
                  _buildDetailTile(
                    Icons.location_on_outlined,
                    'العنوان والفرع',
                    restaurant.location,
                  ),
                  _buildDetailTile(
                    Icons.qr_code_rounded,
                    'معرف المطعم (ID)',
                    restaurant.id,
                    isCode: true,
                  ),
                  _buildDetailTile(
                    Icons.calendar_today_outlined,
                    'تاريخ الإضافة',
                    '${restaurant.createdAt.day}/'
                        '${restaurant.createdAt.month}/'
                        '${restaurant.createdAt.year}',
                  ),

                  const SizedBox(height: 24),

                  // زر تعديل الاسم والعنوان
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(
                          color: Color(0xFF6200EE),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);

                        _showEditRestaurantDialog(
                          context,
                          restaurant,
                          provider,
                        );
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text(
                        'تعديل اسم المطعم والعنوان',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // زر تفعيل أو إيقاف الاشتراك
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: restaurant.isActive
                            ? Colors.red[600]
                            : Colors.green[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final currentId = restaurant.id;
                        final currentUid = restaurant.adminUid;
                        final currentStatus = restaurant.isActive;

                        Navigator.pop(sheetContext);

                        try {
                          await provider.toggleRestaurantStatus(
                            currentId,
                            currentUid,
                            currentStatus,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  currentStatus
                                      ? 'تم إيقاف اشتراك المطعم وحظره بنجاح'
                                      : 'تم تفعيل اشتراك المطعم بنجاح',
                                ),
                                backgroundColor: currentStatus
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('حدث خطأ: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(
                        restaurant.isActive
                            ? Icons.block_rounded
                            : Icons.check_circle_outline_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        restaurant.isActive
                            ? 'تجميد / إيقاف الاشتراك'
                            : 'تفعيل وإعادة الاشتراك',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text(
            'إدارة المطاعم والاشتراكات',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: Consumer<SuperAdminProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.restaurants.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (provider.restaurants.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 70,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد مطاعم مسجلة حالياً',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.restaurants.length,
              itemBuilder: (context, index) {
                final item = provider.restaurants[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: item.isActive
                          ? Colors.grey.withOpacity(0.2)
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showRestaurantDetailsDialog(
                      context,
                      item,
                      provider,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (item.isActive
                                      ? primaryColor
                                      : Colors.red)
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.restaurant_rounded,
                              color: item.isActive
                                  ? primaryColor
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item.location,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (item.isActive
                                      ? Colors.green
                                      : Colors.red)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.isActive ? 'نشط' : 'موقوف',
                              style: TextStyle(
                                color: item.isActive
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: primaryColor,
          elevation: 2,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddRestaurantScreen(),
              ),
            );
          },
          icon: const Icon(
            Icons.add_business_rounded,
            color: Colors.white,
          ),
          label: const Text(
            'إضافة مطعم جديد',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(
    IconData icon,
    String title,
    String value, {
    bool isCode = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                    fontFamily: isCode ? 'Courier' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
