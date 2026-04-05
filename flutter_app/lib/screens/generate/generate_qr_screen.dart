import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/box_repository.dart';
import '../../widgets/loading_overlay.dart';

class GenerateQRScreen extends ConsumerStatefulWidget {
  const GenerateQRScreen({super.key});

  @override
  ConsumerState<GenerateQRScreen> createState() => _GenerateQRScreenState();
}

class _GenerateQRScreenState extends ConsumerState<GenerateQRScreen> {
  final _countController = TextEditingController(text: '10');
  List<String> _generatedIds = [];
  bool _isLoading = false;
  bool _isGenerated = false;

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  Future<void> _generateQRCodes() async {
    final count = int.tryParse(_countController.text);
    if (count == null || count < 1 || count > AppConstants.maxQRBatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter a number between 1 and ${AppConstants.maxQRBatch}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      final repo = ref.read(boxRepositoryProvider);

      final startNum = await repo.getNextBoxNumber(user!.uid);
      final ids = await repo.reserveBoxIds(user.uid, count, startNum);

      setState(() {
        _generatedIds = ids;
        _isGenerated = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Build the full PDF bytes with all QR codes
  Future<Uint8List> _buildPdfBytes() async {
    final pdf = pw.Document();

    // Create labels in batches of 10 per page (2 cols x 5 rows)
    const labelsPerPage = 10;
    const cols = 2;

    for (int page = 0;
        page < (_generatedIds.length / labelsPerPage).ceil();
        page++) {
      final startIdx = page * labelsPerPage;
      final endIdx = (startIdx + labelsPerPage).clamp(0, _generatedIds.length);
      final pageIds = _generatedIds.sublist(startIdx, endIdx);

      // Generate QR images for this page
      final qrImages = <Uint8List>[];
      for (final id in pageIds) {
        final url = 'https://qrbox-cbcbb.web.app/box/$id';
        final qrPainter = QrPainter(
          data: url,
          version: QrVersions.auto,
          gapless: true,
        );
        // Render QR to canvas then encode as PNG for PDF
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        // Paint white background first
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 200, 200),
          Paint()..color = const Color(0xFFFFFFFF),
        );
        qrPainter.paint(canvas, const Size(200, 200));
        final picture = recorder.endRecording();
        final img = await picture.toImage(200, 200);
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          qrImages.add(byteData.buffer.asUint8List());
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('QRBox Labels',
                          style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('Page ${page + 1}',
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),
                // Labels grid
                pw.Expanded(
                  child: pw.GridView(
                    crossAxisCount: cols,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.85,
                    children: List.generate(pageIds.length, (i) {
                      return pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: PdfColors.grey300, width: 0.5),
                          borderRadius:
                              pw.BorderRadius.circular(8),
                        ),
                        child: pw.Column(
                          mainAxisAlignment:
                              pw.MainAxisAlignment.center,
                          children: [
                            if (i < qrImages.length)
                              pw.Image(
                                pw.MemoryImage(qrImages[i]),
                                width: 100,
                                height: 100,
                              ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              pageIds[i],
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'qrbox-cbcbb.web.app/box/${pageIds[i]}',
                              style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  Future<void> _generatePDF() async {
    setState(() => _isLoading = true);
    try {
      final pdfBytes = await _buildPdfBytes();

      // Print/Share PDF
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'QRBox_Labels_${_generatedIds.first}_to_${_generatedIds.last}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.generateQR),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: _isGenerated ? 'Generating PDF...' : 'Creating QR codes...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Card(
                color: AppColors.qrBackground,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.qr_code,
                            color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Batch QR Generator',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Generate multiple QR codes at once and print labels for your boxes.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (!_isGenerated) ...[
                // Count input
                TextFormField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppStrings.numberOfCodes,
                    prefixIcon: const Icon(Icons.numbers),
                    hintText: 'e.g., 10',
                    helperText: 'Max ${AppConstants.maxQRBatch} codes per batch',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _generateQRCodes,
                    icon: const Icon(Icons.qr_code),
                    label: const Text(AppStrings.generateQR),
                  ),
                ),
              ] else ...[
                // Results
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_generatedIds.length} QR Codes Generated',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isGenerated = false;
                          _generatedIds = [];
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('New Batch'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // QR Preview Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.8,
                  ),
                  itemCount:
                      _generatedIds.length > 12 ? 12 : _generatedIds.length,
                  itemBuilder: (context, index) {
                    if (index == 11 && _generatedIds.length > 12) {
                      return Card(
                        child: Center(
                          child: Text(
                            '+${_generatedIds.length - 11}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      );
                    }

                    final id = _generatedIds[index];
                    final url = 'https://qrbox-cbcbb.web.app/box/$id';
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: QrImageView(
                                data: url,
                                version: QrVersions.auto,
                                padding: const EdgeInsets.all(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              id,
                              style: const TextStyle(
                                fontSize: 9,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // PDF button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _generatePDF,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text(AppStrings.generatePDF),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      try {
                        final pdfBytes = await _buildPdfBytes();
                        await Printing.sharePdf(
                          bytes: pdfBytes,
                          filename: 'QRBox_Labels.pdf',
                        );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Share error: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share PDF'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
