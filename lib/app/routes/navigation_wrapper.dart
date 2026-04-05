import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_baby_sara/blocs/activity/activity_bloc.dart';
import 'package:open_baby_sara/blocs/all_timer/sleep_timer/sleep_timer_bloc.dart';
import 'package:open_baby_sara/blocs/baby/baby_bloc.dart';
import 'package:open_baby_sara/blocs/bottom_nav/bottom_nav_bloc.dart';
import 'package:open_baby_sara/blocs/theme/theme_bloc.dart';
import 'package:open_baby_sara/core/utils/check_for_update.dart';
import 'package:open_baby_sara/core/widget_bridge/widget_bridge_service.dart';
import 'package:open_baby_sara/data/repositories/locator.dart';
import 'package:open_baby_sara/data/services/firebase/analytics_service.dart';
import 'package:open_baby_sara/data/services/notification_service.dart';
import 'package:open_baby_sara/views/account/account_page.dart';
import 'package:open_baby_sara/views/activities/activity_page.dart';
import 'package:open_baby_sara/views/history/history_page.dart';
import 'package:open_baby_sara/views/food_recipes/recipes_page.dart';
import 'package:open_baby_sara/views/background_sounds/baby_relaxing_sounds_page.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BabyBloc>().add(LoadBabies());
    });
    getIt<AnalyticsService>().logScreenView('ActivityPage');
    checkAppUpdate(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed && mounted) {
      _refreshWidgets();
    }
  }

  /// App foreground'a döndüğünde veya locale/tema değiştiğinde tüm widget'ları
  /// güncel lokalizasyon ve tema verileriyle yeniler.
  void _refreshWidgets() {
    final babyState = context.read<BabyBloc>().state;
    final themeState = context.read<ThemeBloc>().state;
    if (babyState is! BabyLoaded || babyState.selectedBaby == null) return;
    WidgetBridgeService.refreshAllWidgets(
      babyName: babyState.selectedBaby!.firstName,
      isGirlTheme: themeState is ThemeInitial && themeState.gender == 'Girl',
    );
  }

  void _scheduleMilestones(
    BuildContext context,
    DateTime birthDate,
    String babyName,
  ) {
    // Build all 24 localized strings synchronously before handing off to service
    final titles = {
      for (int m = 1; m <= 24; m++)
        m: context.tr(
          'notif_milestone_title',
          namedArgs: {'name': babyName, 'month': '$m'},
        ),
    };
    final bodies = {
      for (int m = 1; m <= 24; m++)
        m: context.tr(
          'notif_milestone_body',
          namedArgs: {'name': babyName, 'month': '$m'},
        ),
    };

    NotificationService.instance.scheduleMilestoneNotifications(
      birthDate: birthDate,
      titleBuilder: (month) => titles[month] ?? '',
      bodyBuilder: (month) => bodies[month] ?? '',
    );
  }

  Future<void> _handleActivityAdded(
    BuildContext context,
    ActivityAdded state,
  ) async {
    // Build localized strings before async gap
    final babyName = state.babyName;
    final type = state.activityType;

    final isFeed = type == 'breastFeed' ||
        type == 'bottleFeed' ||
        type == 'solids' ||
        type == 'pumpTotal' ||
        type == 'pumpLeftRight';
    final isSleep = type == 'sleep';

    final sleepTitle = context.tr('notif_sleep_title');
    final sleepBody =
        context.tr('notif_sleep_body', namedArgs: {'name': babyName});
    final feedTitle = context.tr('notif_feed_title');
    final feedBody =
        context.tr('notif_feed_body', namedArgs: {'name': babyName});

    final settings = await NotificationService.instance.loadSettings();

    if (isSleep && settings.sleepRemindersEnabled) {
      await NotificationService.instance.scheduleSleepReminder(
        babyName: babyName,
        title: sleepTitle,
        body: sleepBody,
      );
    }

    if (isFeed && settings.feedRemindersEnabled) {
      await NotificationService.instance.scheduleFeedReminder(
        title: feedTitle,
        body: feedBody,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HistoryPage(),
      BabyRelaxingSoundsPage(),
      ActivityPage(),
      RecipesPage(),
      AccountPage(),
    ];
    return MultiBlocListener(
      listeners: [
        BlocListener<BabyBloc, BabyState>(
          listenWhen: (_, s) => s is BabyLoaded,
          listener: (context, state) {
            if (state is BabyLoaded && state.selectedBaby != null) {
              _scheduleMilestones(
                context,
                state.selectedBaby!.dateTime,
                state.selectedBaby!.firstName,
              );
            }
          },
        ),
        BlocListener<ActivityBloc, ActivityState>(
          listenWhen: (_, s) => s is ActivityAdded,
          listener: (context, state) {
            if (state is ActivityAdded) {
              _handleActivityAdded(context, state);
            }
          },
        ),
        // Sleep timer değişimlerinde ana ekran widget'ını güncelle.
        // listenWhen: sadece running↔stopped geçişinde tetikle —
        // her saniyeki Tick event'inde değil. Native widget zamanı
        // kendi hesaplar (startTimestamp üzerinden).
        BlocListener<SleepTimerBloc, SleepTimerState>(
          listenWhen: (prev, curr) {
            if (curr is TimerReset) return true;
            if (prev is TimerRunning && curr is TimerStopped) return true;
            if (prev is! TimerRunning && curr is TimerRunning) return true;
            return false;
          },
          listener: (context, sleepState) {
            final babyState = context.read<BabyBloc>().state;
            final themeState = context.read<ThemeBloc>().state;
            if (babyState is! BabyLoaded || babyState.selectedBaby == null) {
              return;
            }
            final babyName = babyState.selectedBaby!.firstName;
            final isGirlTheme =
                themeState is ThemeInitial && themeState.gender == 'Girl';

            if (sleepState is TimerRunning) {
              WidgetBridgeService.updateSleepWidget(
                isRunning: true,
                startTime: sleepState.startTime,
                babyName: babyName,
                isGirlTheme: isGirlTheme,
              );
            } else if (sleepState is TimerStopped) {
              WidgetBridgeService.updateSleepWidget(
                isRunning: false,
                lastDurationSeconds: sleepState.duration.inSeconds,
                lastEndTime: sleepState.endTime,
                babyName: babyName,
                isGirlTheme: isGirlTheme,
              );
            } else if (sleepState is TimerReset) {
              WidgetBridgeService.updateSleepWidget(
                isRunning: false,
                babyName: babyName,
                isGirlTheme: isGirlTheme,
              );
            }
          },
        ),
      ],
      child: BlocBuilder<BottomNavBloc, BottomNavState>(
        builder: (context, state) {
          final int currentIndex =
              state is BottomNavNext ? state.selectedIndex : 2;

          return Scaffold(
          backgroundColor: Colors.transparent,
          bottomNavigationBar: ConvexAppBar(
            initialActiveIndex:
                state is BottomNavNext ? state.selectedIndex : 2,
            onTap: (int index) {
              context.read<BottomNavBloc>().add(NavItemSelected(index));
              final screenNames = [
                'HistoryPage',
                'BabyRelaxingSoundsPage',
                'ActivityPage',
                'RecipesPage',
                'AccountPage',
              ];
              getIt<AnalyticsService>().logScreenView(screenNames[index]);
            },
            backgroundColor: Colors.deepPurpleAccent,
            style: TabStyle.reactCircle,
            activeColor: Colors.white,
            color: Colors.white70,
            items: [
              TabItem(
                icon: Icons.history_outlined,
                title: context.tr('history'),
              ),
              TabItem(
                icon: Icons.surround_sound_outlined,
                title: context.tr('sounds'),
              ),
              TabItem(
                icon: Icons.local_activity_outlined,
                title: context.tr('activity'),
              ),
              TabItem(
                icon: Icons.receipt_long_outlined,
                title: context.tr('recipes'),
              ),
              TabItem(
                icon: Icons.account_circle_outlined,
                title: context.tr('profile'),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5E6E8), Color(0xFFF6F5F5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),

            child: SafeArea(child: _pages[currentIndex]),
          ),
        );
      },
      ),
    );
  }
}
