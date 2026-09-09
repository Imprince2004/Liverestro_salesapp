import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/quotation_item_model.dart';

class QuotationData {
  final String quotationId;
  final String restaurantName;
  final String contactPerson;
  final String contactPhone;
  final String location;
  final String executiveName;
  final String executivePhone;
  final List<QuotationItemModel> items;
  final double discountPercent;
  final String notes;
  final DateTime createdAt;

  QuotationData({
    required this.quotationId,
    required this.restaurantName,
    required this.contactPerson,
    required this.contactPhone,
    required this.location,
    required this.executiveName,
    required this.executivePhone,
    required this.items,
    this.discountPercent = 0.0,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get discountAmount => subtotal * (discountPercent / 100.0);
  double get taxableAmount => subtotal - discountAmount;
  double get gstAmount => taxableAmount * 0.18;
  double get grandTotal => taxableAmount + gstAmount;
}

class QuotationService {
  static final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);

  /// Generate Quotation PDF in memory
  static Future<Uint8List> generateQuotationPdf(QuotationData data) async {
    final pdf = pw.Document();

    final fontBold = await PdfGoogleFonts.poppinsBold();
    final fontRegular = await PdfGoogleFonts.poppinsRegular();
    final fontMedium = await PdfGoogleFonts.poppinsMedium();

    final dateStr = DateFormat('dd MMM yyyy').format(data.createdAt);
    final validUntilStr = DateFormat('dd MMM yyyy').format(data.createdAt.add(const Duration(days: 15)));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Top Brand Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LiveRestro',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 24,
                          color: PdfColor.fromHex('#714B67'),
                        ),
                      ),
                      pw.Text(
                        'Restaurant POS & Cloud Billing Solutions',
                        style: pw.TextStyle(
                          font: fontMedium,
                          fontSize: 9,
                          color: PdfColor.fromHex('#64748B'),
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F1F5F9'),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'PROPOSAL / QUOTATION',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                            color: PdfColor.fromHex('#0F172A'),
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Quote #: ${data.quotationId}',
                          style: pw.TextStyle(
                            font: fontMedium,
                            fontSize: 9,
                            color: PdfColor.fromHex('#475569'),
                          ),
                        ),
                        pw.Text(
                          'Date: $dateStr',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 8.5,
                            color: PdfColor.fromHex('#64748B'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Divider(thickness: 1, color: PdfColor.fromHex('#E2E8F0')),
              pw.SizedBox(height: 12),

              // 2. Client & Executive Metadata Boxes
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Client Info
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F8FAFC'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'QUOTATION ISSUED TO:',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 8.5,
                              color: PdfColor.fromHex('#64748B'),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            data.restaurantName,
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: PdfColor.fromHex('#0F172A'),
                            ),
                          ),
                          if (data.contactPerson.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Attn: ${data.contactPerson}',
                              style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColor.fromHex('#334155')),
                            ),
                          ],
                          if (data.contactPhone.isNotEmpty) ...[
                            pw.Text(
                              'Phone: ${data.contactPhone}',
                              style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColor.fromHex('#334155')),
                            ),
                          ],
                          if (data.location.isNotEmpty) ...[
                            pw.Text(
                              'Location: ${data.location}',
                              style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColor.fromHex('#64748B')),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  // Executive Info & Validity
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F8FAFC'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PREPARED BY (SALES EXECUTIVE):',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 8.5,
                              color: PdfColor.fromHex('#64748B'),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            data.executiveName.isNotEmpty ? data.executiveName : 'LiveRestro Sales Representative',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 11,
                              color: PdfColor.fromHex('#0F172A'),
                            ),
                          ),
                          if (data.executivePhone.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Contact: ${data.executivePhone}',
                              style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColor.fromHex('#334155')),
                            ),
                          ],
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Offer Valid Until: $validUntilStr',
                            style: pw.TextStyle(font: fontMedium, fontSize: 9, color: PdfColor.fromHex('#0284C7')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // 3. Itemized Products & Hardware Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
                columnWidths: {
                  0: const pw.FixedColumnWidth(28),
                  1: const pw.FlexColumnWidth(4),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FixedColumnWidth(40),
                  4: const pw.FlexColumnWidth(2),
                  5: const pw.FlexColumnWidth(2.5),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#714B67')),
                    children: [
                      _buildTableCell('#', fontBold, isHeader: true, align: pw.TextAlign.center),
                      _buildTableCell('Item Description', fontBold, isHeader: true),
                      _buildTableCell('Category', fontBold, isHeader: true),
                      _buildTableCell('Qty', fontBold, isHeader: true, align: pw.TextAlign.center),
                      _buildTableCell('Unit Price', fontBold, isHeader: true, align: pw.TextAlign.right),
                      _buildTableCell('Total (INR)', fontBold, isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  // Items
                  ...data.items.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final item = entry.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: entry.key % 2 == 0 ? PdfColor.fromHex('#FFFFFF') : PdfColor.fromHex('#F8FAFC'),
                      ),
                      children: [
                        _buildTableCell('$idx', fontRegular, align: pw.TextAlign.center),
                        _buildTableCell(item.name, fontMedium),
                        _buildTableCell(item.category, fontRegular),
                        _buildTableCell('${item.quantity}', fontRegular, align: pw.TextAlign.center),
                        _buildTableCell('Rs. ${item.unitPrice.toStringAsFixed(0)}', fontRegular, align: pw.TextAlign.right),
                        _buildTableCell('Rs. ${item.totalPrice.toStringAsFixed(0)}', fontMedium, align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 14),

              // 4. Financial Calculations Summary Box
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Terms Box
                  pw.Expanded(
                    flex: 6,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F8FAFC'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'TERMS & IMPLEMENTATION CONDITIONS:',
                            style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColor.fromHex('#475569')),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '• 1 Year on-site/replacement warranty on all hardware items.\n'
                            '• Free software setup, staff training & KDS configuration included.\n'
                            '• 50% Advance with Purchase Order, 50% upon successful installation.\n'
                            '• 24/7 dedicated support via LiveRestro Help Center & priority WhatsApp line.',
                            style: pw.TextStyle(font: fontRegular, fontSize: 7.8, color: PdfColor.fromHex('#64748B'), lineSpacing: 2),
                          ),
                          if (data.notes.isNotEmpty) ...[
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'Special Remarks: ${data.notes}',
                              style: pw.TextStyle(font: fontMedium, fontSize: 8, color: PdfColor.fromHex('#0284C7')),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  // Totals Box
                  pw.Expanded(
                    flex: 5,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F1F5F9'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
                      ),
                      child: pw.Column(
                        children: [
                          _buildSummaryRow('Subtotal:', 'Rs. ${data.subtotal.toStringAsFixed(0)}', fontRegular, fontMedium),
                          if (data.discountPercent > 0) ...[
                            pw.SizedBox(height: 4),
                            _buildSummaryRow(
                              'Discount (${data.discountPercent.toStringAsFixed(0)}%):',
                              '- Rs. ${data.discountAmount.toStringAsFixed(0)}',
                              fontRegular,
                              fontMedium,
                              textColor: PdfColor.fromHex('#16A34A'),
                            ),
                          ],
                          pw.SizedBox(height: 4),
                          _buildSummaryRow('Taxable Amount:', 'Rs. ${data.taxableAmount.toStringAsFixed(0)}', fontRegular, fontMedium),
                          pw.SizedBox(height: 4),
                          _buildSummaryRow('GST (18%):', 'Rs. ${data.gstAmount.toStringAsFixed(0)}', fontRegular, fontMedium),
                          pw.SizedBox(height: 6),
                          pw.Divider(thickness: 1, color: PdfColor.fromHex('#CBD5E1')),
                          pw.SizedBox(height: 4),
                          _buildSummaryRow(
                            'Grand Total (INR):',
                            'Rs. ${data.grandTotal.toStringAsFixed(0)}',
                            fontBold,
                            fontBold,
                            fontSize: 11,
                            textColor: PdfColor.fromHex('#714B67'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // 5. Sign-off & Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LiveRestro Technologies Pvt Ltd',
                        style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColor.fromHex('#0F172A')),
                      ),
                      pw.Text(
                        'support@liverestro.com • www.liverestro.com',
                        style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColor.fromHex('#64748B')),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 120,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#94A3B8'), width: 1)),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Authorized Signatory',
                        style: pw.TextStyle(font: fontMedium, fontSize: 8, color: PdfColor.fromHex('#64748B')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 8.5 : 8,
          color: isHeader ? PdfColors.white : PdfColor.fromHex('#1E293B'),
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value,
    pw.Font labelFont,
    pw.Font valueFont, {
    double fontSize = 9,
    PdfColor? textColor,
  }) {
    final color = textColor ?? PdfColor.fromHex('#0F172A');
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: labelFont, fontSize: fontSize, color: PdfColor.fromHex('#475569'))),
        pw.Text(value, style: pw.TextStyle(font: valueFont, fontSize: fontSize, color: color)),
      ],
    );
  }

  /// Preview, Print or Share PDF
  static Future<void> previewQuotation(BuildContext context, QuotationData data) async {
    final bytes = await generateQuotationPdf(data);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'LiveRestro_Quote_${data.restaurantName.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Direct Share on WhatsApp
  static Future<void> shareOnWhatsApp(BuildContext context, QuotationData data) async {
    final cleanPhone = data.contactPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final grandTotalStr = currencyFormatter.format(data.grandTotal);

    final message = '''
*Hello ${data.contactPerson.isNotEmpty ? data.contactPerson : data.restaurantName}*,

Here is your custom *LiveRestro POS & Hardware Deal Proposal* (${data.quotationId}):

*Restaurant*: ${data.restaurantName}
*Items Included*:
${data.items.map((i) => ' • ${i.quantity}x ${i.name} (Rs. ${i.totalPrice.toStringAsFixed(0)})').join('\n')}

*Subtotal*: Rs. ${data.subtotal.toStringAsFixed(0)}
${data.discountPercent > 0 ? '*Discount*: ${data.discountPercent.toStringAsFixed(0)}% (-Rs. ${data.discountAmount.toStringAsFixed(0)})\n' : ''}*GST (18%)*: Rs. ${data.gstAmount.toStringAsFixed(0)}
*Grand Total*: *$grandTotalStr*

Includes 1-Year Hardware Warranty, Free Setup & Staff Training!

Prepared by: ${data.executiveName} (${data.executivePhone})
LiveRestro Cloud POS
''';

    final uri = Uri.parse('https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp on this device.')),
        );
      }
    }
  }
}
