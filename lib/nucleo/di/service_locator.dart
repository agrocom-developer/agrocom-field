import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import '../../features/avisos_locales/data/ids_vistos_store.dart';
import '../../features/incidencias/data/incidencia_repository.dart';
import '../../features/ordenes/data/ordenes_repository.dart';
import '../../features/sesion_vuelo/data/trabajo_repository.dart';
import '../../features/sesion_vuelo/data/sesion_repository.dart';
import '../api/api_client.dart';
import '../auth/dispositivo_store.dart';
import '../auth/login_service.dart';
import '../auth/persona_operativa_store.dart';
import '../auth/rol_activo_store.dart';
import '../auth/token_store.dart';
import '../camara/selector_foto.dart';
import '../catalogo/catalogo_repository.dart';
import '../db/database.dart';
import '../evidencias/compresor_evidencia.dart';
import '../evidencias/directorio_evidencias.dart';
import '../evidencias/evidencia_repository.dart';
import '../evidencias/evidencia_sync_engine.dart';
import '../flavor.dart';
import '../linterna/linterna_controlador.dart';
import '../notificaciones/notificador_local.dart';
import '../preferencias/preferencias_store.dart';
import '../sync/disparador_sync.dart';
import '../sync/outbox_repository.dart';
import '../sync/sync_cubit.dart';
import '../sync/sync_engine.dart';
import '../version/version_instalada.dart';
import '../version/version_repository.dart';
import '../version/version_watcher.dart';

final getIt = GetIt.instance;

// Fallback solo para `flutter run` sin flags — cualquier build real (piloto
// en campo, staging, producción) SIEMPRE pasa --dart-define-from-file. Ver
// docs/decisiones/0004-configuracion-entorno-dart-define-from-file.md.
const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

Future<void> configurarDependencias({required Flavor flavor}) async {
  getIt.registerLazySingleton<Flavor>(() => flavor);
  getIt.registerLazySingleton<TokenStore>(TokenStoreSeguro.new);
  getIt.registerLazySingleton<DispositivoStore>(DispositivoStoreSeguro.new);
  getIt.registerLazySingleton<PersonaOperativaStore>(
    PersonaOperativaStoreSeguro.new,
  );
  getIt.registerLazySingleton<RolActivoStore>(RolActivoStoreSeguro.new);
  getIt.registerLazySingleton<PreferenciasStore>(PreferenciasStoreLocal.new);
  getIt.registerLazySingleton<NotificadorLocal>(NotificadorLocalPlugin.new);
  getIt.registerLazySingleton<LinternaControlador>(
    LinternaControladorTorchLight.new,
  );
  getIt.registerLazySingleton<IdsVistosStore>(IdsVistosStoreLocal.new);
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(baseUrl: _apiBaseUrl, tokenStore: getIt<TokenStore>()),
  );
  getIt.registerLazySingleton<LoginService>(
    () => LoginService(
      apiClient: getIt<ApiClient>(),
      tokenStore: getIt<TokenStore>(),
      dispositivoStore: getIt<DispositivoStore>(),
      personaOperativaStore: getIt<PersonaOperativaStore>(),
      rolActivoStore: getIt<RolActivoStore>(),
    ),
  );
  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);
  getIt.registerLazySingleton<OutboxRepository>(
    () => OutboxRepository(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<SyncEngine>(
    () => SyncEngine(
      apiClient: getIt<ApiClient>(),
      outbox: getIt<OutboxRepository>(),
    ),
  );
  getIt.registerLazySingleton<SyncCubit>(() => SyncCubit(getIt<SyncEngine>()));
  getIt.registerLazySingleton<CatalogoRepository>(
    () => CatalogoRepository(
      db: getIt<AppDatabase>(),
      apiClient: getIt<ApiClient>(),
    ),
  );
  getIt.registerLazySingleton<OrdenesRepository>(
    () => OrdenesRepository(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<TrabajoRepository>(
    () => TrabajoRepository(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<SesionRepository>(
    () => SesionRepository(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<CompresorEvidencia>(
    CompresorEvidenciaFlutterImageCompress.new,
  );
  final directorioEvidencias = await resolverDirectorioEvidencias();
  getIt.registerLazySingleton<EvidenciaRepository>(
    () => EvidenciaRepository(
      getIt<AppDatabase>(),
      compresor: getIt<CompresorEvidencia>(),
      directorioEvidencias: directorioEvidencias,
    ),
  );
  getIt.registerLazySingleton<EvidenciaSyncEngine>(
    () => EvidenciaSyncEngine(
      apiClient: getIt<ApiClient>(),
      db: getIt<AppDatabase>(),
    ),
  );
  getIt.registerLazySingleton<DisparadorSync>(
    () => DisparadorSync(
      catalogoRepositorio: getIt<CatalogoRepository>(),
      syncEngine: getIt<SyncEngine>(),
      evidenciaSyncEngine: getIt<EvidenciaSyncEngine>(),
      cambiosConectividad: Connectivity().onConnectivityChanged,
    ),
  );
  getIt.registerLazySingleton<SelectorFoto>(SelectorFotoImagePicker.new);
  getIt.registerLazySingleton<IncidenciaRepository>(
    () => IncidenciaRepository(
      getIt<AppDatabase>(),
      evidenciaRepository: getIt<EvidenciaRepository>(),
    ),
  );
  getIt.registerLazySingleton<VersionInstalada>(
    VersionInstaladaPackageInfo.new,
  );
  getIt.registerLazySingleton<VersionRepository>(
    () => VersionRepository(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<VersionWatcher>(
    () => VersionWatcher(
      repositorio: getIt<VersionRepository>(),
      versionInstalada: getIt<VersionInstalada>(),
    ),
  );
  // Los repositorios del resto de las features (recargas...) se
  // registran acá cuando esa feature los agregue — no antes.
}
