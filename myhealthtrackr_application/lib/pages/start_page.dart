import 'package:flutter/material.dart';
import 'package:myhealthtrackr/pages/create_account_page.dart';
import 'package:myhealthtrackr/pages/sign_in_page.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  static const routeName = '/start';

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  bool _hasShownRouteMessage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasShownRouteMessage) return;
    _hasShownRouteMessage = true;

    final route = ModalRoute.of(context);
    final arguments = route?.settings.arguments;
    if (arguments is! StartPageMessage) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppSnack.show(context, arguments.message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundCacheWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
            cacheWidth: backgroundCacheWidth,
            filterQuality: FilterQuality.low,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColours.overlayLight,
                  AppColours.transparent,
                  AppColours.overlayDark,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
              child: Column(
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'MyHealthTrackr',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 45,
                            fontWeight: FontWeight.bold,
                            color: AppColours.onDark,
                          ),
                        ),
                        TextSpan(
                          text: '.',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 45,
                            fontWeight: FontWeight.bold,
                            color: AppColours.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 55,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, SignInPage.routeName);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColours.primary,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColours.onDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 55,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          CreateAccountPage.routeName,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColours.secondary,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColours.onDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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

class StartPageMessage {
  const StartPageMessage(this.message);

  final String message;
}
