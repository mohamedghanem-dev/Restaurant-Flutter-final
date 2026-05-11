import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../widgets/app_theme.dart';
import '../models/models.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(slivers: [
        // Header
        SliverAppBar(
          backgroundColor: AppTheme.bg,
          pinned: true,
          expandedHeight: 100,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: AppTheme.gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Icon(Icons.receipt_long_rounded, color: Colors.white, size: 17)),
              ),
              const SizedBox(width: 10),
              const Text('طلباتي',
                style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w900, fontSize: 18)),
            ]),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppTheme.borderGold),
          ),
        ),

        if (uid == null)
          SliverFillRemaining(
            child: _emptyState(
              icon: Icons.lock_outline_rounded,
              title: 'سجّل دخولك أولاً',
              subtitle: 'لمشاهدة طلباتك وتتبع حالتها',
            ),
          )
        else
          SliverToBoxAdapter(
            child: StreamBuilder<List<RestaurantOrder>>(
              stream: FB.userOrdersStream(uid),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return const _LoadingShimmer();
                final orders = snap.data ?? [];
                if (orders.isEmpty)
                  return _emptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'لا توجد طلبات بعد',
                    subtitle: 'اطلب من المنيو وتابع طلباتك هنا',
                  );
                return _OrdersList(orders: orders);
              },
            ),
          ),
      ]),
    );
  }

  Widget _emptyState({required IconData icon, required String title, required String subtitle}) =>
    Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(height: 60),
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            color: AppTheme.surface2, shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border),
          ),
          child: Center(child: Icon(icon, size: 40, color: AppTheme.muted.withOpacity(0.5))),
        ),
        const SizedBox(height: 20),
        Text(title, style: const TextStyle(color: AppTheme.textColor, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
      ]),
    );
}

class _OrdersList extends StatelessWidget {
  final List<RestaurantOrder> orders;
  const _OrdersList({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Summary row
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          _SummaryChip(label: 'إجمالي الطلبات', value: '${orders.length}', color: AppTheme.primary),
          const SizedBox(width: 10),
          _SummaryChip(
            label: 'قيد التنفيذ',
            value: '${orders.where((o) => ['pending','preparing'].contains(o.status)).length}',
            color: AppTheme.gold,
          ),
          const SizedBox(width: 10),
          _SummaryChip(
            label: 'مكتملة',
            value: '${orders.where((o) => o.status == 'delivered').length}',
            color: AppTheme.green,
          ),
        ]),
      ),

      // Orders list
      ...orders.map((o) => _OrderCard(order: o)),
      const SizedBox(height: 24),
    ]);
  }
}

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 10), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final RestaurantOrder order;
  const _OrderCard({required this.order});

  static const _statusConfig = {
    'pending':   {'label': 'قيد التحضير', 'icon': '⏳', 'color': AppTheme.ember, 'step': 1},
    'preparing': {'label': 'يتحضر الآن', 'icon': '👨‍🍳', 'color': AppTheme.gold, 'step': 2},
    'ready':     {'label': 'جاهز للاستلام', 'icon': '✅', 'color': AppTheme.green, 'step': 3},
    'delivered': {'label': 'تم التسليم', 'icon': '🚚', 'color': AppTheme.muted, 'step': 4},
    'cancelled': {'label': 'ملغي', 'icon': '❌', 'color': AppTheme.red, 'step': 0},
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _statusConfig[order.status] ?? _statusConfig['pending']!;
    final color = cfg['color'] as Color;
    final step = cfg['step'] as int;
    final isCancelled = order.status == 'cancelled';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
        ),
        child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          childrenPadding: EdgeInsets.zero,
          shape: const Border(),
          title: Row(children: [
            // Order ID + status badge
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]),
                ),
                const SizedBox(width: 7),
                Text('#${order.id.length > 6 ? order.id.substring(order.id.length - 6).toUpperCase() : order.id.toUpperCase()}',
                  style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w900, fontSize: 15)),
              ]),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${cfg['icon']} ${cfg['label']}',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
            const Spacer(),
            // Price + time
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              ShaderMask(
                shaderCallback: (b) => AppTheme.goldGradient.createShader(b),
                child: Text('${order.total.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 3),
              if (order.createdAt != null)
                Text(
                  '${order.createdAt!.hour}:${order.createdAt!.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
            ]),
          ]),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: [
                // Progress bar (not cancelled)
                if (!isCancelled) ...[
                  const SizedBox(height: 4),
                  _ProgressBar(step: step),
                  const SizedBox(height: 16),
                ],
                Divider(color: AppTheme.border, height: 1),
                const SizedBox(height: 12),

                // Items list
                if (order.items != null)
                  ...((order.items as List).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Center(child: Text('🍖', style: const TextStyle(fontSize: 16))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item['name'] ?? '',
                        style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w700, fontSize: 13))),
                      Text('× ${item['qty'] ?? 1}',
                        style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                      const SizedBox(width: 8),
                      Text('${((item['price'] ?? 0) as num) * ((item['qty'] ?? 1) as num)} ج',
                        style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700, fontSize: 13)),
                    ]),
                  ))),

                Divider(color: AppTheme.border, height: 1),
                const SizedBox(height: 10),

                // Footer info
                if (order.address != null)
                  _InfoRow(icon: Icons.location_on_outlined, text: order.address!),
                if (order.customerName != null)
                  _InfoRow(icon: Icons.person_outline_rounded, text: order.customerName!),
                if (order.paymentMethod != null)
                  _InfoRow(icon: Icons.payment_rounded, text: order.paymentMethod!),

                const SizedBox(height: 4),
                // Total row
                Row(children: [
                  const Text('الإجمالي', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  ShaderMask(
                    shaderCallback: (b) => AppTheme.goldGradient.createShader(b),
                    child: Text('${order.total.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                ]),
              ]),
            ),
          ],
        ),
      ),
    ));
  }
}

class _ProgressBar extends StatelessWidget {
  final int step;
  const _ProgressBar({required this.step});

  static const _steps = ['جديد', 'تحضير', 'جاهز', 'تسليم'];
  static const _colors = [AppTheme.ember, AppTheme.gold, AppTheme.green, AppTheme.muted];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_steps.length, (i) {
        final done = i < step;
        final active = i == step - 1;
        final color = done || active ? _colors[i] : AppTheme.border;
        return Expanded(child: Row(children: [
          Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: active ? 26 : 20,
              height: active ? 26 : 20,
              decoration: BoxDecoration(
                color: done || active ? color.withOpacity(0.15) : AppTheme.surface2,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: active ? 2 : 1),
                boxShadow: active ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)] : null,
              ),
              child: Center(child: Icon(
                done ? Icons.check_rounded : Icons.circle,
                size: done ? 12 : 6,
                color: color,
              )),
            ),
            const SizedBox(height: 4),
            Text(_steps[i], style: TextStyle(
              fontSize: 9, color: color,
              fontWeight: active ? FontWeight.w800 : FontWeight.normal)),
          ]),
          if (i < _steps.length - 1)
            Expanded(child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  i < step - 1 ? _colors[i] : AppTheme.border,
                  i < step - 1 ? _colors[i + 1] : AppTheme.border,
                ]),
                borderRadius: BorderRadius.circular(1),
              ),
            )),
        ]));
      }),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, color: AppTheme.muted, size: 15),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textSub, fontSize: 12))),
    ]),
  );
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(children: List.generate(3, (i) => Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      height: 90,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
    )));
  }
}
