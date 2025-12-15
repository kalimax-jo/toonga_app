import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/version_check_service.dart';
import 'updates/app_update_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> fade;
  late Animation<double> scale;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeIn),
    );

    scale = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
    );

    controller.forward();

    /// After animation finishes → choose next screen
    Future.delayed(const Duration(seconds: 3), _navigateNext);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seen_onboarding') ?? false;
    final route = seen ? "/home" : "/onboarding";
    if (!seen) await prefs.setBool('seen_onboarding', true);

    final versionResult = await VersionCheckService().checkVersion();
    if (!mounted) return;

    if (versionResult.status != AppVersionStatus.allowed) {
      _showUpdateScreen(route, versionResult);
      return;
    }

    Navigator.pushReplacementNamed(context, route);
  }

  void _showUpdateScreen(String route, AppVersionCheckResult result) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AppUpdateScreen(
          status: result.status,
          message: result.message,
          platform: result.platform,
          storeUrl: result.storeUrl,
          continueRoute: route,
          allowSkip: result.status == AppVersionStatus.optionalUpdate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            "assets/images/background.png",
            fit: BoxFit.cover,
          ),

          // Logo + Text Animation
          Center(
            child: FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      "assets/images/logo.png",
                      width: 110,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Toonga.app",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Save while spending",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
