import 'package:get_it/get_it.dart';

import '../api/api_client.dart';
import '../auth/token_store.dart';
import '../catalogo/catalogo_repository.dart';
import '../db/database.dart';
import '../flavor.dart';
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
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(baseUrl: _apiBaseUrl, tokenStore: getIt<TokenStore>()),
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
  // Los repositorios de cada feature (trabajos, sesiones, recargas...) se
  // registran acá cuando esa feature los agregue — no antes.
}
