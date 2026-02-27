// lib/app/constants.dart
import 'package:flutter/material.dart';

const Color kBackgroundColor = Color(0xFF121212);
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimaryColor = Color(0xFFC8A951);
const Color kTextPrimary = Color(0xFFFFFFFF);
const Color kTextSecondary = Color(0xFFB0B0B0);
const Color kSuccessColor = Colors.green;
const Color kWarningColor = Color(0xFFFFA500);
const Color kPendingColor = Colors.grey;
const double kBorderRadius = 16.0;
const double kPadding = 20.0;
const double kSmallPadding = 12.0;

const BoxShadow kSoftShadow = BoxShadow(
  color: Colors.black26,
  blurRadius: 10.0,
  offset: Offset(0, 4),
);

const String kBaseUrl = 'https://your-app.web.app'; // Replace with your Firebase Hosting URL
const String kCloudName = 'your-cloud-name'; // Replace with your Cloudinary cloud name
const String kCloudinaryPreset = 'restaurant_upload'; // Create unsigned upload preset in Cloudinary dashboard

String imageUrlResize(String? url, {double width = 400, bool isThumb = false}) {
  if (url == null || url.isEmpty) return '';
  double w = isThumb ? 100.0 : width;
  return url.contains('cloudinary.com')
      ? '$url?w=${w.toInt()},q_auto,f_auto,c_fill,g_face'
      : url;
}

String getQRData(int tableNumber) => '$kBaseUrl/#/menu?table=$tableNumber';
