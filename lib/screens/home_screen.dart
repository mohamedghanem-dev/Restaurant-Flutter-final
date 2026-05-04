import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_theme.dart';
import 'menu_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _page = 0;
  int _cartCount = 0;
  List<dynamic> _cart = [];
  late List<AnimationController> _iconCtrl;

  @override
  void initState() {
    super.initState();
    _iconCtrl = List.generate(4, (_) => AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300)));
    _iconCtrl[0].forward();
  }

  @override
  void dispose() {
    for (final c in _iconCtrl) c.dispose();
    super.dispose();
  }

  void _updateCart(List<dynamic> cart) {
    setState(() {
      _cart = cart;
      _cartCount = cart.fold(0, (s, i) => s + (i['qty'] as int));
    });
  }

  void _onTab(int i) {
    if (i == _page) return;
    _iconCtrl[_page].reverse();
    HapticFeedback.selectionClick();
    setState(() => _page = i);
    _iconCtrl[i].forward();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final screens = [
      MenuScreen(cart: _cart, onCartUpdate: _updateCart),
      CartScreen(cart: _cart, onCartUpdate: _updateCart, onOrderPlaced: () => setState(() => _page = 2)),
      const OrdersScreen(),
      const ProfileScreen(),
    ];

    final navItems = [
      (Icons.home_rounded, Icons.home_outlined, 'الرئيسية'),
      (Icons.shopping_basket_rounded, Icons.shopping_basket_outlined, 'السلة'),
      (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'طلباتي'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'حسابي'),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: IndexedStack(index: _page, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0C0C0C),
          border: const Border(top: BorderSide(color: AppTheme.borderGold, width: 0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(4, (i) {
                final selected = _page == i;
                return Expanded(child: GestureDetector(
                  onTap: () => _onTab(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedBuilder(
                    animation: _iconCtrl[i],
                    builder: (_, __) {
                      final t = _iconCtrl[i].value;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(alignment: Alignment.center, children: [
                            // glow behind selected
                            if (selected)
                              Container(
                                width: 44, height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: RadialGradient(
                                    colors: [
                                      AppTheme.primary.withOpacity(0.25 * t),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            Transform.scale(
                              scale: 1.0 + 0.12 * t,
                              child: Icon(
                                selected ? navItems[i].$1 : navItems[i].$2,
                                size: 22,
                                color: selected
                                    ? Color.lerp(AppTheme.muted, AppTheme.primary, t)
                                    : AppTheme.muted,
                              ),
                            ),
                            // Badge
                            if (i == 1 && _cartCount > 0)
                              Positioned(
                                top: 0, right: 4,
                                child: Container(
                                  width: 16, height: 16,
                                  decoration: const BoxDecoration(
                                    gradient: AppTheme.gradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(child: Text(
                                    '$_cartCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                                  )),
                                ),
                              ),
                          ]),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: selected ? 9.5 : 9,
                              fontWeight: selected ? FontWeight.w800 : FontWeight.normal,
                              color: selected ? AppTheme.primary : AppTheme.muted,
                              fontFamily: 'Cairo',
                            ),
                            child: Text(navItems[i].$3),
                          ),
                          // bottom indicator dot
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(top: 3),
                            width: selected ? 18 : 0,
                            height: 2.5,
                            decoration: BoxDecoration(
                              gradient: selected ? AppTheme.gradient : null,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ));
              }),
            ),
          ),
        ),
      ),
    );
  }
}
