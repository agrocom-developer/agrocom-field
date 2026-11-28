import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../ui/componentes/componentes_campo.dart';
import '../../../ui/imagenes_campo.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../../ui/boton_principal_marketplace.dart';

/// Rol que la persona dice tener al abrir Agrocom. Solo hay dos: el
/// auxiliar dejó de ser un usuario de la app (ADR 0021).
enum RolElegido { cliente, piloto }

/// Los textos de cada rol. El `switch` es exhaustivo: un rol nuevo no compila
/// hasta tener sus textos (ADR 0022).
extension TextosRolElegido on RolElegido {
  String titulo(AppLocalizations l10n) => switch (this) {
    RolElegido.cliente => l10n.accesoRolCliente,
    RolElegido.piloto => l10n.accesoRolPiloto,
  };

  String detalle(AppLocalizations l10n) => switch (this) {
    RolElegido.cliente => l10n.accesoRolClienteDetalle,
    RolElegido.piloto => l10n.accesoRolPilotoDetalle,
  };

  /// Cómo se nombra en «Continuar como …».
  String enBoton(AppLocalizations l10n) => switch (this) {
    RolElegido.cliente => l10n.accesoRolClienteBoton,
    RolElegido.piloto => l10n.accesoRolPilotoBoton,
  };
}

/// «Elige tu rol»: collage de marca, propuesta y dos opciones (Cliente y
/// Piloto). La elegida lleva fondo de acento suave y borde de 2 dp, y un
/// círculo relleno, así que no depende solo del color.
class ElegirRolPantalla extends StatefulWidget {
  const ElegirRolPantalla({
    required this.alContinuar,
    required this.alTenerCuenta,
    this.inicial = RolElegido.cliente,
    this.cargando = false,
    super.key,
  });

  final ValueChanged<RolElegido> alContinuar;
  final VoidCallback alTenerCuenta;
  final RolElegido inicial;

  /// Mientras es verdadero, el botón no acepta toques y anuncia el envío.
  final bool cargando;

  @override
  State<ElegirRolPantalla> createState() => _ElegirRolPantallaState();
}

class _ElegirRolPantallaState extends State<ElegirRolPantalla> {
  late RolElegido _rol = widget.inicial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final margen = EspaciadoCampo.margenLateral(c.maxWidth);
          final amplia =
              ClasePantallaCampo.deAncho(c.maxWidth) !=
              ClasePantallaCampo.compacto;
          final alto = (c.maxHeight * 0.28).clamp(150.0, 270.0);
          final colage = ClipRRect(
            borderRadius: amplia
                ? BorderRadius.circular(RadioCampo.hoja)
                : const BorderRadius.vertical(
                    bottom: Radius.circular(RadioCampo.hoja),
                  ),
            child: SizedBox(
              height: alto,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: FotoColageCampo(
                      imagen: ImagenesCampo.dronAgrasT50,
                      radio: 0,
                    ),
                  ),
                  const SizedBox(width: EspaciadoCampo.xs),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: FotoColageCampo(
                            imagen: ImagenesCampo.equipoDron,
                            radio: 0,
                          ),
                        ),
                        const SizedBox(height: EspaciadoCampo.xs),
                        Expanded(
                          child: BloqueAmbarCampo(
                            titulo: 'DronAgro',
                            etiqueta: l10n.marketplaceAccesoFumigacionConDron,
                            cifra: false,
                            radio: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
          final cuerpo = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              colage,
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    margen,
                    EspaciadoCampo.xl,
                    margen,
                    EspaciadoCampo.l,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.marketplaceAccesoFumigacionConDronPrecio,
                        style: texto.headlineMedium,
                      ),
                      const SizedBox(height: EspaciadoCampo.s),
                      Text(
                        l10n.marketplaceAccesoPublicaLoteRecibeOfertas,
                        style: texto.bodyLarge?.copyWith(
                          color: paleta.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: EspaciadoCampo.xl),
                      Text(
                        l10n.marketplaceAccesoComoVasUsarAgrocom,
                        style: texto.titleMedium,
                      ),
                      const SizedBox(height: EspaciadoCampo.m),
                      Semantics(
                        container: true,
                        label: l10n.marketplaceAccesoEligeRol,
                        child: Column(
                          children: [
                            for (final rol in RolElegido.values) ...[
                              if (rol != RolElegido.values.first)
                                const SizedBox(height: EspaciadoCampo.s),
                              _OpcionRol(
                                rol: rol,
                                elegido: rol == _rol,
                                alElegir: () => setState(() => _rol = rol),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    margen,
                    EspaciadoCampo.s,
                    margen,
                    EspaciadoCampo.s,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BotonPrincipalMarketplace(
                        key: const Key('rol-continuar'),
                        texto: l10n.marketplaceAccesoContinuarComo(
                          _rol.enBoton(l10n),
                        ),
                        cargando: widget.cargando,
                        onPressed: () => widget.alContinuar(_rol),
                      ),
                      const SizedBox(height: EspaciadoCampo.xs),
                      TextButton(
                        key: const Key('rol-tengo-cuenta'),
                        onPressed: widget.cargando
                            ? null
                            : widget.alTenerCuenta,
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            ObjetivoTactilCampo.minimo,
                          ),
                          foregroundColor: paleta.acentoTexto,
                          textStyle: texto.titleMedium,
                        ),
                        child: Text(l10n.marketplaceAccesoTengoCuenta),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
          if (!amplia) return cuerpo;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: cuerpo,
            ),
          );
        },
      ),
    );
  }
}

class _OpcionRol extends StatelessWidget {
  const _OpcionRol({
    required this.rol,
    required this.elegido,
    required this.alElegir,
  });

  final RolElegido rol;
  final bool elegido;
  final VoidCallback alElegir;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final colorTexto = elegido ? paleta.sobreAcentoContenedor : paleta.texto;
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: elegido,
      label: '${rol.titulo(l10n)}. ${rol.detalle(l10n)}',
      excludeSemantics: true,
      onTap: alElegir,
      child: AnimatedContainer(
        duration: MovimientoCampo.duracion(context, MovimientoCampo.rapida),
        curve: MovimientoCampo.movimiento,
        decoration: BoxDecoration(
          color: elegido ? paleta.acentoContenedor : paleta.superficie,
          borderRadius: BorderRadius.circular(RadioCampo.tarjeta),
          border: Border.all(
            color: elegido ? paleta.acento : paleta.borde,
            width: elegido ? EspaciadoCampo.xs / 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: Key('rol-${rol.name}'),
            borderRadius: BorderRadius.circular(RadioCampo.tarjeta),
            onTap: alElegir,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: ObjetivoTactilCampo.guantes,
              ),
              child: Padding(
                padding: const EdgeInsets.all(EspaciadoCampo.l),
                child: Row(
                  children: [
                    _Circulo(elegido: elegido),
                    const SizedBox(width: EspaciadoCampo.l),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rol.titulo(l10n),
                            style: texto.titleMedium?.copyWith(
                              color: colorTexto,
                            ),
                          ),
                          Text(
                            rol.detalle(l10n),
                            style: texto.bodyMedium?.copyWith(
                              color: elegido
                                  ? paleta.sobreAcentoContenedor
                                  : paleta.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selector circular: vacío con borde, o con aro y centro del color de
/// acento cuando está elegido.
class _Circulo extends StatelessWidget {
  const _Circulo({required this.elegido});

  final bool elegido;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return AnimatedContainer(
      duration: MovimientoCampo.duracion(context, MovimientoCampo.rapida),
      width: EspaciadoCampo.xl,
      height: EspaciadoCampo.xl,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: elegido ? paleta.acento : null,
        border: Border.all(
          color: elegido ? paleta.acento : paleta.bordeFuerte,
          width: EspaciadoCampo.xs / 2,
        ),
      ),
      child: elegido
          ? Center(
              child: Icon(
                Icons.check_rounded,
                size: EspaciadoCampo.l,
                color: paleta.sobreAcento,
              ),
            )
          : null,
    );
  }
}
