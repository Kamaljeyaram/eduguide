import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PdfService {
  static const String baseUrl = 'https://book-backend-iszd.onrender.com';
  final Dio _dio = Dio();

  /// Fetch list of available PDFs from the server
  Future<List<PdfFile>> fetchPdfList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/uploads'));

      if (response.statusCode == 200) {
        // Parse HTML response to extract file links
        final htmlContent = response.body;
        debugPrint('Response body length: ${htmlContent.length}');

        List<PdfFile> pdfFiles = _parseHtmlForPdfFiles(htmlContent);

        // If HTML parsing didn't work well, try alternative approach
        if (pdfFiles.length < 3) {
          debugPrint(
            'HTML parsing found few files, trying alternative approach...',
          );
          pdfFiles = await _tryAlternativeFileList();
        }

        return pdfFiles;
      } else {
        throw Exception('Failed to load PDF list: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching PDF list: $e');
      throw Exception('Error fetching PDF list: $e');
    }
  }

  /// Alternative method to get file list based on known file patterns
  Future<List<PdfFile>> _tryAlternativeFileList() async {
    final List<String> knownFiles = [
      'Biology%202025.pdf',
      'Chemistry-2025.pdf',
      'Com%20Sci%202025.pdf',
      'Math-2025.pdf',
      'Physics%202025.pdf',
    ];

    final List<PdfFile> pdfFiles = [];

    for (final fileName in knownFiles) {
      try {
        final url = '$baseUrl/uploads/$fileName';
        final response = await http.head(Uri.parse(url));

        if (response.statusCode == 200) {
          final decodedName = Uri.decodeComponent(fileName);
          final contentLength = response.headers['content-length'];
          final size = contentLength != null
              ? _formatFileSize(int.parse(contentLength))
              : 'Unknown';

          pdfFiles.add(PdfFile(name: decodedName, url: url, size: size));
          debugPrint('Found file via HEAD request: $decodedName');
        }
      } catch (e) {
        debugPrint('Could not check file $fileName: $e');
      }
    }

    return pdfFiles;
  }

  /// Parse HTML content to extract PDF file information
  List<PdfFile> _parseHtmlForPdfFiles(String htmlContent) {
    final List<PdfFile> pdfFiles = [];

    debugPrint(
      'HTML Content: $htmlContent',
    ); // Debug print to see actual content

    // Simple regex to find download links
    final RegExp linkPattern = RegExp(
      r'<a href="([^"]*)" download>([^<]*)</a>',
    );
    final matches = linkPattern.allMatches(htmlContent);

    debugPrint('Found ${matches.length} matches'); // Debug print

    for (final match in matches) {
      final url = match.group(1);
      final fileName = match.group(2);

      debugPrint('Match - URL: $url, FileName: $fileName'); // Debug print

      if (url != null && fileName != null) {
        // Decode URL-encoded filename for display
        final decodedFileName = Uri.decodeComponent(fileName);

        // Check if it's a PDF file (either in original or decoded name)
        if (fileName.toLowerCase().contains('.pdf') ||
            decodedFileName.toLowerCase().contains('.pdf')) {
          pdfFiles.add(
            PdfFile(
              name: decodedFileName,
              url: '$baseUrl$url',
              size: 'Unknown', // Size not available from HTML
            ),
          );
          debugPrint('Added PDF: $decodedFileName'); // Debug print
        }
      }
    }

    debugPrint('Total PDFs found: ${pdfFiles.length}'); // Debug print
    return pdfFiles;
  }

  /// Download PDF file to device storage
  Future<String> downloadPdf(
    PdfFile pdfFile,
    Function(double) onProgress,
  ) async {
    try {
      // Request storage permission
      await _requestStoragePermission();

      // Get download directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create EduGuide folder if it doesn't exist
      final eduGuideDir = Directory('${directory.path}/EduGuide');
      if (!await eduGuideDir.exists()) {
        await eduGuideDir.create(recursive: true);
      }

      final filePath = '${eduGuideDir.path}/${pdfFile.name}';

      // Download the file with progress tracking
      await _dio.download(
        pdfFile.url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      return filePath;
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      throw Exception('Error downloading PDF: $e');
    }
  }

  /// Using app-specific storage that doesn't require permissions
  Future<void> _requestStoragePermission() async {
    // Using app-specific directories that don't require permissions
    debugPrint(
      'Using app-specific storage directory (no special permissions required)',
    );
  }

  /// Get file size from URL
  Future<String> getFileSize(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      final contentLength = response.headers['content-length'];

      if (contentLength != null) {
        final bytes = int.parse(contentLength);
        return _formatFileSize(bytes);
      }

      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Format file size in human readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

/// Model class for PDF file information
class PdfFile {
  final String name;
  final String url;
  final String size;

  PdfFile({required this.name, required this.url, required this.size});

  @override
  String toString() {
    return 'PdfFile(name: $name, url: $url, size: $size)';
  }
}
