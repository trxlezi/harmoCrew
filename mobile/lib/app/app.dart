import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/details/presentation/details_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/members/presentation/member_form_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/projects/presentation/projects_screen.dart';

class HarmoCrewApp extends StatelessWidget {
  const HarmoCrewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'harmoCrew',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        DetailsScreen.routeName: (_) => const DetailsScreen(),
        MemberFormScreen.routeName: (_) => const MemberFormScreen(),
        ProjectsScreen.routeName: (_) => const ProjectsScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
      },
    );
  }
}
