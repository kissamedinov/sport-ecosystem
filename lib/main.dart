import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/tournaments/data/repositories/tournament_repository.dart';
import 'features/tournaments/providers/tournament_provider.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'core/presentation/screens/main_navigation_screen.dart';
import 'features/squads/providers/squad_provider.dart';
import 'features/lineups/providers/lineup_provider.dart';
import 'features/match_reports/providers/match_report_provider.dart';
import 'features/player_stats/providers/player_stats_provider.dart';
import 'features/tournaments/data/repositories/tournament_squad_repository.dart';
import 'features/tournaments/providers/tournament_squad_provider.dart';
import 'features/teams/data/repositories/team_repository.dart';
import 'features/teams/providers/team_provider.dart';
import 'features/children/data/repositories/child_repository.dart';
import 'features/children/providers/child_provider.dart';
import 'features/matches/data/repositories/match_repository.dart';
import 'features/matches/providers/match_provider.dart';
import 'features/fields/data/repositories/field_repository.dart';
import 'features/fields/providers/booking_provider.dart' as field_booking;
import 'features/players/data/repositories/player_repository.dart';
import 'features/academies/data/repositories/academy_repository.dart';
import 'features/academies/providers/academy_provider.dart';
import 'features/clubs/data/repositories/club_repository.dart';
import 'features/clubs/providers/club_provider.dart';
import 'features/notifications/data/repositories/notification_repository.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/media/data/repositories/media_repository.dart';
import 'features/admin/data/repositories/admin_repository.dart';
import 'features/admin/providers/admin_provider.dart';
import 'features/bookings/data/repositories/booking_repository.dart';
import 'features/bookings/providers/booking_provider.dart' as general_booking;

void main() {
  final apiClient = ApiClient();
  final authRepository = AuthRepository(apiClient);
  final tournamentRepository = TournamentRepository(apiClient);
  final teamRepository = TeamRepository(apiClient);
  final childRepository = ChildRepository(apiClient);
  final matchRepository = MatchRepository(apiClient);
  final fieldRepository = FieldRepository(apiClient);
  final tournamentSquadRepository = TournamentSquadRepository(apiClient);
  final playerRepository = PlayerRepository(apiClient);
  final academyRepository = AcademyRepository(apiClient);
  final clubRepository = ClubRepository(apiClient);
  final notificationRepository = NotificationRepository(apiClient);
  final mediaRepository = MediaRepository(apiClient);
  final adminRepository = AdminRepository(apiClient);
  final bookingRepository = BookingRepository(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => TournamentProvider(tournamentRepository)),
        ChangeNotifierProvider(create: (_) => TeamProvider(teamRepository)),
        ChangeNotifierProvider(create: (_) => ChildProvider(childRepository)),
        ChangeNotifierProvider(create: (_) => MatchProvider(matchRepository)),
        ChangeNotifierProvider(create: (_) => field_booking.BookingProvider(fieldRepository)),
        ChangeNotifierProvider(create: (_) => TournamentSquadProvider(tournamentSquadRepository, tournamentRepository)),
        Provider<PlayerRepository>(create: (_) => playerRepository),
        ChangeNotifierProvider(create: (_) => SquadProvider()),
        ChangeNotifierProvider(create: (_) => LineupProvider()),
        ChangeNotifierProvider(create: (context) => MatchReportProvider()),
        ChangeNotifierProxyProvider<MatchReportProvider, PlayerStatsProvider>(
          create: (context) => PlayerStatsProvider(context.read<MatchReportProvider>()),
          update: (context, matchReportProvider, previous) => PlayerStatsProvider(matchReportProvider),
        ),
        ChangeNotifierProvider(create: (_) => ClubProvider(clubRepository)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(notificationRepository, clubRepository)),
        Provider<MediaRepository>(create: (_) => mediaRepository),
        ChangeNotifierProvider(create: (_) => AdminProvider(adminRepository)),
        ChangeNotifierProvider(create: (_) => AcademyProvider(academyRepository)),
        ChangeNotifierProvider(create: (_) => general_booking.BookingProvider(bookingRepository)),
      ],
      child: const SportsApp(),
    ),
  );
}

class SportsApp extends StatelessWidget {
  const SportsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football Ecosystem',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainNavigationScreen(),
      },
    );
  }
}
