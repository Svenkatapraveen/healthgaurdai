import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';

Future<void> openPdfUrlInNewTab(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    await launchUrl(uri);
  }
}

Future<void> downloadPdfFileFromUrl(String url, String fileName, Uint8List? bytes) async {
  if (bytes != null && bytes.isNotEmpty) {
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  } else {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(uri);
    }
  }
}
