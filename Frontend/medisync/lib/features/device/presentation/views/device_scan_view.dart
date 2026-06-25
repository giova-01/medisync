import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medisync/core/constants/app_colors.dart';
import 'package:medisync/core/constants/app_strings.dart';
import 'package:medisync/core/constants/app_text_styles.dart';
import 'package:medisync/features/auth/presentation/widgets/primary_button.dart';
import 'package:medisync/features/device/domain/entities/device.dart';
import 'package:medisync/features/device/domain/entities/device_status.dart';
import 'package:medisync/features/device/presentation/viewmodels/device_viewmodel.dart';
import 'package:provider/provider.dart';

class DeviceScanView extends StatefulWidget {
  const DeviceScanView({super.key});

  @override
  State<DeviceScanView> createState() => _DeviceScanViewState();
}

class _DeviceScanViewState extends State<DeviceScanView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceViewModel>().checkConnectionStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DeviceViewModel>();
    final state = vm.state;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (state.failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.failure!.message),
            backgroundColor: AppColors.error,
          ),
        );
        vm.clearFailure();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.deviceTitle),
        leading: BackButton(onPressed: () => context.pop()),
        bottom: state.status.isBusy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (state.connectedDevice != null) ...[
            _ConnectedDeviceCard(
              device: state.connectedDevice!,
              onDisconnect: vm.disconnect,
            ),
            const SizedBox(height: 24),
          ],
          if (state.connectedDevice == null) ...[
            Text(
              AppStrings.deviceDescription,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: AppStrings.scanDevices,
              icon: Icons.bluetooth_searching,
              isLoading: state.status.isBusy,
              onPressed: state.status.isBusy ? null : vm.scan,
            ),
          ],
          if (state.availableDevices.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(AppStrings.deviceFound, style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            ...state.availableDevices.map(
              (d) => _DeviceListTile(
                device: d,
                isBusy: state.status.isBusy,
                onConnect: () => vm.connect(d.id),
              ),
            ),
          ],
          if (state.status == DeviceStatus.disconnected &&
              state.availableDevices.isEmpty &&
              state.connectedDevice == null)
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _ConnectedDeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onDisconnect;

  const _ConnectedDeviceCard({
    required this.device,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bluetooth_connected,
                  color: AppColors.secondary,
                  size: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.name, style: AppTextStyles.heading3),
                      Text(
                        AppStrings.deviceConnected,
                        style: AppTextStyles.bodySecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onDisconnect,
                child: const Text(AppStrings.disconnectDevice),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceListTile extends StatelessWidget {
  final Device device;
  final bool isBusy;
  final VoidCallback onConnect;

  const _DeviceListTile({
    required this.device,
    required this.isBusy,
    required this.onConnect,
  });

  Color _rssiColor() {
    if (device.rssi > -70) return AppColors.secondary;
    if (device.rssi > -85) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.bluetooth, color: _rssiColor(), size: 32),
        title: Text(device.name, style: AppTextStyles.body),
        subtitle: Text(
          '${AppStrings.deviceSignal}: ${device.rssi} dBm',
          style: AppTextStyles.bodySecondary,
        ),
        trailing: TextButton(
          onPressed: isBusy ? null : onConnect,
          child: const Text(AppStrings.connectDevice),
        ),
      ),
    );
  }
}
