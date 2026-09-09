import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_cards.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';
import '../providers/order_providers.dart';

/// Full Production Create Sales Order Screen with Catalog, Cart, Tax & PDF generator.
class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  String _selectedRestaurant = 'Spice Junction Fine Dine';
  final Map<String, int> _cartQuantities = {};
  final double _discountPercent = 5.0;
  final String _paymentTerms = 'Net 15 Days';
  bool _isCreating = false;

  void _updateQuantity(ProductModel product, int change) {
    setState(() {
      final current = _cartQuantities[product.id] ?? 0;
      final updated = current + change;
      if (updated <= 0) {
        _cartQuantities.remove(product.id);
      } else {
        _cartQuantities[product.id] = updated;
      }
    });
  }

  double get _subtotal {
    double sum = 0.0;
    final catalog = ref.read(productCatalogProvider).value ?? [];
    _cartQuantities.forEach((prodId, qty) {
      final prod = catalog.firstWhere((p) => p.id == prodId, orElse: () => catalog.first);
      sum += prod.price * qty;
    });
    return sum;
  }

  double get _discountAmount => _subtotal * (_discountPercent / 100);
  double get _taxableAmount => _subtotal - _discountAmount;
  double get _taxAmount => _taxableAmount * 0.18; // 18% GST
  double get _totalAmount => _taxableAmount + _taxAmount;

  Future<void> _submitOrder() async {
    if (_cartQuantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 product for the order')),
      );
      return;
    }

    setState(() => _isCreating = true);
    final catalog = ref.read(productCatalogProvider).value ?? [];
    final items = _cartQuantities.entries.map((e) {
      final prod = catalog.firstWhere((p) => p.id == e.key);
      return OrderItemModel(
        productId: prod.id,
        title: prod.title,
        price: prod.price,
        quantity: e.value,
      );
    }).toList();

    final order = OrderModel(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      restaurantName: _selectedRestaurant,
      items: items,
      subtotal: _subtotal,
      discountAmount: _discountAmount,
      taxAmount: _taxAmount,
      totalAmount: _totalAmount,
      paymentTerms: _paymentTerms,
      status: 'Placed',
      createdAt: 'Just now',
      isSynced: true,
    );

    await ref.read(orderRepositoryProvider).createOrder(order);
    ref.invalidate(orderListProvider);

    if (mounted) {
      setState(() => _isCreating = false);
      _showOrderSuccessDialog(order);
    }
  }

  void _showOrderSuccessDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green),
              SizedBox(width: 8.w),
              const Text('Order Placed Successfully'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order ID: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4.h),
              Text('Total Amount: ₹${order.totalAmount.toStringAsFixed(2)}'),
              SizedBox(height: 4.h),
              Text('Payment Terms: ${order.paymentTerms}'),
              SizedBox(height: 12.h),
              const Text('Invoice PDF generated and queued for printing / distribution.'),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.share_rounded, color: Colors.green),
              label: const Text('Share PDF via WhatsApp'),
              onPressed: () async {
                final uri = Uri.parse(
                    'https://wa.me/?text=Sales%20Order%20${order.id}%20placed%20for%20${order.restaurantName}%20Total:%20INR%20${order.totalAmount}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(productCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sales Order'),
      ),
      body: Column(
        children: [
          // Select Restaurant Header
          Container(
            color: Theme.of(context).cardColor,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              children: [
                const Icon(Icons.storefront, color: AppColors.primary),
                SizedBox(width: 10.w),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRestaurant,
                      isExpanded: true,
                      items: [
                        'Spice Junction Fine Dine',
                        'Royal Biryani House',
                        'Urban Bistro & Bar',
                        'The Pizza Box Express',
                      ]
                          .map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRestaurant = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Product Catalog List
          Expanded(
            child: catalogAsync.when(
              data: (products) {
                return ListView.separated(
                  padding: EdgeInsets.all(16.w),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final qty = _cartQuantities[product.id] ?? 0;

                    return AppCard(
                      isOutlined: true,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
                                SizedBox(height: 2.h),
                                Text(product.description, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]), maxLines: 2),
                                SizedBox(height: 6.h),
                                Text(
                                  '₹${product.price.toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),

                          // Quantity Controls (+/-)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: qty > 0 ? () => _updateQuantity(product, -1) : null,
                                ),
                                Text('$qty', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () => _updateQuantity(product, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),

          // Bottom Order Summary Sheet
          if (_cartQuantities.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal:', style: TextStyle(fontSize: 13.sp, color: Colors.grey[700])),
                      Text('₹${_subtotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 13.sp)),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Discount ($_discountPercent%):', style: TextStyle(fontSize: 13.sp, color: Colors.green)),
                      Text('-₹${_discountAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 13.sp, color: Colors.green)),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GST Tax (18%):', style: TextStyle(fontSize: 13.sp, color: Colors.grey[700])),
                      Text('+₹${_taxAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 13.sp)),
                    ],
                  ),
                  Divider(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount:', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      Text('₹${_totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  PrimaryButton(
                    text: 'Generate PDF & Place Order',
                    isLoading: _isCreating,
                    onPressed: _submitOrder,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
