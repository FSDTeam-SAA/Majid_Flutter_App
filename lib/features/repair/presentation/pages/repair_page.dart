import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../controller/repair_data.dart';
import '../widgets/repair_card.dart';
import '../widgets/repair_stats_row.dart';
import 'repair_request_details_page.dart';

class RepairPage extends StatefulWidget {
  const RepairPage({super.key});

  @override
  State<RepairPage> createState() => _RepairPageState();
}

class _RepairPageState extends State<RepairPage> {
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Repair Requests', trailing: UserAvatar()),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  RepairStatsRow(),
                  SizedBox(height: 20),
                  AppButton(
                    label: 'Create Repair Request',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Repair request form is coming soon.'),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24),
                  _buildSectionHeader(),
                  SizedBox(height: 14),
                  ...sampleRepairs.map(
                    (item) => RepairCard(
                      item: item,
                      onViewReport: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RepairRequestDetailsPage(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildPagination(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Repair Requests',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '10 Records',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    const totalPages = 27;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            if (_currentPage > 1) setState(() => _currentPage--);
          },
          child: Row(
            children: [
              Icon(
                Icons.chevron_left,
                color: _currentPage > 1
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                size: 18,
              ),
              Text(
                'PREVIOUS',
                style: TextStyle(
                  color: _currentPage > 1
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
        ...[1, 2, 3].map(_buildPageNumber),
        Text(
          '  ...  ',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        _buildPageNumber(totalPages),
        SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            if (_currentPage < totalPages) setState(() => _currentPage++);
          },
          child: Row(
            children: [
              Text(
                'NEXT',
                style: TextStyle(
                  color: _currentPage < totalPages
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: _currentPage < totalPages
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageNumber(int page) {
    final isActive = _currentPage == page;
    return GestureDetector(
      onTap: () => setState(() => _currentPage = page),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 3),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              color: isActive ? Colors.black : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
