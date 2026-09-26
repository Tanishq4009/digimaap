import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../models/data.dart';
import '../../services/lmo_auth_service.dart';
import 'checklist_page.dart';

class InspectionDetailPage extends StatefulWidget {
  final String inspectionId;
  const InspectionDetailPage({
    super.key,
    required this.inspectionId,
  });

  @override
  State<InspectionDetailPage> createState() =>
      _InspectionDetailPageState();
}

class _InspectionDetailPageState
    extends State<InspectionDetailPage> {
  bool _isVerifying = false;

  Future<void> _verifyLMOAndBegin() async {
    setState(() => _isVerifying = true);
    try {
      final authService = LmoAuthService();
      final success = await authService
          .verifyInspectorForField(
            widget.inspectionId,
            "LMO_OFFICER_01",
          );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Inspector Verified Successfully.',
            ),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChecklistPage(
              inspectionId: widget.inspectionId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Inspector Verification Failed. Access Denied.',
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      debugPrint('Biometric error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Inspector Verification Failed. Access Denied.',
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = inspectionFor(widget.inspectionId);
    return Shell(
      role: AppRole.inspector,
      title: 'Inspection pre-check',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange50,
                          borderRadius:
                              BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.priority,
                          style: const TextStyle(
                            color: AppColors.saffron,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          'ID: ${item.id}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.business,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.slate,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slate,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(
                    height: 1,
                    color: AppColors.slate100,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.6,
                    children: [
                      InfoGridItem(
                        label: 'Instrument',
                        value: item.instrument,
                      ),
                      InfoGridItem(
                        label: 'Make / model',
                        value: item.model,
                      ),
                      InfoGridItem(
                        label: 'Serial number',
                        value: item.serial,
                      ),
                      InfoGridItem(
                        label: 'Application No',
                        value:
                            item.applicationId ?? item.id,
                      ),
                      InfoGridItem(
                        label: 'Request time',
                        value: item.time,
                      ),
                      InfoGridItem(
                        label: 'Assigned to',
                        value:
                            item.assignedTo ??
                            item.assignedOfficerId ??
                            'LMO Officer',
                      ),
                    ],
                  ),
                  if (item.previousCertificateUrl != null ||
                      item.manufacturerCertificateUrl !=
                          null) ...[
                    const SizedBox(height: 16),
                    const Divider(
                      height: 1,
                      color: AppColors.slate100,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ATTACHED DOCUMENTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        if (item.previousCertificateUrl !=
                            null)
                          Expanded(
                            child: _DocumentPreview(
                              title: 'Previous Certificate',
                              url: item
                                  .previousCertificateUrl!,
                            ),
                          ),
                        if (item.previousCertificateUrl !=
                                null &&
                            item.manufacturerCertificateUrl !=
                                null)
                          const SizedBox(width: 16),
                        if (item.manufacturerCertificateUrl !=
                            null)
                          Expanded(
                            child: _DocumentPreview(
                              title: 'Manufacturer Cert',
                              url: item
                                  .manufacturerCertificateUrl!,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _isVerifying
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.saffron,
                    ),
                  )
                : PrimaryButton(
                    onPressed: _verifyLMOAndBegin,
                    child: const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fingerprint, size: 18),
                        SizedBox(width: 8),
                        Text('Verify LMO & Begin'),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  final String title;
  final String url;

  const _DocumentPreview({
    required this.title,
    required this.url,
  });

  bool get _isPdf {
    final lower = url.toLowerCase();
    return lower.endsWith('.pdf') ||
        lower.contains('.pdf?') ||
        lower.contains('/pdf/') ||
        lower.contains('format=pdf') ||
        lower.contains('resource_type=raw');
  }

  String get _thumbnailUrl {
    if (_isPdf) {
      // Cloudinary & common CDN URL transformation: replacing .pdf with .jpg renders 1st page visual thumbnail
      return url.replaceAll(
        RegExp(r'\.pdf(\?.*)?$', caseSensitive: false),
        '.jpg',
      );
    }
    return url;
  }

  Future<void> _launchPdfUrl(BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Could not launch PDF URL: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open PDF file. Please check link.',
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _openImageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _thumbnailUrl,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) {
                        return Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons
                                    .picture_as_pdf_rounded,
                                color: AppColors.errorRed,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _launchPdfUrl(context);
                                },
                                icon: const Icon(
                                  Icons.open_in_new,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Open PDF Document',
                                ),
                                style:
                                    ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppColors
                                              .errorRed,
                                      foregroundColor:
                                          Colors.white,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () =>
                    Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (_isPdf) {
      _launchPdfUrl(context);
    } else {
      _openImageDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            if (_isPdf)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.red50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.red200,
                  ),
                ),
                child: const Text(
                  'PDF',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: AppColors.errorRed,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _handleTap(context),
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isPdf
                    ? AppColors.errorRed.withValues(
                        alpha: 0.4,
                      )
                    : AppColors.slate.withValues(
                        alpha: 0.2,
                      ),
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _thumbnailUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isPdf
                                ? Icons
                                      .picture_as_pdf_rounded
                                : Icons
                                      .broken_image_outlined,
                            color: _isPdf
                                ? AppColors.errorRed
                                : AppColors.slate,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isPdf
                                ? 'Tap to open PDF'
                                : 'Document Preview',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _isPdf
                                  ? AppColors.errorRed
                                  : AppColors.ink,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (_isPdf)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: 0.65,
                        ),
                        borderRadius: BorderRadius.circular(
                          6,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'OPEN PDF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
