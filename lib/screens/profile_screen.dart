import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../services/firebase_service.dart';
import '../widgets/app_theme.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploadingAvatar = false;

  Future<void> _pickAndUploadAvatar(String uid) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 512);
    if (picked == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final file = File(picked.path);
      final url = await FB.uploadImage(file, 'avatars/$uid.jpg');
      await FB.saveProfile(uid, {'avatar': url});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل رفع الصورة: $e'), backgroundColor: AppTheme.red));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsapp(String number) async {
    final clean = number.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: user == null ? _notLoggedIn(context) : _buildProfile(user),
    );
  }

  Widget _buildProfile(User user) {
    return FutureBuilder(
      future: FB.getProfile(user.uid),
      builder: (_, snap) {
        final profile = snap.data ?? {};
        final fname = profile['fname'] ?? user.displayName?.split(' ').first ?? 'مستخدم';
        final lname = profile['lname'] ?? '';
        final email = user.email ?? profile['email'] ?? '';
        final phone = profile['phone'] ?? '';
        final avatarUrl = profile['avatar'] ?? user.photoURL ?? '';
        final initials = ((fname.isNotEmpty ? fname[0] : '') + (lname.isNotEmpty ? lname[0] : '')).toUpperCase();

        return CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: AppTheme.bg,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(fit: StackFit.expand, children: [
                Container(decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A0800), Color(0xFF0F0500), AppTheme.bg],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    stops: [0.0, 0.5, 1.0],
                  ),
                )),
                Positioned(top: -40, left: 0, right: 0,
                  child: Center(child: Container(width: 220, height: 220,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [AppTheme.ember.withOpacity(0.15), Colors.transparent]))))),
                Positioned(bottom: 16, left: 0, right: 0,
                  child: Column(children: [
                    GestureDetector(
                      onTap: () => _pickAndUploadAvatar(user.uid),
                      child: Stack(alignment: Alignment.bottomRight, children: [
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.gradient,
                            boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 24)]),
                          padding: const EdgeInsets.all(3),
                          child: ClipOval(child: _uploadingAvatar
                            ? Container(color: AppTheme.surface2,
                                child: const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5)))
                            : avatarUrl.isNotEmpty
                              ? Image.network(avatarUrl, fit: BoxFit.cover,
                                  errorBuilder: (_,__,___) => _defaultAvatar(initials))
                              : _defaultAvatar(initials)),
                        ),
                        Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(gradient: AppTheme.gradient, shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.bg, width: 2)),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    ShaderMask(
                      shaderCallback: (b) => AppTheme.goldGradient.createShader(b),
                      child: Text('$fname $lname'.trim(),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(email, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                    ],
                  ])),
              ]),
            ),
            bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppTheme.borderGold)),
          ),

          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(children: [
              _sectionHeader('بياناتي', Icons.person_rounded),
              const SizedBox(height: 10),
              _card(children: [
                if (phone.isNotEmpty) _row(Icons.phone_outlined, 'الهاتف', phone),
                if (email.isNotEmpty) _row(Icons.email_outlined, 'البريد', email),
                _row(Icons.calendar_today_outlined, 'تاريخ الانضمام', _formatDate(profile['joined'])),
              ]),
              const SizedBox(height: 24),

              StreamBuilder<Map<String, dynamic>>(
                stream: FB.settingsStream(),
                builder: (_, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final s = snap.data!;
                  final rPhone    = s['phone']     ?? '';
                  final whatsapp  = s['whatsapp']  ?? '';
                  final address   = s['address']   ?? '';
                  final facebook  = s['facebook']  ?? '';
                  final instagram = s['instagram'] ?? '';
                  final tiktok    = s['tiktok']    ?? '';
                  final youtube   = s['youtube']   ?? '';
                  final twitter   = s['twitter']   ?? '';
                  final hasSocial = [facebook,instagram,tiktok,youtube,twitter].any((v) => v.isNotEmpty);

                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _sectionHeader('بيانات المطعم', Icons.store_rounded),
                    const SizedBox(height: 10),
                    _card(children: [
                      if (rPhone.isNotEmpty)
                        _tapRow(Icons.phone_rounded, 'هاتف المطعم', rPhone,
                          onTap: () => _launchPhone(rPhone), color: AppTheme.green),
                      if (whatsapp.isNotEmpty)
                        _tapRow(Icons.chat_rounded, 'واتساب', whatsapp,
                          onTap: () => _launchWhatsapp(whatsapp), color: const Color(0xFF25D366)),
                      if (address.isNotEmpty)
                        _row(Icons.location_on_outlined, 'العنوان', address),
                    ]),
                    if (hasSocial) ...[
                      const SizedBox(height: 14),
                      _card(children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Row(children: [
                            Icon(Icons.share_rounded, color: AppTheme.primary, size: 16),
                            SizedBox(width: 8),
                            Text('تابعنا على السوشيال ميديا',
                              style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w800, fontSize: 13)),
                          ])),
                        Wrap(spacing: 10, runSpacing: 10, children: [
                          if (facebook.isNotEmpty)
                            _socialBtn('Facebook', const Color(0xFF1877F2), Icons.facebook_rounded, () => _launchUrl(facebook)),
                          if (instagram.isNotEmpty)
                            _socialBtn('Instagram', const Color(0xFFE1306C), Icons.camera_alt_rounded, () => _launchUrl(instagram)),
                          if (tiktok.isNotEmpty)
                            _socialBtn('TikTok', const Color(0xFF69C9D0), Icons.music_note_rounded, () => _launchUrl(tiktok)),
                          if (youtube.isNotEmpty)
                            _socialBtn('YouTube', const Color(0xFFFF0000), Icons.play_circle_rounded, () => _launchUrl(youtube)),
                          if (twitter.isNotEmpty)
                            _socialBtn('X / Twitter', const Color(0xFF1DA1F2), Icons.alternate_email_rounded, () => _launchUrl(twitter)),
                        ]),
                      ]),
                    ],
                  ]);
                },
              ),

              StreamBuilder(
                stream: FB.reviewsStream(),
                builder: (_, snap) {
                  if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
                  final reviews = snap.data!;
                  final avg = reviews.fold(0.0, (s, r) => s + r.stars) / reviews.length;
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 24),
                    _sectionHeader('تقييمات المطعم', Icons.star_rounded),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.gold.withOpacity(0.12), AppTheme.surface],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        ShaderMask(shaderCallback: (b) => AppTheme.goldGradient.createShader(b),
                          child: Text(avg.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900))),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: List.generate(5, (i) => Icon(
                            i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: AppTheme.gold, size: 20))),
                          const SizedBox(height: 4),
                          Text('${reviews.length} تقييم', style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
                        ])),
                      ]),
                    ),
                    ...reviews.take(5).map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(width: 40, height: 40,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.gradient),
                          child: Center(child: Text(r.name.isNotEmpty ? r.name[0] : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(r.name,
                              style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w800, fontSize: 13))),
                            Row(children: List.generate(5, (i) => Icon(
                              i < r.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: AppTheme.gold, size: 13))),
                          ]),
                          if (r.comment != null && r.comment!.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(r.comment!, style: const TextStyle(color: AppTheme.textSub, fontSize: 12, height: 1.4)),
                          ],
                        ])),
                      ]),
                    )),
                  ]);
                },
              ),

              const SizedBox(height: 24),
              SizedBox(width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.red,
                    side: BorderSide(color: AppTheme.red.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    await FB.signOut();
                    if (context.mounted) Navigator.pushAndRemoveUntil(
                      context, MaterialPageRoute(builder: (_) => const AuthScreen()), (_) => false);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                )),
            ]),
          )),
        ]);
      },
    );
  }

  Widget _defaultAvatar(String initials) => Container(color: AppTheme.surface2,
    child: Center(child: Text(initials.isEmpty ? '👤' : initials,
      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900))));

  Widget _sectionHeader(String title, IconData icon) => Row(children: [
    Container(width: 32, height: 32,
      decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(10)),
      child: Center(child: Icon(icon, color: Colors.white, size: 16))),
    const SizedBox(width: 10),
    Text(title, style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w900, fontSize: 16)),
  ]);

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.border)),
    child: Column(children: children));

  Widget _row(IconData icon, String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Icon(icon, color: AppTheme.primary, size: 18),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
      const Spacer(),
      Flexible(child: Text(val, textAlign: TextAlign.end,
        style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 13))),
    ]));

  Widget _tapRow(IconData icon, String label, String val, {required VoidCallback onTap, required Color color}) =>
    GestureDetector(onTap: onTap, child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
        const Spacer(),
        Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(width: 4),
        Icon(Icons.arrow_forward_ios_rounded, color: color, size: 12),
      ])));

  Widget _socialBtn(String name, Color color, IconData icon, VoidCallback onTap) =>
    GestureDetector(onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(name, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ])));

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try { final dt = DateTime.parse(raw.toString()); return '${dt.day}/${dt.month}/${dt.year}'; }
    catch (_) { return raw.toString(); }
  }

  Widget _notLoggedIn(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 90, height: 90,
        decoration: BoxDecoration(color: AppTheme.surface2, shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border)),
        child: Center(child: Icon(Icons.person_outline, size: 40, color: AppTheme.muted.withOpacity(0.4)))),
      const SizedBox(height: 16),
      const Text('غير مسجل الدخول', style: TextStyle(color: AppTheme.muted, fontSize: 16)),
      const SizedBox(height: 20),
      Container(
        decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppTheme.ember.withOpacity(0.4), blurRadius: 16)]),
        child: Material(color: Colors.transparent,
          child: InkWell(borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 13),
              child: Text('تسجيل الدخول',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)))))),
    ]));
}
