import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aim/index.dart';
import 'package:aim/states/base.dart';
import 'package:aim/states/chat.dart';
import 'package:aim/states/configs.dart';
import 'package:aim/states/garments.dart';
import 'package:aim/states/tryon.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SPUtils.init();
  await ConfigState.init();
  await ChatState.init();
  await GarmentsState.init();
  await TryOnResultsState.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConfigState>(create: (_) => ConfigState()),
        ChangeNotifierProvider<ChatState>(create: (_) => ChatState()),
        ChangeNotifierProvider<GarmentsState>(create: (_) => GarmentsState()),
        ChangeNotifierProvider<TryOnResultsState>(
            create: (_) => TryOnResultsState()),
      ],
      child: MaterialApp(
        title: 'AI Makeover',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.purple.shade700, brightness: Brightness.light),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.purple.shade700, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const MyHomePage(title: 'AI Makeover'),
      ),
    );
  }
}
