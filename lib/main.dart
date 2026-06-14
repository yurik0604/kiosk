import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'src/core/config/app_config.dart';
import 'src/core/database/object_box.dart';
import 'src/core/logging/app_logger.dart';
import 'src/core/locale/locale_controller.dart';
import 'src/core/router/app_router.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/catalog/data/catalog_repository.dart';
import 'src/features/rfid/data/rfid_reader_controller.dart';
import 'src/l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: AppConfig.envFile);
  AppLogger.instance.i(
    'Boot: ENV=${AppConfig.env} BASE_URL=${AppConfig.baseUrl}',
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );
  WakelockPlus.enable();

  final objectBox = await ObjectBox.create();

  final container = ProviderContainer(
    overrides: [objectBoxProvider.overrideWithValue(objectBox)],
  );

  // Fire-and-forget: reader auto-connect must not block UI boot.
  unawaited(
    container.read(rfidReaderControllerProvider.notifier).bootstrap(),
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const KioskApp(),
    ),
  );
}

class KioskApp extends ConsumerWidget {
  const KioskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Kiosk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(locale: locale),
      darkTheme: AppTheme.dark(locale: locale),
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
