import 'dart:html' as html;
import 'dart:typed_data';

Future<void> openPdfUrlInNewTab(String url, {Uint8List? bytes}) async {
  if (bytes != null && bytes.isNotEmpty) {
    final blob = html.Blob([bytes], 'application/pdf');
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(blobUrl, '_blank');
  } else if (url.isNotEmpty) {
    html.window.open(url, '_blank', 'noopener,noreferrer');
  }
}

Future<void> downloadPdfFileFromUrl(String url, String fileName, {Uint8List? bytes}) async {
  if (bytes != null && bytes.isNotEmpty) {
    final blob = html.Blob([bytes], 'application/pdf');
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: blobUrl)
      ..target = '_blank'
      ..download = fileName.isNotEmpty ? fileName : 'HealthGuard_AI_Medical_Report.pdf';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(blobUrl);
  } else if (url.isNotEmpty) {
    final anchor = html.AnchorElement(href: url)
      ..target = '_blank'
      ..download = fileName.isNotEmpty ? fileName : 'HealthGuard_AI_Medical_Report.pdf';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
  }
}
