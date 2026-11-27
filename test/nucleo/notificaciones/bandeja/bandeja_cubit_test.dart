import 'package:agrocom_field/nucleo/marketplace/dominio/falla.dart';
import 'package:agrocom_field/nucleo/notificaciones/bandeja/data/bandeja_demo.dart';
import 'package:agrocom_field/nucleo/notificaciones/bandeja/domain/bandeja_repositorio.dart';
import 'package:agrocom_field/nucleo/notificaciones/bandeja/domain/notificacion.dart';
import 'package:agrocom_field/nucleo/notificaciones/bandeja/presentation/bandeja_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _Falla implements BandejaRepositorio {
  _Falla(this.falla);

  final FallaMarketplace falla;

  @override
  Future<List<Notificacion>> listar() async => throw falla;

  @override
  Future<void> marcarLeida(int id) async => throw falla;

  @override
  Future<void> marcarTodasLeidas() async => throw falla;
}

BandejaCubit _cubit() => BandejaCubit(BandejaDemo(latencia: Duration.zero));

void main() {
  test('carga los avisos y cuenta las no leídas', () async {
    final cubit = _cubit();
    await cubit.cargar();
    final e = cubit.state as BandejaLista;
    expect(e.todas, hasLength(7));
    expect(e.noLeidas, 3);
    await cubit.close();
  });

  test('los filtros separan mensajes de avisos del sistema', () async {
    final cubit = _cubit();
    await cubit.cargar();
    cubit.filtrar(FiltroBandeja.mensajes);
    var e = cubit.state as BandejaLista;
    expect(e.visibles, isNotEmpty);
    expect(e.visibles.every((n) => n.esMensaje), isTrue);
    cubit.filtrar(FiltroBandeja.sistema);
    e = cubit.state as BandejaLista;
    expect(e.visibles.every((n) => !n.esMensaje), isTrue);
    expect(e.visibles.length + 3, e.todas.length);
    await cubit.close();
  });

  test('abrir un aviso lo marca leído y no vuelve a contar', () async {
    final cubit = _cubit();
    await cubit.cargar();
    final sinLeer = (cubit.state as BandejaLista).todas.firstWhere(
      (n) => !n.leida,
    );
    await cubit.abrir(sinLeer);
    final e = cubit.state as BandejaLista;
    expect(e.todas.firstWhere((n) => n.id == sinLeer.id).leida, isTrue);
    expect(e.noLeidas, 2);
    await cubit.close();
  });

  test('marcar todas deja la bandeja sin pendientes', () async {
    final cubit = _cubit();
    await cubit.cargar();
    await cubit.marcarTodasLeidas();
    expect((cubit.state as BandejaLista).noLeidas, 0);
    await cubit.close();
  });

  test('sin conexión pasa a error con la marca de red', () async {
    final cubit = BandejaCubit(_Falla(const SinConexion()));
    await cubit.cargar();
    expect((cubit.state as BandejaError).sinConexion, isTrue);
    await cubit.close();
  });

  test('un rechazo del servidor es error sin la marca de red', () async {
    final cubit = BandejaCubit(_Falla(const OperacionRechazada('no')));
    await cubit.cargar();
    expect((cubit.state as BandejaError).sinConexion, isFalse);
    await cubit.close();
  });
}
