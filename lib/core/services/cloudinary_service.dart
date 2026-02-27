import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // القيم الخاصة بك مدمجة مباشرة في الكود
  static const String _cloudName = "dex0hlgz3";
  static const String _uploadPreset = "LUXOR112";

  /// دالة رفع الصورة واستلام الرابط بصيغة https
  static Future<String?> uploadImage(
    Uint8List imageBytes,
    String fileName,
    String folder,
  ) async {
    try {
      // بناء الرابط الخاص بحسابك
      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      // تجهيز طلب الرفع
      final request = http.MultipartRequest('POST', uri);

      // إضافة الحقول المطلوبة (Unsigned)
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;

      // إضافة بيانات الصورة
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      ));

      // إرسال الطلب
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['secure_url'] as String?;
      } else {
        print('Cloudinary Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Cloudinary Exception: $e');
      return null;
    }
  }

  /// دالة تحسين الصورة (Transformations)
  /// لتصغير الحجم تلقائياً وتحويل الصيغة لـ WebP لتسريع التطبيق
  static String imageUrlResize(String url, {bool isThumb = false}) {
    if (!url.contains("cloudinary")) return url;

    // f_auto: تحويل التنسيق تلقائياً | q_auto: ضغط الجودة تلقائياً
    // w_300: تحديد العرض 300 بكسل للمصغرات
    final String transform =
        isThumb ? "w_300,h_300,c_fill,g_auto,f_auto,q_auto" : "f_auto,q_auto";

    return url.replaceFirst("/upload/", "/upload/$transform/");
  }
}
