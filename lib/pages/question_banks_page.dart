import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../services/pdf_service.dart';

class QuestionBanksPage extends StatefulWidget {
  const QuestionBanksPage({super.key});

  @override
  State<QuestionBanksPage> createState() => _QuestionBanksPageState();
}

class _QuestionBanksPageState extends State<QuestionBanksPage> {
  final PdfService _pdfService = PdfService();
  List<PdfFile> _pdfFiles = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _loadPdfFiles();
  }

  Future<void> _loadPdfFiles() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final files = await _pdfService.fetchPdfList();

      // Get file sizes for each PDF
      for (var file in files) {
        final size = await _pdfService.getFileSize(file.url);
        file = PdfFile(name: file.name, url: file.url, size: size);
      }

      setState(() {
        _pdfFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _downloadPdf(PdfFile pdfFile) async {
    try {
      setState(() {
        _downloadProgress[pdfFile.name] = 0.0;
      });

      final filePath = await _pdfService.downloadPdf(pdfFile, (progress) {
        setState(() {
          _downloadProgress[pdfFile.name] = progress;
        });
      });

      setState(() {
        _downloadProgress.remove(pdfFile.name);
      });

      // Show success message and option to open file
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded: ${pdfFile.name}'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFile.open(filePath),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _downloadProgress.remove(pdfFile.name);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded),
          color: const Color(0xFF2D2D2D),
        ),
        title: Text(
          'Question Banks',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadPdfFiles,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            color: const Color(0xFF2D2D2D),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _pdfFiles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading question banks...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load question banks',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPdfFiles,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6BC0),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfFiles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No question banks available'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPdfFiles,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF5C6BC0).withOpacity(0.1),
                        const Color(0xFF5C6BC0).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF5C6BC0).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5C6BC0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.library_books_rounded,
                          color: Color(0xFF5C6BC0),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Previous Year Question Banks',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Download and practice with past ${_pdfFiles.length} years papers',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Available Question Banks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
              ],
            ),
          ),

          // PDF list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _pdfFiles.length,
              itemBuilder: (context, index) {
                return _PdfTile(
                  pdfFile: _pdfFiles[index],
                  downloadProgress: _downloadProgress[_pdfFiles[index].name],
                  onDownload: () => _downloadPdf(_pdfFiles[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfTile extends StatelessWidget {
  final PdfFile pdfFile;
  final double? downloadProgress;
  final VoidCallback onDownload;

  const _PdfTile({
    required this.pdfFile,
    this.downloadProgress,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading = downloadProgress != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // PDF icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF44336).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Color(0xFFF44336),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pdfFile.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.file_present_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Size: ${pdfFile.size}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Download button
                if (isDownloading)
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      value: downloadProgress,
                      strokeWidth: 3,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF5C6BC0),
                      ),
                    ),
                  )
                else
                  IconButton(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF5C6BC0).withOpacity(0.1),
                      foregroundColor: const Color(0xFF5C6BC0),
                    ),
                    tooltip: 'Download PDF',
                  ),
              ],
            ),

            // Progress bar
            if (isDownloading) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: downloadProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF5C6BC0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${((downloadProgress ?? 0) * 100).toInt()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
