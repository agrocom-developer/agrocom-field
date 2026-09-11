import 'package:get_it/get_it.dart';

import '../../features/avisos_locales/data/ids_vistos_store.dart';
import '../../features/ordenes/data/ordenes_repository.dart';
import '../../features/sesion_vuelo/data/trabajo_repository.dart';
import '../../features/sesion_vuelo/data/sesion_repository.dart';
import '../api/api_client.dart';
import '../auth/dispositivo_store.dart';
import '../auth/login_service.dart';
import '../auth/persona_operativa_store.dart';
import '../auth/rol_activo_store.dart';
import '../auth/token_store.dart';
import '../catalogo/catalogo_repository.dart';
import '../db/database.dart';
import '../flavor.dart';
import '../notificaciones/notificador_local.dart';
import '../preferencias/preferencias_store.dart';
import '../sync/outbox_repository.dart';
import '../sync/sync_cubit.dart';
import '../sync/sync_engine.dart';

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
  // Los repositorios de cada feature (recargas...) se
  // registran acá cuando esa feature los agregue — no antes.
}
