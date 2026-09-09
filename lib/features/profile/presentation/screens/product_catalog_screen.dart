import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../leads/presentation/providers/lead_providers.dart';
import '../../../leads/data/models/lead_model.dart';
import '../../data/models/quotation_item_model.dart';
import '../../data/services/quotation_service.dart';

class HardwareProduct {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final String? warranty;
  final Map<String, String> specifications;
  final IconData icon;
  final Color color;

  const HardwareProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    this.warranty,
    required this.specifications,
    required this.icon,
    required this.color,
  });

  String get formattedPrice => '₹${price.toStringAsFixed(0)}';
  String get priceWithGst => '₹${price.toStringAsFixed(0)} + GST';
  double get priceWithGstCalculated => price * 1.18;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'category': category,
        'price': price,
        'warranty': warranty,
        'specifications': specifications,
      };

  factory HardwareProduct.fromJson(Map<String, dynamic> json) {
    final specsRaw = json['specifications'] as Map<String, dynamic>? ?? {};
    final specs = specsRaw.map((k, v) => MapEntry(k, v.toString()));

    IconData icon = Icons.devices_other_rounded;
    Color color = const Color(0xFF6366F1);
    final cat = json['category'] ?? '';

    if (cat == 'POS Hardware') {
      icon = Icons.desktop_windows_rounded;
      color = const Color(0xFF4F46E5);
    } else if (cat == 'Thermal Printers') {
      icon = Icons.receipt_long_rounded;
      color = const Color(0xFF059669);
    } else if (cat == 'Mobile & Tablets') {
      icon = Icons.tablet_android_rounded;
      color = const Color(0xFF0284C7);
    } else if (cat == 'Cash Drawers') {
      icon = Icons.point_of_sale_rounded;
      color = const Color(0xFFD97706);
    } else if (cat == 'Scanners & Displays') {
      icon = Icons.qr_code_scanner_rounded;
      color = const Color(0xFF7C3AED);
    } else if (cat == 'Barcode Weighing Scale') {
      icon = Icons.scale_rounded;
      color = const Color(0xFFDC2626);
    } else if (cat == 'Label Printers') {
      icon = Icons.local_offer_rounded;
      color = const Color(0xFFEA580C);
    } else if (cat == 'KDS') {
      icon = Icons.kitchen_rounded;
      color = const Color(0xFFE11D48);
    } else if (cat == 'SaaS Software') {
      icon = Icons.cloud_done_rounded;
      color = const Color(0xFF10B981);
    }

    return HardwareProduct(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      category: cat,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      warranty: json['warranty'],
      specifications: specs,
      icon: icon,
      color: color,
    );
  }
}

class ProductCatalogScreen extends ConsumerStatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  ConsumerState<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends ConsumerState<ProductCatalogScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, int> _quotationCart = {};

  int get _totalCartCount => _quotationCart.values.fold(0, (sum, qty) => sum + qty);

  double get _totalCartAmount {
    double total = 0.0;
    _quotationCart.forEach((id, qty) {
      try {
        final p = _masterProducts.firstWhere((prod) => prod.id == id);
        total += p.price * qty;
      } catch (_) {}
    });
    return total;
  }

  final List<String> _categories = [
    'All',
    'POS Hardware',
    'Thermal Printers',
    'Mobile & Tablets',
    'Cash Drawers',
    'Scanners & Displays',
    'Barcode Weighing Scale',
    'Label Printers',
    'KDS',
    'SaaS Software',
  ];

  // Master product catalog list with exact 17 hardware items + KDS/SaaS
  final List<HardwareProduct> _masterProducts = [
    // 1. POS Hardware
    const HardwareProduct(
      id: 'hw_pos_01',
      name: 'APEXA X',
      brand: 'Posbank',
      category: 'POS Hardware',
      price: 50000,
      warranty: '3 Year (Onsite)',
      specifications: {
        'Category': 'POS Terminal',
        'Processor': 'Intel® Processor N97, up to 3.6 GHz',
        'System Memory': '4GB DDR4, expandable to 16GB',
        'Storage': '128GB SATA3 2.5" SSD',
        'Display': '15" TFT LCD, 1024 × 768 Touch',
        'OS Licence': 'Windows 10 Included',
        'Warranty': '3 Year (Onsite)',
      },
      icon: Icons.desktop_windows_rounded,
      color: Color(0xFF4F46E5),
    ),
    const HardwareProduct(
      id: 'hw_pos_02',
      name: 'PS-3616-G2',
      brand: 'Posiflex',
      category: 'POS Hardware',
      price: 51000,
      warranty: '3 Year (Onsite)',
      specifications: {
        'Category': 'POS Terminal',
        'Processor': 'Intel Celeron J6412, up to 2.6 GHz',
        'System Memory': '4GB DDR4, expandable to 16GB',
        'Storage': 'M.2 Connector SATA SSD 128GB',
        'Display': '15.6" TFT LCD, 1366 × 768 PCAP',
        'Build Quality': 'IP65 Waterproof Front Panel',
        'Warranty': '3 Year (Onsite)',
      },
      icon: Icons.desktop_windows_rounded,
      color: Color(0xFF4F46E5),
    ),

    // 2. Thermal Printers
    const HardwareProduct(
      id: 'hw_prn_01',
      name: 'TENAX TN260',
      brand: 'Posbank',
      category: 'Thermal Printers',
      price: 7500,
      warranty: '1 Year (Carry-in)',
      specifications: {
        'Category': 'Thermal Printer',
        'Method': 'Direct Thermal',
        'Paper Width': '79.5 ± 0.5mm',
        'Print Width': '72mm',
        'Print Speed': '260 mm/s Max',
        'Interfaces': 'USB + LAN (Ethernet)',
        'Special Features': 'Auto Cutter, ESC/POS Compatible',
        'Warranty': '1 Year (Carry-in)',
      },
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF059669),
    ),
    const HardwareProduct(
      id: 'hw_prn_02',
      name: 'RP82',
      brand: 'Posiflex',
      category: 'Thermal Printers',
      price: 7500,
      warranty: '1 Year (Carry-in)',
      specifications: {
        'Category': 'Thermal Printer',
        'Method': 'Thermal Line',
        'Paper Width': '80mm standard roll',
        'Print Speed': '200 mm/s',
        'Interfaces': 'USB + LAN (Ethernet)',
        'Special Features': 'Auto Cutter, ESC/POS commands',
        'Warranty': '1 Year (Carry-in)',
      },
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF059669),
    ),
    const HardwareProduct(
      id: 'hw_prn_03',
      name: 'RP 327',
      brand: 'Posiflex',
      category: 'Thermal Printers',
      price: 12000,
      warranty: '1 Year (Carry-in)',
      specifications: {
        'Category': 'Premium Wireless Printer',
        'Connectivity': 'WiFi + Bluetooth + USB + LAN',
        'Print Speed': '250 mm/s Fast Print',
        'Kitchen Friendly': 'Waterproof, oil-proof, insect-proof',
        'Alarm Alerts': 'Ring Light alarm & 90dB Sound Alarm',
        'Auto Cutter': 'Durable, 1.5 million cuts',
        'Warranty': '1 Year (Carry-in)',
      },
      icon: Icons.print_rounded,
      color: Color(0xFF059669),
    ),

    // 3. Cash Drawers
    const HardwareProduct(
      id: 'hw_cd_01',
      name: 'CDH-41',
      brand: 'Posbank',
      category: 'Cash Drawers',
      price: 4000,
      specifications: {
        'Category': 'Cash Drawer',
        'Casing': 'Heavy duty steel construction',
        'Dimensions': '415L × 410W × 100H mm',
        'Cash Tray': '5 compartments with metal clips',
        'Coin Tray': '8 compartments, double-row',
        'Interface': 'RJ12 receipt printer trigger, 12V/24V',
        'Durability': '1 Million operations',
      },
      icon: Icons.point_of_sale_rounded,
      color: Color(0xFFD97706),
    ),
    const HardwareProduct(
      id: 'hw_cd_02',
      name: 'CR-410',
      brand: 'Posiflex',
      category: 'Cash Drawers',
      price: 4000,
      warranty: '1 Year (Carry-in)',
      specifications: {
        'Category': 'Cash Drawer',
        'Casing': 'Steel construction with painted front',
        'Dimensions': '410W × 415L × 100H mm',
        'Cash Tray': '5 fixed bill compartments',
        'Coin Tray': '8 fixed coin compartments',
        'Lock Security': '3 key lock positions',
        'Warranty': '1 Year (Carry-in)',
      },
      icon: Icons.point_of_sale_rounded,
      color: Color(0xFFD97706),
    ),

    // 4. Customer Displays (Scanners & Displays)
    const HardwareProduct(
      id: 'hw_dsp_01',
      name: 'APEXA® X-1500',
      brand: 'Posbank',
      category: 'Scanners & Displays',
      price: 17000,
      warranty: '1 Year (Onsite)',
      specifications: {
        'Category': 'Customer Display',
        'Display Type': '15" TFT LCD, LED Backlight',
        'Resolution': '1024 × 768 standard',
        'Brightness': '300 cd/m² typical',
        'Power Supply': 'Adapter 12V, 5A',
        'Integration': 'Mounts on POS back panel',
        'Warranty': '1 Year (Onsite)',
      },
      icon: Icons.monitor_rounded,
      color: Color(0xFF7C3AED),
    ),
    const HardwareProduct(
      id: 'hw_dsp_02',
      name: 'LM-3210E',
      brand: 'Posiflex',
      category: 'Scanners & Displays',
      price: 18000,
      warranty: '1 Year (Onsite)',
      specifications: {
        'Category': 'Customer Display',
        'Display Type': '9.7" TFT LCD Screen',
        'Resolution': 'Up to 1024 × 768',
        'Brightness': '350 cd/m² typical',
        'Power Supply': '12V directly from POS VGA port',
        'Integration': 'Posiflex terminal mountable',
        'Warranty': '1 Year (Onsite)',
      },
      icon: Icons.monitor_rounded,
      color: Color(0xFF7C3AED),
    ),

    // 5. Tablets (Mobile & Tablets)
    const HardwareProduct(
      id: 'hw_tab_01',
      name: 'T803M (8" Tablet)',
      brand: 'IRA',
      category: 'Mobile & Tablets',
      price: 20000,
      specifications: {
        'Category': 'Waiter Tablet / Mobile & Tablet',
        'Display Size': '8-Inch IPS, 1280 × 800',
        'OS': 'Android 15',
        'Connectivity': 'WiFi + Cellular 4G VoLTE, 2 SIMs',
        'Specs': '3GB RAM / 32GB Storage / Quad-Core',
        'Battery': '5500mAh Non-Removable',
        'Included': 'Rubber Rugged Protection Cover',
      },
      icon: Icons.tablet_android_rounded,
      color: Color(0xFF0284C7),
    ),
    const HardwareProduct(
      id: 'hw_tab_02',
      name: 'T1030M (11" Tablet)',
      brand: 'IRA',
      category: 'Mobile & Tablets',
      price: 32000,
      specifications: {
        'Category': 'Premium Tablet / Mobile & Tablet',
        'Display Size': '11-Inch Incell, 2000 × 1200',
        'OS': 'Android 16',
        'Connectivity': 'WiFi + Cellular 4G VoLTE, 2 SIMs',
        'Specs': '4GB RAM / 64GB ROM / 8-Core CPU',
        'Battery': '8000mAh High Capacity',
        'Included': 'Rubber Rugged Protection Cover',
      },
      icon: Icons.tablet_rounded,
      color: Color(0xFF0284C7),
    ),

    // 6. All-in-One Handheld POS (Mobile & Tablets / POS Hardware)
    const HardwareProduct(
      id: 'hw_hh_01',
      name: 'IMIN Swift-2',
      brand: 'IMIN',
      category: 'POS Hardware',
      price: 24000,
      warranty: '1 Year (Carry-in)',
      specifications: {
        'Category': 'All-in-One Handheld POS',
        'Features': 'In-Built Thermal Printer',
        'Display': '6.5" Multipoint Touch Panel, 720 × 1600',
        'OS': 'Android 13, 32bit',
        'Specs': '2GB RAM + 16GB ROM, OTG Support',
        'Battery': '7.7V / 3350mAh / 25.8Wh',
        'Warranty': '1 Year (Carry-in)',
      },
      icon: Icons.phone_android_rounded,
      color: Color(0xFF4F46E5),
    ),

    // 7. Label Printer
    const HardwareProduct(
      id: 'hw_lbl_01',
      name: 'ZD230TA',
      brand: 'Zebra',
      category: 'Label Printers',
      price: 15000,
      warranty: '2 Year (Carry-in)',
      specifications: {
        'Category': 'Label Printer',
        'Resolution': '203 dpi / 8 dots per mm',
        'Print Width': 'Maximum 104 mm',
        'Print Speed': '152 mm per second',
        'Media Width': '25.4 mm to 112 mm',
        'Printing Speed': '90 mm/sec label printing',
        'Ribbon Length': '74 m to 300 m (Wax/Resin)',
        'Warranty': '2 Year (Carry-in)',
      },
      icon: Icons.local_offer_rounded,
      color: Color(0xFFEA580C),
    ),

    // 8. Barcode Weighing Scale
    const HardwareProduct(
      id: 'hw_scale_01',
      name: 'RLS-1000B',
      brand: 'Posiflex',
      category: 'Barcode Weighing Scale',
      price: 37500,
      warranty: '1 Year (Onsite)',
      specifications: {
        'Category': 'Barcode Weighing Scale',
        'Capacity': 'Dual Scale 6 / 15 kg, 2/5 g steps',
        'Display': 'Two-Line LCD, 96 × 32 Dot Matrix',
        'Keyboard': 'PLU 84 Mylar buttons',
        'PLU Storage': 'Stores 10,000 PLUs',
        'Printing Speed': '90 mm/sec label printing',
        'Interfaces': 'RS232 + Ethernet + WiFi',
        'Warranty': '1 Year (Onsite)',
      },
      icon: Icons.scale_rounded,
      color: Color(0xFFDC2626),
    ),

    // 9. Handheld Scanners (Scanners & Displays)
    const HardwareProduct(
      id: 'hw_scan_01',
      name: 'TS220W',
      brand: 'Posbank',
      category: 'Scanners & Displays',
      price: 2500,
      warranty: '3 Year Scanner Warranty',
      specifications: {
        'Category': 'Handheld Scanner',
        'Sensor Type': 'CMOS 640 × 480 pixels',
        'Code Support': '1D & 2D, QR, Data Matrix, PDF417',
        'Scan Mode': 'Manual / Auto-sensing Trigger',
        'Cable': '1.8 meters straight USB',
        'Interfaces': 'USB keyboard, virtual serial',
        'Warranty': '3 Year Scanner Warranty',
      },
      icon: Icons.qr_code_scanner_rounded,
      color: Color(0xFF7C3AED),
    ),
    const HardwareProduct(
      id: 'hw_scan_02',
      name: 'LS-3002',
      brand: 'Posiflex',
      category: 'Scanners & Displays',
      price: 2500,
      warranty: '2 Year (Carry-in)',
      specifications: {
        'Category': 'Handheld Scanner',
        'Scan Rate': '300 scans/second High Speed',
        'Sensor Type': 'CMOS 640 × 480 pixels',
        'Code Support': '1D & 2D, QR, PDF417, DataMatrix',
        'Scan Accuracy': '≥4 mil @ Code39',
        'Weight': '203g with 1.8M USB cable',
        'Warranty': '2 Year (Carry-in)',
      },
      icon: Icons.qr_code_scanner_rounded,
      color: Color(0xFF7C3AED),
    ),

    // 10. Table Top Scanner (Scanners & Displays)
    const HardwareProduct(
      id: 'hw_scan_03',
      name: 'NLS-FR4080',
      brand: 'Newland',
      category: 'Scanners & Displays',
      price: 7000,
      warranty: '3 Year (Carry-in)',
      specifications: {
        'Category': 'Table Top Scanner',
        'Motion Tolerance': '2.5m/s Hands-Free Scanning',
        'Sensor Resolution': '1280 × 800 CMOS High Resolution',
        'Code Support': '1D & 2D, QR, Data Matrix, PDF417',
        'Sealing Protection': 'IP52 Dust & Water Sealed',
        'Drop Resistance': '1.2m concrete drop tested',
        'Warranty': '3 Year (Carry-in)',
      },
      icon: Icons.scanner_rounded,
      color: Color(0xFF7C3AED),
    ),

    // KDS & SaaS
    const HardwareProduct(
      id: 'hw_kds_01',
      name: 'Kitchen Display System (KDS 21.5")',
      brand: 'LiveRestro',
      category: 'KDS',
      price: 16499,
      warranty: '1 Year (Onsite)',
      specifications: {
        'Category': 'KDS Kitchen Automation',
        'Display': '21.5" Full HD Water & Heat Resistant Touch Screen',
        'Features': 'Color-Coded Prep Timer & Order Delay Alerts',
        'Accessory': 'Wireless Bump Bar Support for Chef Station',
      },
      icon: Icons.kitchen_rounded,
      color: Color(0xFFE11D48),
    ),
    const HardwareProduct(
      id: 'sw_saas_01',
      name: 'LiveRestro Pro SaaS Annual Plan',
      brand: 'LiveRestro',
      category: 'SaaS Software',
      price: 14999,
      warranty: '24/7 Cloud Support & SLA',
      specifications: {
        'Category': 'Cloud POS & Billing License',
        'Captain App': 'Unlimited Captain Order Punching Apps',
        'Automation': 'Unified WhatsApp Bill & Invoice Automation',
        'Inventory': 'Inventory Recipe & Food Costing Module',
        'Reliability': 'Offline Mode Continuity with 0% Downtime',
      },
      icon: Icons.cloud_done_rounded,
      color: Color(0xFF10B981),
    ),
  ];

  List<HardwareProduct> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    final hive = getIt<HiveStorageService>();
    final cachedJson = hive.get<String>('products_price_catalog_cache');
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        final list = decoded.map((e) => HardwareProduct.fromJson(Map<String, dynamic>.from(e))).toList();
        if (list.length >= 17) {
          setState(() {
            _products = list;
          });
          return;
        }
      } catch (_) {}
    }

    // Default to master list & save to Hive
    _products = List.from(_masterProducts);
    hive.put('products_price_catalog_cache', jsonEncode(_masterProducts.map((p) => p.toJson()).toList()));
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HardwareProduct> _getFilteredProducts() {
    var list = _products;
    if (_selectedCategory != 'All') {
      list = list.where((p) => p.category == _selectedCategory).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.specifications.values.any((v) => v.toLowerCase().contains(q))).toList();
    }
    return list;
  }

  void _showProductDetails(HardwareProduct product) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.70,
          maxChildSize: 0.92,
          minChildSize: 0.45,
          expand: false,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
              child: ListView(
                controller: scrollCtrl,
                physics: const BouncingScrollPhysics(),
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2.r)),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Header Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: product.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(product.icon, color: product.color, size: 30.sp),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Wrap(
                              spacing: 6.w,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                  decoration: BoxDecoration(
                                    color: product.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    product.brand,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                      color: product.color,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    product.category,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: isDark ? Colors.grey[300] : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Row(
                              children: [
                                Text(
                                  product.formattedPrice,
                                  style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                ),
                                Text(
                                  ' + 18% GST',
                                  style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Specifications Card
                  Text(
                    'Full Technical Specifications',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: product.specifications.entries.map((entry) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                flex: 6,
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (product.warranty != null) ...[
                    SizedBox(height: 14.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user_outlined, size: 16.sp, color: const Color(0xFF10B981)),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Warranty Coverage: ${product.warranty}',
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _getFilteredProducts();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Products & Price Catalog',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 17.sp,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            color: isDark ? AppColors.surfaceDark : Colors.white,
            child: Column(
              children: [
                Container(
                  height: 42.h,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search products by name, brand, spec...',
                      hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search_rounded, size: 18.sp, color: Colors.grey[500]),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                  ),
                ),
                SizedBox(height: 10.h),

                // Category Chips Strip
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: EdgeInsets.only(right: 6.w),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategory = cat);
                          },
                          borderRadius: BorderRadius.circular(10.r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.grey[300] : const Color(0xFF475569)),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Product List View
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 54.sp, color: Colors.grey[400]),
                        SizedBox(height: 12.h),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Try searching with a different keyword or category.',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final product = filtered[index];

                      return InkWell(
                        onTap: () => _showProductDetails(product),
                        borderRadius: BorderRadius.circular(16.r),
                        child: Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: product.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                child: Icon(product.icon, color: product.color, size: 26.sp),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                          decoration: BoxDecoration(
                                            color: product.color.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6.r),
                                          ),
                                          child: Text(
                                            product.brand,
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.bold,
                                              color: product.color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      product.specifications.values.take(2).join(' • '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5.sp,
                                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              product.formattedPrice,
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF10B981),
                                              ),
                                            ),
                                            Text(
                                              ' + GST',
                                              style: TextStyle(
                                                fontSize: 10.5.sp,
                                                color: Colors.grey[500],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        InkWell(
                                          onTap: () => _showProductDetails(product),
                                          child: Row(
                                            children: [
                                              Text(
                                                'View Specs',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              SizedBox(width: 4.w),
                                              Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 11.sp,
                                                color: AppColors.primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10.h),
                                    // Add to Deal Quotation Cart Action Row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if ((_quotationCart[product.id] ?? 0) > 0)
                                          Container(
                                            height: 32.h,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF714B67).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8.r),
                                              border: Border.all(color: const Color(0xFF714B67)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.remove_rounded, size: 16.sp, color: const Color(0xFF714B67)),
                                                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () {
                                                    setState(() {
                                                      final cur = _quotationCart[product.id] ?? 0;
                                                      if (cur <= 1) {
                                                        _quotationCart.remove(product.id);
                                                      } else {
                                                        _quotationCart[product.id] = cur - 1;
                                                      }
                                                    });
                                                  },
                                                ),
                                                Text(
                                                  '${_quotationCart[product.id]}',
                                                  style: TextStyle(
                                                    fontSize: 13.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF714B67),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.add_rounded, size: 16.sp, color: const Color(0xFF714B67)),
                                                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () {
                                                    setState(() {
                                                      _quotationCart[product.id] = (_quotationCart[product.id] ?? 0) + 1;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          SizedBox(
                                            height: 32.h,
                                            child: ElevatedButton.icon(
                                              icon: Icon(Icons.add_shopping_cart_rounded, size: 14.sp, color: Colors.white),
                                              label: Text('Add to Quote', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF714B67),
                                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _quotationCart[product.id] = 1;
                                                });
                                                HapticFeedback.lightImpact();
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _totalCartCount > 0
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF714B67),
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: () => _showQuotationBuilderModal(context, isDark),
              icon: const Icon(Icons.description_rounded),
              label: Text(
                'Build Deal Quote ($_totalCartCount items • ₹${_totalCartAmount.toStringAsFixed(0)})',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
              ),
            )
          : null,
    );
  }

  void _showQuotationBuilderModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuotationBuilderSheet(
        cart: _quotationCart,
        products: _masterProducts,
        isDark: isDark,
        onCartUpdated: (newCart) {
          setState(() {
            _quotationCart.clear();
            _quotationCart.addAll(newCart);
          });
        },
      ),
    );
  }
}

class _QuotationBuilderSheet extends ConsumerStatefulWidget {
  final Map<String, int> cart;
  final List<HardwareProduct> products;
  final bool isDark;
  final ValueChanged<Map<String, int>> onCartUpdated;

  const _QuotationBuilderSheet({
    required this.cart,
    required this.products,
    required this.isDark,
    required this.onCartUpdated,
  });

  @override
  ConsumerState<_QuotationBuilderSheet> createState() => _QuotationBuilderSheetState();
}

class _QuotationBuilderSheetState extends ConsumerState<_QuotationBuilderSheet> {
  final _restaurantNameCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(text: 'Ahmedabad');
  final _notesCtrl = TextEditingController();
  double _discountPercent = 0.0;
  bool _isGenerating = false;

  late Map<String, int> _localCart;

  @override
  void initState() {
    super.initState();
    _localCart = Map.from(widget.cart);
  }

  @override
  void dispose() {
    _restaurantNameCtrl.dispose();
    _contactPersonCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  List<QuotationItemModel> _buildQuotationItems() {
    final List<QuotationItemModel> list = [];
    _localCart.forEach((id, qty) {
      final p = widget.products.firstWhere((prod) => prod.id == id, orElse: () => widget.products.first);
      list.add(QuotationItemModel(
        id: p.id,
        name: '${p.name} (${p.brand})',
        category: p.category,
        unitPrice: p.price,
        quantity: qty,
      ));
    });
    return list;
  }

  double get _subtotal => _buildQuotationItems().fold(0.0, (sum, i) => sum + i.totalPrice);
  double get _discountAmount => _subtotal * (_discountPercent / 100.0);
  double get _taxable => _subtotal - _discountAmount;
  double get _gst => _taxable * 0.18;
  double get _grandTotal => _taxable + _gst;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final leadsAsync = ref.watch(leadListProvider);
    final leads = leadsAsync.value ?? [];
    final isDark = widget.isDark;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, MediaQuery.of(context).viewInsets.bottom + 20.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF714B67).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: const Icon(Icons.request_quote_rounded, color: Color(0xFF714B67), size: 22),
                    ),
                    SizedBox(width: 10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deal Quotation Builder',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Generate GST Quotation & Share Proposal',
                          style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Select from existing leads shortcut
            if (leads.isNotEmpty) ...[
              Text(
                'Auto-Fill from Lead / Client (Optional)',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
              SizedBox(height: 6.h),
              DropdownButtonFormField<LeadModel>(
                decoration: InputDecoration(
                  hintText: 'Select Restaurant Lead...',
                  hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey[400]),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                ),
                items: leads.map((l) {
                  return DropdownMenuItem(
                    value: l,
                    child: Text('${l.restaurantName} (${l.id})', style: TextStyle(fontSize: 12.5.sp)),
                  );
                }).toList(),
                onChanged: (selected) {
                  if (selected != null) {
                    setState(() {
                      _restaurantNameCtrl.text = selected.restaurantName;
                      _contactPersonCtrl.text = selected.contactPersonName;
                      _contactPhoneCtrl.text = selected.mobile.isNotEmpty ? selected.mobile : selected.whatsapp;
                      final locParts = [
                        if (selected.area.isNotEmpty) selected.area,
                        if (selected.city.isNotEmpty) selected.city,
                      ];
                      _locationCtrl.text = locParts.isNotEmpty ? locParts.join(', ') : selected.address;
                    });
                  }
                },
              ),
              SizedBox(height: 12.h),
            ],

            // Restaurant Name & Contact Person Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _restaurantNameCtrl,
                    style: TextStyle(fontSize: 12.5.sp),
                    decoration: InputDecoration(
                      labelText: 'Restaurant Name *',
                      labelStyle: TextStyle(fontSize: 12.sp),
                      prefixIcon: const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF714B67)),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextFormField(
                    controller: _contactPersonCtrl,
                    style: TextStyle(fontSize: 12.5.sp),
                    decoration: InputDecoration(
                      labelText: 'Contact Person',
                      labelStyle: TextStyle(fontSize: 12.sp),
                      prefixIcon: const Icon(Icons.person_rounded, size: 18, color: Color(0xFF714B67)),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // Phone & Location Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _contactPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontSize: 12.5.sp),
                    decoration: InputDecoration(
                      labelText: 'WhatsApp Mobile *',
                      labelStyle: TextStyle(fontSize: 12.sp),
                      prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF10B981)),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextFormField(
                    controller: _locationCtrl,
                    style: TextStyle(fontSize: 12.5.sp),
                    decoration: InputDecoration(
                      labelText: 'City / Location',
                      labelStyle: TextStyle(fontSize: 12.sp),
                      prefixIcon: const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF714B67)),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Cart Items Header
            Text(
              'Selected Proposal Items (${_localCart.length})',
              style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
            ),
            SizedBox(height: 6.h),

            // Cart Items List
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: _localCart.entries.map((entry) {
                  final p = widget.products.firstWhere((prod) => prod.id == entry.key, orElse: () => widget.products.first);
                  final qty = entry.value;

                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                    dense: true,
                    title: Text(
                      p.name,
                      style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    subtitle: Text(
                      '${p.category} • ₹${p.price.toStringAsFixed(0)} each',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${(p.price * qty).toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                        ),
                        SizedBox(width: 8.w),
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (qty <= 1) {
                                _localCart.remove(entry.key);
                              } else {
                                _localCart[entry.key] = qty - 1;
                              }
                              widget.onCartUpdated(_localCart);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: Icon(Icons.remove_rounded, size: 14.sp),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          child: Text('$qty', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _localCart[entry.key] = qty + 1;
                              widget.onCartUpdated(_localCart);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(color: const Color(0xFF714B67).withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: Icon(Icons.add_rounded, size: 14.sp, color: const Color(0xFF714B67)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 12.h),

            // Discount Slider / Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Deal Discount: ${_discountPercent.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                ),
                Text(
                  '- ₹${_discountAmount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                ),
              ],
            ),
            Slider(
              value: _discountPercent,
              min: 0.0,
              max: 30.0,
              divisions: 6,
              label: '${_discountPercent.toStringAsFixed(0)}%',
              activeColor: const Color(0xFF16A34A),
              onChanged: (val) => setState(() => _discountPercent = val),
            ),

            // Calculations Summary Card
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Items Subtotal', '₹${_subtotal.toStringAsFixed(0)}', isDark),
                  if (_discountPercent > 0) ...[
                    SizedBox(height: 4.h),
                    _buildSummaryRow('Discount (${_discountPercent.toStringAsFixed(0)}%)', '- ₹${_discountAmount.toStringAsFixed(0)}', isDark, valueColor: const Color(0xFF16A34A)),
                  ],
                  SizedBox(height: 4.h),
                  _buildSummaryRow('Taxable Amount', '₹${_taxable.toStringAsFixed(0)}', isDark),
                  SizedBox(height: 4.h),
                  _buildSummaryRow('GST (18%)', '₹${_gst.toStringAsFixed(0)}', isDark),
                  Divider(height: 14.h, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Payable:',
                        style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                      Text(
                        '₹${_grandTotal.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF714B67)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),

            // Action Buttons (Preview PDF & Share on WhatsApp)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isGenerating ? null : () => _handleGeneratePdf(user, isPreview: true),
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF714B67), size: 18),
                    label: Text('Preview PDF', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF714B67))),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: const BorderSide(color: Color(0xFF714B67), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : () => _handleGeneratePdf(user, isPreview: false),
                    icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                    label: Text('WhatsApp Deal', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11.5.sp, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? Colors.white : const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  Future<void> _handleGeneratePdf(dynamic user, {required bool isPreview}) async {
    final restaurant = _restaurantNameCtrl.text.trim();
    if (restaurant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select a Restaurant Name.')),
      );
      return;
    }

    if (!isPreview && _contactPhoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter customer mobile number to share via WhatsApp.')),
      );
      return;
    }

    if (_localCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 1 item to the deal quote.')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    HapticFeedback.mediumImpact();

    try {
      final quotationData = QuotationData(
        quotationId: 'LR-QTN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        restaurantName: restaurant,
        contactPerson: _contactPersonCtrl.text.trim(),
        contactPhone: _contactPhoneCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        executiveName: user?.name ?? 'Prince Chandarana',
        executivePhone: user?.phone ?? '9408894448',
        items: _buildQuotationItems(),
        discountPercent: _discountPercent,
        notes: _notesCtrl.text.trim(),
      );

      if (isPreview) {
        await QuotationService.previewQuotation(context, quotationData);
      } else {
        await QuotationService.shareOnWhatsApp(context, quotationData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate quotation: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}
