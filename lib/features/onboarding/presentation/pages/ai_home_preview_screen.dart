import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../auth/presentation/pages/login_screen_view.dart';
import '../../../auth/presentation/pages/signup_screen_view.dart';

class AiHomePreviewScreen extends StatelessWidget {
  const AiHomePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1612),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 24),
                _buildHeroSection(),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 10),
                _buildCarrierChip(),
                const SizedBox(height: 14),
                _buildScanNowButton(),
                const SizedBox(height: 20),
                _buildIconRow(),
                const SizedBox(height: 24),
                _buildLiveDevicePreview(),
                const SizedBox(height: 24),
                _buildAiInsightsSection(),
                const SizedBox(height: 24),
                _buildBuiltForBusiness(),
                const SizedBox(height: 24),
                _buildCtaSection(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'imoscan',
              style: TextStyle(
                color: Color(0xFF8EFC7C),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFF1A73E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
          ],
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF111D1A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.notifications_outlined, color: Colors.white70, size: 20),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scan Any Device.\nKnow Everything.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Instant IMEI lookup, blacklist check, warranty status & resale value all in one tap.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF111D1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E3028), width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search, color: Colors.white.withValues(alpha: 0.4), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enter IMEI / Serial Number',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(6),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF8EFC7C),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.qr_code_scanner, color: Colors.black, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCarrierChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111D1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3028), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF8EFC7C),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('FREE', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('iPhone Carrier Check', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('8 verification types available', style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: Colors.white.withValues(alpha: 0.5), size: 20),
        ],
      ),
    );
  }

  Widget _buildScanNowButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8EFC7C),
          disabledBackgroundColor: const Color(0xFF8EFC7C),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: const Text(
          'Scan Now',
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildIconRow() {
    final icons = [
      ('assets/scanicon/fmidark.png', 'FMI'),
      ('assets/scanicon/carriedark.png', 'Carrier'),
      ('assets/scanicon/mdmdark.png', 'MDM'),
      ('assets/scanicon/gsxdark.png', 'GSX'),
      ('assets/scanicon/solddark.png', 'Sold By'),
      ('assets/scanicon/iclouddark.png', 'iCloud'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: icons.map((item) => _IconChip(assetPath: item.$1, label: item.$2)).toList(),
    );
  }

  Widget _buildLiveDevicePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Live Device Preview', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1D1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E3028), width: 1),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFF192820),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.smartphone, color: Color(0xFF8EFC7C), size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('iPhone 15 Pro Max', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('256GB · Natural Titanium', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF8EFC7C), width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Verified', style: TextStyle(color: Color(0xFF8EFC7C), fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _StatChip(label: 'AI Trust Score', value: '94/100', valueColor: Colors.white)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatChip(label: 'Warranty', value: 'Active', valueColor: Colors.white)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatChip(label: 'Blacklist', value: 'Clean', valueColor: const Color(0xFF8EFC7C))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AI Insights', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1D1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E3028), width: 1),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _TrustScorePainter(94),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('94', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Trust\nScore', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 8, height: 1.2)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: const [
                    _ProgressBar(label: 'Device Health', value: 0.85, displayValue: '85%'),
                    SizedBox(height: 10),
                    _ProgressBar(label: 'Fraud Risk', value: 0.06, displayValue: '6%', barColor: Color(0xFF8EFC7C)),
                    SizedBox(height: 10),
                    _ProgressBar(label: 'Resale Pred.', value: 0.92, displayValue: '92%'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1D1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E3028), width: 1),
                ),
                child: Column(
                  children: [
                    Text('Risk Meter', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 70,
                      height: 40,
                      child: CustomPaint(painter: _GaugePainter(0.1)),
                    ),
                    const SizedBox(height: 4),
                    const Text('Low', style: TextStyle(color: Color(0xFF8EFC7C), fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1D1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E3028), width: 1),
                ),
                child: Column(
                  children: [
                    Text('Fraud Detection', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CustomPaint(
                        painter: _DonutPainter(0.06),
                        child: const Center(
                          child: Text('6%', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Very Safe', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBuiltForBusiness() {
    final cards = [
      _BizCard(asset: 'assets/built/inventorydark.png', title: 'Inventory', subtitle: 'Track stock in real time', gradient: const LinearGradient(colors: [Color(0xFF0D2A1A), Color(0xFF143520)])),
      _BizCard(asset: 'assets/built/repairdark.png', title: 'Repair Track', subtitle: 'Smart job pipeline', gradient: const LinearGradient(colors: [Color(0xFF2A1A00), Color(0xFF3D2800)])),
      _BizCard(asset: 'assets/built/invoicedark.png', title: 'Invoice & CRM', subtitle: 'Send pro invoices', gradient: const LinearGradient(colors: [Color(0xFF0A1A2A), Color(0xFF0F2236)])),
      _BizCard(asset: 'assets/built/aireportdark.png', title: 'AI Reports', subtitle: 'Deep device insights', gradient: const LinearGradient(colors: [Color(0xFF1A0A2A), Color(0xFF260F3A)])),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Built for Business', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: cards.map((c) => _BizCardWidget(card: c)).toList(),
        ),
      ],
    );
  }

  Widget _buildCtaSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1D1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E3028), width: 1),
      ),
      child: Column(
        children: [
          const Text(
            'Ready to scan smarter?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Join 50,000+ businesses using imoscan AI',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreenView()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8EFC7C),
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: const Text('Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SignupScreenView()),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF8EFC7C), width: 1.5),
                shape: const StadiumBorder(),
              ),
              child: const Text('Create Free Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting Widgets ────────────────────────────────────────────────────────

class _IconChip extends StatelessWidget {
  final String assetPath;
  final String label;

  const _IconChip({required this.assetPath, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(assetPath, width: 44, height: 44, fit: BoxFit.contain),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatChip({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1612),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9), textAlign: TextAlign.center),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final String displayValue;
  final Color barColor;

  const _ProgressBar({
    required this.label,
    required this.value,
    required this.displayValue,
    this.barColor = const Color(0xFF8EFC7C),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(displayValue, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: const Color(0xFF1E3028),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

class _BizCard {
  final String asset;
  final String title;
  final String subtitle;
  final LinearGradient gradient;

  const _BizCard({required this.asset, required this.title, required this.subtitle, required this.gradient});
}

class _BizCardWidget extends StatelessWidget {
  final _BizCard card;

  const _BizCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: card.gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3028), width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Image.asset(card.asset, width: 28, height: 28, fit: BoxFit.contain),
          const SizedBox(height: 6),
          Text(card.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(card.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
        ],
      ),
    );
  }
}

// ─── Custom Painters ───────────────────────────────────────────────────────────

class _TrustScorePainter extends CustomPainter {
  final double score;

  _TrustScorePainter(this.score);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final bgPaint = Paint()
      ..color = const Color(0xFF1E3028)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [Color(0xFF4A9EFF), Color(0xFF8EFC7C)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * (score / 100),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GaugePainter extends CustomPainter {
  final double value;

  _GaugePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()
      ..color = const Color(0xFF1E3028)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    final fgPaint = Paint()
      ..color = const Color(0xFF8EFC7C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * value.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutPainter extends CustomPainter {
  final double value;

  _DonutPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final bgPaint = Paint()
      ..color = const Color(0xFF1E3028)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = const Color(0xFF4A9EFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
