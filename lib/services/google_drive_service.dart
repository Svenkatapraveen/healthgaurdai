import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleDriveUploadResult {
  final bool success;
  final String? fileId;
  final String? webViewLink;
  final String? errorMessage;
  final bool canceled;

  GoogleDriveUploadResult({
    required this.success,
    this.fileId,
    this.webViewLink,
    this.errorMessage,
    this.canceled = false,
  });
}

class GoogleDriveService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  /// Uploads PDF bytes directly to Google Drive under the authenticated user's account.
  static Future<GoogleDriveUploadResult> uploadPdfReport({
    required List<int> pdfBytes,
    required String fileName,
  }) async {
    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        return GoogleDriveUploadResult(
          success: false,
          canceled: true,
          errorMessage: 'Google Drive sign-in was canceled.',
        );
      }

      final authHeaders = await account.authHeaders;
      final accessToken = authHeaders['Authorization'];

      if (accessToken == null) {
        return GoogleDriveUploadResult(
          success: false,
          errorMessage: 'Failed to retrieve Google authentication token.',
        );
      }

      // Create multipart upload request to Google Drive API v3
      final uri = Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,webViewLink',
      );

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = accessToken;

      // Add Metadata part
      final metadataJson = jsonEncode({
        'name': fileName,
        'mimeType': 'application/pdf',
      });
      request.files.add(
        http.MultipartFile.fromString(
          'metadata',
          metadataJson,
          contentType: http.MediaType('application', 'json'),
        ),
      );

      // Add Media (PDF Bytes) part
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          pdfBytes,
          filename: fileName,
          contentType: http.MediaType('application', 'pdf'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final fileId = data['id'] as String?;
        final webViewLink = data['webViewLink'] as String? ?? (fileId != null ? 'https://drive.google.com/file/d/$fileId/view' : null);

        return GoogleDriveUploadResult(
          success: true,
          fileId: fileId,
          webViewLink: webViewLink,
        );
      } else {
        final errorData = jsonDecode(response.body);
        final message = errorData['error']?['message'] ?? 'Failed with status ${response.statusCode}';
        return GoogleDriveUploadResult(
          success: false,
          errorMessage: message,
        );
      }
    } catch (e) {
      return GoogleDriveUploadResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}
