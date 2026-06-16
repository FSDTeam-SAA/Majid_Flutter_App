import 'package:flutter/material.dart';
import 'ai_home_preview_screen.dart';

class OnboardingScreenView extends StatefulWidget {
  const OnboardingScreenView({super.key});

  @override
  State<OnboardingScreenView> createState() => _OnboardingScreenViewState();
}

class _OnboardingScreenViewState extends State<OnboardingScreenView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      image: 'assets/images/Rectangle 13.png',
      title: 'Scan Any Device Instantly',
      subtitle: 'Scan IMEI or barcode using your camera and get instant device details.',
    ),
    _OnboardingData(
      image: 'assets/images/Rectangle 13 (1).png',
      title: 'AI-Powered Device Insights',
      subtitle: 'Get smart analysis, risk detection, and detailed reports before you buy or sell.',
    ),
    _OnboardingData(
      image: 'assets/images/Rectangle 13 (2).png',
      title: 'Buy & Sell with Confidence',
      subtitle: 'Avoid scams, verify devices, manage inventory, and generate invoices easily.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AiHomePreviewScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: Column(
        children: [
          // Image section — not swipeable
          Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 8),
            child: SizedBox(
              height: size.height * 0.63,
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(_pages[i].image, fit: BoxFit.cover),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _pages[_currentPage].title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _pages[_currentPage].subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const Spacer(),
                  // Dot indicators (3 dots only)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? const Color(0xFF8EFC7C)
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8EFC7C),
                        foregroundColor: Colors.black,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: Text(
                        isLast ? 'Get Started' : 'Next',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String image;
  final String title;
  final String subtitle;

  const _OnboardingData({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}
