// lib/core/services/qr_service.dart
import '../../app/constants.dart';

class QRService {
  static String generateQRData(int tableNumber, String restaurantId) {
    // قم بتعديل Domain التطبيق الخاص بك
    final baseUrl = "https://qalyoubfantasy.web.app/#/menu"; 
    return "$baseUrl?restaurantId=$restaurantId&table=$tableNumber";
  }
}