import 'dart:io';
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class PredictPage extends StatefulWidget {
  const PredictPage({super.key});

  @override
  State<PredictPage> createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  final _formKey = GlobalKey<FormState>();
  final _physicsController = TextEditingController();
  final _chemistryController = TextEditingController();
  final _mathsController = TextEditingController();
  
  String _selectedCategory = 'OC';
  final List<String> _categories = ['OC', 'BC', 'MBC', 'SC', 'ST'];
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _recommendations = [];
  double? _calculatedCutoff;

  @override
  void dispose() {
    _physicsController.dispose();
    _chemistryController.dispose();
    _mathsController.dispose();
    super.dispose();
  }

  Future<void> _predictColleges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _recommendations = [];
      _calculatedCutoff = null;
    });

    try {
      final physics = double.parse(_physicsController.text);
      final chemistry = double.parse(_chemistryController.text);
      final maths = double.parse(_mathsController.text);

      // Tamil Nadu Engineering Cutoff Formula
      final cutoff = (physics + chemistry) / 2 + maths;
      
      setState(() {
        _calculatedCutoff = cutoff;
      });

      // Connect to Supabase Postgres
      final connection = await Connection.open(
        Endpoint(
          host: 'db.qdrddkzidvajonwhyjol.supabase.co',
          database: 'postgres',
          username: 'postgres',
          password: 'eduguidee20',
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.require,
        ),
      );

      final catColumn = '${_selectedCategory.toLowerCase()}_cutoff';
      
      // Query
      final result = await connection.execute(
        Sql.named('''
          SELECT college_name, department, counseling_code, $catColumn as required_cutoff 
          FROM cutoffs 
          WHERE $catColumn IS NOT NULL AND $catColumn <= @cutoff 
          ORDER BY $catColumn DESC, college_name, department 
          LIMIT 20
        '''),
        parameters: {'cutoff': cutoff},
      );

      final List<Map<String, dynamic>> fetched = [];
      for (final row in result) {
        fetched.add({
          'college_name': row[0] as String?,
          'department': row[1] as String?,
          'counseling_code': row[2].toString(),
          'required_cutoff': row[3] as double?,
        });
      }

      setState(() {
        _recommendations = fetched;
      });

      await connection.close();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generatePdf() async {
    try {
      final pdf = pw.Document();

      // Ensure data is safe
      final physics = _physicsController.text.isEmpty ? '0' : _physicsController.text;
      final chemistry = _chemistryController.text.isEmpty ? '0' : _chemistryController.text;
      final maths = _mathsController.text.isEmpty ? '0' : _mathsController.text;
      final cutoffStr = _calculatedCutoff?.toStringAsFixed(2) ?? 'N/A';
      final category = _selectedCategory;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('EduGuide Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Student Details
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Student Marks', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Physics: $physics'),
                        pw.Text('Chemistry: $chemistry'),
                        pw.Text('Maths: $maths'),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Category: $category'),
                        pw.Text('Cutoff Key: $cutoffStr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              pw.Text('Recommended Colleges', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              
              if (_recommendations.isEmpty)
                pw.Text('No colleges found for this cutoff.')
              else ...[
                // List Header
                pw.Container(
                  color: PdfColors.orange100,
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text('College Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Expanded(flex: 2, child: pw.Text('Dept', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Expanded(flex: 1, child: pw.Text('Code', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Expanded(flex: 1, child: pw.Text('Cutoff', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                ),
                // List Items (Flattened for better pagination)
                ..._recommendations.map((item) {
                   return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(flex: 3, child: pw.Text(item['college_name']?.toString() ?? 'N/A', style: const pw.TextStyle(fontSize: 9))),
                        pw.Expanded(flex: 2, child: pw.Text(item['department']?.toString() ?? 'N/A', style: const pw.TextStyle(fontSize: 9))),
                        pw.Expanded(flex: 1, child: pw.Text(item['counseling_code']?.toString() ?? '-', style: const pw.TextStyle(fontSize: 9))),
                        pw.Expanded(flex: 1, child: pw.Text(item['required_cutoff']?.toString() ?? 'N/A', style: const pw.TextStyle(fontSize: 9, color: PdfColors.green700), textAlign: pw.TextAlign.right)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ];
          },
        ),
      );

      final output = await getApplicationDocumentsDirectory();
      if (!await output.exists()) {
        await output.create(recursive: true);
      }
      
      final file = File('${output.path}/EduGuide_Report.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved to ${file.path}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                OpenFile.open(file.path);
              },
            ),
          ),
        );
        await OpenFile.open(file.path);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
        debugPrint('PDF Error: $e');
        debugPrint('Stack: $stackTrace');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'College Predictor',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your marks to find eligible colleges.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              
              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _physicsController,
                              label: 'Physics',
                              icon: Icons.science_rounded,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _chemistryController,
                              label: 'Chemistry',
                              icon: Icons.biotech_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _mathsController,
                              label: 'Maths',
                              icon: Icons.calculate_rounded,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.category_rounded),
                              ),
                              items: _categories.map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCategory = newValue!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _predictColleges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8A80),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading 
                            ? const SizedBox(
                                height: 20, 
                                width: 20, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              )
                            : const Text(
                                'Predict Colleges',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              if (_calculatedCutoff != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column( // Changed to column to accommodate download button nicely if needed here
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded, color: Color(0xFF1976D2)),
                          const SizedBox(width: 12),
                          Text(
                            'Your Cutoff: ${_calculatedCutoff!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              
              if (_recommendations.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recommended Colleges (${_recommendations.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    IconButton(
                      onPressed: _generatePdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFD84315)),
                      tooltip: 'Download Report',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recommendations.length,
                  itemBuilder: (context, index) {
                    final college = _recommendations[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB5A7).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.school_rounded, color: Color(0xFFFF8A80)),
                        ),
                        title: Text(
                          college['college_name'] ?? 'Unknown College',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              college['department'] ?? 'Unknown Dept',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Code: ${college['counseling_code']}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Req: ${college['required_cutoff']?.toStringAsFixed(1) ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _generatePdf,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download Full Report (PDF)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFFF8A80)),
                      foregroundColor: const Color(0xFFFF8A80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else if (_calculatedCutoff != null && !_isLoading) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'No matching colleges found. Try improving your marks or checking other categories.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        final n = double.tryParse(value);
        if (n == null || n < 0 || n > 100) {
          return '0-100';
        }
        return null;
      },
    );
  }
}
