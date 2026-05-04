import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../widgets/app_theme.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _loading = false;
  bool _googleLoading = false;

  final _loginEmail = TextEditingController();
  final _loginPass  = TextEditingController();
  final _regFname   = TextEditingController();
  final _regLname   = TextEditingController();
  final _regEmail   = TextEditingController();
  final _regPhone   = TextEditingController();
  final _regPass    = TextEditingController();
  final _regPass2   = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [_loginEmail,_loginPass,_regFname,_regLname,_regEmail,_regPhone,_regPass,_regPass2]) c.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginEmail.text.isEmpty || _loginPass.text.isEmpty) { _snack('أدخل البريد وكلمة المرور', isError: true); return; }
    setState(() => _loading = true);
    try {
      await FB.signIn(_loginEmail.text.trim(), _loginPass.text);
      if (mounted) Navigator.pushReplacement(context, _route(const HomeScreen()));
    } on FirebaseAuthException catch (e) { _snack(_authError(e.code), isError: true); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _register() async {
    if (_regFname.text.isEmpty) { _snack('أدخل الاسم الأول', isError: true); return; }
    if (_regEmail.text.isEmpty) { _snack('أدخل البريد', isError: true); return; }
    if (_regPass.text.length < 6) { _snack('كلمة المرور 6 أحرف على الأقل', isError: true); return; }
    if (_regPass.text != _regPass2.text) { _snack('كلمتا المرور غير متطابقتين', isError: true); return; }
    setState(() => _loading = true);
    try {
      final cred = await FB.register(_regEmail.text.trim(), _regPass.text);
      await FB.saveProfile(cred.user!.uid, {
        'fname': _regFname.text.trim(), 'lname': _regLname.text.trim(),
        'email': _regEmail.text.trim(), 'phone': _regPhone.text.trim(),
        'joined': DateTime.now().toIso8601String(),
        'provider': 'email',
      });
      if (mounted) Navigator.pushReplacement(context, _route(const HomeScreen()));
    } on FirebaseAuthException catch (e) { _snack(_authError(e.code), isError: true); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final result = await FB.signInWithGoogle();
      if (result == null) { setState(() => _googleLoading = false); return; }
      if (mounted) Navigator.pushReplacement(context, _route(const HomeScreen()));
    } catch (e) {
      _snack('خطأ في تسجيل جوجل: $e', isError: true);
    } finally { if (mounted) setState(() => _googleLoading = false); }
  }

  Future<void> _guestLogin() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (mounted) Navigator.pushReplacement(context, _route(const HomeScreen()));
    } catch (_) {
      if (mounted) Navigator.pushReplacement(context, _route(const HomeScreen()));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  PageRouteBuilder _route(Widget page) => PageRouteBuilder(
    pageBuilder: (_, a, __) => page,
    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 400),
  );

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_rounded : Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700))),
      ]),
      backgroundColor: isError ? AppTheme.red : AppTheme.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
    ));
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found': return 'البريد غير مسجل';
      case 'wrong-password': return 'كلمة المرور خاطئة';
      case 'email-already-in-use': return 'البريد مستخدم بالفعل';
      case 'invalid-email': return 'بريد إلكتروني غير صالح';
      default: return 'خطأ: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SingleChildScrollView(
        child: Column(children: [
          // === HERO HEADER ===
          SizedBox(
            height: 300,
            child: Stack(fit: StackFit.expand, children: [
              Container(decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0800), Color(0xFF0A0400), AppTheme.bg],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              )),
              Positioned(left: -40, top: -40,
                child: Container(width: 200, height: 200,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [AppTheme.ember.withOpacity(0.2), Colors.transparent])))),
              Positioned(right: -30, bottom: 20,
                child: Container(width: 150, height: 150,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [AppTheme.gold.withOpacity(0.12), Colors.transparent])))),
              Positioned.fill(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 48),
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.goldDark, AppTheme.gold, AppTheme.goldLight],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: AppTheme.gold.withOpacity(0.4), blurRadius: 30, spreadRadius: 2),
                        BoxShadow(color: AppTheme.ember.withOpacity(0.3), blurRadius: 50),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(child: Image.asset('assets/images/logo.png', fit: BoxFit.cover)),
                  ),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (b) => AppTheme.goldGradient.createShader(b),
                    child: const Text('مطعم الشرق',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(height: 6),
                  const Text('MASHWAY AL-SHARQ',
                    style: TextStyle(color: AppTheme.muted, fontSize: 11, letterSpacing: 2.0)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.ember.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.ember.withOpacity(0.3)),
                    ),
                    child: const Text('تذوق أصالة الشرق في كل قمة 🔥',
                      style: TextStyle(color: AppTheme.textSub, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ]),
          ),

          // === GOOGLE SIGN IN ===
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _googleBtn(),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(child: Divider(color: AppTheme.border)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('أو سجّل بالبريد', style: TextStyle(color: AppTheme.muted, fontSize: 12))),
              Expanded(child: Divider(color: AppTheme.border)),
            ]),
          ),
          const SizedBox(height: 12),

          // === TABS ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface2, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppTheme.ember.withOpacity(0.35), blurRadius: 12)],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.muted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, fontFamily: 'Cairo'),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
                tabs: const [Tab(text: 'تسجيل الدخول'), Tab(text: 'حساب جديد')],
              ),
            ),
          ),

          const SizedBox(height: 4),

          SizedBox(
            height: 380,
            child: TabBarView(controller: _tab, children: [_loginTab(), _registerTab()]),
          ),

          // === GUEST ===
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(children: [
              Row(children: [
                Expanded(child: Divider(color: AppTheme.border)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('أو', style: TextStyle(color: AppTheme.muted, fontSize: 13))),
                Expanded(child: Divider(color: AppTheme.border)),
              ]),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity, height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSub,
                    side: const BorderSide(color: AppTheme.border, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loading ? null : _guestLogin,
                  icon: const Icon(Icons.person_outline_rounded, size: 18),
                  label: const Text('تصفح كضيف', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _googleBtn() => GestureDetector(
    onTap: _googleLoading ? null : _googleSignIn,
    child: Container(
      width: double.infinity, height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: _googleLoading
        ? const Center(child: SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.grey)))
        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Google G logo
            Container(
              width: 24, height: 24,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: 12),
            const Text('تسجيل الدخول بـ Google',
              style: TextStyle(
                color: Color(0xFF1F1F1F), fontWeight: FontWeight.w700,
                fontSize: 15, fontFamily: 'Cairo')),
          ]),
    ),
  );

  Widget _loginTab() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: Column(children: [
      _inp('البريد الإلكتروني', _loginEmail, icon: Icons.email_outlined, type: TextInputType.emailAddress),
      const SizedBox(height: 14),
      _inp('كلمة المرور', _loginPass, icon: Icons.lock_outline, obscure: true),
      const SizedBox(height: 24),
      _submitBtn('دخول 🔥', _login),
    ]),
  );

  Widget _registerTab() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: Column(children: [
      Row(children: [
        Expanded(child: _inp('الاسم الأول *', _regFname)),
        const SizedBox(width: 12),
        Expanded(child: _inp('الاسم الأخير', _regLname)),
      ]),
      const SizedBox(height: 12),
      _inp('البريد الإلكتروني *', _regEmail, icon: Icons.email_outlined, type: TextInputType.emailAddress),
      const SizedBox(height: 12),
      _inp('رقم الهاتف', _regPhone, icon: Icons.phone_outlined, type: TextInputType.phone),
      const SizedBox(height: 12),
      _inp('كلمة المرور *', _regPass, icon: Icons.lock_outline, obscure: true),
      const SizedBox(height: 12),
      _inp('تأكيد كلمة المرور *', _regPass2, icon: Icons.lock_outline, obscure: true),
      const SizedBox(height: 22),
      _submitBtn('إنشاء الحساب', _register),
    ]),
  );

  Widget _inp(String label, TextEditingController ctrl,
      {IconData? icon, bool obscure = false, TextInputType? type}) =>
    TextField(
      controller: ctrl, obscureText: obscure,
      keyboardType: type, textAlign: TextAlign.right,
      style: const TextStyle(color: AppTheme.textColor, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.muted, fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, color: AppTheme.muted, size: 19) : null,
        filled: true, fillColor: AppTheme.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
      ),
    );

  Widget _submitBtn(String label, VoidCallback onTap) => Container(
    width: double.infinity, height: 52,
    decoration: BoxDecoration(
      gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: AppTheme.ember.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 5))],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: _loading ? null : onTap,
        child: Center(child: _loading
          ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Text(label, style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
      ),
    ),
  );
}

// Google G logo painter
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    // Blue arc
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = size.width * 0.22;
    p.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.75), -0.52, 2.09, false, p);
    p.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.75), 1.57, 1.57, false, p);
    p.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.75), 3.14, 0.79, false, p);
    p.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.75), 3.93, 0.79, false, p);
    // White horizontal bar for G
    final bar = Paint()..color = Colors.white..strokeWidth = size.width * 0.22..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(c.dx, c.dy), Offset(c.dx + r * 0.75, c.dy), bar);
  }
  @override
  bool shouldRepaint(_) => false;
}
