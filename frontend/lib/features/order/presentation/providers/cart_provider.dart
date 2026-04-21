import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final int menuId;
  final String name;
  final double price;
  int quantity;
  String notes;

  CartItem({
    required this.menuId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.notes = '',
  });

  double get subtotal => price * quantity;
}

enum DiscountType { percentage, flat }

class CartState {
  final List<CartItem> items;
  final int? customerId;
  final String? customerName;
  final int? promoId;
  final double discountValue;
  final DiscountType discountType;
  final int? tableId;
  final String? notes;
  final double shippingFee;
  final double taxPct;
  final double serviceChargePct;

  CartState({
    required this.items,
    this.customerId,
    this.customerName,
    this.promoId,
    this.discountValue = 0,
    this.discountType = DiscountType.percentage,
    this.notes,
    this.shippingFee = 0,
    this.tableId,
    this.taxPct = 10,
    this.serviceChargePct = 0,
  });

  CartState copyWith({
    List<CartItem>? items,
    int? customerId,
    String? customerName,
    int? promoId,
    double? discountValue,
    DiscountType? discountType,
    String? notes,
    double? shippingFee,
    int? tableId,
    double? taxPct,
    double? serviceChargePct,
    bool clearCustomer = false,
    bool clearPromo = false,
  }) {
    return CartState(
      items: items ?? this.items,
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      customerName: clearCustomer ? null : (customerName ?? this.customerName),
      promoId: clearPromo ? null : (promoId ?? this.promoId),
      discountValue: discountValue ?? this.discountValue,
      discountType: discountType ?? this.discountType,
      notes: notes ?? this.notes,
      shippingFee: shippingFee ?? this.shippingFee,
      tableId: tableId ?? this.tableId,
      taxPct: taxPct ?? this.taxPct,
      serviceChargePct: serviceChargePct ?? this.serviceChargePct,
    );
  }

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);

  double get discountAmount {
    if (discountType == DiscountType.percentage) {
      return (subtotal + serviceChargeAmount) * (discountValue / 100);
    } else {
      return discountValue;
    }
  }

  double get serviceChargeAmount => subtotal * (serviceChargePct / 100);

  double get taxAmount => (subtotal + serviceChargeAmount) * (taxPct / 100);

  double get total => subtotal - discountAmount + taxAmount + serviceChargeAmount + shippingFee;
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState(items: []));

  void addItem(Map<String, dynamic> menu) {
    final menuId = menu['id'] as int;
    final existingIndex = state.items.indexWhere((item) => item.menuId == menuId);

    if (existingIndex != -1) {
      final updatedItems = [...state.items];
      updatedItems[existingIndex].quantity++;
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(items: [
        ...state.items,
        CartItem(
          menuId: menuId,
          name: menu['name'],
          price: (menu['price'] as num).toDouble(),
        )
      ]);
    }
  }

  void removeItem(int menuId) {
    state = state.copyWith(items: state.items.where((item) => item.menuId != menuId).toList());
  }

  void updateQuantity(int menuId, int delta) {
    final updatedItems = state.items.map((item) {
      if (item.menuId == menuId) {
        final newQty = item.quantity + delta;
        if (newQty <= 0) return item; // keep, will be filtered below
        item.quantity = newQty;
      }
      return item;
    }).where((item) => item.quantity > 0).toList();
    state = state.copyWith(items: [...updatedItems]);
  }

  void setCustomer(int? id, String? name) {
    state = state.copyWith(customerId: id, customerName: name, clearCustomer: id == null);
  }

  void setTable(int? id) {
    state = state.copyWith(tableId: id);
  }

  void setDiscount(double value, DiscountType type) {
    state = state.copyWith(discountValue: value, discountType: type);
  }

  void applyPromo(int? promoId, double value, DiscountType type) {
    state = state.copyWith(
      promoId: promoId,
      discountValue: value,
      discountType: type,
      clearPromo: promoId == null,
    );
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void updateItemNote(int menuId, String note) {
    final updatedItems = state.items.map((item) {
      if (item.menuId == menuId) {
        return CartItem(
          menuId: item.menuId,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
          notes: note,
        );
      }
      return item;
    }).toList();
    state = state.copyWith(items: updatedItems);
  }

  void setSettings(double tax, double service) {
    state = state.copyWith(taxPct: tax, serviceChargePct: service);
  }

  void clearCart() {
    state = CartState(items: [], taxPct: state.taxPct, serviceChargePct: state.serviceChargePct);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
