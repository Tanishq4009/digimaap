import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/lmo_auth_provider.dart';
import 'services/socket_service.dart';
import 'routes.dart';
import 'theme/colors.dart';
import 'widgets/common.dart';
import 'pages/entry_page.dart';
import 'pages/not_found_page.dart';
import 'pages/shared/help_page.dart';
import 'pages/shared/notifications_page.dart';
import 'pages/consumer/login_page.dart';
import 'pages/consumer/home_page.dart';
import 'pages/consumer/scan_page.dart';
import 'pages/consumer/search_page.dart';
import 'pages/consumer/offline_page.dart';
import 'pages/consumer/history_page.dart';
import 'pages/consumer/profile_page.dart';
import 'pages/consumer/report_page.dart';
import 'pages/inspector/login_page.dart';
import 'pages/inspector/home_page.dart';
import 'pages/inspector/history_page.dart';
import 'pages/inspector/sync_page.dart';
import 'pages/inspector/profile_page.dart';
import 'pages/inspector/query_page.dart';
import 'services/connectivity_service.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

final ValueNotifier<List<NotificationItem>>
inspectorNotificationsNotifier = ValueNotifier([
  const NotificationItem(
    'New assignment received',
    'Sharma Fuel & Weighing Services was assigned to you.',
    '12 min ago',
    Icons.fact_check_outlined,
  ),
  const NotificationItem(
    'Sync reminder',
    '2 completed inspections are waiting to sync.',
    '1 hr ago',
    Icons.notifications_none_rounded,
  ),
]);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConnectivityService().init();
  runApp(const EMaapApp());
}

class EMaapApp extends StatefulWidget {
  const EMaapApp({super.key});

  @override
  State<EMaapApp> createState() => _EMaapAppState();
}

class _EMaapAppState extends State<EMaapApp> {
  @override
  void initState() {
    super.initState();
    SocketService().connect(
      navigatorKey: navigatorKey,
      notificationsNotifier: inspectorNotificationsNotifier,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LmoAuthProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'DigiMaap · Legal Metrology',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.navy,
            primary: AppColors.navy,
            secondary: AppColors.saffron,
          ),
          fontFamily: 'Intel',
        ),
        initialRoute: Routes.entry,
        routes: {
          Routes.entry: (_) => const EntryPage(),
          Routes.consumerLogin: (_) =>
              const ConsumerLoginPage(),
          Routes.consumerHome: (_) =>
              const ConsumerHomePage(),
          Routes.consumerScan: (_) => const ScanPage(),
          Routes.consumerSearch: (_) =>
              const SearchCertificatePage(),
          Routes.consumerOffline: (_) =>
              const ConsumerOfflinePage(),
          Routes.consumerHistory: (_) =>
              const ConsumerHistoryPage(),
          Routes.consumerNotifications: (_) =>
              const NotificationsPage(role: AppRole.consumer),
          Routes.consumerProfile: (_) => const ProfilePage(),
          Routes.consumerReport: (_) => const ReportPage(),
          Routes.help: (_) => const HelpPage(),
          Routes.inspectorLogin: (_) =>
              const InspectorLoginPage(),
          Routes.inspectorHome: (_) =>
              const InspectorHomePage(),
          Routes.inspectorNotifications: (_) =>
              const NotificationsPage(
                role: AppRole.inspector,
              ),
          Routes.inspectorInspections: (_) =>
              const InspectorHistoryPage(),
          Routes.inspectorSync: (_) =>
              const InspectorSyncPage(),
          Routes.inspectorProfile: (_) =>
              const InspectorProfilePage(),
          Routes.inspectorQuery: (_) =>
              const InspectorQueryPage(),
        },
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => const NotFoundPage(),
        ),
      ),
    );
  }
}

