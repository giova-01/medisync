import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:medisync/core/network/api_client.dart';
import 'package:medisync/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:medisync/features/device/data/datasources/ble/ble_datasource.dart';
import 'package:medisync/features/device/data/datasources/local/device_local_datasource.dart';
import 'package:medisync/features/device/data/repositories/device_repository_impl.dart';
import 'package:medisync/features/device/domain/repositories/device_repository.dart';
import 'package:medisync/features/device/domain/usecases/connect_device_usecase.dart';
import 'package:medisync/features/device/domain/usecases/disconnect_device_usecase.dart';
import 'package:medisync/features/device/domain/usecases/get_connected_device_usecase.dart';
import 'package:medisync/features/device/domain/usecases/scan_devices_usecase.dart';
import 'package:medisync/features/device/presentation/viewmodels/device_viewmodel.dart';
import 'package:medisync/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:medisync/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:medisync/features/auth/domain/repositories/auth_repository.dart';
import 'package:medisync/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:medisync/features/auth/domain/usecases/login_usecase.dart';
import 'package:medisync/features/auth/domain/usecases/logout_usecase.dart';
import 'package:medisync/features/auth/domain/usecases/recover_password_usecase.dart';
import 'package:medisync/features/auth/domain/usecases/register_usecase.dart';
import 'package:medisync/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:medisync/features/medication/data/datasources/local/med_local_datasource.dart';
import 'package:medisync/features/medication/data/datasources/remote/med_remote_datasource.dart';
import 'package:medisync/features/medication/data/repositories/medication_repository_impl.dart';
import 'package:medisync/features/medication/domain/repositories/medication_repository.dart';
import 'package:medisync/features/medication/domain/usecases/add_medicamento_usecase.dart';
import 'package:medisync/features/medication/domain/usecases/confirm_intake_usecase.dart';
import 'package:medisync/features/medication/domain/usecases/get_daily_intakes_usecase.dart';
import 'package:medisync/features/medication/domain/usecases/list_medicamentos_usecase.dart';
import 'package:medisync/features/medication/domain/usecases/postpone_intake_usecase.dart';
import 'package:medisync/features/medication/domain/usecases/remove_medicamento_usecase.dart';
import 'package:medisync/features/medication/domain/usecases/update_medicamento_usecase.dart';
import 'package:medisync/features/medication/presentation/viewmodels/intakes_viewmodel.dart';
import 'package:medisync/features/medication/presentation/viewmodels/schedule_viewmodel.dart';
import 'package:medisync/features/user_profile/data/datasources/remote/link_remote_datasource.dart';
import 'package:medisync/features/user_profile/data/datasources/remote/profile_remote_datasource.dart';
import 'package:medisync/features/user_profile/data/repositories/link_repository_impl.dart';
import 'package:medisync/features/user_profile/data/repositories/profile_repository_impl.dart';
import 'package:medisync/features/user_profile/domain/repositories/link_repository.dart';
import 'package:medisync/features/user_profile/domain/repositories/profile_repository.dart';
import 'package:medisync/features/user_profile/domain/usecases/get_profile_usecase.dart';
import 'package:medisync/features/user_profile/domain/usecases/list_links_usecase.dart';
import 'package:medisync/features/user_profile/domain/usecases/request_link_usecase.dart';
import 'package:medisync/features/user_profile/domain/usecases/respond_link_usecase.dart';
import 'package:medisync/features/user_profile/domain/usecases/revoke_link_usecase.dart';
import 'package:medisync/features/user_profile/domain/usecases/update_profile_usecase.dart';
import 'package:medisync/features/user_profile/presentation/viewmodels/links_viewmodel.dart';
import 'package:medisync/features/user_profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:medisync/features/vital_signs/data/datasources/remote/vitals_remote_datasource.dart';
import 'package:medisync/features/vital_signs/data/repositories/vital_signs_repository_impl.dart';
import 'package:medisync/features/vital_signs/domain/repositories/vital_signs_repository.dart';
import 'package:medisync/features/vital_signs/domain/usecases/get_history_usecase.dart';
import 'package:medisync/features/vital_signs/domain/usecases/get_latest_readings_usecase.dart';
import 'package:medisync/features/alerts/data/datasources/notification_datasource.dart';
import 'package:medisync/features/alerts/data/repositories/alerts_repository_impl.dart';
import 'package:medisync/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:medisync/features/alerts/domain/usecases/get_alerts_usecase.dart';
import 'package:medisync/features/alerts/domain/usecases/mark_alert_as_read_usecase.dart';
import 'package:medisync/features/alerts/domain/usecases/mark_all_as_read_usecase.dart';
import 'package:medisync/features/alerts/presentation/viewmodels/alerts_viewmodel.dart';
import 'package:medisync/features/vital_signs/presentation/viewmodels/vitals_viewmodel.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── Core ──────────────────────────────────────────────────────────────────
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final localDS = AuthLocalDataSourceImpl(secureStorage);
  sl.registerLazySingleton<AuthLocalDataSource>(() => localDS);

  final baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000/api/v1';

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(
      tokenDS: localDS,
      baseUrl: baseUrl,
    ),
  );

  // ── Auth feature ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<ApiClient>()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      local: sl<AuthLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RecoverPasswordUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl<AuthRepository>()));

  // AuthViewModel is a singleton: GoRouter uses it as refreshListenable
  // and it is provided at the root of the widget tree.
  sl.registerLazySingleton<AuthViewModel>(
    () => AuthViewModel(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      recoverPasswordUseCase: sl(),
      currentUserUseCase: sl(),
    ),
  );

  // ── user_profile feature ──────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton<LinkRemoteDataSource>(
    () => LinkRemoteDataSourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<LinkRepository>(
    () => LinkRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton(() => GetProfileUseCase(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => RequestLinkUseCase(sl<LinkRepository>()));
  sl.registerLazySingleton(() => RespondLinkUseCase(sl<LinkRepository>()));
  sl.registerLazySingleton(() => ListLinksUseCase(sl<LinkRepository>()));
  sl.registerLazySingleton(() => RevokeLinkUseCase(sl<LinkRepository>()));
  sl.registerFactory(
    () => ProfileViewModel(
      getProfileUC: sl(),
      updateUC: sl(),
    ),
  );
  sl.registerFactory(
    () => LinksViewModel(
      requestUC: sl(),
      respondUC: sl(),
      listUC: sl(),
      revokeUC: sl(),
    ),
  );

  // ── medication feature ────────────────────────────────────────────────────
  sl.registerLazySingleton<MedRemoteDataSource>(
    () => MedRemoteDataSourceImpl(sl<ApiClient>(), sl<AuthLocalDataSource>()),
  );
  sl.registerLazySingleton<MedLocalDataSource>(() => MedLocalDataSourceImpl());
  sl.registerLazySingleton<MedicationRepository>(
    () => MedicationRepositoryImpl(remote: sl(), local: sl()),
  );
  sl.registerLazySingleton(() => GetDailyIntakesUseCase(sl<MedicationRepository>()));
  sl.registerLazySingleton(() => ConfirmIntakeUseCase(sl<MedicationRepository>()));
  sl.registerLazySingleton(() => PostponeIntakeUseCase(sl<MedicationRepository>()));
  sl.registerLazySingleton(() => ListMedicamentosUseCase(sl<MedicationRepository>()));
  sl.registerLazySingleton(() => AddMedicamentoUseCase(sl<MedicationRepository>()));
  sl.registerLazySingleton(() => UpdateMedicamentoUseCase(sl<MedicationRepository>()));
  sl.registerLazySingleton(() => RemoveMedicamentoUseCase(sl<MedicationRepository>()));
  sl.registerFactory(
    () => IntakesViewModel(
      getDailyIntakesUC: sl(),
      confirmUC: sl(),
      postponeUC: sl(),
    ),
  );
  sl.registerFactory(
    () => ScheduleViewModel(
      listUC: sl(),
      addUC: sl(),
      updateUC: sl(),
      removeUC: sl(),
    ),
  );

  // ── device feature ────────────────────────────────────────────────────────
  sl.registerLazySingleton<BleDataSource>(() => BleDataSourceMock());
  sl.registerLazySingleton<DeviceLocalDataSource>(
    () => DeviceLocalDataSourceImpl(secureStorage),
  );
  sl.registerLazySingleton<DeviceRepository>(
    () => DeviceRepositoryImpl(ble: sl(), local: sl(), api: sl<ApiClient>()),
  );
  sl.registerLazySingleton(() => ScanDevicesUseCase(sl<DeviceRepository>()));
  sl.registerLazySingleton(() => ConnectDeviceUseCase(sl<DeviceRepository>()));
  sl.registerLazySingleton(() => DisconnectDeviceUseCase(sl<DeviceRepository>()));
  sl.registerLazySingleton(() => GetConnectedDeviceUseCase(sl<DeviceRepository>()));
  sl.registerLazySingleton<DeviceViewModel>(
    () => DeviceViewModel(
      scanUC: sl(),
      connectUC: sl(),
      disconnectUC: sl(),
      getConnectedUC: sl(),
    ),
  );

  // ── vital_signs feature ───────────────────────────────────────────────────
  sl.registerLazySingleton<VitalsRemoteDataSource>(
    () => VitalsRemoteDataSourceImpl(sl<ApiClient>(), sl<AuthLocalDataSource>(), baseUrl),
  );
  sl.registerLazySingleton<VitalSignsRepository>(
    () => VitalSignsRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton(() => GetLatestReadingsUseCase(sl<VitalSignsRepository>()));
  sl.registerLazySingleton(() => GetHistoryUseCase(sl<VitalSignsRepository>()));
  sl.registerFactory(
    () => VitalsViewModel(
      repository: sl(),
      getLatestUC: sl(),
      getHistoryUC: sl(),
    ),
  );

  // ── alerts feature ────────────────────────────────────────────────────────
  sl.registerLazySingleton<NotificationDataSource>(
    () => NotificationDataSourceImpl(sl<ApiClient>(), sl<AuthLocalDataSource>(), baseUrl),
  );
  sl.registerLazySingleton<AlertsRepository>(
    () => AlertsRepositoryImpl(notificationDS: sl()),
  );
  sl.registerLazySingleton(() => GetAlertsUseCase(sl<AlertsRepository>()));
  sl.registerLazySingleton(
    () => MarkAlertAsReadUseCase(sl<AlertsRepository>()),
  );
  sl.registerLazySingleton(
    () => MarkAllAsReadUseCase(sl<AlertsRepository>()),
  );
  sl.registerLazySingleton<AlertsViewModel>(
    () => AlertsViewModel(
      repository: sl(),
      getAlertsUC: sl(),
      markAsReadUC: sl(),
      markAllAsReadUC: sl(),
    ),
  );
}
