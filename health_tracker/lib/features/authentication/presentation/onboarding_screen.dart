import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _slides = [
    const OnboardingData(
      title: 'Track Vitals in Real-Time',
      description: 'Monitor your heart rate, steps, blood oxygen saturation (SpO₂), and temperature directly from your custom ESP32 wearable.',
      icon: Icons.monitor_heart_rounded,
      color: AppTheme.heartRate,
    ),
    const OnboardingData(
      title: 'Seamless BLE Connection',
      description: 'Connect instantly via Bluetooth Low Energy (BLE) with features like auto-reconnect, signal metrics, and low-latency sync.',
      icon: Icons.bluetooth_searching_rounded,
      color: AppTheme.steps,
    ),
    const OnboardingData(
      title: 'Live Vitals Monitoring',
      description: 'Experience clinical-grade real-time graphing, beat animations, and boundary warnings if your vitals go out of normal ranges.',
      icon: Icons.insights_rounded,
      color: AppTheme.tempAmber,
    ),
    const OnboardingData(
      title: 'Secure Cloud Sync',
      description: 'Your health records are cached locally first, then encrypted and synchronized to your private Firebase backup when online.',
      icon: Icons.cloud_done_rounded,
      color: AppTheme.spo2Mint,
    ),
    const OnboardingData(
      title: 'Privacy & Permissions',
      description: 'We request location, Bluetooth scan, and notifications access to interact with your health band. Your data stays entirely in your control.',
      icon: Icons.verified_user_rounded,
      color: AppTheme.warning,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final primaryBtnColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return Scaffold(
      body: Stack(
        children: [
          Container(color: bgColor),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Skip',
                      style: TextStyle(color: subtitleColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 180,
                              width: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: slide.color.withOpacity(0.12),
                                border: Border.all(color: slide.color.withOpacity(0.3), width: 2),
                              ),
                              child: Icon(
                                slide.icon,
                                size: 80,
                                color: slide.color,
                              ),
                            ),
                            const SizedBox(height: 48),
                            GlassCard(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  Text(
                                    slide.title,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: titleColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    slide.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: subtitleColor,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          _slides.length,
                          (index) => Container(
                            margin: const EdgeInsets.only(right: 6),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? primaryBtnColor
                                  : subtitleColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      FloatingActionButton(
                        onPressed: () {
                          if (_currentPage < _slides.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOutCubic,
                            );
                          } else {
                            context.go('/login');
                          }
                        },
                        backgroundColor: primaryBtnColor,
                        foregroundColor: Colors.white,
                        child: Icon(
                          _currentPage == _slides.length - 1
                              ? Icons.check
                              : Icons.arrow_forward_ios_rounded,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
