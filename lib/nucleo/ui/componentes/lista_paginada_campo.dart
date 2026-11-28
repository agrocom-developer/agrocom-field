import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';
import 'boton_secundario_campo.dart';
import 'esqueleto_variantes_campo.dart';

/// Estado de una [ListaPaginadaCampo], tal como lo lleva un bloc — este
/// widget no pide datos por sí mismo, solo pinta lo que el bloc entrega y
/// avisa cuándo pedir más. Un bloc típico mapea su propio estado a esto en
/// el builder, sin duplicar los campos.
@immutable
class EstadoListaPaginadaCampo<T> {
  const EstadoListaPaginadaCampo({
    this.items = const [],
    this.cargandoInicial = false,
    this.cargandoMas = false,
    this.hayMasPaginas = true,
    this.errorInicial,
    this.errorPagina,
    this.sinRed = false,
  });

  final List<T> items;

  /// Primera carga, todavía sin ítems.
  final bool cargandoInicial;

  /// Pidiendo la página siguiente; los ítems ya cargados se siguen viendo.
  final bool cargandoMas;

  /// `false` cuando el servidor ya no tiene más páginas (fin de la lista).
  final bool hayMasPaginas;

  /// Mensaje si la primera página falló (lista vacía con error).
  final String? errorInicial;

  /// Mensaje si una página siguiente falló (los ítems ya cargados quedan).
  final String? errorPagina;

  /// Sin conexión y sin ítems todavía — estado "sin red" distinto del error,
  /// porque no hay nada que reintentar hasta que vuelva la señal.
  final bool sinRed;

  bool get estaVacia =>
      items.isEmpty && !cargandoInicial && errorInicial == null && !sinRed;
}

/// Lista con paginación por páginas y `pull-to-refresh`, lista para un bloc:
/// carga inicial (esqueleto), página siguiente (esqueleto al pie), fin real
/// ("no hay más"), error con reintentar (inicial y de página) y vacío.
///
/// El widget no guarda su propio estado de red — lo recibe en [estado] y
/// notifica con [onRefrescar] (deslizar hacia abajo) y [onCargarMas] (al
/// acercarse al final). Quien lo usa decide qué hacer con cada aviso; este
/// widget nunca repite una llamada mientras [EstadoListaPaginadaCampo.cargandoMas]
/// siga en `true`.
class ListaPaginadaCampo<T> extends StatefulWidget {
  const ListaPaginadaCampo({
    required this.estado,
    required this.constructorItem,
    required this.onRefrescar,
    this.onCargarMas,
    this.vacio,
    this.esqueletoFila = const EsqueletoFilaListaCampo(),
    this.separacion = EspaciadoCampo.m,
    this.margen = const EdgeInsets.all(EspaciadoCampo.l),
    this.umbralCargaMas = 240,
    super.key,
  });

  final EstadoListaPaginadaCampo<T> estado;
  final Widget Function(BuildContext context, T item, int indice)
  constructorItem;

  /// El usuario deslizó hacia abajo para refrescar desde el principio.
  final Future<void> Function() onRefrescar;

  /// Se acercó al final de la lista y hay más páginas por pedir.
  final VoidCallback? onCargarMas;

  /// Reemplaza el estado vacío por defecto.
  final Widget? vacio;

  /// Forma de cada bloque del esqueleto (3 se repiten en la carga inicial).
  final Widget esqueletoFila;

  final double separacion;
  final EdgeInsetsGeometry margen;

  /// Distancia en píxeles al final a partir de la cual se pide la página
  /// siguiente.
  final double umbralCargaMas;

  @override
  State<ListaPaginadaCampo<T>> createState() => _ListaPaginadaCampoState<T>();
}

class _ListaPaginadaCampoState<T> extends State<ListaPaginadaCampo<T>> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _avisarSiCercaDelFinal() {
    final estado = widget.estado;
    if (widget.onCargarMas == null ||
        estado.cargandoMas ||
        estado.cargandoInicial ||
        !estado.hayMasPaginas ||
        estado.errorPagina != null) {
      return;
    }
    if (!_scroll.hasClients) return;
    final restante = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (restante <= widget.umbralCargaMas) widget.onCargarMas!();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final estado = widget.estado;

    if (estado.sinRed && estado.items.isEmpty) {
      return _EstadoCentrado(
        icono: Icons.wifi_off_rounded,
        texto: l10n.listaPaginadaSinRed,
        accion: BotonSecundarioCampo(
          texto: l10n.listaPaginadaReintentar,
          onPressed: widget.onRefrescar,
        ),
      );
    }

    if (estado.errorInicial != null && estado.items.isEmpty) {
      return _EstadoCentrado(
        icono: Icons.error_outline_rounded,
        texto: estado.errorInicial!,
        accion: BotonSecundarioCampo(
          texto: l10n.listaPaginadaReintentar,
          onPressed: widget.onRefrescar,
        ),
      );
    }

    if (estado.cargandoInicial && estado.items.isEmpty) {
      return ListView.separated(
        padding: widget.margen,
        itemCount: 3,
        separatorBuilder: (_, _) => SizedBox(height: widget.separacion),
        itemBuilder: (_, _) => widget.esqueletoFila,
      );
    }

    if (estado.estaVacia) {
      return widget.vacio ??
          _EstadoCentrado(
            icono: Icons.inbox_outlined,
            texto: l10n.listaPaginadaVacia,
          );
    }

    final hayPie =
        estado.cargandoMas ||
        !estado.hayMasPaginas ||
        estado.errorPagina != null;

    return RefreshIndicator(
      onRefresh: widget.onRefrescar,
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (_) {
          _avisarSiCercaDelFinal();
          return false;
        },
        child: ListView.separated(
          controller: _scroll,
          padding: widget.margen,
          itemCount: estado.items.length + (hayPie ? 1 : 0),
          separatorBuilder: (_, _) => SizedBox(height: widget.separacion),
          itemBuilder: (context, indice) {
            if (indice < estado.items.length) {
              return widget.constructorItem(
                context,
                estado.items[indice],
                indice,
              );
            }
            if (estado.errorPagina != null) {
              return _PiePagina(
                texto: estado.errorPagina!,
                accion: TextButton(
                  onPressed: widget.onCargarMas,
                  child: Text(l10n.listaPaginadaReintentar),
                ),
              );
            }
            if (estado.cargandoMas) return widget.esqueletoFila;
            return _PiePagina(
              texto: l10n.listaPaginadaFin,
              icono: Icons.check_circle_outline_rounded,
              color: paleta.textoSecundario,
            );
          },
        ),
      ),
    );
  }
}

class _PiePagina extends StatelessWidget {
  const _PiePagina({required this.texto, this.accion, this.icono, this.color});

  final String texto;
  final Widget? accion;
  final IconData? icono;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final colorTexto = color ?? paleta.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EspaciadoCampo.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 18, color: colorTexto),
            const SizedBox(width: EspaciadoCampo.s),
          ],
          Flexible(
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: TipografiaCampo.datoMono.copyWith(color: colorTexto),
            ),
          ),
          ?accion,
        ],
      ),
    );
  }
}

class _EstadoCentrado extends StatelessWidget {
  const _EstadoCentrado({
    required this.icono,
    required this.texto,
    this.accion,
  });

  final IconData icono;
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspaciadoCampo.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 40, color: paleta.textoSecundario),
            const SizedBox(height: EspaciadoCampo.m),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TipografiaCampo.cuerpo.copyWith(
                color: paleta.textoSecundario,
              ),
            ),
            if (accion != null) ...[
              const SizedBox(height: EspaciadoCampo.l),
              accion!,
            ],
          ],
        ),
      ),
    );
  }
}
