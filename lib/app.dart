import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';
import 'core/theme/app_theme.dart';
import 'core/state/app_state.dart';
import 'features/onboarding/screens/welcome_screen.dart';
import 'shared/navigation/main_navigation.dart';

class MyCalorieApp extends StatelessWidget {
  const MyCalorieApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Calorie',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: DevicePreview.locale(context),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        child = DevicePreview.appBuilder(context, child);
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Directionality(textDirection: TextDirection.rtl, child: child),
        );
      },
      home: Consumer<AppState>(
        builder: (_, state, __) => state.isOnboardingComplete
            ? const MainNavigation()
            : const WelcomeScreen(),
      ),
    );
  }
}
