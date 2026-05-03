import 'package:myhealthtrackr/pages/account_created_page.dart';
import 'package:myhealthtrackr/pages/barcode_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:myhealthtrackr/pages/create_account_page.dart';
import 'package:myhealthtrackr/pages/diary_page.dart';
import 'package:myhealthtrackr/pages/home_page.dart';
import 'package:myhealthtrackr/pages/meal_recommendation_setup_page.dart';
import 'package:myhealthtrackr/pages/plans_page.dart';
import 'package:myhealthtrackr/pages/profile_page.dart';
import 'package:myhealthtrackr/pages/sign_in_page.dart';
import 'package:myhealthtrackr/pages/start_page.dart';
import 'package:myhealthtrackr/services/auth_controller.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/keyboard_dismiss_on_tap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _authController.restoreSession();
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyHealthTrackr',
      builder: (context, child) {
        return KeyboardDismissOnTap(
          child: AuthScope(
            controller: _authController,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const _AuthGate(),
      routes: {
        StartPage.routeName: (_) => const StartPage(),
        SignInPage.routeName: (_) => const SignInPage(),
        CreateAccountPage.routeName: (_) => const CreateAccountPage(),
        AccountCreatedPage.routeName: (_) =>
            const AccountCreatedPage(email: '', name: ''),
        HomePage.routeName: (_) => const HomePage(),
        DiaryPage.routeName: (_) => const DiaryPage(),
        PlansPage.routeName: (_) => const PlansPage(),
        MealRecommendationSetupPage.routeName: (_) =>
            const MealRecommendationSetupPage(),
        ProfilePage.routeName: (_) => const ProfilePage(),
        BarcodeScannerPage.routeName: (_) => const BarcodeScannerPage(),
      },
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: AppTextStyles.fontFamily,
        colorScheme: const ColorScheme.dark(
          primary: AppColours.primary,
          secondary: AppColours.primary,
          surface: AppColours.secondary,
          onSurface: AppColours.onDark,
          error: AppColours.danger,
        ),
        primaryColor: AppColours.primary,
        scaffoldBackgroundColor: AppColours.background,
        tabBarTheme: const TabBarThemeData(indicatorColor: AppColours.primary),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColours.primary,
          selectionColor: AppColours.primary.withValues(alpha: 0.35),
          selectionHandleColor: AppColours.primary,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _NoTransitionsPageTransitionsBuilder(),
            TargetPlatform.iOS: _NoTransitionsPageTransitionsBuilder(),
          },
        ),
      ),
    );
  }
}

class _NoTransitionsPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authController = AuthScope.watch(context);

    switch (authController.status) {
      case AuthStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const HomePage();
      case AuthStatus.unauthenticated:
        return const StartPage();
    }
  }
}
