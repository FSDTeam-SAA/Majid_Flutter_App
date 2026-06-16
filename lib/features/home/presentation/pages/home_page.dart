import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedPeriod = 2;

  static const _periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  static const List<double> _thisMonth = [4200, 7000, 9200, 11500, 13800, 14500, 15800, 16000, 15200, 14800, 14200, 13500];
  static const List<double> _lastMonth = [3500, 5800, 7500, 9000, 10200, 11000, 12000, 12500, 11800, 11200, 10500, 10000];

  static const _products = [
    ('iPhone 15 Pro (256GB)', 128),
    ('Samsung S24 Ultra', 97),
    ('AirPods Pro 2', 86),
    ('iPhone 14 (128GB)', 72),
    ('Samsung A54', 61),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildPeriodTabs(),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildSalesTrend(),
              const SizedBox(height: 20),
              _buildTopProducts(),
              const SizedBox(height: 20),
              _buildAIInsights(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: 'imo', style: TextStyle(color: AppColors.primary)),
              TextSpan(text: 'scan', style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.verified, color: Color(0xFF1DA1F2), size: 18),
        const Spacer(),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 20),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 19,
          backgroundColor: AppColors.cardBackground,
          child: ClipOval(
            child: Image.network(
              'https://i.pravatar.cc/100',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const Icon(Icons.person, color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(_periods.length, (i) {
          final selected = i == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  _periods[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? AppColors.background : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _statCard('Total Sales', '£48,200', Icons.bar_chart, const Color(0xFF1A3020), const Color(0xFF2D5C38)),
        _statCard('Total Profit', '£14,650', Icons.account_balance_wallet_outlined, const Color(0xFF1F1A35), const Color(0xFF3D2F6E)),
        _statCard('Total Orders', '642', Icons.inventory_2_outlined, const Color(0xFF182232), const Color(0xFF1E4080)),
        _statCard('Avg Order Value', '£75.08', Icons.my_location_outlined, const Color(0xFF2A1E12), const Color(0xFF7A3B1E)),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color iconBg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconColor.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _actionBtn('Add Repair', Icons.build_outlined),
            const SizedBox(width: 12),
            _actionBtn('Create Invoice', Icons.note_add_outlined),
            const SizedBox(width: 12),
            _actionBtn('Add Item', Icons.shopping_bag_outlined),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn(String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTrend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Sales Trend', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.fieldBorder),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Text('Monthly', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendDot(AppColors.primary, 'This Month'),
              const SizedBox(width: 16),
              _legendDot(AppColors.textSecondary, 'Last Month'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _ChartPainter(thisMonth: _thisMonth, lastMonth: _lastMonth),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              Text('7', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              Text('14', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              Text('18', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildTopProducts() {
    return Column(
      children: [
        Row(
          children: [
            const Text('Top Selling Products', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('View All', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(_products.length, (i) {
          final (name, sold) = _products[i];
          final progress = sold / _products[0].$2;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text('${i + 1}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.fieldBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.phone_iphone, color: AppColors.textSecondary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.fieldBackground,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$sold', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const Text('Sold', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAIInsights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('AI Insights', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('View All', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2C40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bar_chart, color: Color(0xFF5B9FD4), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'iPhone 15 Pro sales increased by 42% this month. Consider increasing stock!',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) => Container(
              width: i == 0 ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i == 0 ? AppColors.primary : AppColors.fieldBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> thisMonth;
  final List<double> lastMonth;

  const _ChartPainter({required this.thisMonth, required this.lastMonth});

  @override
  void paint(Canvas canvas, Size size) {
    final allValues = [...thisMonth, ...lastMonth];
    final maxVal = allValues.reduce(max);
    final minVal = allValues.reduce(min) * 0.8;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Y-axis labels
    const yLabels = ['18000', '13500', '9000', '4500', '0'];
    final textStyle = TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9);
    for (int i = 0; i < yLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: yLabels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, size.height * i / 4 - 6));
    }

    _drawLine(canvas, size, lastMonth, const Color(0xFF6B7B74), minVal, maxVal);
    _drawLine(canvas, size, thisMonth, AppColors.primary, minVal, maxVal, drawDots: true);
  }

  void _drawLine(Canvas canvas, Size size, List<double> data, Color color, double minVal, double maxVal, {bool drawDots = false}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final n = data.length;
    final path = Path();

    double x(int i) => size.width * i / (n - 1);
    double y(int i) => size.height - (data[i] - minVal) / (maxVal - minVal) * size.height;

    path.moveTo(x(0), y(0));
    for (int i = 1; i < n; i++) {
      final cpX = (x(i - 1) + x(i)) / 2;
      path.cubicTo(cpX, y(i - 1), cpX, y(i), x(i), y(i));
    }
    canvas.drawPath(path, paint);

    if (drawDots) {
      for (int i = 0; i < n; i++) {
        canvas.drawCircle(Offset(x(i), y(i)), 4, Paint()..color = color);
        canvas.drawCircle(Offset(x(i), y(i)), 4, Paint()
          ..color = const Color(0xFF131F1C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => false;
}
