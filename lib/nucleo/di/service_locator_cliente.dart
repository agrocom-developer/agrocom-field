import 'package:get_it/get_it.dart';

import '../api/api_client.dart';
import '../auth/token_store.dart';
import '../entorno/api_base_url.dart';
import '../flavor.dart';

/// Inyección mínima del flavor cliente: solo lo que necesita sin base local
/// (API y sesión). No registra `AppDatabase`, `SyncEngine` ni
/// `DisparadorSync`: el cliente es online-first y no usa outbox (ADR 0009).
Future<void> configurarDependenciasCliente() async {
  final getIt = GetIt.instance;
  getIt.registerLazySingleton<Flavor>(() => Flavor.cliente);
  getIt.registerLazySingleton<TokenStore>(TokenStoreSeguro.new);
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(baseUrl: apiBaseUrl, tokenStore: getIt<TokenStore>()),
  );
}
