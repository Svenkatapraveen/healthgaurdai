import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';

Future<void> openPdfUrlInNewTab(String url, {Uint8List? bytes}) async {
  if (bytes != null && bytes.isNotEmpty) {
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  } else if (url.isNotEmpty) {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(uri);
    }
  }
}

Future<void> downloadPdfFileFromUrl(String url, String fileName, {Uint8List? bytes}) async {
  if (bytes != null && bytes.isNotEmpty) {
    await Printing.sharePdf(bytes: bytes, filename: fileName.isNotEmpty ? fileName : 'HealthGuard_AI_Medical_Report.pdf');
  } else if (url.isNotEmpty) {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(uri);
    }
  }
}
