import 'dart:html' as html;
import 'dart:typed_data';

Future<void> openPdfUrlInNewTab(String url) async {
  html.window.open(url, '_blank', 'noopener,noreferrer');
}

Future<void> downloadPdfFileFromUrl(String url, String fileName, Uint8List? bytes) async {
  if (bytes != null && bytes.isNotEmpty) {
    final blob = html.Blob([bytes], 'application/pdf');
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: blobUrl)
      ..target = '_blank'
      ..download = fileName;
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(blobUrl);
  } else {
    final anchor = html.AnchorElement(href: url)
      ..target = '_blank'
      ..download = fileName;
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
  }
}
