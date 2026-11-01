import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

class CsvExporter {
  /// Exports 2D list of data to a CSV file and triggers browser download
  static void exportToCsv({
    required String filename,
    required List<List<dynamic>> rows,
  }) {
    final csvData = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csvData);

    if (kIsWeb) {
      try {
        final base64String = base64Encode(bytes);
        final url = 'data:text/csv;charset=utf-8;base64,$base64String';
        final anchor = web.HTMLAnchorElement()
          ..href = url
          ..download = filename.endsWith('.csv') ? filename : '$filename.csv';
        web.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
      } catch (e) {
        debugPrint('Web CSV download error: $e');
      }
    } else {
      debugPrint('Non-web CSV export: $filename, rows: ${rows.length}');
    }
  }
}
