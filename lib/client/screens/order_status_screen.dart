import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/order_provider.dart';
import '../../app/constants.dart';
import '../../widgets/loading_widget.dart';

class OrderStatusScreen extends StatelessWidget {
  final String orderId;
  const OrderStatusScreen({super.key, required this.orderId});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Done':
        return const Color(0xFF00B686);
      case 'Preparing':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00B686);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // نفس خلفية المنيو
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ORDER SUMMARY',
          style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          try {
            final order = orderProvider.getOrderById(orderId);
            if (order == null) return const LoadingWidget();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // --- Status Card (Noon Style) ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildStatusStepper(order.status, primaryColor),
                        const SizedBox(height: 30),
                        Text(
                          'Order #${order.id.substring(order.id.length - 6).toUpperCase()}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _getStatusColor(order.status),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Table ${order.tableNumber} • Ground Floor',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Order Items Detail ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ORDER DETAILS',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const Divider(height: 24),
                        ...order.items
                            .map((item) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${item.quantity}x ${item.name}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF404040))),
                                      Text(
                                          '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ))
                            .toList(),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('\$${order.totalPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: primaryColor)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'We will notify you once your order is ready!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          } catch (e) {
            return const LoadingWidget();
          }
        },
      ),
    );
  }

  // ميثود لرسم تتبع حالة الطلب بشكل مودرن
  Widget _buildStatusStepper(String status, Color primary) {
    bool isPreparing = status == 'Preparing' || status == 'Done';
    bool isDone = status == 'Done';

    return Row(
      children: [
        _stepCircle(Icons.check_circle, primary, true),
        _stepLine(isPreparing ? primary : Colors.grey.shade200),
        _stepCircle(Icons.restaurant,
            isPreparing ? primary : Colors.grey.shade200, isPreparing),
        _stepLine(isDone ? primary : Colors.grey.shade200),
        _stepCircle(
            Icons.celebration, isDone ? primary : Colors.grey.shade200, isDone),
      ],
    );
  }

  Widget _stepCircle(IconData icon, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _stepLine(Color color) =>
      Expanded(child: Container(height: 2, color: color));
}
