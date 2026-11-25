import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/foto_perfil/presentation/foto_perfil_widgets.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tema_visual/selector_tema_visual.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../calificar/domain/calificacion_repositorio.dart';
import '../../contactos/domain/contacto.dart';
import '../../contactos/domain/contactos_repositorio.dart';
import '../../contactos/presentation/contactos_pantalla.dart';
import '../../lotes/presentation/fila_lote.dart';
import '../../solicitar/domain/solicitud_repositorio.dart';
import '../domain/cuenta_repositorio.dart';

/// Perfil del cliente (pantalla 17): quién es, sus cifras, «Mis campos», los
/// ajustes (tema) y cerrar sesión; debajo, lo que los proveedores dijeron de
/// él.
class CuentaPantalla extends StatefulWidget {
  const CuentaPantalla({this.alCerrarSesion, this.alPublicar, super.key});

  /// Acción de cerrar sesión; sin ella el botón no se muestra.
  final VoidCallback? alCerrarSesion;

  /// Abre el flujo de publicar un lote («+ Agregar» de «Mis campos»).
  final VoidCallback? alPublicar;

  @override
  State<CuentaPantalla> createState() => _CuentaPantallaState();
}

class _CuentaPantallaState extends State<CuentaPantalla> {
  /// Cambia al reintentar para que la carga vuelva a empezar.
  int _intento = 0;

  VoidCallback? get alCerrarSesion => widget.alCerrarSesion;
  VoidCallback? get alPublicar => widget.alPublicar;

  /// El repositorio de contactos existe solo si la app lo provee.
  bool get conContactos {
    try {
      context.read<ContactosRepositorio>();
      return true;
    } on ProviderNotFoundException {
      return false;
    }
  }

  static String _iniciales(String nombre) => nombre
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  static Future<_Datos> _cargar(
    CuentaRepositorio cuentas,
    CalificacionRepositorio calificaciones,
    SolicitudRepositorio solicitudes,
  ) async {
    final (cuenta, resumen, lotes) = await (
      cuentas.cuenta(),
      calificaciones.recibidas(),
      solicitudes.lotesDelCliente(),
    ).wait;
    return _Datos(cuenta, resumen, lotes);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return FuturoEstable<_Datos>(
      key: ValueKey(_intento),
      crear: () => _cargar(
        context.read<CuentaRepositorio>(),
        context.read<CalificacionRepositorio>(),
        context.read<SolicitudRepositorio>(),
      ),
      builder: (context, snap) {
        if (snap.hasError) {
          return EstadoErrorMarketplace(
            titulo: t.perfilErrorCargaTitulo,
            detalle: t.perfilErrorCargaDetalle,
            onReintentar: () => setState(() => _intento++),
          );
        }
        final d = snap.data;
        if (d == null) {
          return const Padding(
            padding: EdgeInsets.all(EspaciadoCampo.l),
            child: EsqueletoCampo(alto: 160),
          );
        }
        final cuenta = d.cuenta;
        final resumen = d.resumen;
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            FotoPerfilProveedor(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AvatarFotoPerfil(
                        iniciales: _iniciales(cuenta.nombre),
                        nombre: cuenta.nombre,
                        tamano: 64,
                      ),
                      const SizedBox(width: EspaciadoCampo.l),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                cuenta.nombre,
                                style: texto.headlineSmall,
                              ),
                            ),
                            Text(
                              cuenta.empresa.isEmpty
                                  ? t.perfilClienteRol
                                  : '${t.perfilClienteRol} · ${cuenta.empresa}',
                              style: texto.bodyMedium?.copyWith(
                                color: paleta.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: EspaciadoCampo.s),
                  const AccionesFotoPerfil(),
                ],
              ),
            ),
            const SizedBox(height: EspaciadoCampo.l),
            SuperficieMarketplace(
              child: Row(
                children: [
                  Expanded(
                    child: _Cifra(
                      '${d.lotes.length}',
                      t.perfilClienteEstadLotes,
                    ),
                  ),
                  Expanded(
                    child: _Cifra(
                      '${cuenta.serviciosTotales}',
                      t.perfilClienteEstadServicios,
                    ),
                  ),
                  Expanded(
                    child: _Cifra(
                      resumen.promedio.toStringAsFixed(1).replaceAll('.', ','),
                      t.perfilClienteEstadCalificacion,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: EspaciadoCampo.l),
            SuperficieMarketplace(
              padding: const EdgeInsets.symmetric(horizontal: EspaciadoCampo.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: EspaciadoCampo.m),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              t.perfilMisCampos,
                              style: texto.titleLarge,
                            ),
                          ),
                        ),
                        if (alPublicar != null)
                          TextButton(
                            key: const Key('perfil-agregar-campo'),
                            onPressed: alPublicar,
                            child: Text(t.perfilAgregarCampo),
                          ),
                      ],
                    ),
                  ),
                  if (d.lotes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: EspaciadoCampo.m,
                      ),
                      child: Text(
                        t.perfilMisCamposVacio,
                        style: texto.bodyMedium?.copyWith(
                          color: paleta.textoSecundario,
                        ),
                      ),
                    ),
                  for (final lote in d.lotes) FilaLote(lote: lote),
                ],
              ),
            ),
            const SizedBox(height: EspaciadoCampo.l),
            const SuperficieMarketplace(
              child: SelectorTemaVisual(predeterminado: ModoVisualCampo.claro),
            ),
            if (cuenta.empresa.isNotEmpty && conContactos) ...[
              const SizedBox(height: EspaciadoCampo.l),
              _FilaContactos(),
            ],
            const SizedBox(height: EspaciadoCampo.xl),
            Text(t.perfilLoDicen, style: texto.titleLarge),
            const SizedBox(height: EspaciadoCampo.m),
            for (final c in resumen.recientes) ...[
              SuperficieMarketplace(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(c.autor, style: texto.titleSmall)),
                        CalificacionCampo(valor: c.puntaje, tamano: 18),
                      ],
                    ),
                    if (c.comentario != null) ...[
                      const SizedBox(height: 6),
                      Text(c.comentario!, style: texto.bodyMedium),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: EspaciadoCampo.s),
            ],
            if (alCerrarSesion != null) ...[
              const SizedBox(height: EspaciadoCampo.xl),
              Center(
                child: TextButton(
                  key: const Key('cuenta-cerrar-sesion'),
                  onPressed: alCerrarSesion,
                  style: TextButton.styleFrom(
                    foregroundColor: paleta.error,
                    minimumSize: const Size(
                      ObjetivoTactilCampo.minimo,
                      ObjetivoTactilCampo.guantes,
                    ),
                  ),
                  child: Text(
                    t.perfilCerrarSesion,
                    style: TipografiaCampo.tituloTarjeta.copyWith(
                      color: paleta.error,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// «Contactos de referencia · N personas»: abre la pantalla de contactos.
class _FilaContactos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return FuturoEstable<List<ContactoCliente>>(
      crear: () => context.read<ContactosRepositorio>().listar(),
      builder: (context, snap) => SuperficieMarketplace(
        key: const Key('perfil-contactos'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ContactosPantalla()),
        ),
        child: Row(
          children: [
            Icon(Icons.groups_outlined, color: context.paleta.acentoTexto),
            const SizedBox(width: EspaciadoCampo.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.contactosPerfilFila, style: texto.titleMedium),
                  if (snap.data != null)
                    Text(
                      t.contactosPerfilDetalle(snap.data!.length),
                      style: texto.bodyMedium?.copyWith(
                        color: context.paleta.textoSecundario,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.paleta.textoSecundario,
            ),
          ],
        ),
      ),
    );
  }
}

class _Datos {
  const _Datos(this.cuenta, this.resumen, this.lotes);

  final CuentaCliente cuenta;
  final ResumenCalificaciones resumen;
  final List<Lote> lotes;
}

class _Cifra extends StatelessWidget {
  const _Cifra(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          valor,
          style: TipografiaCampo.cifraMedia.copyWith(
            color: context.paleta.texto,
          ),
        ),
        Text(
          etiqueta,
          textAlign: TextAlign.center,
          style: texto.bodySmall?.copyWith(
            color: context.paleta.textoSecundario,
          ),
        ),
      ],
    );
  }
}
