import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';

class UpgradePlanPage extends StatelessWidget {
  const UpgradePlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  children: const [
                    _StarterCard(),
                    SizedBox(height: 12),
                    _PayAsYouGoCard(),
                    SizedBox(height: 20),
                    _DiamondCard(),
                    SizedBox(height: 12),
                    _EnterpriseCard(),
                  ],
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
              'Pricing Plan',
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

// ── Shared widgets ────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final Widget icon;
  final String name;
  final String subtitle;
  final String price;
  final String priceUnit;
  final List<String> features;
  final String buttonLabel;
  final bool buttonFilled;
  final String? badge;

  const _PlanCard({
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.price,
    this.priceUnit = '/month',
    required this.features,
    required this.buttonLabel,
    this.buttonFilled = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1923),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A2840)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (priceUnit.isNotEmpty)
                    Text(
                      priceUnit,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FeaturesGrid(features: features),
          const SizedBox(height: 16),
          _ActionBtn(label: buttonLabel, filled: buttonFilled),
        ],
      ),
    );

    if (badge == null) return card;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: -14,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFB8760A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturesGrid extends StatelessWidget {
  final List<String> features;
  const _FeaturesGrid({required this.features});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < features.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: _FeatureItem(features[i])),
            if (i + 1 < features.length)
              Expanded(child: _FeatureItem(features[i + 1]))
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      );
      if (i + 2 < features.length) rows.add(const SizedBox(height: 8));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

class _FeatureItem extends StatelessWidget {
  final String label;
  const _FeatureItem(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check, color: Color(0xFF4DD9AC), size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final bool filled;
  const _ActionBtn({required this.label, required this.filled});

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label selected. Payment setup is coming soon.'),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label selected. Payment setup is coming soon.'),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── Plan icon boxes ────────────────────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  final Color bgColor;
  final IconData icon;
  final Color iconColor;

  const _IconBox({
    required this.bgColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 28),
    );
  }
}

// ── Individual plan cards ──────────────────────────────────────────────────────

class _StarterCard extends StatelessWidget {
  const _StarterCard();

  @override
  Widget build(BuildContext context) {
    return const _PlanCard(
      icon: _IconBox(
        bgColor: Color(0xFF0E1E35),
        icon: Icons.rocket_launch_outlined,
        iconColor: Color(0xFF5B8DEF),
      ),
      name: 'Starter',
      subtitle: 'Basic free plan for beginners',
      price: '\$0',
      features: ['2 Free Checks', 'Risk Analysis'],
      buttonLabel: 'Start Free',
    );
  }
}

class _PayAsYouGoCard extends StatelessWidget {
  const _PayAsYouGoCard();

  @override
  Widget build(BuildContext context) {
    return const _PlanCard(
      icon: _IconBox(
        bgColor: Color(0xFF0E2318),
        icon: Icons.bolt,
        iconColor: AppColors.primary,
      ),
      name: 'Pay As You Go',
      subtitle: 'Flexible usage based pricing',
      price: '\$3-\$30',
      priceUnit: '',
      features: [
        'AI Risk Analysis',
        'Market Value',
        'Full Report',
        'Auto Invoicing',
      ],
      buttonLabel: 'Top Up & Start',
    );
  }
}

class _DiamondCard extends StatelessWidget {
  const _DiamondCard();

  @override
  Widget build(BuildContext context) {
    return const _PlanCard(
      badge: '10% Off',
      icon: _IconBox(
        bgColor: Color(0xFF2A1800),
        icon: Icons.diamond_outlined,
        iconColor: Color(0xFFE8920A),
      ),
      name: 'Diamond Plan',
      subtitle: 'Best for growing businesses',
      price: '\$100',
      features: ['10% Discount', 'API Access', 'Reports', 'Auto Invoicing'],
      buttonLabel: 'Upgrade to Diamond',
      buttonFilled: true,
    );
  }
}

class _EnterpriseCard extends StatelessWidget {
  const _EnterpriseCard();

  @override
  Widget build(BuildContext context) {
    return const _PlanCard(
      icon: _IconBox(
        bgColor: Color(0xFF1A0F2E),
        icon: Icons.business_outlined,
        iconColor: Color(0xFF9B6EE8),
      ),
      name: 'Enterprise',
      subtitle: 'Custom solution for large companies',
      price: 'Custom',
      priceUnit: '',
      features: ['Custom Pricing', 'Full API Access', 'Dedicated Support'],
      buttonLabel: 'Contact Us',
      buttonFilled: true,
    );
  }
}
