import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Container(
            width: PdfPageFormat.a4.width * 0.85,
            height: PdfPageFormat.a4.height * 0.8,
            padding: const pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#4C1D95'), width: 3),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('GETTALLER', style: pw.TextStyle(fontSize: 14, letterSpacing: 6, color: PdfColor.fromHex('#4C1D95'))),
                pw.SizedBox(height: 20),
                pw.Text('Certificate of Completion', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1A1A2E'))),
                pw.SizedBox(height: 10),
                pw.Container(width: 80, height: 2, color: PdfColor.fromHex('#7C3AED')),
                pw.SizedBox(height: 30),
                pw.Text('This certifies that', style: pw.TextStyle(fontSize: 14, color: PdfColor.fromHex('#666666'))),
                pw.SizedBox(height: 10),
                pw.Text('Alex Johnson', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#4C1D95'))),
                pw.SizedBox(height: 10),
                pw.Text('has successfully completed the', style: pw.TextStyle(fontSize: 14, color: PdfColor.fromHex('#666666'))),
                pw.SizedBox(height: 10),
                pw.Text('90-Day Height Growth Program', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1A1A2E'))),
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Column(children: [
                      pw.Text('162.0 cm', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#666666'))),
                      pw.Text('Starting Height', style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('#999999'))),
                    ]),
                    pw.SizedBox(width: 40),
                    pw.Text('\u2192', style: pw.TextStyle(fontSize: 24, color: PdfColor.fromHex('#7C3AED'))),
                    pw.SizedBox(width: 40),
                    pw.Column(children: [
                      pw.Text('178.5 cm', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#4C1D95'))),
                      pw.Text('Target Potential', style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('#999999'))),
                    ]),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Text('15/03/2026 \u2014 13/06/2026', style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('#999999'))),
                pw.SizedBox(height: 8),
                pw.Text('15 years old \u2022 Male', style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('#999999'))),
                pw.SizedBox(height: 40),
                pw.Container(width: 200, height: 1, color: PdfColor.fromHex('#CCCCCC')),
                pw.SizedBox(height: 8),
                pw.Text('gettaller.app', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#AAAAAA'))),
              ],
            ),
          ),
        );
      },
    ),
  );
  final file = File('certificate_example.pdf');
  await file.writeAsBytes(await pdf.save());
  print('Saved: ${file.path}');
}
