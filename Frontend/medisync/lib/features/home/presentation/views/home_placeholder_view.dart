import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medisync/core/constants/app_colors.dart';
import 'package:medisync/core/constants/app_strings.dart';
import 'package:medisync/core/constants/app_text_styles.dart';
import 'package:medisync/core/di/injection_container.dart';
import 'package:medisync/core/router/app_router.dart';
import 'package:medisync/features/auth/domain/entities/usuario.dart';
import 'package:medisync/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:medisync/features/device/domain/entities/device_status.dart';
import 'package:medisync/features/device/presentation/viewmodels/device_viewmodel.dart';
import 'package:medisync/features/medication/presentation/views/cuidador_paciente_view.dart';
import 'package:medisync/features/medication/presentation/views/daily_intakes_view.dart';
import 'package:medisync/features/medication/presentation/views/schedule_view.dart';
import 'package:medisync/features/medication/presentation/viewmodels/intakes_viewmodel.dart';
import 'package:medisync/features/medication/presentation/viewmodels/schedule_viewmodel.dart';
import 'package:medisync/features/alerts/presentation/viewmodels/alerts_viewmodel.dart';
import 'package:medisync/features/alerts/presentation/views/alerts_view.dart';
import 'package:medisync/features/vital_signs/presentation/viewmodels/vitals_viewmodel.dart';
import 'package:medisync/features/vital_signs/presentation/views/vitals_view.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Shell with role-based BottomNavigationBar.
// Placeholder tabs use IndexedStack to preserve scroll state.
// Profile and Links tabs navigate via go_router.
// ---------------------------------------------------------------------------

class HomeShellView extends StatefulWidget {
  const HomeShellView({super.key});

  @override
  State<HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends State<HomeShellView> {
  int _currentIndex = 0;

  List<_NavTab> _tabs(TipoPerfil? tipoPerfil) => switch (tipoPerfil) {
        TipoPerfil.cuidador => [
            _NavTab(
              icon: Icons.person,
              label: AppStrings.tabPaciente,
              widget: ChangeNotifierProvider.value(
                value: sl<IntakesViewModel>(),
                child: const CuidadorPacienteView(),
              ),
            ),
            _NavTab(
              icon: Icons.notifications,
              label: AppStrings.tabAlertas,
              widget: const AlertsView(),
            ),
            _NavTab(
              icon: Icons.link,
              label: AppStrings.tabVinculos,
              route: AppRoutes.links,
            ),
            _NavTab(
              icon: Icons.person_outline,
              label: AppStrings.tabPerfil,
              route: AppRoutes.profile,
            ),
          ],
        TipoPerfil.profesionalSalud => [
            _NavTab(
              icon: Icons.local_pharmacy,
              label: AppStrings.tabMedicacion,
              widget: ChangeNotifierProvider.value(
                value: sl<ScheduleViewModel>(),
                child: const ScheduleView(),
              ),
            ),
            _NavTab(
              icon: Icons.notifications,
              label: AppStrings.tabAlertas,
              widget: const AlertsView(),
            ),
            _NavTab(
              icon: Icons.people,
              label: AppStrings.tabVinculados,
              route: AppRoutes.links,
            ),
            _NavTab(
              icon: Icons.person_outline,
              label: AppStrings.tabPerfil,
              route: AppRoutes.profile,
            ),
          ],
        _ => [
            _NavTab(
              icon: Icons.medication,
              label: AppStrings.tabTomas,
              widget: ChangeNotifierProvider.value(
                value: sl<IntakesViewModel>(),
                child: const DailyIntakesView(),
              ),
            ),
            _NavTab(
              icon: Icons.monitor_heart,
              label: AppStrings.tabVitales,
              widget: const _VitalesTab(),
            ),
            _NavTab(
              icon: Icons.notifications,
              label: AppStrings.tabAlertas,
              widget: const AlertsView(),
            ),
            _NavTab(
              icon: Icons.person_outline,
              label: AppStrings.tabPerfil,
              route: AppRoutes.profile,
            ),
          ],
      };

  void _onTap(BuildContext context, int index, List<_NavTab> tabs) {
    final tab = tabs[index];
    if (tab.route != null) {
      context.go(tab.route!);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  int _stackIndex(int tabIndex, List<_NavTab> tabs) {
    int count = 0;
    for (int i = 0; i < tabIndex; i++) {
      if (tabs[i].route == null) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final tipoPerfil = context.watch<AuthViewModel>().state.user?.tipoPerfil;
    final tabs = _tabs(tipoPerfil);
    final unreadCount = context.watch<AlertsViewModel>().state.unreadCount;

    final safeIndex =
        _currentIndex < tabs.length ? _currentIndex : 0;
    final currentTab = tabs[safeIndex];

    final stackWidgets =
        tabs.where((t) => t.route == null).map((t) => t.widget!).toList();

    return Scaffold(
      body: currentTab.route != null
          ? stackWidgets.isNotEmpty
              ? stackWidgets.first
              : const SizedBox.shrink()
          : IndexedStack(
              index: _stackIndex(safeIndex, tabs),
              children: stackWidgets,
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (i) => _onTap(context, i, tabs),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 14,
        unselectedFontSize: 13,
        iconSize: 28,
        items: tabs
            .map((t) => BottomNavigationBarItem(
                  icon: t.label == AppStrings.tabAlertas && unreadCount > 0
                      ? Badge(
                          label: Text('$unreadCount'),
                          child: Icon(t.icon),
                        )
                      : Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  final String? route;
  final Widget? widget;

  const _NavTab({
    required this.icon,
    required this.label,
    this.route,
    this.widget,
  });
}

class _VitalesTab extends StatelessWidget {
  const _VitalesTab();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DeviceViewModel>();
    final connected = vm.state.status.isActive;

    if (connected) {
      return ChangeNotifierProvider.value(
        value: sl<VitalsViewModel>(),
        child: const VitalsView(),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bluetooth_disabled, size: 72, color: AppColors.textHint),
            const SizedBox(height: 20),
            Text(
              AppStrings.deviceDisconnected,
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.devicePrompt,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text(AppStrings.connectDevice),
              onPressed: () => context.go(AppRoutes.device),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

