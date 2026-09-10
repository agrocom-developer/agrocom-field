import 'package:get_it/get_it.dart';

import '../api/api_client.dart';
import '../auth/token_store.dart';
import '../flavor.dart';

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
  // AppDatabase, SyncEngine, SyncCubit y los repositorios de cada feature se
  // registran acá cuando TE-04/TE-05/TE-06 los agreguen — no antes.
}
