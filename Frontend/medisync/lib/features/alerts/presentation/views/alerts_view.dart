import 'package:flutter/material.dart';
import 'package:medisync/core/constants/app_colors.dart';
import 'package:medisync/core/constants/app_strings.dart';
import 'package:medisync/core/constants/app_text_styles.dart';
import 'package:medisync/core/errors/failures.dart';
import 'package:medisync/features/alerts/presentation/viewmodels/alerts_viewmodel.dart';
import 'package:medisync/features/alerts/presentation/views/widgets/alert_card.dart';
import 'package:provider/provider.dart';

class AlertsView extends StatefulWidget {
  const AlertsView({super.key});

  @override
  State<AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> {
  Failure? _shownFailure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertsViewModel>().loadAlerts();
    });
  }

  void _maybeShowError(BuildContext context, AlertsState state) {
    final failure = state.failure;
    if (failure == null || failure == _shownFailure) return;
    _shownFailure = failure;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
      context.read<AlertsViewModel>().clearFailure();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AlertsViewModel>();
    final state = vm.state;
    _maybeShowError(context, state);

    final sorted = state.sorted;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.alerts),
      ),
      body: state.isLoading && sorted.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (sorted.isNotEmpty)
                  _MarkAllReadHeader(
                    enabled: state.unreadCount > 0,
                    onTap: vm.markAllAsRead,
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: vm.loadAlerts,
                    child: sorted.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.notifications_none,
                                          size: 72,
                                          color: Theme.of(context).disabledColor),
                                      const SizedBox(height: 20),
                                      Text(AppStrings.noAlerts,
                                          style: AppTextStyles.bodySecondary,
                                          textAlign: TextAlign.center),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: sorted.length,
                            itemBuilder: (context, index) =>
                                AlertCard(alerta: sorted[index]),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MarkAllReadHeader extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _MarkAllReadHeader({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: enabled ? onTap : null,
          icon: const Icon(Icons.done_all),
          label: const Text(AppStrings.markAllAsRead,
              style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
