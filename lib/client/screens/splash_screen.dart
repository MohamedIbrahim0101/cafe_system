import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../state/restaurant_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // تحكم في الأنميشن: تكبير بسيط مع ظهور تدريجي
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500)
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn)
    );

    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // تحميل بيانات المطعم أثناء شاشة الـ Splash
    final restaurantProvider = context.read<RestaurantProvider>();
    await restaurantProvider.load();
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      // التوجه إلى القائمة الرئيسية (يمكنك تغيير الطاولة لتكون ديناميكية لاحقاً)
      context.go('/menu?table=1'); 
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = context.watch<RestaurantProvider>().restaurant;
    final primaryColor = const Color(0xFF00B686); // اللون الأخضر الموحد

    return Scaffold(
      backgroundColor: Colors.white, // خلفية بيضاء نقية
      body: Stack(
        children: [
          // لوجو خفيف في الخلفية كعنصر تصميمي (اختياري)
          Positioned(
            right: -50,
            top: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: primaryColor.withOpacity(0.03),
            ),
          ),
          
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // تصميم اللوجو بشكل دائري بريميوم
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: restaurant?.logoUrl != null && restaurant!.logoUrl.isNotEmpty
                            ? Image.network(
                                restaurant.logoUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildDefaultLogo(primaryColor),
                              )
                            : _buildDefaultLogo(primaryColor),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // اسم المطعم بخط Cinzel الفاخر أو خط Google Fonts المختار
                    Text(
                      restaurant?.name.toUpperCase() ?? "ROMDOL.",
                      style: GoogleFonts.cinzel(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // خط فاصل صغير ورفيع
                    Container(
                      width: 40,
                      height: 2,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 16),
                    
                    // نص ترحيبي بسيط
                    Text(
                      "PREMIUM DINING EXPERIENCE",
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // مؤشر تحميل بسيط في الأسفل
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor.withOpacity(0.5)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDefaultLogo(Color color) {
    return Icon(Icons.restaurant_menu_rounded, size: 60, color: color);
  }
}