import 'package:myhealthtrackr/pages/account_created_page.dart';
import 'package:myhealthtrackr/pages/barcode_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:myhealthtrackr/pages/create_account_page.dart';
import 'package:myhealthtrackr/pages/diary_page.dart';
import 'package:myhealthtrackr/pages/home_page.dart';
import 'package:myhealthtrackr/pages/plans_page.dart';
import 'package:myhealthtrackr/pages/profile_page.dart';
import 'package:myhealthtrackr/pages/sign_in_page.dart';
import 'package:myhealthtrackr/pages/start_page.dart';
import 'package:myhealthtrackr/services/auth_controller.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';

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
        return AuthScope(
          controller: _authController,
          child: child ?? const SizedBox.shrink(),
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
        ProfilePage.routeName: (_) => const ProfilePage(),
        BarcodeScannerPage.routeName: (_) => const BarcodeScannerPage(),
      },
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: AppTextStyles.fontFamily,
        scaffoldBackgroundColor: AppColours.background,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _NoTransitionsPageTransitionsBuilder(),
            TargetPlatform.iOS: _NoTransitionsPageTransitionsBuilder(),
            TargetPlatform.macOS: _NoTransitionsPageTransitionsBuilder(),
            TargetPlatform.linux: _NoTransitionsPageTransitionsBuilder(),
            TargetPlatform.windows: _NoTransitionsPageTransitionsBuilder(),
            TargetPlatform.fuchsia: _NoTransitionsPageTransitionsBuilder(),
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
