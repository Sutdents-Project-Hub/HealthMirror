import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/data_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';
import 'services/health_mirror_controller.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HealthMirrorApp());
}

class HealthMirrorApp extends StatefulWidget {
  const HealthMirrorApp({super.key});

  @override
  State<HealthMirrorApp> createState() => _HealthMirrorAppState();
}

class _HealthMirrorAppState extends State<HealthMirrorApp> {
  late final HealthMirrorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HealthMirrorController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HealthMirrorScope(
      controller: _controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'HealthMirror',
        theme: HealthMirrorTheme.light(),
        darkTheme: HealthMirrorTheme.dark(),
        home: const HealthMirrorShell(),
      ),
    );
  }
}

class HealthMirrorScope extends InheritedNotifier<HealthMirrorController> {
  const HealthMirrorScope({
    required HealthMirrorController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static HealthMirrorController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<HealthMirrorScope>();
    assert(scope?.notifier != null, 'HealthMirrorScope not found');
    return scope!.notifier!;
  }
}

class HealthMirrorShell extends StatefulWidget {
  const HealthMirrorShell({super.key});

  @override
  State<HealthMirrorShell> createState() => _HealthMirrorShellState();
}

class _HealthMirrorShellState extends State<HealthMirrorShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.monitor_heart_outlined),
      selectedIcon: Icon(Icons.monitor_heart),
      label: '總覽',
    ),
    NavigationDestination(
      icon: Icon(Icons.dataset_outlined),
      selectedIcon: Icon(Icons.dataset),
      label: '資料',
    ),
    NavigationDestination(
      icon: Icon(Icons.summarize_outlined),
      selectedIcon: Icon(Icons.summarize),
      label: '週報',
    ),
    NavigationDestination(
      icon: Icon(Icons.flag_outlined),
      selectedIcon: Icon(Icons.flag),
      label: '目標',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: '設定',
    ),
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.monitor_heart_outlined),
      selectedIcon: Icon(Icons.monitor_heart),
      label: Text('總覽'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.dataset_outlined),
      selectedIcon: Icon(Icons.dataset),
      label: Text('資料'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.summarize_outlined),
      selectedIcon: Icon(Icons.summarize),
      label: Text('週報'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.flag_outlined),
      selectedIcon: Icon(Icons.flag),
      label: Text('目標'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('設定'),
    ),
  ];

  static const _screens = [
    DashboardScreen(),
    DataScreen(),
    ReportScreen(),
    GoalsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = HealthMirrorScope.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 900;
        final body = controller.isLoading
            ? const _LoadingView()
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(_selectedIndex),
                  child: _screens[_selectedIndex],
                ),
              );

        return Scaffold(
          appBar: AppBar(
            title: const _AppBarTitle(),
            actions: [
              IconButton(
                tooltip: '重新產生模擬資料',
                onPressed: controller.isLoading
                    ? null
                    : () => controller.generateRandomSimulation(),
                icon: const Icon(Icons.auto_fix_high_outlined),
              ),
            ],
          ),
          body: useRail
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) {
                        setState(() => _selectedIndex = index);
                      },
                      labelType: NavigationRailLabelType.all,
                      destinations: _railDestinations,
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: body),
                  ],
                )
              : body,
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  destinations: _destinations,
                ),
        );
      },
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'HealthMirror'),
          TextSpan(
            text: '  未來自我投射鏡',
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w900,
        fontSize: 20,
        color: scheme.onSurface,
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(dimension: 44, child: CircularProgressIndicator()),
    );
  }
}
