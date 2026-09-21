import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import 'seal_capture_page.dart';

class _LoadBand {
  final double fromMultiples; // load ≥ fromMultiples * e
  final double
  toMultiples; // load <  toMultiples  * e  (double.infinity = no upper limit)
  final double mpeMultiples; // MPE = mpeMultiples * e
  const _LoadBand(this.fromMultiples, this.toMultiples, this.mpeMultiples);
}

const _mpeTable = <String, List<_LoadBand>>{
  'Class I': [
    _LoadBand(0, 50000, 0.5),
    _LoadBand(50000, 200000, 1.0),
    _LoadBand(200000, double.infinity, 1.5),
  ],
  'Class II': [
    _LoadBand(0, 5000, 0.5),
    _LoadBand(5000, 20000, 1.0),
    _LoadBand(20000, double.infinity, 1.5),
  ],
  'Class III': [
    _LoadBand(0, 500, 0.5),
    _LoadBand(500, 2000, 1.0),
    _LoadBand(2000, double.infinity, 1.5),
  ],
  'Class IIII': [
    _LoadBand(0, 50, 0.5),
    _LoadBand(50, 200, 1.0),
    _LoadBand(200, double.infinity, 1.5),
  ],
};

double _lookupMpe(String accuracyClass, double standardWeight, double e) {
  final bands = _mpeTable[accuracyClass];
  if (bands == null || e <= 0) return 0;
  final multiples = (standardWeight / e);
  for (final band in bands) {
    if (multiples >= band.fromMultiples && multiples < band.toMultiples) {
      return band.mpeMultiples * e;
    }
  }
  // Fallback: last band
  return bands.last.mpeMultiples * e;
}

class MpeCalculatorPage extends StatefulWidget {
  final String inspectionId;
  final Map<String, dynamic> auditTrailData;

  const MpeCalculatorPage({
    super.key,
    required this.inspectionId,
    this.auditTrailData = const {},
  });

  @override
  State<MpeCalculatorPage> createState() => _MpeCalculatorPageState();
}

class _MpeCalculatorPageState extends State<MpeCalculatorPage>
    with SingleTickerProviderStateMixin {
  // Form controllers
  String _accuracyClass = 'Class III';
  final _eCtrl = TextEditingController();
  final _stdWeightCtrl = TextEditingController();
  final _observedCtrl = TextEditingController();

  // Result state
  bool _calculated = false;
  double? _observedError;
  double? _mpe;
  bool? _passed;

  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _eCtrl.dispose();
    _stdWeightCtrl.dispose();
    _observedCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final e = double.tryParse(_eCtrl.text.trim());
    final stdWeight = double.tryParse(_stdWeightCtrl.text.trim());
    final observed = double.tryParse(_observedCtrl.text.trim());

    if (e == null || stdWeight == null || observed == null || e <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields correctly'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final obsErr = (observed - stdWeight).abs();
    final mpe = _lookupMpe(_accuracyClass, stdWeight, e);
    final passed = obsErr <= mpe;

    setState(() {
      _observedError = obsErr;
      _mpe = mpe;
      _passed = passed;
      _calculated = true;
    });

    _animCtrl.forward(from: 0);
  }

  void _reset() {
    setState(() {
      _calculated = false;
      _observedError = null;
      _mpe = null;
      _passed = null;
    });
    _animCtrl.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Shell(
      role: AppRole.inspector,
      title: 'MPE Calculator',
      nav: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info banner ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.heroCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calculate_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OIML R 76 · Legal Metrology Rules, 2011',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Automated MPE Verification',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Threshold fixed at 0.3e for repeatability check',
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Input Section ─────────────────────────────
            _SectionLabel(label: 'Instrument Parameters'),
            const SizedBox(height: 12),

            // Accuracy class selector
            _InputCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accuracy Class',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: ['Class I', 'Class II', 'Class III', 'Class IIII']
                        .map((cls) {
                          final active = _accuracyClass == cls;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _accuracyClass = cls);
                                _reset();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.navy
                                      : AppColors.slate100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  cls.replaceAll('Class ', ''),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: active
                                        ? Colors.white
                                        : AppColors.slate,
                                  ),
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // e, Standard weight, Observed reading
            Row(
              children: [
                Expanded(
                  child: _InputCard(
                    child: _NumField(
                      label: 'Scale Interval',
                      hint: 'e.g. 0.5',
                      unit: 'kg',
                      controller: _eCtrl,
                      onChanged: (_) => _reset(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InputCard(
                    child: _NumField(
                      label: 'Standard Weight (L)',
                      hint: 'e.g. 10.000',
                      unit: 'kg',
                      controller: _stdWeightCtrl,
                      onChanged: (_) => _reset(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputCard(
                    child: _NumField(
                      label: 'Observed Reading (I)',
                      hint: 'e.g. 10.020',
                      unit: 'kg',
                      controller: _observedCtrl,
                      onChanged: (_) => _reset(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Calculate Button ──────────────────────────
            if (!_calculated)
              PrimaryButton(
                onPressed: _calculate,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calculate_outlined),
                    SizedBox(width: 10),
                    Text('Calculate MPE'),
                  ],
                ),
              ),

            // ── Result Card ───────────────────────────────
            if (_calculated && _passed != null) ...[
              ScaleTransition(
                scale: _scaleAnim,
                child: _ResultCard(
                  passed: _passed!,
                  observedError: _observedError!,
                  mpe: _mpe!,
                  accuracyClass: _accuracyClass,
                  e: double.tryParse(_eCtrl.text) ?? 1,
                ),
              ),
              const SizedBox(height: 20),

              // PASS → continue; FAIL → go home
              if (_passed!)
                PrimaryButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SealCapturePage(
                          inspectionId: widget.inspectionId,
                          auditTrailData: widget.auditTrailData,
                        ),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_outlined),
                      SizedBox(width: 10),
                      Text('Continue to Seal Evidence'),
                    ],
                  ),
                )
              else
                _FailActionButtons(
                  onRecalculate: _reset,
                  onGoHome: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.slate400,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final Widget child;
  const _InputCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NumField extends StatelessWidget {
  final String label;
  final String hint;
  final String unit;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _NumField({
    required this.label,
    required this.hint,
    required this.unit,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.slate,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: AppColors.slate400,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                unit,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final bool passed;
  final double observedError;
  final double mpe;
  final String accuracyClass;
  final double e;

  const _ResultCard({
    required this.passed,
    required this.observedError,
    required this.mpe,
    required this.accuracyClass,
    required this.e,
  });

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppColors.success : AppColors.errorRed;
    final bgColor = passed ? AppColors.green50 : AppColors.red50;
    final icon = passed ? Icons.check_circle_rounded : Icons.cancel_rounded;

    // Repeatability check: 0.3e threshold
    final repeatOk = observedError <= 0.3 * e;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 12),
          Text(
            passed ? 'INSTRUMENT PASSED' : 'INSTRUMENT FAILED',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            passed
                ? 'Observed error is within the permissible limit.'
                : 'Observed error exceeds the permissible limit.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Result grid
          _ResultRow(
            label: 'Accuracy Class',
            value: accuracyClass,
            valueColor: AppColors.navy,
          ),
          const SizedBox(height: 10),
          _ResultRow(
            label: 'Observed Error',
            value: '${observedError.toStringAsFixed(4)} kg',
            valueColor: AppColors.ink,
          ),
          const SizedBox(height: 10),
          _ResultRow(
            label: 'Maximum Permissible Error',
            value: '${mpe.toStringAsFixed(4)} kg',
            valueColor: AppColors.ink,
          ),
          const SizedBox(height: 10),
          _ResultRow(
            label: 'Repeatability Threshold (0.3e)',
            value: '${(0.3 * e).toStringAsFixed(4)} kg',
            valueColor: AppColors.ink,
          ),
          const SizedBox(height: 10),
          _ResultRow(
            label: 'Repeatability Check',
            value: repeatOk ? 'OK' : 'FAIL',
            valueColor: repeatOk ? AppColors.success : AppColors.errorRed,
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.slate),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _FailActionButtons extends StatelessWidget {
  final VoidCallback onRecalculate;
  final VoidCallback onGoHome;

  const _FailActionButtons({
    required this.onRecalculate,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PrimaryButton(
          secondary: true,
          onPressed: onRecalculate,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh_rounded),
              SizedBox(width: 8),
              Text('Re-enter Readings'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: Material(
            color: AppColors.errorRed,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onGoHome,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Mark Failed & Go to Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
