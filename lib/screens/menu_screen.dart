import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../models/models.dart';
import '../widgets/app_theme.dart';

class MenuScreen extends StatefulWidget {
  final List<dynamic> cart;
  final Function(List<dynamic>) onCartUpdate;
  const MenuScreen({super.key, required this.cart, required this.onCartUpdate});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCat = 'all';

  void _addToCart(MenuItem item) {
    final cart = List<dynamic>.from(widget.cart);
    final idx = cart.indexWhere((c) => c['id'] == item.id);
    if (idx >= 0) cart[idx]['qty']++;
    else cart.add({'id': item.id, 'name': item.name, 'price': item.salePrice ?? item.price, 'qty': 1, 'image': item.image});
    widget.onCartUpdate(cart);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('تم إضافة ${item.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
      backgroundColor: AppTheme.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(slivers: [

        // === HEADER ===
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppTheme.bg,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Stack(fit: StackFit.expand, children: [
              // hero food image
              Image.network(
                'https://images.unsplash.com/photo-1544025162-d76694265947?w=1000',
                fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(color: AppTheme.surface),
              ),
              // gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      AppTheme.bg.withOpacity(0.85),
                      AppTheme.bg,
                    ],
                    stops: const [0.0, 0.75, 1.0],
                  ),
                ),
              ),
              // left glow
              Positioned(
                left: -30, top: -30,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppTheme.ember.withOpacity(0.2), Colors.transparent]),
                  ),
                ),
              ),
              // Brand row
              Positioned(
                bottom: 16, right: 16, left: 16,
                child: Row(children: [
                  // Logo with gold ring
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.goldDark, AppTheme.gold, AppTheme.goldLight],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      boxShadow: [BoxShadow(
                        color: AppTheme.gold.withOpacity(0.4),
                        blurRadius: 16, spreadRadius: 1,
                      )],
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: ClipOval(child: Image.asset('assets/images/logo.png', fit: BoxFit.cover)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ShaderMask(
                      shaderCallback: (b) => AppTheme.goldGradient.createShader(b),
                      child: const Text('مطعم الشرق',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                    const Text('MASHWAY AL-SHARQ',
                      style: TextStyle(color: AppTheme.muted, fontSize: 10, letterSpacing: 1.5)),
                  ])),
                  // Flame badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: AppTheme.gradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppTheme.ember.withOpacity(0.4), blurRadius: 10)],
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('🔥', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text('نار على نار', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        ),

        // === OFFERS ===
        SliverToBoxAdapter(child: StreamBuilder(
          stream: FB.offersStream(),
          builder: (_, snap) {
            if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(children: [
                  Container(width: 3, height: 18, decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  const Text('العروض الحصرية 🎁',
                    style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w900, fontSize: 15)),
                ]),
              ),
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snap.data!.length,
                  itemBuilder: (_, i) {
                    final o = snap.data![i];
                    return Container(
                      width: 230,
                      margin: const EdgeInsets.only(left: 12, bottom: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E0D00), Color(0xFF2A1400)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.25), width: 1),
                        boxShadow: [BoxShadow(color: AppTheme.ember.withOpacity(0.12), blurRadius: 12)],
                      ),
                      child: Stack(children: [
                        if (o.image != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(o.image!, fit: BoxFit.cover,
                              width: double.infinity, height: double.infinity,
                              color: Colors.black.withOpacity(0.55), colorBlendMode: BlendMode.darken,
                              errorBuilder: (_,__,___) => const SizedBox())),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end, children: [
                            if (o.discount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.gradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('خصم ${o.discount}%',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                              ),
                            const SizedBox(height: 5),
                            Text(o.title, style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                          ]),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ]);
          },
        )),

        // === RESTAURANT STATUS ===
        SliverToBoxAdapter(child: StreamBuilder(
          stream: FB.settingsStream(),
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final open = snap.data!['restaurantOpen'] != false;
            if (open) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.red.withOpacity(0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.access_time_rounded, color: AppTheme.red, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text('المطعم مغلق حالياً',
                  style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w700))),
              ]),
            );
          },
        )),

        // === CATEGORIES ===
        SliverToBoxAdapter(child: StreamBuilder(
          stream: FB.categoriesStream(),
          builder: (_, snap) {
            final cats = snap.data ?? [];
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Row(children: [
                  Container(width: 3, height: 18, decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  const Text('القائمة 🍽️',
                    style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w900, fontSize: 15)),
                ]),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _catChip('all', 'الكل'),
                    ...cats.map((c) => _catChip(c.id, c.name)),
                  ],
                ),
              ),
            ]);
          },
        )),

        // === ITEMS GRID ===
        SliverToBoxAdapter(child: StreamBuilder(
          stream: FB.itemsStream(),
          builder: (_, snap) {
            if (!snap.hasData) return const Center(child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(
                color: AppTheme.primary, strokeWidth: 2.5)));
            final all = snap.data!.where((i) => i.available).toList();
            final items = _selectedCat == 'all' ? all : all.where((i) => i.categoryId == _selectedCat).toList();
            if (items.isEmpty) return Padding(
              padding: const EdgeInsets.all(48),
              child: Center(child: Column(children: [
                Icon(Icons.restaurant_outlined, size: 48, color: AppTheme.muted.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('لا توجد أصناف', style: TextStyle(color: AppTheme.muted, fontSize: 14)),
              ])));
            return GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14,
                childAspectRatio: 0.7),
              itemCount: items.length,
              itemBuilder: (_, i) => _FoodCard(item: items[i], onAdd: () => _addToCart(items[i])),
            );
          },
        )),
      ]),
    );
  }

  Widget _catChip(String id, String label) {
    final selected = _selectedCat == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCat = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.gradient : null,
          color: selected ? null : AppTheme.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : AppTheme.border, width: 1),
          boxShadow: selected ? [BoxShadow(
            color: AppTheme.ember.withOpacity(0.3), blurRadius: 10)] : null,
        ),
        child: Center(child: Text(label, style: TextStyle(
          color: selected ? Colors.white : AppTheme.muted,
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500))),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onAdd;
  const _FoodCard({required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          Expanded(
            flex: 5,
            child: Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                child: item.image != null && item.image!.isNotEmpty
                  ? Image.network(
                      item.image!, fit: BoxFit.cover,
                      width: double.infinity, height: double.infinity,
                      loadingBuilder: (_, child, prog) => prog == null ? child
                        : Container(color: AppTheme.surface2,
                            child: const Center(child: Icon(Icons.restaurant, color: AppTheme.border, size: 32))),
                      errorBuilder: (_,__,___) => Container(color: AppTheme.surface2,
                        child: const Center(child: Icon(Icons.restaurant, color: AppTheme.border, size: 32))))
                  : Container(color: AppTheme.surface2,
                      child: const Center(child: Icon(Icons.restaurant, color: AppTheme.border, size: 32))),
              ),
              // Sale tag
              if (item.salePrice != null)
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: AppTheme.gradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: AppTheme.ember.withOpacity(0.4), blurRadius: 8)],
                    ),
                    child: const Text('خصم', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                ),
              // Bottom gradient on image
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [AppTheme.surface, AppTheme.surface.withOpacity(0)]),
                  ),
                ),
              ),
            ]),
          ),
          // Info
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w800, fontSize: 13)),
                Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${(item.salePrice ?? item.price).toStringAsFixed(0)} ج',
                      style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w900, fontSize: 15)),
                    if (item.salePrice != null)
                      Text('${item.price.toStringAsFixed(0)} ج',
                        style: const TextStyle(color: AppTheme.muted, fontSize: 10,
                          decoration: TextDecoration.lineThrough)),
                  ]),
                  const Spacer(),
                  GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        gradient: AppTheme.gradient,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [BoxShadow(color: AppTheme.ember.withOpacity(0.4), blurRadius: 10)],
                      ),
                      child: const Center(child: Icon(Icons.add_rounded, color: Colors.white, size: 18)),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
            decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
          if (item.image != null && item.image!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(item.image!, height: 210,
                width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_,__,___) => const SizedBox())),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(item.name,
                  style: const TextStyle(color: AppTheme.textColor, fontSize: 20, fontWeight: FontWeight.w900))),
                if (item.salePrice != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppTheme.gradient,
                      borderRadius: BorderRadius.circular(8)),
                    child: const Text('عرض خاص 🔥',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
              ]),
              if (item.description != null) ...[
                const SizedBox(height: 8),
                Text(item.description!,
                  style: const TextStyle(color: AppTheme.textSub, fontSize: 13, height: 1.5)),
              ],
              const SizedBox(height: 18),
              Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ShaderMask(
                    shaderCallback: (b) => AppTheme.goldGradient.createShader(b),
                    child: Text('${(item.salePrice ?? item.price).toStringAsFixed(0)} ج.م',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                  ),
                  if (item.salePrice != null)
                    Text('كان: ${item.price.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(color: AppTheme.muted, fontSize: 11,
                        decoration: TextDecoration.lineThrough)),
                ]),
                const Spacer(),
                SizedBox(
                  width: 150,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppTheme.gradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: AppTheme.ember.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () { Navigator.pop(context); onAdd(); },
                        child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('أضف للسلة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                        ])),
                      ),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 10),
        ]),
      ),
    );
  }
}
