import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';

class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key});

  static const _transactions = [
    _Transaction(id: '#4B0082E0', amount: 75.50, date: '10.02.2024'),
    _Transaction(id: '#FF5733E0', amount: 220.00, date: '05.03.2024'),
    _Transaction(id: '#28B463E0', amount: 150.75, date: '15.04.2024'),
    _Transaction(id: '#3498DBE0', amount: 99.99, date: '22.05.2024'),
    _Transaction(id: '#FFC300E0', amount: 40.00, date: '30.06.2024'),
    _Transaction(id: '#C70039E0', amount: 130.25, date: '18.07.2024'),
    _Transaction(id: '#C70039E0', amount: 130.25, date: '18.07.2024'),
    _Transaction(id: '#900C3FE0', amount: 60.80, date: '25.08.2024'),
    _Transaction(id: '#581845E0', amount: 200.10, date: '12.09.2024'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  itemCount: _transactions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _TransactionCard(tx: _transactions[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
                size: 16,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'My Transactions',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final _Transaction tx;
  const _TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1923),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A2840)),
      ),
      child: Row(
        children: [
          const _MastercardLogo(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.id,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'MasterCard **** 9918',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${tx.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tx.date,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MastercardLogo extends StatelessWidget {
  const _MastercardLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: CustomPaint(painter: _MastercardPainter()),
    );
  }
}

class _MastercardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.26;
    final offset = r * 0.55;

    // Red circle (left)
    canvas.drawCircle(
      Offset(cx - offset, cy),
      r,
      Paint()..color = const Color(0xFFEB001B),
    );
    // Orange circle (right, slightly transparent so overlap is visible)
    canvas.drawCircle(
      Offset(cx + offset, cy),
      r,
      Paint()
        ..color = const Color(0xFFF79E1B)
        ..blendMode = BlendMode.srcOver,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Transaction {
  final String id;
  final double amount;
  final String date;
  const _Transaction({
    required this.id,
    required this.amount,
    required this.date,
  });
}
