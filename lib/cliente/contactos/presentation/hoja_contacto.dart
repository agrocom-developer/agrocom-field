import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/ui/boton_principal_marketplace.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/contacto.dart';
import 'contactos_cubit.dart';

/// Hoja para agregar o corregir un contacto. [guardar] devuelve el resultado
/// del servidor: si falla, la hoja queda abierta con lo escrito y dice por
/// qué.
class HojaContacto extends StatefulWidget {
  const HojaContacto({required this.guardar, this.contacto, super.key});

  final ContactoCliente? contacto;
  final Future<ResultadoContacto> Function(DatosContacto datos) guardar;

  /// Abre la hoja; devuelve `true` si el contacto se guardó.
  static Future<bool?> abrir(
    BuildContext context, {
    required Future<ResultadoContacto> Function(DatosContacto datos) guardar,
    ContactoCliente? contacto,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => HojaContacto(guardar: guardar, contacto: contacto),
  );

  @override
  State<HojaContacto> createState() => _HojaContactoState();
}

class _HojaContactoState extends State<HojaContacto> {
  late final _nombre = TextEditingController(text: widget.contacto?.nombre);
  late final _celular = TextEditingController(text: widget.contacto?.telefono);
  late final _cargo = TextEditingController(text: widget.contacto?.cargo);
  late bool _principal = widget.contacto?.esPrincipal ?? false;
  bool _enviando = false;
  bool _intento = false;
  String? _fallo;

  @override
  void dispose() {
    _nombre.dispose();
    _celular.dispose();
    _cargo.dispose();
    super.dispose();
  }

  bool get _nombreValido => _nombre.text.trim().isNotEmpty;
  bool get _celularValido =>
      _celular.text.replaceAll(RegExp(r'\D'), '').length >= 7;

  Future<void> _guardar() async {
    setState(() => _intento = true);
    if (!_nombreValido || !_celularValido) return;
    final t = AppLocalizations.of(context);
    setState(() {
      _enviando = true;
      _fallo = null;
    });
    final r = await widget.guardar(
      DatosContacto(
        nombre: _nombre.text,
        telefono: _celular.text,
        cargo: _cargo.text,
        esPrincipal: _principal,
      ),
    );
    if (!mounted) return;
    switch (r) {
      case ContactoGuardado():
        Navigator.of(context).pop(true);
      case ContactoFallo(:final sinConexion, :final mensaje):
        setState(() {
          _enviando = false;
          _fallo = sinConexion
              ? t.contactosSinConexion
              : (mensaje ?? t.contactosErrorGuardar);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        EspaciadoCampo.l,
        0,
        EspaciadoCampo.l,
        MediaQuery.viewInsetsOf(context).bottom + EspaciadoCampo.l,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                widget.contacto == null ? t.contactosNuevo : t.contactosEditar,
                style: texto.titleLarge,
              ),
            ),
            const SizedBox(height: EspaciadoCampo.l),
            TextField(
              key: const ValueKey('contacto-nombre'),
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: t.contactosNombre,
                errorText: _intento && !_nombreValido
                    ? t.contactosErrorNombre
                    : null,
              ),
            ),
            const SizedBox(height: EspaciadoCampo.m),
            TextField(
              key: const ValueKey('contacto-celular'),
              controller: _celular,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: t.contactosCelular,
                errorText: _intento && !_celularValido
                    ? t.contactosErrorCelular
                    : null,
              ),
            ),
            const SizedBox(height: EspaciadoCampo.m),
            TextField(
              key: const ValueKey('contacto-cargo'),
              controller: _cargo,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: t.contactosCargo),
            ),
            const SizedBox(height: EspaciadoCampo.s),
            SwitchListTile(
              key: const ValueKey('contacto-principal'),
              contentPadding: EdgeInsets.zero,
              value: _principal,
              // El principal actual no se desmarca: se marca a otro.
              onChanged: widget.contacto?.esPrincipal ?? false
                  ? null
                  : (v) => setState(() => _principal = v),
              title: Text(t.contactosHacerPrincipal),
              subtitle: Text(t.contactosHacerPrincipalAyuda),
            ),
            if (_fallo != null) ...[
              const SizedBox(height: EspaciadoCampo.s),
              Semantics(
                liveRegion: true,
                child: Text(
                  _fallo!,
                  key: const ValueKey('contacto-fallo'),
                  style: texto.bodyMedium?.copyWith(color: paleta.error),
                ),
              ),
            ],
            const SizedBox(height: EspaciadoCampo.l),
            BotonPrincipalMarketplace(
              key: const ValueKey('contacto-guardar'),
              texto: t.contactosGuardar,
              cargando: _enviando,
              onPressed: _guardar,
            ),
            TextButton(
              onPressed: _enviando ? null : () => Navigator.of(context).pop(),
              child: Text(t.contactosCancelar),
            ),
          ],
        ),
      ),
    );
  }
}
