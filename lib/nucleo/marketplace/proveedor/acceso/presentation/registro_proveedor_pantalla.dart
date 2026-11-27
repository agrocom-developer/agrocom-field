import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../auth/cuenta/domain/cuenta_seguridad.dart';
import '../../../../auth/cuenta/presentation/cuenta_ya_registrada_pantalla.dart';
import '../../../../auth/cuenta/presentation/recuperar_acceso_pantalla.dart';
import '../../../../auth/cuenta/presentation/verificar_telefono_hoja.dart';
import '../../../../camara/selector_imagen.dart';
import '../../../../permisos/presentation/hoja_permiso.dart';
import '../../../../ui/componentes/encabezado_de_marca.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../ui/boton_principal_marketplace.dart';
import '../../../ui/campo_formulario_marketplace.dart';
import '../../../ui/marketplace_ui.dart';
import '../domain/acceso_proveedor.dart';
import 'acceso_cubit.dart';
import 'registro_cubit.dart';

/// Abre el alta del piloto independiente sobre el ingreso. Al terminar, la
/// sesión ya quedó iniciada y la puerta de acceso muestra la app.
Future<void> abrirRegistro(BuildContext context) {
  final acceso = context.read<AccesoCubit>();
  final repoAcceso = context.read<AccesoProveedorRepositorio>();
  final drones = context.read<RegistroDronesRepositorio>();
  final selector = context.read<SelectorImagen>();
  final l10n = AppLocalizations.of(context);
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (_) => RegistroCubit(
          acceso: repoAcceso,
          drones: drones,
          selector: selector,
          l10n: l10n,
        ),
        child: RegistroProveedorPantalla(
          alTerminar: () {
            Navigator.of(context).popUntil((r) => r.isFirst);
            acceso.alRegistrarse();
          },
        ),
      ),
    ),
  );
}

/// El alta del piloto independiente en cuatro pasos: sus datos, su licencia,
/// su dron y las fotos del dron. Un administrador lo aprueba antes de que
/// pueda ver solicitudes.
class RegistroProveedorPantalla extends StatefulWidget {
  const RegistroProveedorPantalla({required this.alTerminar, super.key});

  final VoidCallback alTerminar;

  @override
  State<RegistroProveedorPantalla> createState() =>
      _RegistroProveedorPantallaState();
}

class _RegistroProveedorPantallaState extends State<RegistroProveedorPantalla> {
  AppLocalizations get l10n => AppLocalizations.of(context);

  List<String> _titulos(BuildContext context) => [
    l10n.proveedorAccesoDatosPersonales,
    l10n.proveedorAccesoLicencia,
    l10n.proveedorAccesoEquipo,
    l10n.proveedorAccesoFotosDelDron,
  ];
  List<String> _apoyos(BuildContext context) => [
    l10n.proveedorAccesoAsiIdentificamosContactanLos,
    l10n.proveedorAccesoAdministradorRevisaAntesQue,
    l10n.proveedorAccesoDronVehiculoRevisamosAntes,
    l10n.proveedorAccesoFrontalLateralPlacaSerie,
  ];
  final _claves = List.generate(3, (_) => GlobalKey<FormState>());
  int _paso = 0;

  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _documento = TextEditingController();
  final _nacimiento = TextEditingController();
  final _telefono = TextEditingController();
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  final _licencia = TextEditingController();
  final _licenciaVence = TextEditingController();
  final _categoria = TextEditingController();
  final _marca = TextEditingController();
  final _modelo = TextEditingController();
  final _serie = TextEditingController();
  final _anio = TextEditingController();
  final _capacidad = TextEditingController();
  final _pasada = TextEditingController();

  DateTime? _fechaNacimiento;
  DateTime? _fechaVence;

  @override
  void dispose() {
    for (final c in [
      _nombres,
      _apellidos,
      _documento,
      _nacimiento,
      _telefono,
      _usuario,
      _contrasena,
      _licencia,
      _licenciaVence,
      _categoria,
      _marca,
      _modelo,
      _serie,
      _anio,
      _capacidad,
      _pasada,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _obligatorio(String? v) => (v ?? '').trim().isEmpty
      ? AppLocalizations.of(context).proveedorAccesoDatoObligatorio
      : null;

  String? _decimal(String? v) {
    final d = Decimal.tryParse((v ?? '').trim().replaceAll(',', '.'));
    return d == null || d <= Decimal.zero
        ? AppLocalizations.of(context).proveedorAccesoNumeroMayorCero
        : null;
  }

  Future<DateTime?> _elegirFecha({
    required DateTime inicial,
    required DateTime primera,
    required DateTime ultima,
  }) => showDatePicker(
    context: context,
    initialDate: inicial,
    firstDate: primera,
    lastDate: ultima,
    helpText: AppLocalizations.of(context).proveedorAccesoEligeFecha,
  );

  String _texto(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/'
      '${f.month.toString().padLeft(2, '0')}/${f.year}';

  void _siguiente() {
    if (_paso < 3 && !(_claves[_paso].currentState?.validate() ?? false)) {
      return;
    }
    if (_paso == 0 && _fechaNacimiento == null) {
      setState(() {});
      return;
    }
    if (_paso == 1 && _fechaVence == null) {
      setState(() {});
      return;
    }
    if (_paso < 3) {
      setState(() => _paso++);
    } else {
      _enviar();
    }
  }

  void _enviar() {
    final persona = DatosPersona(
      nombres: _nombres.text,
      apellidos: _apellidos.text,
      documentoIdentidad: _documento.text,
      fechaNacimiento: _fechaNacimiento!,
      telefono: _telefono.text,
      usuario: _usuario.text,
      contrasena: _contrasena.text,
      licenciaNumero: _licencia.text,
      licenciaVence: _fechaVence!,
      categoriaHabilitacion: _categoria.text,
    );
    final dron = DatosDron(
      marca: _marca.text,
      modelo: _modelo.text,
      numeroSerie: _serie.text,
      anio: int.tryParse(_anio.text.trim()),
      capacidadTanqueL: Decimal.parse(
        _capacidad.text.trim().replaceAll(',', '.'),
      ),
      anchoPasadaM: Decimal.parse(_pasada.text.trim().replaceAll(',', '.')),
    );
    context.read<RegistroCubit>().enviar(persona, dron);
  }

  Widget _campo(
    String etiqueta,
    TextEditingController c, {
    FormFieldValidator<String>? validator,
    TextInputType? teclado,
    bool oculto = false,
    String? errorServidor,
    TextCapitalization mayusculas = TextCapitalization.words,
    String? ayuda,
    List<TextInputFormatter>? formatos,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: EspaciadoCampo.m),
    child: CampoFormularioMarketplace(
      etiqueta: etiqueta,
      controller: c,
      validator: validator ?? _obligatorio,
      keyboardType: teclado,
      obscureText: oculto,
      errorServidor: errorServidor,
      textCapitalization: mayusculas,
      ayuda: ayuda,
      inputFormatters: formatos,
      textInputAction: TextInputAction.next,
    ),
  );

  Widget _fecha(
    String etiqueta,
    TextEditingController c,
    DateTime? valor,
    Future<void> Function() elegir,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: EspaciadoCampo.m),
    child: Semantics(
      button: true,
      label: '$etiqueta, ${valor == null ? 'sin elegir' : _texto(valor)}',
      child: InkWell(
        onTap: elegir,
        borderRadius: BorderRadius.circular(RadioCampo.media),
        child: IgnorePointer(
          child: CampoFormularioMarketplace(
            etiqueta: etiqueta,
            controller: c,
            validator: (_) =>
                valor == null ? l10n.proveedorAccesoEligeUnaFecha : null,
          ),
        ),
      ),
    ),
  );

  /// El primer paso con un campo que el servidor rechazó.
  int _pasoDeErrores(Map<String, String> errores) {
    const persona = {
      'nombres',
      'apellidos',
      'documento_identidad',
      'fecha_nacimiento',
      'telefono',
      'username',
      'password',
      'nombre',
    };
    const licencia = {
      'licencia_numero',
      'licencia_vence',
      'categoria_habilitacion',
    };
    if (errores.keys.any(persona.contains)) return 0;
    if (errores.keys.any(licencia.contains)) return 1;
    return 2;
  }

  Widget _pasoPersona(Map<String, String> errores) => Form(
    key: _claves[0],
    child: Column(
      children: [
        _campo('Nombres', _nombres),
        _campo('Apellidos', _apellidos),
        _campo(
          l10n.proveedorAccesoCarnetIdentidad,
          _documento,
          teclado: TextInputType.text,
          errorServidor: errores['documento_identidad'],
          mayusculas: TextCapitalization.characters,
        ),
        _fecha(
          l10n.proveedorAccesoFechaNacimiento,
          _nacimiento,
          _fechaNacimiento,
          () async {
            final f = await _elegirFecha(
              inicial: DateTime(1990),
              primera: DateTime(1940),
              ultima: DateTime.now().subtract(const Duration(days: 365 * 18)),
            );
            if (f != null) {
              setState(() {
                _fechaNacimiento = f;
                _nacimiento.text = _texto(f);
              });
            }
          },
        ),
        _campo(
          l10n.proveedorAccesoTelefono,
          _telefono,
          teclado: TextInputType.phone,
          errorServidor: errores['telefono'],
        ),
        _campo(
          l10n.proveedorAccesoUsuario,
          _usuario,
          errorServidor: errores['username'],
          mayusculas: TextCapitalization.none,
          ayuda: l10n.proveedorAccesoConEsteUsuarioEntras,
        ),
        _campo(
          l10n.proveedorAccesoContrasena,
          _contrasena,
          oculto: true,
          errorServidor: errores['password'],
          mayusculas: TextCapitalization.none,
          ayuda: l10n.cuentaContrasenaMinimo(ReglasContrasena.largoMinimo),
          validator: ReglasContrasena.validarNueva,
        ),
      ],
    ),
  );

  Widget _pasoLicencia(Map<String, String> errores) => Form(
    key: _claves[1],
    child: Column(
      children: [
        _campo(
          l10n.proveedorAccesoNumeroLicenciaPiloto,
          _licencia,
          errorServidor: errores['licencia_numero'],
          mayusculas: TextCapitalization.characters,
        ),
        _fecha(
          l10n.proveedorAccesoVence,
          _licenciaVence,
          _fechaVence,
          () async {
            final f = await _elegirFecha(
              inicial: DateTime.now().add(const Duration(days: 365)),
              primera: DateTime.now(),
              ultima: DateTime.now().add(const Duration(days: 365 * 10)),
            );
            if (f != null) {
              setState(() {
                _fechaVence = f;
                _licenciaVence.text = _texto(f);
              });
            }
          },
        ),
        _campo(
          l10n.proveedorAccesoCategoriaHabilitacion,
          _categoria,
          errorServidor: errores['categoria_habilitacion'],
          ayuda: l10n.proveedorAccesoComoFiguraLicencia,
          mayusculas: TextCapitalization.characters,
        ),
      ],
    ),
  );

  Widget _pasoDron(Map<String, String> errores) => Form(
    key: _claves[2],
    child: Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: EspaciadoCampo.m),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ChipEstadoMarketplace(
              etiqueta: l10n.proveedorAccesoRevisionTerminarRegistro,
              tono: TonoEstado.info,
              icono: Icons.hourglass_top_rounded,
            ),
          ),
        ),
        _campo('Marca', _marca),
        _campo('Modelo', _modelo),
        _campo(
          l10n.proveedorAccesoNumeroSerie,
          _serie,
          errorServidor: errores['numero_serie'],
          mayusculas: TextCapitalization.characters,
        ),
        _campo(
          l10n.proveedorAccesoAnoOpcional,
          _anio,
          teclado: TextInputType.number,
          validator: (_) => null,
        ),
        _campo(
          l10n.proveedorAccesoCapacidadDelTanqueLitros,
          _capacidad,
          validator: _decimal,
          teclado: const TextInputType.numberWithOptions(decimal: true),
        ),
        _campo(
          l10n.proveedorAccesoAnchoPasadaMetros,
          _pasada,
          validator: _decimal,
          teclado: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    ),
  );

  /// `409 cuenta_ya_registrada`: explica que ya existe una cuenta y manda al
  /// ingreso (o a recuperar el acceso). Al iniciar sesión, la app continúa
  /// donde quedó el registro según `siguiente_paso`.
  void _avisarCuentaExistente(String? tipoCuenta) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (rutaContext) => CuentaYaRegistradaPantalla(
          app: AppCuenta.proveedor,
          tipoCuenta: tipoCuenta,
          alIniciarSesion: () =>
              Navigator.of(rutaContext).popUntil((r) => r.isFirst),
          alRecuperarAcceso: () async {
            await abrirRecuperarAcceso(rutaContext, app: AppCuenta.proveedor);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegistroCubit, RegistroEstado>(
      listenWhen: (a, b) => b.cuentaExistente && !a.cuentaExistente,
      listener: (context, e) => _avisarCuentaExistente(e.tipoCuentaExistente),
      child: _consumidor(context),
    );
  }

  Widget _consumidor(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return BlocConsumer<RegistroCubit, RegistroEstado>(
      // Un error por campo devuelve al paso donde está el campo.
      listenWhen: (a, b) =>
          b.erroresPorCampo.isNotEmpty &&
          a.erroresPorCampo != b.erroresPorCampo,
      listener: (context, e) =>
          setState(() => _paso = _pasoDeErrores(e.erroresPorCampo)),
      builder: (context, estado) {
        final errores = estado.erroresPorCampo;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.proveedorAccesoRegistroPiloto),
            leading: estado.enviando
                ? const SizedBox.shrink()
                : _paso > 0 && !estado.terminado
                ? IconButton(
                    tooltip: l10n.proveedorAccesoPasoAnterior,
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => setState(() => _paso--),
                  )
                : null,
          ),
          body: estado.terminado
              ? _Listo(alTerminar: widget.alTerminar)
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(EspaciadoCampo.l),
                    children: [
                      const EncabezadoDeMarca(
                        rol: RolApp.piloto,
                        compacto: true,
                      ),
                      const SizedBox(height: EspaciadoCampo.l),
                      _Encabezado(
                        paso: _paso,
                        total: _titulos(context).length,
                        titulo: _titulos(context)[_paso],
                        apoyo: _apoyos(context)[_paso],
                      ),
                      const SizedBox(height: EspaciadoCampo.l),
                      if (estado.mensaje != null) ...[
                        AvisoMarketplace(
                          mensaje: estado.mensaje!,
                          tono: TonoAviso.error,
                        ),
                        const SizedBox(height: EspaciadoCampo.l),
                      ],
                      switch (_paso) {
                        0 => _pasoPersona(errores),
                        1 => _pasoLicencia(errores),
                        2 => _pasoDron(errores),
                        _ => _PasoFotos(estado: estado),
                      },
                      const SizedBox(height: EspaciadoCampo.l),
                      BotonPrincipalMarketplace(
                        texto: _paso < 3
                            ? l10n.proveedorAccesoContinuar
                            : estado.paso == PasoRegistro.cuenta
                            ? l10n.proveedorAccesoCrearCuenta
                            : l10n.proveedorAccesoReintentar,
                        cargando: estado.enviando,
                        onPressed: _paso == 3 && !estado.fotosObligatoriasListas
                            ? null
                            : _siguiente,
                      ),
                      if (_paso == 3 && !estado.fotosObligatoriasListas) ...[
                        const SizedBox(height: EspaciadoCampo.s),
                        Text(
                          l10n.proveedorAccesoFaltanLasFotosObligatorias,
                          style: texto.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}

/// Cabecera de cada paso: «PASO 1 DE 4» en mono, título, una línea de apoyo y
/// una barra de segmentos (hechos en acento). El texto del paso se anuncia al
/// cambiar.
class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.paso,
    required this.total,
    required this.titulo,
    required this.apoyo,
  });

  final int paso;
  final int total;
  final String titulo;
  final String apoyo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          liveRegion: true,
          label: l10n.proveedorAccesoPaso(paso + 1, total, titulo),
          excludeSemantics: true,
          child: Text(
            l10n.proveedorAccesoPaso2(paso + 1, total),
            style: texto.labelSmall?.copyWith(color: paleta.acentoTexto),
          ),
        ),
        const SizedBox(height: EspaciadoCampo.xs),
        Text(titulo, style: texto.headlineMedium),
        const SizedBox(height: EspaciadoCampo.xs),
        Text(
          apoyo,
          style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
        ),
        const SizedBox(height: EspaciadoCampo.m),
        ExcludeSemantics(
          child: Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: EspaciadoCampo.xs),
                Expanded(
                  child: AnimatedContainer(
                    duration: MovimientoCampo.duracion(
                      context,
                      MovimientoCampo.rapida,
                    ),
                    height: EspaciadoCampo.s,
                    decoration: BoxDecoration(
                      color: i <= paso ? paleta.acento : paleta.superficie2,
                      borderRadius: BorderRadius.circular(RadioCampo.capsula),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PasoFotos extends StatelessWidget {
  const _PasoFotos({required this.estado});

  final RegistroEstado estado;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final cubit = context.read<RegistroCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.proveedorAccesoAdministradorLasRevisaAntes,
          style: texto.bodyLarge,
        ),
        const SizedBox(height: EspaciadoCampo.l),
        if (estado.fotoError != null) ...[
          AvisoMarketplace(mensaje: estado.fotoError!, tono: TonoAviso.error),
          const SizedBox(height: EspaciadoCampo.m),
        ],
        for (final tipo in TipoFotoDron.values.where((t) => t.obligatoria)) ...[
          _TarjetaFoto(
            tipo: tipo,
            bytes: estado.fotos[tipo],
            cargando: estado.fotoCargando == tipo,
            alCamara: () async {
              if (await permitirCamaraConExplicacion(context)) {
                await cubit.elegirFoto(tipo, deGaleria: false);
              }
            },
            alGaleria: () => cubit.elegirFoto(tipo, deGaleria: true),
            alQuitar: () => cubit.quitarFoto(tipo),
          ),
          const SizedBox(height: EspaciadoCampo.m),
        ],
      ],
    );
  }
}

class _TarjetaFoto extends StatelessWidget {
  const _TarjetaFoto({
    required this.tipo,
    required this.bytes,
    required this.cargando,
    required this.alCamara,
    required this.alGaleria,
    required this.alQuitar,
  });

  final TipoFotoDron tipo;
  final Uint8List? bytes;
  final bool cargando;
  final VoidCallback alCamara;
  final VoidCallback alGaleria;
  final VoidCallback alQuitar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final lista = bytes != null;
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.proveedorAccesoFoto(tipo.etiqueta.toLowerCase()),
                  style: texto.titleMedium,
                ),
              ),
              if (lista)
                ChipEstadoMarketplace(
                  etiqueta: l10n.proveedorAccesoLista,
                  tono: TonoEstado.exito,
                  icono: Icons.check_circle_rounded,
                )
              else
                ChipEstadoMarketplace(
                  etiqueta: l10n.proveedorAccesoFalta,
                  tono: TonoEstado.alerta,
                  icono: Icons.add_a_photo_outlined,
                ),
            ],
          ),
          if (lista) ...[
            const SizedBox(height: EspaciadoCampo.s),
            ClipRRect(
              borderRadius: BorderRadius.circular(RadioCampo.chip),
              child: Image.memory(
                bytes!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                semanticLabel: l10n.proveedorAccesoFotoDelDron(
                  tipo.etiqueta.toLowerCase(),
                ),
              ),
            ),
          ],
          const SizedBox(height: EspaciadoCampo.s),
          Wrap(
            spacing: EspaciadoCampo.s,
            children: [
              OutlinedButton.icon(
                onPressed: cargando ? null : alCamara,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(
                  lista
                      ? l10n.proveedorAccesoTomarOtra
                      : l10n.proveedorAccesoCamara,
                ),
              ),
              OutlinedButton.icon(
                onPressed: cargando ? null : alGaleria,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.proveedorAccesoGaleria),
              ),
              if (lista)
                TextButton(
                  onPressed: alQuitar,
                  child: Text(l10n.proveedorAccesoQuitar),
                ),
            ],
          ),
          if (cargando)
            const Padding(
              padding: EdgeInsets.only(top: EspaciadoCampo.s),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _Listo extends StatelessWidget {
  const _Listo({required this.alTerminar});

  final VoidCallback alTerminar;

  /// La sesión ya está abierta tras el alta: se ofrece verificar el teléfono
  /// con un código (opcional; también está en Seguridad del perfil).
  static bool _puedeVerificarTelefono(BuildContext context) {
    try {
      context.read<CuentaSeguridadRepositorio>();
      return true;
    } on ProviderNotFoundException {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(EspaciadoCampo.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              size: 56,
              color: context.paleta.acentoTexto,
            ),
            const SizedBox(height: EspaciadoCampo.l),
            Text(
              l10n.proveedorAccesoRegistroEstaRevision,
              style: texto.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: EspaciadoCampo.s),
            Text(
              l10n.proveedorAccesoAdministradorRevisaLicenciaDron,
              style: texto.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: EspaciadoCampo.xl),
            BotonPrincipalMarketplace(
              texto: l10n.proveedorAccesoEntrarApp,
              onPressed: alTerminar,
            ),
            if (_puedeVerificarTelefono(context)) ...[
              const SizedBox(height: EspaciadoCampo.s),
              TextButton.icon(
                key: const Key('registro-verificar-telefono'),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    ObjetivoTactilCampo.guantes,
                  ),
                ),
                onPressed: () => mostrarVerificarTelefono(context),
                icon: const Icon(Icons.phone_android_rounded),
                label: Text(l10n.cuentaVerificarMiTelefono),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
