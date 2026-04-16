import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/auth/auth_bloc.dart';
import '../core/network/connectivity_service.dart';
import 'di.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class PerformazApp extends StatefulWidget {
  const PerformazApp({super.key});

  @override
  State<PerformazApp> createState() => _PerformazAppState();
}

class _PerformazAppState extends State<PerformazApp> {
  late final AuthBloc _authBloc;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>()..add(const AuthCheckRequested());
    _appRouter = AppRouter(authBloc: _authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        RepositoryProvider.value(
          value: getIt<ConnectivityService>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Performaz',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _appRouter.router,
      ),
    );
  }
}
