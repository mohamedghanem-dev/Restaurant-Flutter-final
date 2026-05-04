import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../widgets/app_theme.dart';

class CartScreen extends StatefulWidget {
  final List<dynamic> cart;
  final Function(List<dynamic>) onCartUpdate;
  final VoidCallback onOrderPlaced;
  const CartScreen({super.key, required this.cart, required this.onCartUpdate, required this.onOrderPlaced});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  String _payMethod = 'كاش عند الاستلام';
  bool _placing = false;

  double get _total => widget.cart.fold(0, (s, i) => s + (i['price'] as num) * (i['qty'] as int));

  void _updateQty(String id, int delta) {
    final cart = List<dynamic>.from(widget.cart);
    final idx = cart.indexWhere((c) => c['id'] == id);
    if (idx < 0) return;
    cart[idx]['qty'] = (cart[idx]['qty'] as int) + delta;
    if (cart[idx]['qty'] <= 0) cart.removeAt(idx);
    widget.onCartUpdate(cart);
  }

  Future<void> _placeOrder() async {
    if (widget.cart.isEmpty) return;
    if (_nameCtrl.text.isEmpty || _addrCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('أدخل الاسم والعنوان', style: TextStyle()),
        backgroundColor: AppTheme.red));
      return;
    }
    setState(() => _placing = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FB.placeOrder({
        'userId': uid ?? 'guest',
        'customerName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addrCtrl.text.trim(),
        'paymentMethod': _payMethod,
        'items': widget.cart,
        'total': _total,
        'status': 'pending',
      });
      widget.onCartUpdate([]);
      widget.onOrderPlaced();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🎉 تم استلام طلبك بنجاح!', style: TextStyle()),
        backgroundColor: AppTheme.green, behavior: SnackBarBehavior.floating));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('خطأ: $e', style: const TextStyle()),
        backgroundColor: AppTheme.red));
    } finally { if (mounted) setState(() => _placing = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text('السلة', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textColor)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border)),
      ),
      body: widget.cart.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.shopping_basket_outlined, size: 64, color: AppTheme.muted.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('السلة فارغة', style: TextStyle(color: AppTheme.muted, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('أضف أصناف من القائمة', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
          ]))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Items
              ...widget.cart.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['name'], style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('${item['price']} ج × ${item['qty']} = ${(item['price'] as num) * (item['qty'] as int)} ج',
                      style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                  ])),
                  Row(children: [
                    _qtyBtn(Icons.remove, () => _updateQty(item['id'], -1)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${item['qty']}', style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w900, fontSize: 16))),
                    _qtyBtn(Icons.add, () => _updateQty(item['id'], 1)),
                  ]),
                ]),
              )),

              // Order form
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('بيانات التوصيل', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w900, fontSize: 15)),
                  const SizedBox(height: 14),
                  _formField('الاسم *', _nameCtrl, Icons.person_outline),
                  const SizedBox(height: 10),
                  _formField('رقم الهاتف', _phoneCtrl, Icons.phone_outlined, type: TextInputType.phone),
                  const SizedBox(height: 10),
                  _formField('العنوان *', _addrCtrl, Icons.location_on_outlined),
                  const SizedBox(height: 10),
                  // Payment
                  DropdownButtonFormField<String>(
                    value: _payMethod,
                    decoration: InputDecoration(
                      labelText: 'طريقة الدفع',
                      labelStyle: const TextStyle(color: AppTheme.muted, fontSize: 12),
                      prefixIcon: const Icon(Icons.payment, color: AppTheme.muted, size: 18),
                      filled: true, fillColor: AppTheme.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
                      isDense: true,
                    ),
                    dropdownColor: AppTheme.surface2,
                    style: const TextStyle(color: AppTheme.textColor, fontSize: 13),
                    items: ['كاش عند الاستلام', 'فودافون كاش', 'إنستا باي'].map((m) =>
                      DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _payMethod = v!),
                  ),
                ]),
              ),

              // Total + order btn
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1A0800), Color(0xFF120500)]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('الإجمالي', style: TextStyle(color: AppTheme.muted)),
                    Text('${_total.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 20)),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _placing ? null : _placeOrder,
                      child: _placing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('تأكيد الطلب 🎉', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 80),
            ],
          ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border)),
      child: Center(child: Icon(icon, size: 16, color: AppTheme.primary)),
    ),
  );

  Widget _formField(String label, TextEditingController ctrl, IconData icon, {TextInputType? type}) =>
    TextField(
      controller: ctrl, keyboardType: type, textAlign: TextAlign.right,
      style: const TextStyle(color: AppTheme.textColor, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.muted, fontSize: 12),
        prefixIcon: Icon(icon, color: AppTheme.muted, size: 18),
        filled: true, fillColor: AppTheme.surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        isDense: true,
      ),
    );
}
