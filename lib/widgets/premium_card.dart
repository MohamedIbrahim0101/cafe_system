// lib/widgets/premium_card.dart
import 'package:flutter/material.dart';
import '../app/constants.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? height;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: padding ?? const EdgeInsets.all(kPadding),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: const [kSoftShadow],
      ),
      child: child,
    );
  }
}
