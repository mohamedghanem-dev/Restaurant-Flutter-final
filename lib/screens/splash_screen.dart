import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_theme.dart';
import 'home_screen.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _btnCtrl;

  late Animation<double> _bgFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _btnFade;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _btnFade = CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn);
    _shimmer = Tween<double>(begin: -1.5, end: 2.5)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));

    // Sequence
    _bgCtrl.forward().then((_) {
      _logoCtrl.forward().then((_) {
        _textCtrl.forward().then((_) {
          _btnCtrl.forward();
        });
      });
    });

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, anim, __) => user != null ? const HomeScreen() : const AuthScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ));
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _logoCtrl.dispose();
    _textCtrl.dispose(); _btnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Background image full cover
        FadeTransition(
          opacity: _bgFade,
          child: SizedBox.expand(
            child: Image.asset(
              'assets/images/splash.png',
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Dark overlay gradient for text readability
        FadeTransition(
          opacity: _bgFade,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.35),
                  Colors.transparent,
                  Colors.black.withOpacity(0.75),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // Bottom overlay glow
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: FadeTransition(
            opacity: _bgFade,
            child: Container(
              height: size.height * 0.38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Content
        SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // Bottom text block
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                child: Column(children: [
                  // Tagline
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFF5C518), Color(0xFFFFE082), Color(0xFFF5C518)],
                          ).createShader(bounds),
                          child: const Text(
                            'تذوق أصالة الشرق',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w900,
                              color: Colors.white, height: 1.2,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'في كل قمة',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'مشويات المتميزة... نار على نار',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // CTA Button with shimmer
                  FadeTransition(
                    opacity: _btnFade,
                    child: AnimatedBuilder(
                      animation: _shimmer,
                      builder: (_, child) {
                        return Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFB8860B), Color(0xFFF5C518), Color(0xFFDAA520)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF5C518).withOpacity(0.4),
                                blurRadius: 20, offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(children: [
                              child!,
                              // shimmer effect
                              Positioned.fill(
                                child: ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    begin: Alignment(_shimmer.value - 0.5, 0),
                                    end: Alignment(_shimmer.value + 0.5, 0),
                                    colors: [Colors.transparent, Colors.white.withOpacity(0.35), Colors.transparent],
                                  ).createShader(bounds),
                                  child: Container(color: Colors.white),
                                ),
                              ),
                            ]),
                          ),
                        );
                      },
                      child: Center(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.restaurant_menu_rounded, color: Colors.black87, size: 20),
                          const SizedBox(width: 10),
                          const Text(
                            'اطلب الآن عبر التطبيق',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900,
                              color: Colors.black87, letterSpacing: 0.3,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
