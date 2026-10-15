import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'menu_board/providers/menu_provider.dart';
import 'menu_board/providers/order_provider.dart';
import 'menu_board/providers/pengeluaran_provider.dart';
import 'menu_board/router/app_router.dart';
import 'menu_board/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => PengeluaranProvider()),
      ],
      child: MaterialApp.router(
        title: 'Kasir Sapuangin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
        routerConfig: AppRouter.router,
      ),
    );
  }
}