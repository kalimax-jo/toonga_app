import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/orders/my_orders_screen.dart';
import 'screens/products/beverage_products_screen.dart';
import 'screens/pay/pay_vendor_screen.dart';
import 'theme/app_theme.dart';
import 'screens/reels/reels_screen.dart';
import 'screens/reels/saved_reels_screen.dart';
import 'screens/notifications/notification_screen.dart';
import 'screens/offers/offer_screen.dart';
import 'screens/booking/event_checkout_screen.dart';
import 'services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/orders/deliveries_screen.dart';
import 'screens/vendors/vendors_screen.dart';
import 'screens/wishlist/wishlist_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await firebaseMessagingBackgroundHandler(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FcmService.instance.init();
  runApp(const ToongaApp());
}

class ToongaApp extends StatelessWidget {
  const ToongaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Toonga App",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: "/",
      routes: {
        "/": (context) => const SplashScreen(),
        "/onboarding": (context) => const OnboardingScreen(),
        "/login": (context) => const LoginScreen(),
        "/register": (context) => const RegisterScreen(),
        "/forgot-password": (context) => const ForgotPasswordScreen(),
        "/home": (context) => const HomeScreen(),
        "/profile": (context) => const ProfileScreen(),
        "/orders": (context) => const MyOrdersScreen(),
        "/products/beverage": (context) => const BeverageProductsScreen(),
        "/reels": (context) => const ReelsScreen(),
        "/reels/saved": (context) => const SavedReelsScreen(),
        "/notifications": (context) => const NotificationScreen(),
        "/offers": (context) => const OfferScreen(),
        "/checkout/event": (context) => const EventCheckoutScreen(),
        "/deliveries": (context) => const DeliveriesScreen(),
        "/vendors": (context) => const VendorsScreen(),
        "/wishlist": (context) => const WishlistScreen(),
        "/pay": (context) => const PayVendorScreen(),
      },
    );
  }
}
