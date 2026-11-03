import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:web/web.dart' as web;
import '../../models/customer_model.dart';
import '../constants/app_constants.dart';
import 'date_formatter.dart';

class PdfExporter {
  /// Generates a professional multi-page PDF document for all customers and triggers browser download
  static Future<void> exportCustomersToPdf(List<CustomerModel> customers) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final dateStr = DateFormatter.formatDate(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NAYAGRA WATER TREATMENT PLANTS',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('0C243B'),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        AppConstants.appTagline,
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColor.fromHex('4A627A'),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        AppConstants.companyAddress,
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('1B6CA8'),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('E8F4FC'),
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColor.fromHex('1B6CA8'), width: 0.5),
                        ),
                        child: pw.Text(
                          'CUSTOMER DIRECTORY REPORT',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('1B6CA8'),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated: $dateStr',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColor.fromHex('70889E'),
                        ),
                      ),
                      pw.Text(
                        'Total Customers: ${customers.length}',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('0C243B'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColor.fromHex('1B6CA8'), thickness: 1.5),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Nayagra Water Treatment Plants - Confidential CRM Record',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          if (customers.isEmpty) {
            return [
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(40),
                  child: pw.Text(
                    'No customer records found.',
                    style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('70889E')),
                  ),
                ),
              ),
            ];
          }

          final headers = [
            '#',
            'Customer Name',
            'Phone Number',
            'Site / Facility',
            'City & State',
            'PIN Code',
            'Installed On',
            'Next Service Date',
            'Status',
          ];

          final data = customers.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final c = entry.value;

            final nextService = c.nextServiceDate != null
                ? DateFormatter.formatDate(c.nextServiceDate!)
                : 'Pending';

            final isOverdue = c.nextServiceDate != null && DateFormatter.isOverdue(c.nextServiceDate!);
            final status = isOverdue
                ? 'Overdue'
                : (c.totalServicesCompleted > 0 && c.nextServiceDate == null ? 'Completed' : 'Upcoming');

            return [
              '$index',
              c.name,
              c.phoneNumber,
              c.siteName.isNotEmpty ? c.siteName : c.name,
              '${c.city.isNotEmpty ? c.city : "N/A"}, ${c.state}',
              c.pinCode.isNotEmpty ? c.pinCode : 'N/A',
              DateFormatter.formatDate(c.installationDate),
              nextService,
              status,
            ];
          }).toList();

          return [
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              border: pw.TableBorder.all(color: PdfColor.fromHex('E2E8F0'), width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('0C243B'),
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.center,
                6: pw.Alignment.center,
                7: pw.Alignment.center,
                8: pw.Alignment.center,
              },
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              oddRowDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('F8FAFC'),
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      try {
        final base64String = base64Encode(bytes);
        final filename = 'Nayagra_Customers_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}.pdf';
        final url = 'data:application/pdf;base64,$base64String';
        final anchor = web.HTMLAnchorElement()
          ..href = url
          ..download = filename;
        web.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
      } catch (e) {
        debugPrint('Web PDF download error: $e');
      }
    } else {
      debugPrint('Generated PDF bytes: ${bytes.length}');
    }
  }

  /// Generates a single customer profile & maintenance report PDF
  static Future<void> exportCustomerProfilePdf({
    required CustomerModel customer,
    required List<dynamic> services,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NAYAGRA WATER TREATMENT PLANTS',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('0C243B'),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        AppConstants.companyAddress,
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColor.fromHex('1B6CA8'),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('E8F4FC'),
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColor.fromHex('1B6CA8'), width: 0.5),
                        ),
                        child: pw.Text(
                          'PLANT SERVICE REPORT',
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('1B6CA8'),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Date: ${DateFormatter.formatDate(now)}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColor.fromHex('1B6CA8'), thickness: 1.5),
              pw.SizedBox(height: 10),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Customer Details Card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('F8FAFC'),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColor.fromHex('E2E8F0'), width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Client & Installation Details',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('0C243B')),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildPdfRow('Customer Name:', customer.name),
                            _buildPdfRow('Contact Number:', customer.phoneNumber),
                            _buildPdfRow('Site / Facility:', customer.siteName.isNotEmpty ? customer.siteName : customer.name),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildPdfRow('Installation Date:', DateFormatter.formatDate(customer.installationDate)),
                            _buildPdfRow('Next Service Due:', customer.nextServiceDate != null ? DateFormatter.formatDate(customer.nextServiceDate!) : 'Scheduled'),
                            _buildPdfRow('Location:', '${customer.city.isNotEmpty ? customer.city : "N/A"}, ${customer.state}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (customer.fullAddress.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    _buildPdfRow('Address:', customer.fullAddress),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            if (customer.products.isNotEmpty) ...[
              pw.Text(
                'Installed Equipment & Products',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('0C243B')),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['#', 'Product / Equipment Name', 'Specification & Details'],
                data: customer.products.asMap().entries.map((entry) {
                  return [
                    '#${entry.key + 1}',
                    entry.value.name,
                    entry.value.details.isNotEmpty ? entry.value.details : '-',
                  ];
                }).toList(),
                border: pw.TableBorder.all(color: PdfColor.fromHex('E2E8F0'), width: 0.5),
                headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('1B6CA8')),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
              pw.SizedBox(height: 14),
            ],

            // Service History Header
            pw.Text(
              '6-Month Maintenance & Service History',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('0C243B')),
            ),
            pw.SizedBox(height: 8),

            if (services.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Text(
                  'No service records available yet. First service will be due 6 months from installation.',
                  style: pw.TextStyle(fontSize: 9.5, color: PdfColor.fromHex('70889E')),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: ['#', 'Scheduled', 'Completed', 'Status', 'Technician', 'Service Notes & Changes'],
                data: services.map((s) {
                  return [
                    '#${s.serviceNumber}',
                    DateFormatter.formatDate(s.serviceDate),
                    s.completedDate != null ? DateFormatter.formatDate(s.completedDate!) : '-',
                    s.status,
                    s.technicianName != null && s.technicianName!.isNotEmpty ? s.technicianName! : '-',
                    s.serviceNotes.isNotEmpty ? s.serviceNotes : (s.changesMade.isNotEmpty ? s.changesMade : '-'),
                  ];
                }).toList(),
                border: pw.TableBorder.all(color: PdfColor.fromHex('E2E8F0'), width: 0.5),
                headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('0C243B')),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      try {
        final cleanName = customer.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        final filename = 'Nayagra_${cleanName}_Report.pdf';
        final base64String = base64Encode(bytes);
        final url = 'data:application/pdf;base64,$base64String';
        final anchor = web.HTMLAnchorElement()
          ..href = url
          ..download = filename;
        web.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
      } catch (e) {
        debugPrint('Web PDF download error: $e');
      }
    }
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 85,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('4A627A')),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 8.5, color: PdfColor.fromHex('0C243B')),
            ),
          ),
        ],
      ),
    );
  }
}
