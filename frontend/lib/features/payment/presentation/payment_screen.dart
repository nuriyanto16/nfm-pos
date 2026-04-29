import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../order/presentation/providers/cart_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/receipt_printer.dart';
import 'widgets/receipt_view.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final int? orderId;
  const PaymentScreen({super.key, this.orderId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String selectedMethod = 'Tunai';
  String orderSource = 'Resto';
  String deliveryMethod = 'Makan di Tempat';
  final TextEditingController amountController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();
  final TextEditingController shippingFeeController = TextEditingController();
  bool isProcessing = false;
  Map<String, dynamic>? createdOrder;

  // Quick cash amounts
  final List<double> _quickAmounts = [50000, 100000, 150000, 200000];

  static const _paymentMethods = [
    {'value': 'Tunai', 'icon': Icons.payments_outlined, 'label': 'Tunai'},
    {'value': 'QRIS', 'icon': Icons.qr_code_2, 'label': 'QRIS'},
    {'value': 'GoPay', 'icon': Icons.account_balance_wallet, 'label': 'GoPay'},
    {'value': 'ShopeePay', 'icon': Icons.account_balance_wallet, 'label': 'ShopeePay'},
    {'value': 'OVO', 'icon': Icons.account_balance_wallet, 'label': 'OVO'},
    {'value': 'DANA', 'icon': Icons.account_balance_wallet, 'label': 'DANA'},
    {'value': 'Transfer Bank', 'icon': Icons.account_balance_outlined, 'label': 'Transfer'},
    {'value': 'Kartu Debit/Kredit', 'icon': Icons.credit_card_outlined, 'label': 'Kartu'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingOrder());
    }
  }

  Future<void> _loadExistingOrder() async {
    setState(() => isProcessing = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('orders/${widget.orderId}');
      setState(() => createdOrder = res.data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat pesanan: $e')));
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> _processPayment() async {
    final cart = ref.read(cartProvider);
    if (createdOrder == null) {
      if (cart.items.isEmpty) return;
    }

    setState(() => isProcessing = true);

    try {
      final dio = ref.read(dioProvider);

      // 1. Create Order
      if (createdOrder == null) {
        final orderData = {
          'table_id': null,
          'customer_id': cart.customerId,
          'customer_name': cart.customerName ?? 'Pelanggan Umum',
          'discount_amount': cart.discountAmount,
          'shipping_fee': double.tryParse(shippingFeeController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0,
          'notes': cart.notes ?? '',
          'order_source': orderSource,
          'delivery_method': deliveryMethod,
          'items': cart.items.map((item) => {
            'menu_id': item.menuId,
            'quantity': item.quantity,
          }).toList(),
        };
        final orderResponse = await dio.post('orders', data: orderData);
        createdOrder = orderResponse.data;
      }

      // 2. Process Payment
      final totalToPay = (createdOrder!['total_amount'] as num).toDouble();
      final amountPaid = selectedMethod == 'Tunai'
          ? (double.tryParse(amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? totalToPay)
          : totalToPay;

      final paymentData = {
        'order_id': createdOrder!['id'],
        'amount_paid': amountPaid,
        'payment_method': selectedMethod,
        'reference_no': referenceController.text,
        'change': selectedMethod == 'Tunai' ? amountPaid - (createdOrder!['total_amount'] as num).toDouble() : 0,
      };

      await dio.post('orders/${createdOrder!['id']}/pay', data: paymentData);

      if (mounted) {
        _showReceiptDialog(amountPaid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
        setState(() => createdOrder = null); // reset order on failure
      }
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  void _showReceiptDialog(double amountPaid) {
    showDialog(
      context: context,
      barrierDismissible: true, // FIX: allow dismiss by tapping outside
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header — FIX: close button
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'Pembayaran Berhasil!',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        ref.read(cartProvider.notifier).clearCart();
                        Navigator.pop(context);
                        context.go('/pos');
                      },
                    ),
                  ],
                ),
              ),
              // Receipt preview
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ReceiptView(
                    order: createdOrder!,
                    amountPaid: amountPaid,
                    paymentMethod: selectedMethod,
                  ),
                ),
              ),
              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ReceiptPrinter.printReceipt(
                            createdOrder!,
                            amountPaid: amountPaid,
                            paymentMethod: selectedMethod,
                          );
                        },
                        icon: const Icon(Icons.print),
                        label: const Text('Cetak Struk'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          ref.read(cartProvider.notifier).clearCart();
                          Navigator.pop(context);
                          context.go('/pos');
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Selesai'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final isLoadedOrder = createdOrder != null && widget.orderId != null;
    final double calculatedShippingFee = isLoadedOrder ? ((createdOrder!['shipping_fee'] as num?)?.toDouble() ?? 0) : (double.tryParse(shippingFeeController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0);
    final double total = isLoadedOrder ? (createdOrder!['total_amount'] as num).toDouble() : cart.total + calculatedShippingFee;
    final subtotal = isLoadedOrder ? (createdOrder!['total_amount'] as num).toDouble() / 1.1 : cart.subtotal; // Rough estimate or fetch from API
    final taxAmount = subtotal * 0.1;
    final amountPaid = double.tryParse(amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    final change = amountPaid - total;
    final isNonCash = selectedMethod != 'Tunai';
    final bool isPaid = createdOrder != null && (createdOrder!['is_paid'] == true || createdOrder!['is_paid'] == 1);
    // canPay: allow if not paid, not processing, and either (non-cash or cash with enough money) OR it's an existing order we're settling
    final canPay = !isPaid && !isProcessing && (createdOrder != null || (cart.items.isNotEmpty && (isNonCash || change >= 0)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 768) {
            return _buildDesktop(cart, total, taxAmount, calculatedShippingFee, change, isNonCash, canPay, isLoadedOrder, isPaid);
          }
          return _buildMobile(cart, total, taxAmount, calculatedShippingFee, change, isNonCash, canPay, isLoadedOrder, isPaid);
        },
      ),
    );
  }

  Widget _buildDesktop(cart, double total, double taxAmount, double shippingFeeAmount, double change, bool isNonCash, bool canPay, bool isLoadedOrder, bool isPaid) {
    return Row(
      children: [
        // Left: Order Summary
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _OrderSummaryCard(
              cart: createdOrder ?? cart,
              total: total,
              taxAmount: taxAmount,
              shippingFee: shippingFeeAmount,
              isLoadedOrder: isLoadedOrder,
              isPaid: isPaid,
            ),
          ),
        ),
        // Right: Payment Form
        SizedBox(
          width: 420,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _PaymentForm(
              selectedMethod: selectedMethod,
              amountController: amountController,
              referenceController: referenceController,
              shippingController: shippingFeeController,
              isLoadedOrder: isLoadedOrder,
              quickAmounts: _quickAmounts,
              total: total,
              change: change,
              isNonCash: isNonCash,
              canPay: canPay,
              isProcessing: isProcessing,
              isPaid: isPaid,
              onMethodChanged: (v) => setState(() => selectedMethod = v),
              onAmountChanged: () => setState(() {}),
              onPay: _processPayment,
              orderSource: orderSource,
              onSourceChanged: (v) => setState(() => orderSource = v!),
              deliveryMethod: deliveryMethod,
              onDeliveryMethodChanged: (v) => setState(() => deliveryMethod = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobile(cart, double total, double taxAmount, double shippingFeeAmount, double change, bool isNonCash, bool canPay, bool isLoadedOrder, bool isPaid) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _OrderSummaryCard(
            cart: createdOrder ?? cart,
            total: total,
            taxAmount: taxAmount,
            shippingFee: shippingFeeAmount,
            isLoadedOrder: isLoadedOrder,
            isPaid: isPaid,
          ),
          const SizedBox(height: 16),
          _PaymentForm(
            selectedMethod: selectedMethod,
            amountController: amountController,
            referenceController: referenceController,
            shippingController: shippingFeeController,
            isLoadedOrder: isLoadedOrder,
            quickAmounts: _quickAmounts,
            total: total,
            change: change,
            isNonCash: isNonCash,
            canPay: canPay,
            isProcessing: isProcessing,
            isPaid: isPaid,
            onMethodChanged: (v) => setState(() => selectedMethod = v),
            onAmountChanged: () => setState(() {}),
            onPay: _processPayment,
            orderSource: orderSource,
            onSourceChanged: (v) => setState(() => orderSource = v!),
            deliveryMethod: deliveryMethod,
            onDeliveryMethodChanged: (v) => setState(() => deliveryMethod = v!),
          ),
        ],
      ),
    );
  }
}

// ─── Order Summary Card ───────────────────────────────────────────────────────
class _OrderSummaryCard extends StatelessWidget {
  final dynamic cart;
  final double total;
  final double taxAmount;
  final double shippingFee;
  final bool isLoadedOrder;
  final bool isPaid;

  const _OrderSummaryCard({
    required this.cart,
    required this.total,
    required this.taxAmount,
    this.shippingFee = 0,
    this.isLoadedOrder = false,
    this.isPaid = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMap = cart is Map;
    final List<dynamic> items = isMap ? (cart['items'] as List? ?? []) : (cart as CartState).items;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ringkasan Pesanan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final name = isMap ? (item['menu']?['name'] ?? 'Menu') : item.name;
                  final qty = isMap ? item['quantity'] : item.quantity;
                  final price = isMap ? (item['price'] as num).toDouble() : item.price;
                  final subtotal = isMap ? (item['subtotal'] as num).toDouble() : item.subtotal;
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(name),
                    subtitle: Text('$qty x ${formatRupiah(price)}'),
                    trailing: Text(formatRupiah(subtotal),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
            const Divider(height: 24),
            const Divider(height: 24),
            _PriceRow(label: 'Subtotal', value: isMap ? (cart['total_amount'] as num).toDouble() / 1.1 : cart.subtotal),
            if ((isMap ? (cart['discount_amount'] as num).toDouble() : cart.discountAmount) > 0)
              _PriceRow(
                label: 'Diskon', 
                value: isMap ? -(cart['discount_amount'] as num).toDouble() : -cart.discountAmount, 
                color: Colors.red
              ),
            if (shippingFee > 0)
              _PriceRow(label: 'Biaya Pengiriman', value: shippingFee),
            _PriceRow(label: 'Pajak (10%)', value: taxAmount),
            const Divider(height: 12),
            _PriceRow(label: 'Total Tagihan', value: total, isBold: true, fontSize: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Payment Form ─────────────────────────────────────────────────────────────
class _PaymentForm extends StatelessWidget {
  final String selectedMethod;
  final TextEditingController amountController;
  final TextEditingController referenceController;
  final TextEditingController shippingController;
  final bool isLoadedOrder;
  final List<double> quickAmounts;
  final double total;
  final double change;
  final bool isNonCash;
  final bool canPay;
  final bool isProcessing;
  final ValueChanged<String> onMethodChanged;
  final VoidCallback onAmountChanged;
  final VoidCallback onPay;

  final String orderSource;
  final ValueChanged<String?> onSourceChanged;
  final String deliveryMethod;
  final ValueChanged<String?> onDeliveryMethodChanged;

  const _PaymentForm({
    required this.selectedMethod,
    required this.amountController,
    required this.referenceController,
    required this.shippingController,
    this.isLoadedOrder = false,
    required this.quickAmounts,
    required this.total,
    required this.change,
    required this.isNonCash,
    required this.canPay,
    required this.isProcessing,
    this.isPaid = false,
    required this.onMethodChanged,
    required this.onAmountChanged,
    required this.onPay,
    required this.orderSource,
    required this.onSourceChanged,
    required this.deliveryMethod,
    required this.onDeliveryMethodChanged,
  });
  
  final bool isPaid;

  static const _methods = [
    {'value': 'Tunai', 'icon': Icons.payments_outlined, 'label': 'Tunai'},
    {'value': 'QRIS', 'icon': Icons.qr_code_2, 'label': 'QRIS'},
    {'value': 'GoPay', 'icon': Icons.account_balance_wallet, 'label': 'GoPay'},
    {'value': 'ShopeePay', 'icon': Icons.account_balance_wallet, 'label': 'ShopeePay'},
    {'value': 'OVO', 'icon': Icons.account_balance_wallet, 'label': 'OVO'},
    {'value': 'DANA', 'icon': Icons.account_balance_wallet, 'label': 'DANA'},
    {'value': 'Transfer Bank', 'icon': Icons.account_balance_outlined, 'label': 'Transfer'},
    {'value': 'Kartu Debit/Kredit', 'icon': Icons.credit_card_outlined, 'label': 'Kartu'},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isLoadedOrder) ...[
          const Text('Sumber Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: orderSource,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
            items: ['Resto', 'Online', 'Shopee Food', 'Go Food', 'Grab Food'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: onSourceChanged,
          ),
          const SizedBox(height: 16),
          const Text('Metode Pengiriman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: deliveryMethod,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
            items: ['Makan di Tempat', 'Bawa Pulang', 'Pengiriman'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: onDeliveryMethodChanged,
          ),
          const SizedBox(height: 20),
        ],
        // Payment Method selector
        const Text('Metode Pembayaran',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2,
          children: _methods.map((m) {
            final isSelected = selectedMethod == m['value'];
            return InkWell(
              onTap: () => onMethodChanged(m['value'] as String),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(m['icon'] as IconData,
                        color: isSelected ? colorScheme.primary : colorScheme.outline,
                        size: 22),
                    const SizedBox(height: 2),
                    Text(m['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),
        if (!isLoadedOrder) ...[
          TextField(
            controller: shippingController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Biaya Pengiriman (Opsional)',
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => onAmountChanged(),
          ),
          const SizedBox(height: 16),
        ],

        // Cash input
        if (!isNonCash) ...[
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Uang yang Diterima',
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => onAmountChanged(),
          ),
          const SizedBox(height: 10),
          // Quick amounts
          Wrap(
            spacing: 8,
            children: quickAmounts.map((amt) => OutlinedButton(
              onPressed: () {
                amountController.text = amt.toInt().toString();
                onAmountChanged();
              },
              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              child: Text(formatRupiah(amt), style: const TextStyle(fontSize: 12)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          // Change display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: change >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: change >= 0 ? Colors.green : Colors.red),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kembalian', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  formatRupiah(change >= 0 ? change : 0),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: change >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Reference no for non-cash
          TextField(
            controller: referenceController,
            decoration: InputDecoration(
              labelText: 'No. Referensi / Kode Transaksi (Opsional)',
              border: const OutlineInputBorder(),
              hintText: selectedMethod == 'QRIS' ? 'Scan kode QR terlebih dahulu' : 'Masukkan no. referensi',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Tagihan', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
                Text(formatRupiah(total), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary)),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Pay button
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: canPay ? onPay : (isPaid ? () => onPay() : null),
            style: isPaid ? FilledButton.styleFrom(backgroundColor: Colors.green) : null,
            child: isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    isPaid ? 'SUDAH DIBAYAR (LIHAT STRUK)' : 'BAYAR ${formatRupiah(total)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── Price Row ────────────────────────────────────────────────────────────────
class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;
  final bool isBold;
  final double fontSize;

  const _PriceRow({
    required this.label,
    required this.value,
    this.color,
    this.isBold = false,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : null)),
          Text(
            formatRupiah(value),
            style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : null, color: color),
          ),
        ],
      ),
    );
  }
}
