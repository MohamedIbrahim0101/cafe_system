import 'package:flutter/material.dart';
import 'package:premium_store/state/inventory_provider.dart';
import 'package:provider/provider.dart';

class StockControlScreen extends StatefulWidget {
  const StockControlScreen({super.key});

  @override
  State<StockControlScreen> createState() => _StockControlScreenState();
}

class _StockControlScreenState extends State<StockControlScreen> {
  final Color primaryGreen = const Color(0xFF00B686);
  final Color warningOrange = const Color(0xFFFF9800);
  final Color dangerRed = const Color(0xFFE53935);
  final Color backgroundColor = const Color(0xFFF8F9FA);

  final _reduceFormKey = GlobalKey<FormState>();
  final _reduceAmountController = TextEditingController();

  @override
  void dispose() {
    _reduceAmountController.dispose();
    super.dispose();
  }

  // نافذة منبثقة تطلب من المستخدم إدخال الرقم الذي يريد نقصه يدوياً
  void _showReduceStockDialog(
      SupplierInvoice invoice, InventoryProvider provider) {
    _reduceAmountController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.remove_circle_outline_rounded, color: dangerRed),
              const SizedBox(width: 10),
              const Text("تسجيل استهلاك / نقص مخزن",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Form(
            key: _reduceFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("المنتج: ${invoice.productName}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                    "المتاح الحالي: ${invoice.remainingQuantity} ${invoice.unit}",
                    style: TextStyle(color: primaryGreen)),
                const Divider(height: 20),
                TextFormField(
                  controller: _reduceAmountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return "يرجى تحديد كمية الخصم";
                    final numValue = double.tryParse(value);
                    if (numValue == null || numValue <= 0)
                      return "أدخل رقماً صحيحاً أكبر من الصفر";
                    if (numValue > invoice.remainingQuantity)
                      return "الكمية أكبر من المتاح بالمخزن!";
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "الكمية المستهلكة (التي نقصت)",
                    suffixText: invoice.unit,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: dangerRed, width: 2)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text("إلغاء", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: dangerRed,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                if (_reduceFormKey.currentState!.validate()) {
                  // حوار انتظار التحميل
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          const Center(child: CircularProgressIndicator()));

                  try {
                    double amount =
                        double.parse(_reduceAmountController.text.trim());
                    await provider.reduceStockQuantity(invoice.id, amount);

                    if (mounted) {
                      Navigator.pop(context); // إغلاق التحميل
                      Navigator.pop(context); // إغلاق الديالوج
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('تم تحديث نقص المخزن واحتساب المتبقي.'),
                            backgroundColor: Colors.black),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('خطأ: $e'),
                          backgroundColor: Colors.red));
                    }
                  }
                }
              },
              child: const Text("تأكيد الخصم",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
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
          title: const Text("مراقبة كميات ونقص المخازن الفعلي",
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
        ),
        body: Consumer<InventoryProvider>(
          builder: (context, inventoryProvider, child) {
            if (inventoryProvider.isLoading)
              return const Center(child: CircularProgressIndicator());
            if (inventoryProvider.invoices.isEmpty)
              return const Center(
                  child: Text("لا توجد بضائع مشتراة لمراقبتها حالياً."));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: inventoryProvider.invoices.length,
              itemBuilder: (context, index) {
                final item = inventoryProvider.invoices[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: item.isOutOffStock
                          ? dangerRed.withOpacity(0.4)
                          : item.isRunningOut
                              ? warningOrange.withOpacity(0.4)
                              : Colors.grey.withOpacity(0.15),
                      width: (item.isRunningOut || item.isOutOffStock) ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // الجزء العلوي: الرسائل التحذيرية التلقائية بناءً على قربها من الصفر
                        if (item.isOutOffStock)
                          _buildStatusAlert(
                              Icons.dangerous_rounded,
                              "لقد نفدت هذه السلعة تماماً من المخزن (0)!",
                              dangerRed)
                        else if (item.isRunningOut)
                          _buildStatusAlert(
                              Icons.warning_amber_rounded,
                              "انتبه! هذا المنتج قارب على النفاد والوصول للصفر!",
                              warningOrange),

                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: item.isOutOffStock
                                      ? dangerRed.withOpacity(0.1)
                                      : primaryGreen.withOpacity(0.1),
                                  shape: BoxShape.circle),
                              child: Icon(Icons.inventory_2_outlined,
                                  color: item.isOutOffStock
                                      ? dangerRed
                                      : primaryGreen),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text("المورد: ${item.supplierName}",
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${item.remainingQuantity} / ${item.quantity} ${item.unit}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: item.isOutOffStock
                                              ? dangerRed
                                              : (item.isRunningOut
                                                  ? warningOrange
                                                  : Colors.black),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text("المتبقي الفعلي بالمخزن",
                                          style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 11)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // شريط التقدم المرئي يوضح النسبة المتبقية
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: item.quantity > 0
                                ? (item.remainingQuantity / item.quantity)
                                : 0,
                            backgroundColor: Colors.grey[200],
                            color: item.isOutOffStock
                                ? dangerRed
                                : (item.isRunningOut
                                    ? warningOrange
                                    : primaryGreen),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // زر التحكم اليدوي لنقص كمية معينة وتطبيق عملية الطرح والخصم
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                "تم استهلاك: ${item.consumedQuantity} ${item.unit}",
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13)),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: item.isOutOffStock
                                    ? Colors.grey
                                    : dangerRed.withOpacity(0.9),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              onPressed: item.isOutOffStock
                                  ? null
                                  : () => _showReduceStockDialog(
                                      item, inventoryProvider),
                              icon: const Icon(Icons.trending_down_rounded,
                                  color: Colors.white, size: 18),
                              label: const Text("تسجيل استهلاك يدوي",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // بناء واجهة التنبيهات العلوية بداخل الكارد
  Widget _buildStatusAlert(IconData icon, String message, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))),
        ],
      ),
    );
  }
}
