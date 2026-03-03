import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../state/order_provider.dart';
import '../../widgets/loading_widget.dart';

class OrderStatusScreen extends StatelessWidget {
  final String orderId;
  const OrderStatusScreen({super.key, required this.orderId});

  // 1. ميثود ذكية لتحديد الألوان (تم تحديثها لتدعم delivred)
  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('deliv') ||
        s.contains('done') ||
        s.contains('complet') ||
        s.contains('paid') ||
        s.contains('serve')) {
      return const Color(0xFF00B686); // اللون الأخضر للحالات المنتهية
    }
    if (s.contains('prepar')) {
      return const Color(0xFFFF9800); // برتقالي للتحضير
    }
    if (s.contains('pend')) {
      return const Color(0xFF2196F3); // أزرق للانتظار
    }
    if (s.contains('cancel')) {
      return Colors.red;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00B686);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 22),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'LIVE ORDER STATUS',
          style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          final order = orderProvider.getOrderById(orderId);

          // في حالة عدم وجود الطلب (مثلاً أثناء التحميل أو بعد الـ Refresh مباشرة)
          if (order == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingWidget(),
                  SizedBox(height: 16),
                  Text("Fetching your order details...",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 2. 🔥 فحص الحالات النهائية (تم التعديل ليدعم delivred)
          final String s = order.status.toLowerCase();
          final bool isFinalStatus = s.contains('deliv') ||
              s.contains('paid') ||
              s.contains('complet') ||
              s.contains('cancel') ||
              s.contains('serve') ||
              s.contains('done');

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // --- Status Card ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildStatusStepper(order.status, primaryColor),
                            const SizedBox(height: 32),
                            Text(
                              'Order ID: #${order.id.substring(order.id.length - 6).toUpperCase()}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              order.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: _getStatusColor(order.status),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Table ${order.tableNumber}',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // --- Order Details Card ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.list_alt_rounded,
                                    size: 18, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('ORDER SUMMARY',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.grey,
                                        letterSpacing: 1.1)),
                              ],
                            ),
                            const Divider(height: 32),
                            ...order.items.map((item) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Text('${item.quantity}x',
                                          style: const TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(item.name,
                                            style: const TextStyle(
                                                fontSize: 15,
                                                color: Color(0xFF2D2D2D),
                                                fontWeight: FontWeight.w500)),
                                      ),
                                      Text(
                                        'EGP ${(item.price * item.quantity).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                )),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                                Text(
                                    'EGP ${order.totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22,
                                        color: primaryColor)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Icon(Icons.sync_rounded,
                          color: Colors.grey, size: 20),
                      const SizedBox(height: 8),
                      const Text(
                        'This page updates in real-time as the kitchen\nprepares your delicious meal.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey, fontSize: 12, height: 1.5),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // --- Bottom Action Bar (ديناميكي بناءً على الحالة) ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4))
                ]),
                child: SafeArea(
                  child: isFinalStatus
                      ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await orderProvider.clearLocalSession();
                              context.go('/menu?table=${order.tableNumber}');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("PLACE NEW ORDER",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  context
                                      .go('/menu?table=${order.tableNumber}');
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text("ORDER MORE"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  side: const BorderSide(color: primaryColor),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 3. ميثود رسم الـ Stepper (تم التعديل ليدعم delivred)
  Widget _buildStatusStepper(String status, Color primary) {
    final s = status.toLowerCase();

    // فحص لو الحالة في مرحلة التحضير أو ما بعدها
    bool isPreparing = s.contains('prepar') ||
        s.contains('deliv') ||
        s.contains('done') ||
        s.contains('complet') ||
        s.contains('serve') ||
        s.contains('paid');

    // فحص لو الطلب وصل للزبون فعلياً
    bool isDone = s.contains('deliv') ||
        s.contains('done') ||
        s.contains('complet') ||
        s.contains('serve') ||
        s.contains('paid');

    return Row(
      children: [
        _stepCircle(
            Icons.receipt_long, primary, true), // تم الاستلام دائماً مفعلة
        _stepLine(isPreparing ? primary : Colors.grey.shade200),
        _stepCircle(Icons.restaurant,
            isPreparing ? primary : Colors.grey.shade200, isPreparing),
        _stepLine(isDone ? primary : Colors.grey.shade200),
        _stepCircle(Icons.check_circle, isDone ? primary : Colors.grey.shade200,
            isDone),
      ],
    );
  }

  Widget _stepCircle(IconData icon, Color color, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isActive ? color : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, color: isActive ? Colors.white : color, size: 18),
    );
  }

  Widget _stepLine(Color color) => Expanded(
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          height: 3,
          color: color));
}
