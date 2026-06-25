import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int _selectedIndex = 1; // Stock is selected by default

  final List<IconData> _icons = [
    Icons.grid_view_rounded, // Dashboard
    Icons.inventory_2_rounded, // Stock
    Icons.qr_code_scanner_rounded, // Scan
    Icons.build_rounded, // Repair
    Icons.description_rounded, // Invoice
  ];

  final List<String> _labels = [
    "Dashboard",
    "Stock",
    "Scan",
    "Repair",
    "Invoice",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: Color(0xFF0F0F0F), // Dark background
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bottom Navigation Items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              bool isCenter = index == 2; // Center position for Stock
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = index);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 8),
                    Icon(
                      _icons[index],
                      color: _selectedIndex == index
                          ? Colors.white
                          : Colors.grey[600],
                      size: isCenter ? 28 : 26,
                    ),
                    SizedBox(height: 4),
                    Text(
                      _labels[index],
                      style: TextStyle(
                        color: _selectedIndex == index
                            ? Colors.white
                            : Colors.grey[600],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              );
            }),
          ),

          // Highlighted Center Stock Button
          Positioned(
            top: -25,
            left: MediaQuery.of(context).size.width / 2 - 35,
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedIndex = 2);
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
