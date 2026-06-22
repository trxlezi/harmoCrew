import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/native/native_features_store.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/collaboration/screens/applications_screen.dart';
import '../features/collaboration/screens/collaboration_screen.dart';
import '../features/collaboration/screens/decisions_screen.dart';
import '../features/collaboration/screens/kanban_screen.dart';
import '../features/collaboration/screens/messages_screen.dart';
import '../features/collaboration/screens/rehearsals_screen.dart';
import '../features/collaboration/screens/responsibilities_screen.dart';
import '../features/collaboration/screens/tasks_screen.dart';
import '../features/collaboration/screens/weekly_goals_screen.dart';
import '../features/details/presentation/details_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/members/presentation/artist_detail_screen.dart';
import '../features/members/presentation/member_form_screen.dart';
import '../features/members/presentation/talents_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/projects/presentation/projects_screen.dart';

class HarmoCrewApp extends StatelessWidget {
  const HarmoCrewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NativeFeaturesStore>.value(
          value: NativeFeaturesStore.instance,
        ),
      ],
      child: MaterialApp(
        title: 'harmoCrew',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        initialRoute: LoginScreen.routeName,
        routes: {
          LoginScreen.routeName: (_) => const LoginScreen(),
          RegisterScreen.routeName: (_) => const RegisterScreen(),
          HomeScreen.routeName: (_) => const HomeScreen(),
          DetailsScreen.routeName: (_) => const DetailsScreen(),
          ApplicationsScreen.routeName: (_) => const ApplicationsScreen(),
          CollaborationScreen.routeName: (_) => const CollaborationScreen(),
          DecisionsScreen.routeName: (_) => const DecisionsScreen(),
          KanbanScreen.routeName: (_) => const KanbanScreen(),
          MessagesScreen.routeName: (_) => const MessagesScreen(),
          RehearsalsScreen.routeName: (_) => const RehearsalsScreen(),
          ResponsibilitiesScreen.routeName: (_) =>
              const ResponsibilitiesScreen(),
          TasksScreen.routeName: (_) => const TasksScreen(),
          WeeklyGoalsScreen.routeName: (_) => const WeeklyGoalsScreen(),
          ArtistDetailScreen.routeName: (_) => const ArtistDetailScreen(),
          MemberFormScreen.routeName: (_) => const MemberFormScreen(),
          TalentsScreen.routeName: (_) => const TalentsScreen(),
          ProjectsScreen.routeName: (_) => const ProjectsScreen(),
          ProfileScreen.routeName: (_) => const ProfileScreen(),
        },
      ),
    );
  }
}
