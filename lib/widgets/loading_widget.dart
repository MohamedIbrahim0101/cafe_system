// lib/widgets/loading_widget.dart
import 'package:flutter/material.dart';
import '../app/constants.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: kPrimaryColor),
    );
  }
}
