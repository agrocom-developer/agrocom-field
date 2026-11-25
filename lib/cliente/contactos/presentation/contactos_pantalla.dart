import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/ui/boton_principal_marketplace.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../comun/presentation/estado_falla.dart';
import '../domain/contacto.dart';
import '../domain/contactos_repositorio.dart';
import 'contactos_cubit.dart';
import 'hoja_contacto.dart';

/// Contactos de referencia del cliente empresa: quién atiende al piloto en
/// cada solicitud. Se agrega, se corrige (tocando la fila) y se quita; el
/// principal es el que se usa cuando una solicitud no elige a otra persona.
class ContactosPantalla extends StatelessWidget {
  const ContactosPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ContactosCubit(context.read<ContactosRepositorio>())..cargar(),
      child: const _Vista(),
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.contactosTitulo)),
      body: BlocBuilder<ContactosCubit, ContactosEstado>(
        builder: (context, estado) => switch (estado) {
          ContactosCargando() => const Padding(
            padding: EdgeInsets.all(EspaciadoCampo.l),
            child: EsqueletoCampo(alto: 160),
          ),
          ContactosError(:final sinConexion) => EstadoFalla(
            sinConexion: sinConexion,
            queNoCargo: t.contactosTitulo.toLowerCase(),
            alReintentar: context.read<ContactosCubit>().cargar,
          ),
          ContactosListos() => _Lista(estado: estado),
        },
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.estado});

  final ContactosListos estado;

  Future<void> _abrir(BuildContext context, [ContactoCliente? contacto]) {
    final cubit = context.read<ContactosCubit>();
    return HojaContacto.abrir(
      context,
      contacto: contacto,
      guardar: (datos) => cubit.guardar(datos, id: contacto?.id),
    );
  }

  Future<void> _quitar(BuildContext context, ContactoCliente c) async {
    final t = AppLocalizations.of(context);
    final cubit = context.read<ContactosCubit>();
    final mensajes = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.contactosQuitarPregunta(c.nombre)),
        content: Text(t.contactosQuitarAviso),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.contactosCancelar),
          ),
          TextButton(
            key: const ValueKey('contacto-confirmar-quitar'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.contactosQuitar),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final r = await cubit.darDeBaja(c.id);
    if (r is ContactoFallo) {
      mensajes.showSnackBar(
        SnackBar(
          content: Text(
            r.sinConexion
                ? t.contactosSinConexion
                : (r.mensaje ?? t.contactosErrorGuardar),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final unico = estado.contactos.length <= 1;
    return ListView(
      padding: const EdgeInsets.all(EspaciadoCampo.l),
      children: [
        Text(
          t.contactosIntro,
          style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
        ),
        const SizedBox(height: EspaciadoCampo.l),
        for (final c in estado.contactos) ...[
          SuperficieMarketplace(
            key: ValueKey('contacto-${c.id}'),
            onTap: estado.ocupado ? null : () => _abrir(context, c),
            child: Semantics(
              container: true,
              label: t.contactosFilaSemantica(
                c.nombre,
                c.cargo ?? '',
                c.telefono,
              ),
              excludeSemantics: true,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.nombre, style: texto.titleMedium),
                        if (c.cargo != null)
                          Text(
                            c.cargo!,
                            style: texto.bodyMedium?.copyWith(
                              color: paleta.textoSecundario,
                            ),
                          ),
                        const SizedBox(height: EspaciadoCampo.xs),
                        Text(
                          c.telefono,
                          style: TipografiaCampo.datoMono.copyWith(
                            color: paleta.texto,
                          ),
                        ),
                        if (c.esPrincipal) ...[
                          const SizedBox(height: EspaciadoCampo.s),
                          ChipEstadoMarketplace(
                            etiqueta: t.contactosPrincipal,
                            tono: TonoEstado.exito,
                            icono: Icons.star_rounded,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    key: ValueKey('contacto-quitar-${c.id}'),
                    tooltip: unico ? t.contactosUnicoAviso : t.contactosQuitar,
                    onPressed: unico || estado.ocupado
                        ? null
                        : () => _quitar(context, c),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: EspaciadoCampo.s),
        ],
        if (unico && estado.contactos.isNotEmpty)
          Text(
            t.contactosUnicoAviso,
            style: texto.bodySmall?.copyWith(color: paleta.textoSecundario),
          ),
        const SizedBox(height: EspaciadoCampo.l),
        BotonPrincipalMarketplace(
          key: const ValueKey('contacto-agregar'),
          texto: t.contactosAgregar,
          icono: Icons.add_rounded,
          onPressed: estado.ocupado ? null : () => _abrir(context),
        ),
      ],
    );
  }
}
