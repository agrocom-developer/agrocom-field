import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// Título de la pantalla para reportar un problema con un servicio.
  ///
  /// In es, this message translates to:
  /// **'Reportar un problema'**
  String get problemaTitulo;

  /// No description provided for @problemaPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Qué pasó?'**
  String get problemaPregunta;

  /// No description provided for @problemaMotivoSemantica.
  ///
  /// In es, this message translates to:
  /// **'Motivo del problema'**
  String get problemaMotivoSemantica;

  /// No description provided for @problemaDetalleEtiqueta.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos qué viste'**
  String get problemaDetalleEtiqueta;

  /// No description provided for @problemaDetalleAyuda.
  ///
  /// In es, this message translates to:
  /// **'Al menos una oración: dónde, cuándo y qué.'**
  String get problemaDetalleAyuda;

  /// No description provided for @problemaSinConexion.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. El reporte no se envió; vuelve a intentarlo cuando tengas señal.'**
  String get problemaSinConexion;

  /// No description provided for @problemaErrorEnvio.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enviar el reporte. Vuelve a intentarlo.'**
  String get problemaErrorEnvio;

  /// No description provided for @problemaAvisoSoporte.
  ///
  /// In es, this message translates to:
  /// **'Soporte te responde en 24 horas hábiles. El proveedor también ve el reporte y puede responder.'**
  String get problemaAvisoSoporte;

  /// No description provided for @problemaBotonEnviar.
  ///
  /// In es, this message translates to:
  /// **'Enviar reporte'**
  String get problemaBotonEnviar;

  /// No description provided for @problemaBotonReintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get problemaBotonReintentar;

  /// No description provided for @problemaBotonVolver.
  ///
  /// In es, this message translates to:
  /// **'Volver al servicio'**
  String get problemaBotonVolver;

  /// No description provided for @problemaEnviadoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Recibimos tu reporte'**
  String get problemaEnviadoTitulo;

  /// No description provided for @problemaEnviadoCaso.
  ///
  /// In es, this message translates to:
  /// **'Caso {numero} · {motivo}'**
  String problemaEnviadoCaso(String numero, String motivo);

  /// No description provided for @problemaEnviadoMensaje.
  ///
  /// In es, this message translates to:
  /// **'Soporte te responde en 24 horas hábiles. Mientras tanto, el servicio queda en revisión.'**
  String get problemaEnviadoMensaje;

  /// No description provided for @problemaMotivoCoberturaIncompleta.
  ///
  /// In es, this message translates to:
  /// **'Cobertura incompleta'**
  String get problemaMotivoCoberturaIncompleta;

  /// No description provided for @problemaMotivoCoberturaIncompletaAyuda.
  ///
  /// In es, this message translates to:
  /// **'Quedaron partes del lote sin aplicar.'**
  String get problemaMotivoCoberturaIncompletaAyuda;

  /// No description provided for @problemaMotivoMalaAplicacion.
  ///
  /// In es, this message translates to:
  /// **'Mala aplicación'**
  String get problemaMotivoMalaAplicacion;

  /// No description provided for @problemaMotivoMalaAplicacionAyuda.
  ///
  /// In es, this message translates to:
  /// **'Franjas sin cubrir o con doble pasada.'**
  String get problemaMotivoMalaAplicacionAyuda;

  /// No description provided for @problemaMotivoDanoCultivos.
  ///
  /// In es, this message translates to:
  /// **'Daño a cultivos o a terceros'**
  String get problemaMotivoDanoCultivos;

  /// No description provided for @problemaMotivoDanoCultivosAyuda.
  ///
  /// In es, this message translates to:
  /// **'La aplicación afectó tu cultivo o un lote vecino.'**
  String get problemaMotivoDanoCultivosAyuda;

  /// No description provided for @problemaMotivoProductoDistinto.
  ///
  /// In es, this message translates to:
  /// **'Producto distinto al pactado'**
  String get problemaMotivoProductoDistinto;

  /// No description provided for @problemaMotivoProductoDistintoAyuda.
  ///
  /// In es, this message translates to:
  /// **'Se aplicó otro producto u otra dosis.'**
  String get problemaMotivoProductoDistintoAyuda;

  /// No description provided for @problemaMotivoEquipoAusente.
  ///
  /// In es, this message translates to:
  /// **'El equipo no se presentó'**
  String get problemaMotivoEquipoAusente;

  /// No description provided for @problemaMotivoEquipoAusenteAyuda.
  ///
  /// In es, this message translates to:
  /// **'Nadie llegó en la fecha pactada.'**
  String get problemaMotivoEquipoAusenteAyuda;

  /// No description provided for @problemaMotivoEvidenciaFaltante.
  ///
  /// In es, this message translates to:
  /// **'Faltan evidencias'**
  String get problemaMotivoEvidenciaFaltante;

  /// No description provided for @problemaMotivoEvidenciaFaltanteAyuda.
  ///
  /// In es, this message translates to:
  /// **'No están las fotos o el registro del vuelo.'**
  String get problemaMotivoEvidenciaFaltanteAyuda;

  /// No description provided for @problemaMotivoCobroIndebido.
  ///
  /// In es, this message translates to:
  /// **'Cobro indebido'**
  String get problemaMotivoCobroIndebido;

  /// No description provided for @problemaMotivoCobroIndebidoAyuda.
  ///
  /// In es, this message translates to:
  /// **'El monto no coincide con lo estimado.'**
  String get problemaMotivoCobroIndebidoAyuda;

  /// No description provided for @problemaMotivoTratoInadecuado.
  ///
  /// In es, this message translates to:
  /// **'Trato inadecuado'**
  String get problemaMotivoTratoInadecuado;

  /// No description provided for @problemaMotivoTratoInadecuadoAyuda.
  ///
  /// In es, this message translates to:
  /// **'Hubo una falta de respeto o de cuidado.'**
  String get problemaMotivoTratoInadecuadoAyuda;

  /// No description provided for @navInicio.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navInicio;

  /// No description provided for @navLotes.
  ///
  /// In es, this message translates to:
  /// **'Lotes'**
  String get navLotes;

  /// No description provided for @navServicios.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get navServicios;

  /// No description provided for @navPerfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navPerfil;

  /// No description provided for @navMapa.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get navMapa;

  /// No description provided for @navOfertas.
  ///
  /// In es, this message translates to:
  /// **'Ofertas'**
  String get navOfertas;

  /// Selector del tema visual en el perfil.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get temaTitulo;

  /// No description provided for @temaClaro.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get temaClaro;

  /// No description provided for @temaOscuro.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get temaOscuro;

  /// No description provided for @temaCampo.
  ///
  /// In es, this message translates to:
  /// **'Campo AAA'**
  String get temaCampo;

  /// No description provided for @publicarLote.
  ///
  /// In es, this message translates to:
  /// **'Publicar lote'**
  String get publicarLote;

  /// No description provided for @publicarLoteCerrar.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get publicarLoteCerrar;

  /// No description provided for @solicitudPublicada.
  ///
  /// In es, this message translates to:
  /// **'Publicamos tu solicitud. Te avisamos cuando lleguen ofertas.'**
  String get solicitudPublicada;

  /// No description provided for @perfilClienteRol.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get perfilClienteRol;

  /// No description provided for @perfilClienteEstadLotes.
  ///
  /// In es, this message translates to:
  /// **'lotes'**
  String get perfilClienteEstadLotes;

  /// No description provided for @perfilClienteEstadServicios.
  ///
  /// In es, this message translates to:
  /// **'servicios'**
  String get perfilClienteEstadServicios;

  /// No description provided for @perfilClienteEstadCalificacion.
  ///
  /// In es, this message translates to:
  /// **'como cliente'**
  String get perfilClienteEstadCalificacion;

  /// No description provided for @perfilMisCampos.
  ///
  /// In es, this message translates to:
  /// **'Mis lotes'**
  String get perfilMisCampos;

  /// No description provided for @perfilAgregarCampo.
  ///
  /// In es, this message translates to:
  /// **'+ Agregar'**
  String get perfilAgregarCampo;

  /// No description provided for @perfilMisCamposVacio.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes lotes. Se guardan al publicar tu primera solicitud.'**
  String get perfilMisCamposVacio;

  /// No description provided for @perfilHectareasUnidad.
  ///
  /// In es, this message translates to:
  /// **'{hectareas} ha'**
  String perfilHectareasUnidad(String hectareas);

  /// No description provided for @perfilLoDicen.
  ///
  /// In es, this message translates to:
  /// **'Lo que dicen de ti'**
  String get perfilLoDicen;

  /// No description provided for @perfilCerrarSesion.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get perfilCerrarSesion;

  /// No description provided for @perfilErrorCargaTitulo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu perfil'**
  String get perfilErrorCargaTitulo;

  /// No description provided for @perfilErrorCargaDetalle.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión y vuelve a intentarlo.'**
  String get perfilErrorCargaDetalle;

  /// No description provided for @lotesTitulo.
  ///
  /// In es, this message translates to:
  /// **'Lotes'**
  String get lotesTitulo;

  /// No description provided for @lotesVacioTitulo.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes lotes'**
  String get lotesVacioTitulo;

  /// No description provided for @lotesVacioDetalle.
  ///
  /// In es, this message translates to:
  /// **'Marca tu primer lote en el mapa al publicar una solicitud. Queda guardado para la próxima vez.'**
  String get lotesVacioDetalle;

  /// No description provided for @lotesLoteDetalle.
  ///
  /// In es, this message translates to:
  /// **'{zona} · {cultivo}'**
  String lotesLoteDetalle(String zona, String cultivo);

  /// No description provided for @perfilProveedorRolPiloto.
  ///
  /// In es, this message translates to:
  /// **'Piloto'**
  String get perfilProveedorRolPiloto;

  /// No description provided for @perfilProveedorAjustes.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get perfilProveedorAjustes;

  /// No description provided for @perfilProveedorSinCalificaciones.
  ///
  /// In es, this message translates to:
  /// **'Todavía sin calificaciones'**
  String get perfilProveedorSinCalificaciones;

  /// No description provided for @perfilProveedorServicios.
  ///
  /// In es, this message translates to:
  /// **'{n} servicios'**
  String perfilProveedorServicios(int n);

  /// No description provided for @perfilProveedorDocumentoAtencion.
  ///
  /// In es, this message translates to:
  /// **'«{nombre}» necesita tu atención. Un documento vencido suspende las ofertas.'**
  String perfilProveedorDocumentoAtencion(String nombre);

  /// No description provided for @perfilProveedorDocumentosAtencion.
  ///
  /// In es, this message translates to:
  /// **'{n} documentos necesitan tu atención. Un documento vencido suspende las ofertas.'**
  String perfilProveedorDocumentosAtencion(int n);

  /// No description provided for @perfilProveedorMetricas.
  ///
  /// In es, this message translates to:
  /// **'Métricas'**
  String get perfilProveedorMetricas;

  /// No description provided for @perfilProveedorDronLicencia.
  ///
  /// In es, this message translates to:
  /// **'Dron y licencia'**
  String get perfilProveedorDronLicencia;

  /// No description provided for @perfilProveedorDronesUno.
  ///
  /// In es, this message translates to:
  /// **'1 dron'**
  String get perfilProveedorDronesUno;

  /// No description provided for @perfilProveedorDronesVarios.
  ///
  /// In es, this message translates to:
  /// **'{n} drones'**
  String perfilProveedorDronesVarios(int n);

  /// No description provided for @perfilProveedorHectareasMes.
  ///
  /// In es, this message translates to:
  /// **'Hectáreas por mes'**
  String get perfilProveedorHectareasMes;

  /// No description provided for @perfilProveedorHectareasMesVacio.
  ///
  /// In es, this message translates to:
  /// **'Las hectáreas de cada mes aparecen aquí después de tu primer servicio.'**
  String get perfilProveedorHectareasMesVacio;

  /// No description provided for @perfilProveedorDocumentos.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get perfilProveedorDocumentos;

  /// No description provided for @perfilProveedorDocumentosVacio.
  ///
  /// In es, this message translates to:
  /// **'Todavía no subiste documentos. Sin ellos no se puede aprobar tu perfil.'**
  String get perfilProveedorDocumentosVacio;

  /// No description provided for @perfilProveedorZonas.
  ///
  /// In es, this message translates to:
  /// **'Zonas de cobertura'**
  String get perfilProveedorZonas;

  /// No description provided for @perfilProveedorZonaSemantica.
  ///
  /// In es, this message translates to:
  /// **'Zona: {zona}'**
  String perfilProveedorZonaSemantica(String zona);

  /// No description provided for @perfilProveedorCalificaciones.
  ///
  /// In es, this message translates to:
  /// **'Calificaciones recibidas'**
  String get perfilProveedorCalificaciones;

  /// No description provided for @perfilProveedorResenasVacio.
  ///
  /// In es, this message translates to:
  /// **'Las calificaciones de tus clientes aparecen aquí después de cada servicio.'**
  String get perfilProveedorResenasVacio;

  /// No description provided for @perfilProveedorErrorTitulo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu perfil'**
  String get perfilProveedorErrorTitulo;

  /// No description provided for @perfilProveedorErrorDetalle.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión y vuelve a intentarlo.'**
  String get perfilProveedorErrorDetalle;

  /// No description provided for @perfilProveedorAvisos.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get perfilProveedorAvisos;

  /// No description provided for @perfilProveedorAvisosDetalle.
  ///
  /// In es, this message translates to:
  /// **'Nuevas solicitudes en tus zonas, mensajes y ofertas'**
  String get perfilProveedorAvisosDetalle;

  /// No description provided for @perfilProveedorCerrarSesionDetalle.
  ///
  /// In es, this message translates to:
  /// **'Lo que aún no se subió se conserva en este teléfono'**
  String get perfilProveedorCerrarSesionDetalle;

  /// No description provided for @perfilPublicoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Perfil del piloto'**
  String get perfilPublicoTitulo;

  /// No description provided for @perfilPublicoOfertaPara.
  ///
  /// In es, this message translates to:
  /// **'Oferta para {lote}'**
  String perfilPublicoOfertaPara(String lote);

  /// No description provided for @perfilPublicoEstadCalificacion.
  ///
  /// In es, this message translates to:
  /// **'calificación'**
  String get perfilPublicoEstadCalificacion;

  /// No description provided for @perfilPublicoEstadResenas.
  ///
  /// In es, this message translates to:
  /// **'calificaciones'**
  String get perfilPublicoEstadResenas;

  /// No description provided for @perfilPublicoEstadCumplimiento.
  ///
  /// In es, this message translates to:
  /// **'cancelaciones'**
  String get perfilPublicoEstadCumplimiento;

  /// No description provided for @perfilPublicoEquipo.
  ///
  /// In es, this message translates to:
  /// **'EQUIPO'**
  String get perfilPublicoEquipo;

  /// No description provided for @perfilPublicoDron.
  ///
  /// In es, this message translates to:
  /// **'{dron} · {litros} L'**
  String perfilPublicoDron(String dron, String litros);

  /// No description provided for @perfilPublicoDronAnio.
  ///
  /// In es, this message translates to:
  /// **'Año {anio}'**
  String perfilPublicoDronAnio(int anio);

  /// No description provided for @perfilPublicoSinDron.
  ///
  /// In es, this message translates to:
  /// **'Este piloto aún no muestra su dron.'**
  String get perfilPublicoSinDron;

  /// No description provided for @perfilPublicoSuOferta.
  ///
  /// In es, this message translates to:
  /// **'Su oferta'**
  String get perfilPublicoSuOferta;

  /// No description provided for @perfilPublicoTotal.
  ///
  /// In es, this message translates to:
  /// **'total {monto}'**
  String perfilPublicoTotal(String monto);

  /// No description provided for @perfilPublicoElegir.
  ///
  /// In es, this message translates to:
  /// **'Elegir'**
  String get perfilPublicoElegir;

  /// No description provided for @perfilPublicoVerPerfil.
  ///
  /// In es, this message translates to:
  /// **'Ver perfil'**
  String get perfilPublicoVerPerfil;

  /// No description provided for @perfilPublicoFotoDe.
  ///
  /// In es, this message translates to:
  /// **'Foto de {nombre}'**
  String perfilPublicoFotoDe(String nombre);

  /// No description provided for @contactosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Contactos de referencia'**
  String get contactosTitulo;

  /// No description provided for @contactosIntro.
  ///
  /// In es, this message translates to:
  /// **'El piloto que elijas ve a la persona de contacto de cada solicitud, con su cargo, solo después de adjudicarla.'**
  String get contactosIntro;

  /// No description provided for @contactosPrincipal.
  ///
  /// In es, this message translates to:
  /// **'Principal'**
  String get contactosPrincipal;

  /// No description provided for @contactosAgregar.
  ///
  /// In es, this message translates to:
  /// **'Agregar contacto'**
  String get contactosAgregar;

  /// No description provided for @contactosEditar.
  ///
  /// In es, this message translates to:
  /// **'Editar contacto'**
  String get contactosEditar;

  /// No description provided for @contactosNuevo.
  ///
  /// In es, this message translates to:
  /// **'Nuevo contacto'**
  String get contactosNuevo;

  /// No description provided for @contactosNombre.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get contactosNombre;

  /// No description provided for @contactosCelular.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get contactosCelular;

  /// No description provided for @contactosCargo.
  ///
  /// In es, this message translates to:
  /// **'Cargo (opcional)'**
  String get contactosCargo;

  /// No description provided for @contactosHacerPrincipal.
  ///
  /// In es, this message translates to:
  /// **'Es el contacto principal'**
  String get contactosHacerPrincipal;

  /// No description provided for @contactosHacerPrincipalAyuda.
  ///
  /// In es, this message translates to:
  /// **'Se usa cuando una solicitud no elige a otra persona.'**
  String get contactosHacerPrincipalAyuda;

  /// No description provided for @contactosGuardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get contactosGuardar;

  /// No description provided for @contactosCancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get contactosCancelar;

  /// No description provided for @contactosQuitar.
  ///
  /// In es, this message translates to:
  /// **'Eliminar contacto'**
  String get contactosQuitar;

  /// No description provided for @contactosQuitarPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar a {nombre}?'**
  String contactosQuitarPregunta(String nombre);

  /// No description provided for @contactosQuitarAviso.
  ///
  /// In es, this message translates to:
  /// **'Las solicitudes que ya publicaste conservan a esta persona.'**
  String get contactosQuitarAviso;

  /// No description provided for @contactosUnicoAviso.
  ///
  /// In es, this message translates to:
  /// **'Una empresa necesita al menos un contacto: agrega otro antes de eliminar a este.'**
  String get contactosUnicoAviso;

  /// No description provided for @contactosErrorNombre.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre.'**
  String get contactosErrorNombre;

  /// No description provided for @contactosErrorCelular.
  ///
  /// In es, this message translates to:
  /// **'Escribe un teléfono de al menos 7 dígitos.'**
  String get contactosErrorCelular;

  /// No description provided for @contactosSinConexion.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. No se guardó nada; vuelve a intentarlo cuando tengas señal.'**
  String get contactosSinConexion;

  /// No description provided for @contactosErrorGuardar.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el contacto. Vuelve a intentarlo.'**
  String get contactosErrorGuardar;

  /// No description provided for @contactosFilaSemantica.
  ///
  /// In es, this message translates to:
  /// **'{nombre}, {cargo}, {celular}'**
  String contactosFilaSemantica(String nombre, String cargo, String celular);

  /// No description provided for @contactosPerfilFila.
  ///
  /// In es, this message translates to:
  /// **'Contactos de referencia'**
  String get contactosPerfilFila;

  /// No description provided for @contactosPerfilDetalle.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, one{1 persona} other{{n} personas}}'**
  String contactosPerfilDetalle(int n);

  /// No description provided for @contactosEmpresaPublicar.
  ///
  /// In es, this message translates to:
  /// **'Persona de contacto'**
  String get contactosEmpresaPublicar;

  /// No description provided for @contactosEmpresaPublicarAyuda.
  ///
  /// In es, this message translates to:
  /// **'El piloto elegido verá a quién llamar.'**
  String get contactosEmpresaPublicarAyuda;

  /// No description provided for @registroEmpresaInterruptor.
  ///
  /// In es, this message translates to:
  /// **'Asociar a una empresa'**
  String get registroEmpresaInterruptor;

  /// No description provided for @registroEmpresaAyuda.
  ///
  /// In es, this message translates to:
  /// **'Si publicas lotes a nombre de una empresa, agrégala. Tú quedas como su contacto principal.'**
  String get registroEmpresaAyuda;

  /// No description provided for @registroEmpresaRazon.
  ///
  /// In es, this message translates to:
  /// **'Razón social'**
  String get registroEmpresaRazon;

  /// No description provided for @registroEmpresaDocumento.
  ///
  /// In es, this message translates to:
  /// **'NIT'**
  String get registroEmpresaDocumento;

  /// No description provided for @registroEmpresaCargo.
  ///
  /// In es, this message translates to:
  /// **'Tu cargo en la empresa (opcional)'**
  String get registroEmpresaCargo;

  /// No description provided for @registroEmpresaContactoNota.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre y teléfono quedan como contacto principal. Después puedes agregar a otras personas desde tu perfil.'**
  String get registroEmpresaContactoNota;

  /// No description provided for @chatTitulo.
  ///
  /// In es, this message translates to:
  /// **'Chat con el piloto'**
  String get chatTitulo;

  /// No description provided for @chatHoy.
  ///
  /// In es, this message translates to:
  /// **'HOY'**
  String get chatHoy;

  /// No description provided for @chatCabecera.
  ///
  /// In es, this message translates to:
  /// **'{lote} · {estado}'**
  String chatCabecera(String lote, String estado);

  /// No description provided for @chatFotoDe.
  ///
  /// In es, this message translates to:
  /// **'Foto de {nombre}'**
  String chatFotoDe(String nombre);

  /// No description provided for @chatVacioTitulo.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay mensajes'**
  String get chatVacioTitulo;

  /// No description provided for @chatVacioDetalle.
  ///
  /// In es, this message translates to:
  /// **'Escríbele al piloto para coordinar el día de la visita y los accesos al lote.'**
  String get chatVacioDetalle;

  /// No description provided for @chatSinConexionAviso.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Los mensajes nuevos llegan cuando vuelva la señal.'**
  String get chatSinConexionAviso;

  /// No description provided for @chatCerradoAviso.
  ///
  /// In es, this message translates to:
  /// **'El chat se cerró. Puedes leer lo conversado, pero ya no escribir.'**
  String get chatCerradoAviso;

  /// No description provided for @chatEscribe.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje'**
  String get chatEscribe;

  /// No description provided for @chatEnviar.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get chatEnviar;

  /// No description provided for @chatEnviarSemantica.
  ///
  /// In es, this message translates to:
  /// **'Enviar mensaje'**
  String get chatEnviarSemantica;

  /// No description provided for @chatEnviando.
  ///
  /// In es, this message translates to:
  /// **'Enviando'**
  String get chatEnviando;

  /// No description provided for @chatAdjuntar.
  ///
  /// In es, this message translates to:
  /// **'Enviar una foto'**
  String get chatAdjuntar;

  /// No description provided for @chatFotoCamara.
  ///
  /// In es, this message translates to:
  /// **'Tomar una foto'**
  String get chatFotoCamara;

  /// No description provided for @chatFotoGaleria.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get chatFotoGaleria;

  /// No description provided for @chatFalloSinConexion.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Tu mensaje sigue aquí; envíalo cuando vuelva la señal.'**
  String get chatFalloSinConexion;

  /// No description provided for @chatFalloCerrado.
  ///
  /// In es, this message translates to:
  /// **'El chat se cerró y no se envió tu mensaje.'**
  String get chatFalloCerrado;

  /// No description provided for @chatFalloDesconocido.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enviarlo. Tu mensaje sigue aquí; vuelve a intentarlo.'**
  String get chatFalloDesconocido;

  /// No description provided for @chatFalloFoto.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enviar la foto. Vuelve a intentarlo.'**
  String get chatFalloFoto;

  /// No description provided for @chatAutorTu.
  ///
  /// In es, this message translates to:
  /// **'Tú'**
  String get chatAutorTu;

  /// No description provided for @chatAutorPiloto.
  ///
  /// In es, this message translates to:
  /// **'Piloto'**
  String get chatAutorPiloto;

  /// No description provided for @chatMensajeSemantica.
  ///
  /// In es, this message translates to:
  /// **'{autor}, {hora}: {texto}'**
  String chatMensajeSemantica(String autor, String hora, String texto);

  /// No description provided for @chatFotoSemantica.
  ///
  /// In es, this message translates to:
  /// **'{autor}, {hora}: foto. {pie}'**
  String chatFotoSemantica(String autor, String hora, String pie);

  /// No description provided for @precioFinalConfirmar.
  ///
  /// In es, this message translates to:
  /// **'Confirmar precio final'**
  String get precioFinalConfirmar;

  /// No description provided for @precioFinalPorConfirmar.
  ///
  /// In es, this message translates to:
  /// **'POR CONFIRMAR'**
  String get precioFinalPorConfirmar;

  /// No description provided for @precioFinalConfirmado.
  ///
  /// In es, this message translates to:
  /// **'CONFIRMADO'**
  String get precioFinalConfirmado;

  /// No description provided for @precioFinalConfirmadoAviso.
  ///
  /// In es, this message translates to:
  /// **'Confirmaste el precio final. El pago sigue siendo directo al piloto.'**
  String get precioFinalConfirmadoAviso;

  /// No description provided for @precioFinalFalloSinConexion.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. No se confirmó nada; vuelve a intentarlo cuando tengas señal.'**
  String get precioFinalFalloSinConexion;

  /// No description provided for @precioFinalFalloRechazado.
  ///
  /// In es, this message translates to:
  /// **'El servicio todavía no terminó, así que no se puede confirmar el precio.'**
  String get precioFinalFalloRechazado;

  /// No description provided for @precioFinalFalloDesconocido.
  ///
  /// In es, this message translates to:
  /// **'No pudimos confirmar el precio final. Vuelve a intentarlo.'**
  String get precioFinalFalloDesconocido;

  /// No description provided for @precioFinalAbrirDisputa.
  ///
  /// In es, this message translates to:
  /// **'Abrir un reclamo'**
  String get precioFinalAbrirDisputa;

  /// No description provided for @contactoPilotoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Persona de contacto'**
  String get contactoPilotoTitulo;

  /// No description provided for @estadoReintentarAhora.
  ///
  /// In es, this message translates to:
  /// **'Reintentar ahora'**
  String get estadoReintentarAhora;

  /// No description provided for @estadoSinSenalBanner.
  ///
  /// In es, this message translates to:
  /// **'reintentando'**
  String get estadoSinSenalBanner;

  /// No description provided for @estadoSinConexionTitulo.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get estadoSinConexionTitulo;

  /// No description provided for @estadoSinConexionDetalle.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos señal para cargar {queNoCargo}. Revisa tu conexión y vuelve a intentarlo.'**
  String estadoSinConexionDetalle(String queNoCargo);

  /// No description provided for @estadoErrorTitulo.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal'**
  String get estadoErrorTitulo;

  /// No description provided for @estadoErrorDetalle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar {queNoCargo}. Vuelve a intentarlo en un momento.'**
  String estadoErrorDetalle(String queNoCargo);

  /// No description provided for @estadoTablaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Qué funciona sin red'**
  String get estadoTablaTitulo;

  /// No description provided for @estadoTablaFotos.
  ///
  /// In es, this message translates to:
  /// **'Fotos y avance'**
  String get estadoTablaFotos;

  /// No description provided for @estadoTablaFuncionan.
  ///
  /// In es, this message translates to:
  /// **'Funcionan sin red'**
  String get estadoTablaFuncionan;

  /// No description provided for @estadoTablaOfertas.
  ///
  /// In es, this message translates to:
  /// **'Ofertas y chat'**
  String get estadoTablaOfertas;

  /// No description provided for @estadoTablaRequieren.
  ///
  /// In es, this message translates to:
  /// **'Requieren red'**
  String get estadoTablaRequieren;

  /// No description provided for @estadoErrorEstaPantalla.
  ///
  /// In es, this message translates to:
  /// **'esta pantalla'**
  String get estadoErrorEstaPantalla;

  /// No description provided for @envioErrorTitulo.
  ///
  /// In es, this message translates to:
  /// **'No se envió tu solicitud'**
  String get envioErrorTitulo;

  /// No description provided for @envioErrorDetalleSinRed.
  ///
  /// In es, this message translates to:
  /// **'Lo que escribiste sigue aquí. Cuando vuelva la señal, toca «Reintentar ahora»: no se publica dos veces.'**
  String get envioErrorDetalleSinRed;

  /// No description provided for @envioErrorDetalleRechazo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos publicarla. Lo que escribiste sigue aquí.'**
  String get envioErrorDetalleRechazo;

  /// No description provided for @envioErrorVolver.
  ///
  /// In es, this message translates to:
  /// **'Volver al formulario'**
  String get envioErrorVolver;

  /// No description provided for @listaVerLotesMapa.
  ///
  /// In es, this message translates to:
  /// **'Ver lotes en el mapa'**
  String get listaVerLotesMapa;

  /// No description provided for @redSinSenalTitulo.
  ///
  /// In es, this message translates to:
  /// **'Sin señal'**
  String get redSinSenalTitulo;

  /// No description provided for @redSinSenalMensaje.
  ///
  /// In es, this message translates to:
  /// **'lo que ya cargaste sigue a la vista. Publicar u ofertar necesita red.'**
  String get redSinSenalMensaje;

  /// No description provided for @componentesCalificacion.
  ///
  /// In es, this message translates to:
  /// **'Calificación: {valor} de 5'**
  String componentesCalificacion(int valor);

  /// No description provided for @componentesPorHectarea.
  ///
  /// In es, this message translates to:
  /// **'Bs {valor} por hectárea'**
  String componentesPorHectarea(String valor);

  /// No description provided for @componentesBs.
  ///
  /// In es, this message translates to:
  /// **'Bs {valor}'**
  String componentesBs(String valor);

  /// No description provided for @componentesRonda.
  ///
  /// In es, this message translates to:
  /// **'Ronda {hechas} de {total}'**
  String componentesRonda(int hechas, int total);

  /// No description provided for @componentesRonda2.
  ///
  /// In es, this message translates to:
  /// **'RONDA {hechas}/{total}'**
  String componentesRonda2(int hechas, int total);

  /// No description provided for @componentesVolver.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get componentesVolver;

  /// No description provided for @componentesCargando.
  ///
  /// In es, this message translates to:
  /// **'Cargando'**
  String get componentesCargando;

  /// No description provided for @componentesSincronizacion.
  ///
  /// In es, this message translates to:
  /// **'Sincronización: {texto}'**
  String componentesSincronizacion(String texto);

  /// No description provided for @componentesArrastraParaVerMas.
  ///
  /// In es, this message translates to:
  /// **'Arrastra para ver más o menos'**
  String get componentesArrastraParaVerMas;

  /// No description provided for @componentesAgrocom.
  ///
  /// In es, this message translates to:
  /// **'Agrocom'**
  String get componentesAgrocom;

  /// No description provided for @componentesOfertaServicioQuedanPara.
  ///
  /// In es, this message translates to:
  /// **'Oferta de servicio: {titulo}, {monto}, quedan {tiempo} para responder'**
  String componentesOfertaServicioQuedanPara(
    String titulo,
    String monto,
    String tiempo,
  );

  /// No description provided for @componentesPago.
  ///
  /// In es, this message translates to:
  /// **'PAGO'**
  String get componentesPago;

  /// No description provided for @componentesDistancia.
  ///
  /// In es, this message translates to:
  /// **'DISTANCIA'**
  String get componentesDistancia;

  /// No description provided for @componentesSinConexionParaResponder.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Para responder necesitas red.'**
  String get componentesSinConexionParaResponder;

  /// No description provided for @componentesRechazar.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get componentesRechazar;

  /// No description provided for @componentesVerDetalleMapa.
  ///
  /// In es, this message translates to:
  /// **'Ver detalle y mapa'**
  String get componentesVerDetalleMapa;

  /// No description provided for @componentesElegido.
  ///
  /// In es, this message translates to:
  /// **'ELEGIDO'**
  String get componentesElegido;

  /// No description provided for @componentesPedido.
  ///
  /// In es, this message translates to:
  /// **'Solicitud {numero}, {estado}'**
  String componentesPedido(String numero, String estado);

  /// No description provided for @uiPosicionDelDron.
  ///
  /// In es, this message translates to:
  /// **'Posición del dron'**
  String get uiPosicionDelDron;

  /// No description provided for @uiOpenstreetmap.
  ///
  /// In es, this message translates to:
  /// **'OpenStreetMap'**
  String get uiOpenstreetmap;

  /// No description provided for @componentesRondaSemantica.
  ///
  /// In es, this message translates to:
  /// **'Ronda {ronda} de {totalRondas}, {autor}: {precio} bolivianos por hectárea, total {total} bolivianos{nota}{turno}'**
  String componentesRondaSemantica(
    Object ronda,
    Object totalRondas,
    String autor,
    Object precio,
    Object total,
    String nota,
    String turno,
  );

  /// No description provided for @componentesNotaSufijo.
  ///
  /// In es, this message translates to:
  /// **', {nota}'**
  String componentesNotaSufijo(String nota);

  /// No description provided for @componentesTurnoSufijo.
  ///
  /// In es, this message translates to:
  /// **', turno de responder'**
  String get componentesTurnoSufijo;

  /// No description provided for @componentesPilotoMinuscula.
  ///
  /// In es, this message translates to:
  /// **'piloto'**
  String get componentesPilotoMinuscula;

  /// No description provided for @componentesClienteMinuscula.
  ///
  /// In es, this message translates to:
  /// **'cliente'**
  String get componentesClienteMinuscula;

  /// No description provided for @componentesPilotoMayuscula.
  ///
  /// In es, this message translates to:
  /// **'PILOTO'**
  String get componentesPilotoMayuscula;

  /// No description provided for @componentesClienteMayuscula.
  ///
  /// In es, this message translates to:
  /// **'CLIENTE'**
  String get componentesClienteMayuscula;

  /// No description provided for @componentesOfertaSemantica.
  ///
  /// In es, this message translates to:
  /// **'Oferta de {piloto}: {precio} bolivianos por hectárea, total {total} bolivianos{elegida}'**
  String componentesOfertaSemantica(
    String piloto,
    Object precio,
    Object total,
    String elegida,
  );

  /// No description provided for @componentesElegidaSufijo.
  ///
  /// In es, this message translates to:
  /// **', elegida'**
  String get componentesElegidaSufijo;

  /// No description provided for @componentesCalificacionPromedioSemantica.
  ///
  /// In es, this message translates to:
  /// **'Calificación {valor} de 5{detalle}'**
  String componentesCalificacionPromedioSemantica(String valor, String detalle);

  /// No description provided for @componentesStepperSemantica.
  ///
  /// In es, this message translates to:
  /// **'{etiqueta}: {valor}{unidad}'**
  String componentesStepperSemantica(
    String etiqueta,
    Object valor,
    String unidad,
  );

  /// No description provided for @componentesStepperUnidad.
  ///
  /// In es, this message translates to:
  /// **' {unidad}'**
  String componentesStepperUnidad(String unidad);

  /// No description provided for @accesoFumigacionConDronesPedido.
  ///
  /// In es, this message translates to:
  /// **'Fumigación con drones cuando la necesites'**
  String get accesoFumigacionConDronesPedido;

  /// No description provided for @accesoSolicitaServicioSigueVuelo.
  ///
  /// In es, this message translates to:
  /// **'Solicita el servicio, sigue el vuelo en vivo y califica al piloto.'**
  String get accesoSolicitaServicioSigueVuelo;

  /// No description provided for @accesoIngresaCuenta.
  ///
  /// In es, this message translates to:
  /// **'Ingresa a tu cuenta'**
  String get accesoIngresaCuenta;

  /// No description provided for @accesoSolicitaServicioSigueloVivo.
  ///
  /// In es, this message translates to:
  /// **'Solicita un servicio y síguelo en vivo.'**
  String get accesoSolicitaServicioSigueloVivo;

  /// No description provided for @accesoUsuario.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get accesoUsuario;

  /// No description provided for @accesoContrasena.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get accesoContrasena;

  /// No description provided for @accesoIngresar.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get accesoIngresar;

  /// No description provided for @accesoPrimeraVezAgrocom.
  ///
  /// In es, this message translates to:
  /// **'¿Primera vez en Agrocom?'**
  String get accesoPrimeraVezAgrocom;

  /// No description provided for @accesoCrearCuenta.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get accesoCrearCuenta;

  /// No description provided for @accesoComenzar.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get accesoComenzar;

  /// No description provided for @accesoTengoCuenta.
  ///
  /// In es, this message translates to:
  /// **'Ya tengo cuenta'**
  String get accesoTengoCuenta;

  /// No description provided for @accesoSaltar.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get accesoSaltar;

  /// No description provided for @accesoPortada.
  ///
  /// In es, this message translates to:
  /// **'Portada {i} de {_portadas}'**
  String accesoPortada(int i, int _portadas);

  /// No description provided for @accesoHectareasPublicadas.
  ///
  /// In es, this message translates to:
  /// **'hectáreas publicadas'**
  String get accesoHectareasPublicadas;

  /// No description provided for @accesoPrecioFinal.
  ///
  /// In es, this message translates to:
  /// **'Precio final'**
  String get accesoPrecioFinal;

  /// No description provided for @accesoPudimosAbrirSesion.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir tu sesión'**
  String get accesoPudimosAbrirSesion;

  /// No description provided for @accesoIntentaNuevoMomento.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a intentarlo en un momento.'**
  String get accesoIntentaNuevoMomento;

  /// No description provided for @accesoReintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get accesoReintentar;

  /// No description provided for @accesoVolverIngreso.
  ///
  /// In es, this message translates to:
  /// **'Volver al ingreso'**
  String get accesoVolverIngreso;

  /// No description provided for @accesoCreaCuenta.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta'**
  String get accesoCreaCuenta;

  /// No description provided for @accesoTomaMenosMinuto.
  ///
  /// In es, this message translates to:
  /// **'Toma menos de un minuto.'**
  String get accesoTomaMenosMinuto;

  /// No description provided for @accesoNombreCompleto.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get accesoNombreCompleto;

  /// No description provided for @accesoTelefono.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get accesoTelefono;

  /// No description provided for @accesoConQueVasEntrar.
  ///
  /// In es, this message translates to:
  /// **'Con este usuario ingresas a la app. Sin espacios ni correo.'**
  String get accesoConQueVasEntrar;

  /// No description provided for @accesoMinimoCaracteresConLetras.
  ///
  /// In es, this message translates to:
  /// **'Mínimo {largoMinimoContrasena} caracteres, con letras y números.'**
  String accesoMinimoCaracteresConLetras(int largoMinimoContrasena);

  /// No description provided for @calificarGraciasPorCalificarServicio.
  ///
  /// In es, this message translates to:
  /// **'Gracias por calificar el servicio'**
  String get calificarGraciasPorCalificarServicio;

  /// No description provided for @calificarOmitir.
  ///
  /// In es, this message translates to:
  /// **'Omitir'**
  String get calificarOmitir;

  /// No description provided for @calificarComentarioOpcional.
  ///
  /// In es, this message translates to:
  /// **'Comentario opcional'**
  String get calificarComentarioOpcional;

  /// No description provided for @comunAvance.
  ///
  /// In es, this message translates to:
  /// **'Avance: {etiqueta}'**
  String comunAvance(String etiqueta);

  /// No description provided for @comunPrecioPorHectarea.
  ///
  /// In es, this message translates to:
  /// **'Precio por hectárea'**
  String get comunPrecioPorHectarea;

  /// No description provided for @comunBsHa.
  ///
  /// In es, this message translates to:
  /// **'Bs/ha'**
  String get comunBsHa;

  /// No description provided for @comunMensajeParaPilotoOpcional.
  ///
  /// In es, this message translates to:
  /// **'Mensaje para el piloto (opcional)'**
  String get comunMensajeParaPilotoOpcional;

  /// No description provided for @comunAvanceSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Avance de la solicitud'**
  String get comunAvanceSolicitud;

  /// No description provided for @inicioSolicitudActiva.
  ///
  /// In es, this message translates to:
  /// **'Solicitud activa'**
  String get inicioSolicitudActiva;

  /// No description provided for @inicioCompararOfertas.
  ///
  /// In es, this message translates to:
  /// **'Comparar ofertas'**
  String get inicioCompararOfertas;

  /// No description provided for @inicioVerSeguimiento.
  ///
  /// In es, this message translates to:
  /// **'Ver seguimiento'**
  String get inicioVerSeguimiento;

  /// No description provided for @inicioCalificar.
  ///
  /// In es, this message translates to:
  /// **'Calificar'**
  String get inicioCalificar;

  /// No description provided for @inicioHola.
  ///
  /// In es, this message translates to:
  /// **'Hola, {nombre}'**
  String inicioHola(String nombre);

  /// No description provided for @inicioPerfil.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil'**
  String get inicioPerfil;

  /// No description provided for @inicioPublicarLote.
  ///
  /// In es, this message translates to:
  /// **'Publicar lote'**
  String get inicioPublicarLote;

  /// No description provided for @inicioTienesSolicitudesCurso.
  ///
  /// In es, this message translates to:
  /// **'No tienes solicitudes en curso'**
  String get inicioTienesSolicitudesCurso;

  /// No description provided for @inicioTocaPublicarLoteMarca.
  ///
  /// In es, this message translates to:
  /// **'Toca «Publicar lote», marca tu lote y compara las ofertas de los pilotos.'**
  String get inicioTocaPublicarLoteMarca;

  /// No description provided for @inicioDescartarAviso.
  ///
  /// In es, this message translates to:
  /// **'Descartar notificación'**
  String get inicioDescartarAviso;

  /// No description provided for @inicioCalificasteCon.
  ///
  /// In es, this message translates to:
  /// **'Calificaste con {puntajeDelCliente} de 5'**
  String inicioCalificasteCon(int puntajeDelCliente);

  /// No description provided for @inicioReintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get inicioReintentar;

  /// No description provided for @ofertasCompararOfertas.
  ///
  /// In es, this message translates to:
  /// **'Comparar ofertas'**
  String get ofertasCompararOfertas;

  /// No description provided for @ofertasEncontramosEstaSolicitud.
  ///
  /// In es, this message translates to:
  /// **'No encontramos esta solicitud'**
  String get ofertasEncontramosEstaSolicitud;

  /// No description provided for @ofertasVuelveSolicitudesAbrelaNuevo.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a «Solicitudes» y ábrela de nuevo.'**
  String get ofertasVuelveSolicitudesAbrelaNuevo;

  /// No description provided for @ofertasElegir.
  ///
  /// In es, this message translates to:
  /// **'¿Elegir a {nombre}?'**
  String ofertasElegir(String nombre);

  /// No description provided for @ofertasQuedanAcordadosPorHectarea.
  ///
  /// In es, this message translates to:
  /// **'Quedan acordados {precioHa} por hectárea ({montoEstimado} estimados). Las demás ofertas se cierran y el piloto recibe tu contacto.'**
  String ofertasQuedanAcordadosPorHectarea(
    String precioHa,
    String montoEstimado,
  );

  /// No description provided for @ofertasVolver.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get ofertasVolver;

  /// No description provided for @ofertasElegirPiloto.
  ///
  /// In es, this message translates to:
  /// **'Elegir piloto'**
  String get ofertasElegirPiloto;

  /// No description provided for @ofertasPideProponPrecioPiloto.
  ///
  /// In es, this message translates to:
  /// **'Pide {precioHa}/ha. Propón tu precio; el piloto puede aceptar o responder.'**
  String ofertasPideProponPrecioPiloto(String precioHa);

  /// No description provided for @ofertasSinConexionVesUltimo.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Ves lo último que cargamos; puede estar desactualizado.'**
  String get ofertasSinConexionVesUltimo;

  /// No description provided for @ofertasOfertasOrden.
  ///
  /// In es, this message translates to:
  /// **'OFERTAS · ORDEN: {etiqueta}'**
  String ofertasOfertasOrden(String etiqueta);

  /// No description provided for @ofertasElegir2.
  ///
  /// In es, this message translates to:
  /// **'Elegir a {primerNombre} · {montoEstimado}'**
  String ofertasElegir2(String primerNombre, String montoEstimado);

  /// No description provided for @ofertasContraofertar.
  ///
  /// In es, this message translates to:
  /// **'Contraofertar'**
  String get ofertasContraofertar;

  /// No description provided for @ofertasRechazar.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get ofertasRechazar;

  /// No description provided for @ofertasUltimaRondaSoloPuedes.
  ///
  /// In es, this message translates to:
  /// **'Última ronda: solo puedes elegirlo o rechazarlo.'**
  String get ofertasUltimaRondaSoloPuedes;

  /// No description provided for @ofertasEsperandoRespuesta.
  ///
  /// In es, this message translates to:
  /// **'Esperando la respuesta de {primerNombre}'**
  String ofertasEsperandoRespuesta(String primerNombre);

  /// No description provided for @ofertasTodaviaHayOfertas.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay ofertas'**
  String get ofertasTodaviaHayOfertas;

  /// No description provided for @ofertasLosPilotosZonaVen.
  ///
  /// In es, this message translates to:
  /// **'Los pilotos de la zona ya ven tu solicitud. Cuando alguno ofrezca, te avisamos. Si tarda, puedes subir tu precio.'**
  String get ofertasLosPilotosZonaVen;

  /// No description provided for @ofertasFoto.
  ///
  /// In es, this message translates to:
  /// **'Foto de {nombre}'**
  String ofertasFoto(String nombre);

  /// No description provided for @ofertasFotoDelDron.
  ///
  /// In es, this message translates to:
  /// **'Foto del dron {dron}'**
  String ofertasFotoDelDron(String dron);

  /// No description provided for @ofertasRondas.
  ///
  /// In es, this message translates to:
  /// **'RONDAS'**
  String get ofertasRondas;

  /// No description provided for @ofertasRonda.
  ///
  /// In es, this message translates to:
  /// **'{precioHa}/ha · ronda {numero}'**
  String ofertasRonda(String precioHa, int numero);

  /// No description provided for @ofertasBsHa.
  ///
  /// In es, this message translates to:
  /// **'Bs {precioHa}/ha'**
  String ofertasBsHa(String precioHa);

  /// No description provided for @seguimientoEncontramosEsteServicio.
  ///
  /// In es, this message translates to:
  /// **'No encontramos este servicio'**
  String get seguimientoEncontramosEsteServicio;

  /// No description provided for @seguimientoVuelveSolicitudesAbreloNuevo.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a «Solicitudes» y ábrelo de nuevo.'**
  String get seguimientoVuelveSolicitudesAbreloNuevo;

  /// No description provided for @seguimientoPrecioFinal.
  ///
  /// In es, this message translates to:
  /// **'Precio final'**
  String get seguimientoPrecioFinal;

  /// No description provided for @seguimientoSonMenosQueLas.
  ///
  /// In es, this message translates to:
  /// **'Son {menos} menos que las publicadas ({hectareas}). El total sale de lo que el piloto ejecutó.'**
  String seguimientoSonMenosQueLas(String menos, String hectareas);

  /// No description provided for @seguimientoPagoDirectoPilotoAgrocom.
  ///
  /// In es, this message translates to:
  /// **'El pago es directo al piloto. Agrocom no cobra dentro de la app.'**
  String get seguimientoPagoDirectoPilotoAgrocom;

  /// No description provided for @seguimientoReportasteProblemaCasoSoporte.
  ///
  /// In es, this message translates to:
  /// **'Reportaste un problema (caso {numeroCaso}). Soporte te responde en 24 horas hábiles.'**
  String seguimientoReportasteProblemaCasoSoporte(String numeroCaso);

  /// No description provided for @seguimientoCalificacion.
  ///
  /// In es, this message translates to:
  /// **'Tu calificación'**
  String get seguimientoCalificacion;

  /// No description provided for @seguimientoCalificarPiloto.
  ///
  /// In es, this message translates to:
  /// **'Calificar al piloto'**
  String get seguimientoCalificarPiloto;

  /// No description provided for @seguimientoSinConexionVesUltimo.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Ves lo último que cargamos; puede estar desactualizado.'**
  String get seguimientoSinConexionVesUltimo;

  /// No description provided for @seguimientoPilotoConfirmado.
  ///
  /// In es, this message translates to:
  /// **'Piloto confirmado'**
  String get seguimientoPilotoConfirmado;

  /// No description provided for @seguimientoInicioVuelo.
  ///
  /// In es, this message translates to:
  /// **'Inicio de vuelo'**
  String get seguimientoInicioVuelo;

  /// No description provided for @seguimientoAcuerdenFechaPorChat.
  ///
  /// In es, this message translates to:
  /// **'Acuerda la fecha con el piloto por el chat.'**
  String get seguimientoAcuerdenFechaPorChat;

  /// No description provided for @seguimientoCierrePrecioFinal.
  ///
  /// In es, this message translates to:
  /// **'Cierre y precio final'**
  String get seguimientoCierrePrecioFinal;

  /// No description provided for @seguimientoTerminarLote.
  ///
  /// In es, this message translates to:
  /// **'Al terminar el lote'**
  String get seguimientoTerminarLote;

  /// No description provided for @seguimientoHa.
  ///
  /// In es, this message translates to:
  /// **' / {total} ha'**
  String seguimientoHa(String total);

  /// No description provided for @seguimientoPilotoTodaviaEmpezoAcuerden.
  ///
  /// In es, this message translates to:
  /// **'El piloto todavía no empezó. Acuerda la fecha con él por el chat.'**
  String get seguimientoPilotoTodaviaEmpezoAcuerden;

  /// No description provided for @seguimientoUltimaActualizacion.
  ///
  /// In es, this message translates to:
  /// **'Última actualización {ahora}'**
  String seguimientoUltimaActualizacion(String ahora);

  /// No description provided for @seguimientoPrecioFinalPagar.
  ///
  /// In es, this message translates to:
  /// **'Precio final a pagar'**
  String get seguimientoPrecioFinalPagar;

  /// No description provided for @seguimientoPagasPilotoFueraApp.
  ///
  /// In es, this message translates to:
  /// **'Le pagas al piloto fuera de la app.'**
  String get seguimientoPagasPilotoFueraApp;

  /// No description provided for @seguimientoFoto.
  ///
  /// In es, this message translates to:
  /// **'Foto de {nombre}'**
  String seguimientoFoto(String nombre);

  /// No description provided for @seguimientoPiloto.
  ///
  /// In es, this message translates to:
  /// **'Tu piloto'**
  String get seguimientoPiloto;

  /// No description provided for @seguimientoChat.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get seguimientoChat;

  /// No description provided for @seguimientoTodaviaHayFotosPiloto.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay fotos. El piloto las sube a medida que avanza, y las verás aquí.'**
  String get seguimientoTodaviaHayFotosPiloto;

  /// No description provided for @seguimientoFotoDelAvance.
  ///
  /// In es, this message translates to:
  /// **'Foto del avance'**
  String get seguimientoFotoDelAvance;

  /// No description provided for @seguimientoCerrar.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get seguimientoCerrar;

  /// No description provided for @seguimientoFotoDelAvance2.
  ///
  /// In es, this message translates to:
  /// **'Foto del avance, {subidaEn}'**
  String seguimientoFotoDelAvance2(String subidaEn);

  /// No description provided for @seguimientoUltimaFotoDelAvance.
  ///
  /// In es, this message translates to:
  /// **'Última foto del avance'**
  String get seguimientoUltimaFotoDelAvance;

  /// No description provided for @seguimientoFotoAnteriorDelAvance.
  ///
  /// In es, this message translates to:
  /// **'Foto anterior del avance'**
  String get seguimientoFotoAnteriorDelAvance;

  /// No description provided for @seguimientoFotoDelAvanceToca.
  ///
  /// In es, this message translates to:
  /// **'Foto del avance, {subidaEn} {subidaEn2}. Toca para ampliar'**
  String seguimientoFotoDelAvanceToca(String subidaEn, String subidaEn2);

  /// No description provided for @seguimientoHitoAvance.
  ///
  /// In es, this message translates to:
  /// **'Avance {porcentaje} %'**
  String seguimientoHitoAvance(String porcentaje);

  /// No description provided for @seguimientoHitoFotos.
  ///
  /// In es, this message translates to:
  /// **'{fotos, plural, =1{1 foto} other{{fotos} fotos}}{hace}'**
  String seguimientoHitoFotos(int fotos, String hace);

  /// No description provided for @seguimientoHitoHaceSufijo.
  ///
  /// In es, this message translates to:
  /// **' · {hace}'**
  String seguimientoHitoHaceSufijo(String hace);

  /// No description provided for @ofertasContraofertarA.
  ///
  /// In es, this message translates to:
  /// **'Contraofertar a {nombre}'**
  String ofertasContraofertarA(String nombre);

  /// No description provided for @ofertasOfertaRecibida.
  ///
  /// In es, this message translates to:
  /// **'1 oferta recibida'**
  String get ofertasOfertaRecibida;

  /// No description provided for @ofertasOfertasRecibidas.
  ///
  /// In es, this message translates to:
  /// **'{recibidas} ofertas recibidas'**
  String ofertasOfertasRecibidas(int recibidas);

  /// No description provided for @ofertasLasOfertas.
  ///
  /// In es, this message translates to:
  /// **'las ofertas'**
  String get ofertasLasOfertas;

  /// No description provided for @ofertasEnviarContraoferta.
  ///
  /// In es, this message translates to:
  /// **'Enviar contraoferta'**
  String get ofertasEnviarContraoferta;

  /// No description provided for @ofertasPedido.
  ///
  /// In es, this message translates to:
  /// **'SOLICITUD #{id}'**
  String ofertasPedido(String id);

  /// No description provided for @ofertasSolicitudExpiroAbrelaNuevo.
  ///
  /// In es, this message translates to:
  /// **'La solicitud expiró. Ábrela de nuevo para recibir ofertas.'**
  String get ofertasSolicitudExpiroAbrelaNuevo;

  /// No description provided for @ofertasSolicitudCancelo.
  ///
  /// In es, this message translates to:
  /// **'La solicitud se canceló.'**
  String get ofertasSolicitudCancelo;

  /// No description provided for @ofertasElegistePilotoParaEsta.
  ///
  /// In es, this message translates to:
  /// **'Ya elegiste a un piloto para esta solicitud.'**
  String get ofertasElegistePilotoParaEsta;

  /// No description provided for @ofertasOfertasCerradas.
  ///
  /// In es, this message translates to:
  /// **'Ofertas cerradas'**
  String get ofertasOfertasCerradas;

  /// No description provided for @ofertasSinCalificaciones.
  ///
  /// In es, this message translates to:
  /// **'Sin calificaciones'**
  String get ofertasSinCalificaciones;

  /// No description provided for @ofertasAceptoPrecio.
  ///
  /// In es, this message translates to:
  /// **'Aceptó tu precio'**
  String get ofertasAceptoPrecio;

  /// No description provided for @ofertasContraoferta.
  ///
  /// In es, this message translates to:
  /// **'Tu contraoferta · R{numero}/{maximo}'**
  String ofertasContraoferta(int numero, int maximo);

  /// No description provided for @ofertasEnviamosContraofertaPilotoTiene.
  ///
  /// In es, this message translates to:
  /// **'Enviamos tu contraoferta. El piloto tiene que responder.'**
  String get ofertasEnviamosContraofertaPilotoTiene;

  /// No description provided for @ofertasRechazasteOfertaLasDemas.
  ///
  /// In es, this message translates to:
  /// **'Rechazaste la oferta. Las demás siguen abiertas.'**
  String get ofertasRechazasteOfertaLasDemas;

  /// No description provided for @ofertasSinConexionEnviamosRespuesta.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. No se envió tu respuesta; vuelve a intentarlo cuando tengas señal.'**
  String get ofertasSinConexionEnviamosRespuesta;

  /// No description provided for @ofertasPudimosEnviarRespuesta.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enviar tu respuesta. Vuelve a intentarlo.'**
  String get ofertasPudimosEnviarRespuesta;

  /// No description provided for @ofertasContraofertaRonda.
  ///
  /// In es, this message translates to:
  /// **'Tu contraoferta · ronda {numero}'**
  String ofertasContraofertaRonda(int numero);

  /// No description provided for @ofertasAceptaPrecio.
  ///
  /// In es, this message translates to:
  /// **'Acepta tu precio'**
  String get ofertasAceptaPrecio;

  /// No description provided for @ofertasPideMasQuePrecio.
  ///
  /// In es, this message translates to:
  /// **'Pide {dif}/ha más que tu precio'**
  String ofertasPideMasQuePrecio(String dif);

  /// No description provided for @ofertasIgualaPrecio.
  ///
  /// In es, this message translates to:
  /// **'Iguala tu precio'**
  String get ofertasIgualaPrecio;

  /// No description provided for @ofertasOfreceMenosQuePrecio.
  ///
  /// In es, this message translates to:
  /// **'Ofrece {dif}/ha menos que tu precio'**
  String ofertasOfreceMenosQuePrecio(String dif);

  /// No description provided for @ofertasLote.
  ///
  /// In es, this message translates to:
  /// **'A {distanciaKm} de tu lote'**
  String ofertasLote(String distanciaKm);

  /// No description provided for @ofertasCanceloSusServicios.
  ///
  /// In es, this message translates to:
  /// **'Canceló {porcentaje} % de sus servicios'**
  String ofertasCanceloSusServicios(int porcentaje);

  /// No description provided for @ofertasOfertaVencio.
  ///
  /// In es, this message translates to:
  /// **'La oferta venció'**
  String get ofertasOfertaVencio;

  /// No description provided for @ofertasVence.
  ///
  /// In es, this message translates to:
  /// **'Vence en {inMinutes}'**
  String ofertasVence(String inMinutes);

  /// No description provided for @ofertasVencida.
  ///
  /// In es, this message translates to:
  /// **'Vencida'**
  String get ofertasVencida;

  /// No description provided for @seguimientoChat2.
  ///
  /// In es, this message translates to:
  /// **'el chat'**
  String get seguimientoChat2;

  /// No description provided for @seguimientoMapaDelLoteSin.
  ///
  /// In es, this message translates to:
  /// **'Mapa del lote {nombre}, sin ubicación del piloto'**
  String seguimientoMapaDelLoteSin(String nombre);

  /// No description provided for @seguimientoMapaDelLoteCon.
  ///
  /// In es, this message translates to:
  /// **'Mapa del lote {nombre} con la última ubicación del piloto'**
  String seguimientoMapaDelLoteCon(String nombre);

  /// No description provided for @seguimientoServicioTerminado.
  ///
  /// In es, this message translates to:
  /// **'{nombre} · servicio terminado'**
  String seguimientoServicioTerminado(String nombre);

  /// No description provided for @seguimientoPrecioFinal2.
  ///
  /// In es, this message translates to:
  /// **'el precio final'**
  String get seguimientoPrecioFinal2;

  /// No description provided for @seguimientoPedido.
  ///
  /// In es, this message translates to:
  /// **'SOLICITUD #{id}'**
  String seguimientoPedido(String id);

  /// No description provided for @seguimientoTotalPagarPiloto.
  ///
  /// In es, this message translates to:
  /// **'Total a pagar al piloto'**
  String get seguimientoTotalPagarPiloto;

  /// No description provided for @seguimientoReportarProblema.
  ///
  /// In es, this message translates to:
  /// **'Reportar un problema'**
  String get seguimientoReportarProblema;

  /// No description provided for @seguimientoServicioTerminado2.
  ///
  /// In es, this message translates to:
  /// **'Servicio terminado'**
  String get seguimientoServicioTerminado2;

  /// No description provided for @seguimientoServicioCurso.
  ///
  /// In es, this message translates to:
  /// **'Servicio en curso'**
  String get seguimientoServicioCurso;

  /// No description provided for @seguimientoSeguimiento.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento'**
  String get seguimientoSeguimiento;

  /// No description provided for @seguimientoSeguimiento2.
  ///
  /// In es, this message translates to:
  /// **'el seguimiento'**
  String get seguimientoSeguimiento2;

  /// No description provided for @seguimientoMasFotosDelAvance.
  ///
  /// In es, this message translates to:
  /// **'Más fotos del avance'**
  String get seguimientoMasFotosDelAvance;

  /// No description provided for @seguimientoDondeEstaPiloto.
  ///
  /// In es, this message translates to:
  /// **'Dónde está el piloto'**
  String get seguimientoDondeEstaPiloto;

  /// No description provided for @seguimientoNotasDelPiloto.
  ///
  /// In es, this message translates to:
  /// **'Notas del piloto'**
  String get seguimientoNotasDelPiloto;

  /// No description provided for @seguimientoDeHa.
  ///
  /// In es, this message translates to:
  /// **'{hechas} de {total} ha'**
  String seguimientoDeHa(String hechas, String total);

  /// No description provided for @seguimientoPropuesto.
  ///
  /// In es, this message translates to:
  /// **'{precioHaPropuesto}/ha propuesto'**
  String seguimientoPropuesto(String precioHaPropuesto);

  /// No description provided for @seguimientoAcordado.
  ///
  /// In es, this message translates to:
  /// **'{precioHaAcordado}/ha acordado'**
  String seguimientoAcordado(String precioHaAcordado);

  /// No description provided for @seguimientoPilotoComparteUbicacionCuando.
  ///
  /// In es, this message translates to:
  /// **'El piloto comparte su ubicación cuando empieza el trabajo.'**
  String get seguimientoPilotoComparteUbicacionCuando;

  /// No description provided for @seguimientoSinUbicacionRecienteEscribele.
  ///
  /// In es, this message translates to:
  /// **'Sin ubicación reciente. Escríbele por el chat si necesitas saber dónde está.'**
  String get seguimientoSinUbicacionRecienteEscribele;

  /// No description provided for @seguimientoUltimaUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Última ubicación {ahora}.'**
  String seguimientoUltimaUbicacion(String ahora);

  /// No description provided for @seguimientoSinUbicacionRecienteUltima.
  ///
  /// In es, this message translates to:
  /// **'Sin ubicación reciente. La última fue {ahora}.'**
  String seguimientoSinUbicacionRecienteUltima(String ahora);

  /// No description provided for @ofertasRondaCorta.
  ///
  /// In es, this message translates to:
  /// **'R{numero}/{maximo}'**
  String ofertasRondaCorta(int numero, int maximo);

  /// No description provided for @ofertasNotaCalificaciones.
  ///
  /// In es, this message translates to:
  /// **'{nota}/5 · {cantidad, plural, =1{1 calificación} other{{cantidad} calificaciones}}'**
  String ofertasNotaCalificaciones(String nota, int cantidad);

  /// No description provided for @ofertasOrdenPrecio.
  ///
  /// In es, this message translates to:
  /// **'Menor precio'**
  String get ofertasOrdenPrecio;

  /// No description provided for @ofertasOrdenCalificacion.
  ///
  /// In es, this message translates to:
  /// **'Mejor calificación'**
  String get ofertasOrdenCalificacion;

  /// No description provided for @ofertasOfertaCambio.
  ///
  /// In es, this message translates to:
  /// **'La oferta cambió.'**
  String get ofertasOfertaCambio;

  /// No description provided for @ofertasActualizamosLista.
  ///
  /// In es, this message translates to:
  /// **'{motivo} Actualizamos la lista.'**
  String ofertasActualizamosLista(String motivo);

  /// No description provided for @seguimientoElPiloto.
  ///
  /// In es, this message translates to:
  /// **'El piloto'**
  String get seguimientoElPiloto;

  /// No description provided for @seguimientoHoraUltima.
  ///
  /// In es, this message translates to:
  /// **'{hora} · ÚLTIMA'**
  String seguimientoHoraUltima(String hora);

  /// No description provided for @seguimientoFotosUnidad.
  ///
  /// In es, this message translates to:
  /// **'fotos'**
  String get seguimientoFotosUnidad;

  /// No description provided for @seguimientoDelServicio.
  ///
  /// In es, this message translates to:
  /// **'del servicio'**
  String get seguimientoDelServicio;

  /// No description provided for @solicitarTodaviaTienesLotesGuardados.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes lotes guardados'**
  String get solicitarTodaviaTienesLotesGuardados;

  /// No description provided for @solicitarPasaDibujarMarcaLas.
  ///
  /// In es, this message translates to:
  /// **'Pasa a «Dibujar» y marca las esquinas en el mapa.'**
  String get solicitarPasaDibujarMarcaLas;

  /// No description provided for @solicitarDeshacer.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get solicitarDeshacer;

  /// No description provided for @solicitarBorrarTodo.
  ///
  /// In es, this message translates to:
  /// **'Borrar todo'**
  String get solicitarBorrarTodo;

  /// No description provided for @solicitarHectareasFumigar.
  ///
  /// In es, this message translates to:
  /// **'Hectáreas a fumigar'**
  String get solicitarHectareasFumigar;

  /// No description provided for @solicitarHa.
  ///
  /// In es, this message translates to:
  /// **'ha'**
  String get solicitarHa;

  /// No description provided for @solicitarPedirloParaMananaMarca.
  ///
  /// In es, this message translates to:
  /// **'Si la necesitas para mañana, tu solicitud se marca como urgente. Los pilotos con el dron libre responden más rápido.'**
  String get solicitarPedirloParaMananaMarca;

  /// No description provided for @solicitarComoLlegaLoteOpcional.
  ///
  /// In es, this message translates to:
  /// **'Cómo se llega al lote (opcional)'**
  String get solicitarComoLlegaLoteOpcional;

  /// No description provided for @solicitarCaminoPortonReferencias.
  ///
  /// In es, this message translates to:
  /// **'Camino, portón, referencias'**
  String get solicitarCaminoPortonReferencias;

  /// No description provided for @solicitarObservacionesOpcional.
  ///
  /// In es, this message translates to:
  /// **'Observaciones (opcional)'**
  String get solicitarObservacionesOpcional;

  /// No description provided for @solicitarCultivosVecinosLineasElectricas.
  ///
  /// In es, this message translates to:
  /// **'Cultivos vecinos, líneas eléctricas, estado del lote'**
  String get solicitarCultivosVecinosLineasElectricas;

  /// No description provided for @solicitarLosPilotosPuedenAceptar.
  ///
  /// In es, this message translates to:
  /// **'Los pilotos pueden aceptar tu precio o proponer el suyo. Tú eliges la oferta que prefieras.'**
  String get solicitarLosPilotosPuedenAceptar;

  /// No description provided for @solicitarPrecioPorHectarea.
  ///
  /// In es, this message translates to:
  /// **'Precio por hectárea'**
  String get solicitarPrecioPorHectarea;

  /// No description provided for @solicitarPrecioExactoPorHectarea.
  ///
  /// In es, this message translates to:
  /// **'Precio exacto por hectárea'**
  String get solicitarPrecioExactoPorHectarea;

  /// No description provided for @solicitarPrecioExacto.
  ///
  /// In es, this message translates to:
  /// **'Precio exacto'**
  String get solicitarPrecioExacto;

  /// No description provided for @solicitarBs.
  ///
  /// In es, this message translates to:
  /// **'Bs '**
  String get solicitarBs;

  /// No description provided for @solicitarPor.
  ///
  /// In es, this message translates to:
  /// **'por ha'**
  String get solicitarPor;

  /// No description provided for @solicitarTotalEstimado.
  ///
  /// In es, this message translates to:
  /// **'Total estimado'**
  String get solicitarTotalEstimado;

  /// No description provided for @solicitarBs2.
  ///
  /// In es, this message translates to:
  /// **'Bs —'**
  String get solicitarBs2;

  /// No description provided for @solicitarPrecioFinalCalculaCon.
  ///
  /// In es, this message translates to:
  /// **'El precio final se calcula con las hectáreas realmente ejecutadas. Le pagas al piloto al terminar, fuera de la app.'**
  String get solicitarPrecioFinalCalculaCon;

  /// No description provided for @solicitarPasoAnterior.
  ///
  /// In es, this message translates to:
  /// **'Paso anterior'**
  String get solicitarPasoAnterior;

  /// No description provided for @solicitarPaso.
  ///
  /// In es, this message translates to:
  /// **'Paso {indice} de {total} · {etiqueta}'**
  String solicitarPaso(int indice, int total, String etiqueta);

  /// No description provided for @solicitarPublicarLote.
  ///
  /// In es, this message translates to:
  /// **'Publicar lote'**
  String get solicitarPublicarLote;

  /// No description provided for @solicitarPudimosCargarTusLotes.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus lotes'**
  String get solicitarPudimosCargarTusLotes;

  /// No description provided for @solicitarPublicarUnaSolicitudNecesita.
  ///
  /// In es, this message translates to:
  /// **'Publicar una solicitud necesita conexión. Revisa la señal y vuelve a intentarlo.'**
  String get solicitarPublicarUnaSolicitudNecesita;

  /// No description provided for @solicitarReintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get solicitarReintentar;

  /// No description provided for @solicitarSuperficie.
  ///
  /// In es, this message translates to:
  /// **'Superficie: {texto}'**
  String solicitarSuperficie(String texto);

  /// No description provided for @solicitarEsquinaDelLote.
  ///
  /// In es, this message translates to:
  /// **'Esquina {numero} del lote'**
  String solicitarEsquinaDelLote(int numero);

  /// No description provided for @solicitudesSuperficie.
  ///
  /// In es, this message translates to:
  /// **'Superficie'**
  String get solicitudesSuperficie;

  /// No description provided for @solicitudesTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get solicitudesTotal;

  /// No description provided for @solicitudesCalificasteCon.
  ///
  /// In es, this message translates to:
  /// **'Calificaste con {puntajeDelCliente}'**
  String solicitudesCalificasteCon(int puntajeDelCliente);

  /// No description provided for @solicitudesSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Solicitud'**
  String get solicitudesSolicitud;

  /// No description provided for @solicitudesEncontramosEstaSolicitud.
  ///
  /// In es, this message translates to:
  /// **'No encontramos esta solicitud'**
  String get solicitudesEncontramosEstaSolicitud;

  /// No description provided for @solicitudesVuelveSolicitudesAbrelaNuevo.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a «Solicitudes» y ábrela de nuevo.'**
  String get solicitudesVuelveSolicitudesAbrelaNuevo;

  /// No description provided for @solicitudesCambiarPrecio.
  ///
  /// In es, this message translates to:
  /// **'Cambiar tu precio'**
  String get solicitudesCambiarPrecio;

  /// No description provided for @solicitudesLasOfertasQueRecibiste.
  ///
  /// In es, this message translates to:
  /// **'Las ofertas que ya recibiste no cambian; los pilotos que negocian contigo reciben una notificación.'**
  String get solicitudesLasOfertasQueRecibiste;

  /// No description provided for @solicitudesVerLasOfertas.
  ///
  /// In es, this message translates to:
  /// **'Ver las ofertas'**
  String get solicitudesVerLasOfertas;

  /// No description provided for @solicitudesVerSeguimientoChat.
  ///
  /// In es, this message translates to:
  /// **'Ver seguimiento y chat'**
  String get solicitudesVerSeguimientoChat;

  /// No description provided for @solicitudesCalificarPiloto.
  ///
  /// In es, this message translates to:
  /// **'Calificar al piloto'**
  String get solicitudesCalificarPiloto;

  /// No description provided for @solicitudesVolverAbrirSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Volver a abrir la solicitud'**
  String get solicitudesVolverAbrirSolicitud;

  /// No description provided for @solicitudesEditarPrecio.
  ///
  /// In es, this message translates to:
  /// **'Editar precio'**
  String get solicitudesEditarPrecio;

  /// No description provided for @solicitudesVence.
  ///
  /// In es, this message translates to:
  /// **'Vence el {venceEn}'**
  String solicitudesVence(String venceEn);

  /// No description provided for @solicitudesCultivo.
  ///
  /// In es, this message translates to:
  /// **'Cultivo'**
  String get solicitudesCultivo;

  /// No description provided for @solicitudesDesde.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get solicitudesDesde;

  /// No description provided for @solicitudesReintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get solicitudesReintentar;

  /// No description provided for @solicitudesCancelarSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Cancelar la solicitud'**
  String get solicitudesCancelarSolicitud;

  /// No description provided for @solicitudesReportarProblema.
  ///
  /// In es, this message translates to:
  /// **'Reportar un problema'**
  String get solicitudesReportarProblema;

  /// No description provided for @solicitudesVolver.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get solicitudesVolver;

  /// No description provided for @solicitudesPrecioFinalPagar.
  ///
  /// In es, this message translates to:
  /// **'Precio final a pagar'**
  String get solicitudesPrecioFinalPagar;

  /// No description provided for @solicitudesEjecutadas.
  ///
  /// In es, this message translates to:
  /// **'{ejecutadas} ejecutadas × {precioHaVigente}/ha'**
  String solicitudesEjecutadas(String ejecutadas, String precioHaVigente);

  /// No description provided for @solicitudesPagasPilotoDirectamenteFuera.
  ///
  /// In es, this message translates to:
  /// **'Le pagas al piloto directamente, fuera de la app. Agrocom no cobra ni suma nada a este monto.'**
  String get solicitudesPagasPilotoDirectamenteFuera;

  /// No description provided for @solicitudesReportasteProblemaCasoSoporte.
  ///
  /// In es, this message translates to:
  /// **'Reportaste un problema: {etiqueta}. Caso {numeroCaso}, {etiqueta2}. Soporte te responde en 24 horas hábiles.'**
  String solicitudesReportasteProblemaCasoSoporte(
    String etiqueta,
    String numeroCaso,
    String etiqueta2,
  );

  /// No description provided for @solicitudesCancelarSolicitud2.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar la solicitud?'**
  String get solicitudesCancelarSolicitud2;

  /// No description provided for @solicitudesGratisLosPilotosCon.
  ///
  /// In es, this message translates to:
  /// **'Es gratis. Los pilotos con ofertas verán que se cerró.'**
  String get solicitudesGratisLosPilotosCon;

  /// No description provided for @solicitudesMotivo.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get solicitudesMotivo;

  /// No description provided for @solicitudesCancelarSolicitud3.
  ///
  /// In es, this message translates to:
  /// **'Cancelar solicitud'**
  String get solicitudesCancelarSolicitud3;

  /// No description provided for @solicitudesMisSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Mis solicitudes'**
  String get solicitudesMisSolicitudes;

  /// No description provided for @solicitudesSinConexionVesUltimo.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Ves lo último que cargamos; puede estar desactualizado.'**
  String get solicitudesSinConexionVesUltimo;

  /// No description provided for @solicitudesTodos.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get solicitudesTodos;

  /// No description provided for @solicitudesActivos.
  ///
  /// In es, this message translates to:
  /// **'Activas'**
  String get solicitudesActivos;

  /// No description provided for @solicitudesListos.
  ///
  /// In es, this message translates to:
  /// **'Terminadas'**
  String get solicitudesListos;

  /// No description provided for @solicitudesFumigadoConAgrocom.
  ///
  /// In es, this message translates to:
  /// **'Fumigado con Agrocom'**
  String get solicitudesFumigadoConAgrocom;

  /// No description provided for @solicitarQueLoteFumigamos.
  ///
  /// In es, this message translates to:
  /// **'¿Qué lote fumigamos?'**
  String get solicitarQueLoteFumigamos;

  /// No description provided for @solicitarTocaMapaCadaEsquina.
  ///
  /// In es, this message translates to:
  /// **'Toca el mapa en cada esquina del lote. Con tres esquinas ya se calcula la superficie.'**
  String get solicitarTocaMapaCadaEsquina;

  /// No description provided for @solicitarBienMarcaDosEsquinas.
  ///
  /// In es, this message translates to:
  /// **'Bien. Marca dos esquinas más.'**
  String get solicitarBienMarcaDosEsquinas;

  /// No description provided for @solicitarFaltaUnaEsquinaPara.
  ///
  /// In es, this message translates to:
  /// **'Falta una esquina para cerrar el lote.'**
  String get solicitarFaltaUnaEsquinaPara;

  /// No description provided for @solicitarContornoListoArrastraUna.
  ///
  /// In es, this message translates to:
  /// **'Contorno listo. Arrastra una esquina para ajustarla o sigue agregando puntos.'**
  String get solicitarContornoListoArrastraUna;

  /// No description provided for @solicitarQueVamosAplicar.
  ///
  /// In es, this message translates to:
  /// **'¿Qué vamos a aplicar?'**
  String get solicitarQueVamosAplicar;

  /// No description provided for @solicitarCultivo.
  ///
  /// In es, this message translates to:
  /// **'Cultivo'**
  String get solicitarCultivo;

  /// No description provided for @solicitarProducto.
  ///
  /// In es, this message translates to:
  /// **'Producto'**
  String get solicitarProducto;

  /// No description provided for @solicitarCuandoNecesitas.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo lo necesitas?'**
  String get solicitarCuandoNecesitas;

  /// No description provided for @solicitarDatosParaLosPilotos.
  ///
  /// In es, this message translates to:
  /// **'Datos para los pilotos'**
  String get solicitarDatosParaLosPilotos;

  /// No description provided for @solicitarCuantoPagasPorHectarea.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto pagas por hectárea?'**
  String get solicitarCuantoPagasPorHectarea;

  /// No description provided for @solicitarEscribePrecioParaVer.
  ///
  /// In es, this message translates to:
  /// **'Escribe un precio para ver cuánto sería.'**
  String get solicitarEscribePrecioParaVer;

  /// No description provided for @solicitarHa2.
  ///
  /// In es, this message translates to:
  /// **'{precio}/ha × {hectareas}'**
  String solicitarHa2(String precio, String hectareas);

  /// No description provided for @solicitarLote.
  ///
  /// In es, this message translates to:
  /// **'Lote'**
  String get solicitarLote;

  /// No description provided for @solicitarSuperficie2.
  ///
  /// In es, this message translates to:
  /// **'Superficie'**
  String get solicitarSuperficie2;

  /// No description provided for @solicitarFecha.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get solicitarFecha;

  /// No description provided for @solicitarReintentarPublicacion.
  ///
  /// In es, this message translates to:
  /// **'Reintentar publicación'**
  String get solicitarReintentarPublicacion;

  /// No description provided for @solicitarPublicarSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Publicar solicitud'**
  String get solicitarPublicarSolicitud;

  /// No description provided for @solicitarContinuar.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get solicitarContinuar;

  /// No description provided for @solicitarMapaParaDibujarContorno.
  ///
  /// In es, this message translates to:
  /// **'Mapa para dibujar el contorno del lote. {vertices} esquinas marcadas.'**
  String solicitarMapaParaDibujarContorno(int vertices);

  /// No description provided for @solicitarMapaLoteElegido.
  ///
  /// In es, this message translates to:
  /// **'Mapa. Lote elegido: {nombre}, {zona}.'**
  String solicitarMapaLoteElegido(String nombre, String zona);

  /// No description provided for @solicitarMapaTusLotesToca.
  ///
  /// In es, this message translates to:
  /// **'Mapa de tus lotes. Toca uno para elegirlo.'**
  String get solicitarMapaTusLotesToca;

  /// No description provided for @solicitarArrastraParaMoverla.
  ///
  /// In es, this message translates to:
  /// **'Arrastra para moverla'**
  String get solicitarArrastraParaMoverla;

  /// No description provided for @calificarComoFueServicio.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo fue el servicio?'**
  String get calificarComoFueServicio;

  /// No description provided for @calificarComoFueServicio2.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo fue el servicio de {primerNombre}?'**
  String calificarComoFueServicio2(String primerNombre);

  /// No description provided for @calificarSinConexionCalificacionEnvio.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Tu calificación no se envió; vuelve a intentarlo cuando tengas señal.'**
  String get calificarSinConexionCalificacionEnvio;

  /// No description provided for @calificarPudimosEnviarCalificacionPrueba.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enviar tu calificación. Vuelve a intentarlo.'**
  String get calificarPudimosEnviarCalificacionPrueba;

  /// No description provided for @calificarReintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get calificarReintentar;

  /// No description provided for @calificarEnviarCalificacion.
  ///
  /// In es, this message translates to:
  /// **'Enviar calificación'**
  String get calificarEnviarCalificacion;

  /// No description provided for @calificarQueDestacas.
  ///
  /// In es, this message translates to:
  /// **'¿Qué destacas?'**
  String get calificarQueDestacas;

  /// No description provided for @calificarQuePuedeMejorar.
  ///
  /// In es, this message translates to:
  /// **'¿Qué se puede mejorar?'**
  String get calificarQuePuedeMejorar;

  /// No description provided for @accesoSesionVencioEntraNuevo.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión venció. Ingresa de nuevo.'**
  String get accesoSesionVencioEntraNuevo;

  /// No description provided for @accesoTusDatos.
  ///
  /// In es, this message translates to:
  /// **'Tus datos'**
  String get accesoTusDatos;

  /// No description provided for @accesoAcceso.
  ///
  /// In es, this message translates to:
  /// **'Tu acceso'**
  String get accesoAcceso;

  /// No description provided for @acceso118.
  ///
  /// In es, this message translates to:
  /// **'118 ha × 64'**
  String get acceso118;

  /// No description provided for @acceso552.
  ///
  /// In es, this message translates to:
  /// **'Bs 7.552'**
  String get acceso552;

  /// No description provided for @inicioVerOtraSolicitudActiva.
  ///
  /// In es, this message translates to:
  /// **'Ver la otra solicitud activa'**
  String get inicioVerOtraSolicitudActiva;

  /// No description provided for @inicioVerLasOtrasSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Ver las otras {otrosActivos} solicitudes activas'**
  String inicioVerLasOtrasSolicitudes(int otrosActivos);

  /// No description provided for @inicioPorCalificar.
  ///
  /// In es, this message translates to:
  /// **'Por calificar'**
  String get inicioPorCalificar;

  /// No description provided for @inicioAvisos.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get inicioAvisos;

  /// No description provided for @inicioHistorialReciente.
  ///
  /// In es, this message translates to:
  /// **'Historial reciente'**
  String get inicioHistorialReciente;

  /// No description provided for @inicioVerTodo.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get inicioVerTodo;

  /// No description provided for @inicioSinConexion.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get inicioSinConexion;

  /// No description provided for @inicioPudimosCargarInicio.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu inicio'**
  String get inicioPudimosCargarInicio;

  /// No description provided for @inicioRevisaSenalIntentaNuevo.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu señal y vuelve a intentarlo. Publicar una solicitud requiere conexión.'**
  String get inicioRevisaSenalIntentaNuevo;

  /// No description provided for @inicioIntentaNuevoMomento.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a intentarlo en un momento.'**
  String get inicioIntentaNuevoMomento;

  /// No description provided for @comunEnviando.
  ///
  /// In es, this message translates to:
  /// **'{texto}, enviando'**
  String comunEnviando(String texto);

  /// No description provided for @comunFoto.
  ///
  /// In es, this message translates to:
  /// **'Foto'**
  String get comunFoto;

  /// No description provided for @comunEscribePrecioParaVer.
  ///
  /// In es, this message translates to:
  /// **'Escribe un precio para ver el total.'**
  String get comunEscribePrecioParaVer;

  /// No description provided for @comunTotalEstimadoPor.
  ///
  /// In es, this message translates to:
  /// **'Total estimado: {valor} por {hectareas}'**
  String comunTotalEstimadoPor(String valor, String hectareas);

  /// No description provided for @solicitudesPrecioAcordado.
  ///
  /// In es, this message translates to:
  /// **'Precio acordado'**
  String get solicitudesPrecioAcordado;

  /// No description provided for @solicitudesPrecio.
  ///
  /// In es, this message translates to:
  /// **'Tu precio'**
  String get solicitudesPrecio;

  /// No description provided for @solicitudesSolicitud2.
  ///
  /// In es, this message translates to:
  /// **'la solicitud'**
  String get solicitudesSolicitud2;

  /// No description provided for @solicitudesGuardarPrecio.
  ///
  /// In es, this message translates to:
  /// **'Guardar precio'**
  String get solicitudesGuardarPrecio;

  /// No description provided for @solicitudesPublicada.
  ///
  /// In es, this message translates to:
  /// **'{zona} · publicada el {publicadaEn}'**
  String solicitudesPublicada(String zona, String publicadaEn);

  /// No description provided for @solicitudesSinConexionGuardoCambio.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. No se guardó el cambio; vuelve a intentarlo cuando tengas señal.'**
  String get solicitudesSinConexionGuardoCambio;

  /// No description provided for @solicitudesPudimosCompletarOperacion.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar la operación. Vuelve a intentarlo.'**
  String get solicitudesPudimosCompletarOperacion;

  /// No description provided for @solicitudesSinConexionFaltanCargar.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. No pudimos cargar tu calificación ni el reclamo.'**
  String get solicitudesSinConexionFaltanCargar;

  /// No description provided for @solicitudesPudimosCargarCalificacionReclamo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu calificación y el reclamo.'**
  String get solicitudesPudimosCargarCalificacionReclamo;

  /// No description provided for @solicitudesCancelasteEstaSolicitudPuedes.
  ///
  /// In es, this message translates to:
  /// **'Cancelaste esta solicitud. Puedes publicar otra desde «Solicitar».'**
  String get solicitudesCancelasteEstaSolicitudPuedes;

  /// No description provided for @solicitudesCancelasteEstaSolicitudPuedes2.
  ///
  /// In es, this message translates to:
  /// **'Cancelaste esta solicitud: {motivoCancelacion}. Puedes publicar otra desde «Solicitar».'**
  String solicitudesCancelasteEstaSolicitudPuedes2(String motivoCancelacion);

  /// No description provided for @solicitudesEstado.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get solicitudesEstado;

  /// No description provided for @solicitudesQuienFumiga.
  ///
  /// In es, this message translates to:
  /// **'Quién fumiga'**
  String get solicitudesQuienFumiga;

  /// No description provided for @solicitudesQuePediste.
  ///
  /// In es, this message translates to:
  /// **'Lo que solicitaste'**
  String get solicitudesQuePediste;

  /// No description provided for @solicitudesProducto.
  ///
  /// In es, this message translates to:
  /// **'Producto'**
  String get solicitudesProducto;

  /// No description provided for @solicitudesFechaDeseada.
  ///
  /// In es, this message translates to:
  /// **'Fecha deseada'**
  String get solicitudesFechaDeseada;

  /// No description provided for @solicitudesAccesos.
  ///
  /// In es, this message translates to:
  /// **'Accesos'**
  String get solicitudesAccesos;

  /// No description provided for @solicitudesObservaciones.
  ///
  /// In es, this message translates to:
  /// **'Observaciones'**
  String get solicitudesObservaciones;

  /// No description provided for @solicitudesCalificacion.
  ///
  /// In es, this message translates to:
  /// **'Tu calificación'**
  String get solicitudesCalificacion;

  /// No description provided for @solicitudesTusSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'tus solicitudes'**
  String get solicitudesTusSolicitudes;

  /// No description provided for @solicitudesTodaviaPublicasteSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Todavía no publicaste solicitudes'**
  String get solicitudesTodaviaPublicasteSolicitudes;

  /// No description provided for @solicitudesHaySolicitudesCurso.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes en curso'**
  String get solicitudesHaySolicitudesCurso;

  /// No description provided for @solicitudesTodaviaHayServiciosTerminados.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay servicios terminados'**
  String get solicitudesTodaviaHayServiciosTerminados;

  /// No description provided for @solicitudesCuandoPilotoTerminaQueda.
  ///
  /// In es, this message translates to:
  /// **'Cuando un piloto termina, queda guardado aquí con sus fotos y el precio final.'**
  String get solicitudesCuandoPilotoTerminaQueda;

  /// No description provided for @solicitudesPublicaLoteComparaLas.
  ///
  /// In es, this message translates to:
  /// **'Publica un lote, compara las ofertas de los pilotos y elige.'**
  String get solicitudesPublicaLoteComparaLas;

  /// No description provided for @solicitarErrorHectareasVacio.
  ///
  /// In es, this message translates to:
  /// **'Indica cuántas hectáreas quieres fumigar.'**
  String get solicitarErrorHectareasVacio;

  /// No description provided for @solicitarErrorNoEsNumeroHectareas.
  ///
  /// In es, this message translates to:
  /// **'Escribe un número, por ejemplo 85,5.'**
  String get solicitarErrorNoEsNumeroHectareas;

  /// No description provided for @solicitarErrorHectareasNoPositivas.
  ///
  /// In es, this message translates to:
  /// **'La superficie tiene que ser mayor a 0.'**
  String get solicitarErrorHectareasNoPositivas;

  /// No description provided for @solicitarErrorDosDecimales.
  ///
  /// In es, this message translates to:
  /// **'Usa como máximo dos decimales.'**
  String get solicitarErrorDosDecimales;

  /// No description provided for @solicitarErrorHectareasMaximas.
  ///
  /// In es, this message translates to:
  /// **'Una solicitud admite hasta {maximo} ha.'**
  String solicitarErrorHectareasMaximas(String maximo);

  /// No description provided for @solicitarErrorHectareasSobreLote.
  ///
  /// In es, this message translates to:
  /// **'El lote tiene {tope} ha: no puedes solicitar más.'**
  String solicitarErrorHectareasSobreLote(String tope);

  /// No description provided for @solicitarErrorPrecioVacio.
  ///
  /// In es, this message translates to:
  /// **'Propón cuánto pagarías por hectárea.'**
  String get solicitarErrorPrecioVacio;

  /// No description provided for @solicitarErrorNoEsNumeroPrecio.
  ///
  /// In es, this message translates to:
  /// **'Escribe un número, por ejemplo 120.'**
  String get solicitarErrorNoEsNumeroPrecio;

  /// No description provided for @solicitarErrorPrecioNoPositivo.
  ///
  /// In es, this message translates to:
  /// **'El precio tiene que ser mayor a 0.'**
  String get solicitarErrorPrecioNoPositivo;

  /// No description provided for @solicitarHectareasDelContorno.
  ///
  /// In es, this message translates to:
  /// **'Del contorno salen {hectareas}. Ajústalas si vas a fumigar otra superficie.'**
  String solicitarHectareasDelContorno(String hectareas);

  /// No description provided for @solicitarHectareasDelLote.
  ///
  /// In es, this message translates to:
  /// **'El lote tiene {hectareas}. Ajústalas si vas a fumigar otra superficie.'**
  String solicitarHectareasDelLote(String hectareas);

  /// No description provided for @solicitarMisLotes.
  ///
  /// In es, this message translates to:
  /// **'Mis lotes'**
  String get solicitarMisLotes;

  /// No description provided for @solicitarDibujar.
  ///
  /// In es, this message translates to:
  /// **'Dibujar'**
  String get solicitarDibujar;

  /// No description provided for @solicitarEnviandoSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Enviando la solicitud'**
  String get solicitarEnviandoSolicitud;

  /// No description provided for @solicitarPasoLote.
  ///
  /// In es, this message translates to:
  /// **'Lote'**
  String get solicitarPasoLote;

  /// No description provided for @solicitarPasoAplicacion.
  ///
  /// In es, this message translates to:
  /// **'Aplicación'**
  String get solicitarPasoAplicacion;

  /// No description provided for @solicitarPasoCuando.
  ///
  /// In es, this message translates to:
  /// **'Cuándo'**
  String get solicitarPasoCuando;

  /// No description provided for @solicitarPasoPrecio.
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get solicitarPasoPrecio;

  /// No description provided for @accesoErrorCredenciales.
  ///
  /// In es, this message translates to:
  /// **'El usuario o la contraseña no coinciden. Revísalos y vuelve a intentarlo.'**
  String get accesoErrorCredenciales;

  /// No description provided for @accesoErrorSinConexion.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Lo que escribiste sigue aquí: vuelve a intentarlo cuando tengas señal.'**
  String get accesoErrorSinConexion;

  /// No description provided for @accesoErrorDesconocido.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar la operación. Vuelve a intentarlo en un momento.'**
  String get accesoErrorDesconocido;

  /// No description provided for @accesoPortadaPublicaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Publica tu lote en el mapa'**
  String get accesoPortadaPublicaTitulo;

  /// No description provided for @accesoPortadaPublicaDetalle.
  ///
  /// In es, this message translates to:
  /// **'Marca el área, define tu precio por hectárea y recibe ofertas de pilotos cercanos.'**
  String get accesoPortadaPublicaDetalle;

  /// No description provided for @accesoPortadaNegociaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Negocia hasta 5 rondas'**
  String get accesoPortadaNegociaTitulo;

  /// No description provided for @accesoPortadaNegociaDetalle.
  ///
  /// In es, this message translates to:
  /// **'Cada piloto acepta tu precio o contraoferta. Tú eliges con quién trabajar.'**
  String get accesoPortadaNegociaDetalle;

  /// No description provided for @accesoPortadaPagasTitulo.
  ///
  /// In es, this message translates to:
  /// **'Pagas lo que se fumigó'**
  String get accesoPortadaPagasTitulo;

  /// No description provided for @accesoPortadaPagasDetalle.
  ///
  /// In es, this message translates to:
  /// **'Precio final = hectáreas ejecutadas × precio acordado. El pago es directo con el piloto.'**
  String get accesoPortadaPagasDetalle;

  /// No description provided for @historialMesEne.
  ///
  /// In es, this message translates to:
  /// **'Ene'**
  String get historialMesEne;

  /// No description provided for @historialMesFeb.
  ///
  /// In es, this message translates to:
  /// **'Feb'**
  String get historialMesFeb;

  /// No description provided for @historialMesMar.
  ///
  /// In es, this message translates to:
  /// **'Mar'**
  String get historialMesMar;

  /// No description provided for @historialMesAbr.
  ///
  /// In es, this message translates to:
  /// **'Abr'**
  String get historialMesAbr;

  /// No description provided for @historialMesMay.
  ///
  /// In es, this message translates to:
  /// **'May'**
  String get historialMesMay;

  /// No description provided for @historialMesJun.
  ///
  /// In es, this message translates to:
  /// **'Jun'**
  String get historialMesJun;

  /// No description provided for @historialMesJul.
  ///
  /// In es, this message translates to:
  /// **'Jul'**
  String get historialMesJul;

  /// No description provided for @historialMesAgo.
  ///
  /// In es, this message translates to:
  /// **'Ago'**
  String get historialMesAgo;

  /// No description provided for @historialMesSep.
  ///
  /// In es, this message translates to:
  /// **'Sep'**
  String get historialMesSep;

  /// No description provided for @historialMesOct.
  ///
  /// In es, this message translates to:
  /// **'Oct'**
  String get historialMesOct;

  /// No description provided for @historialMesNov.
  ///
  /// In es, this message translates to:
  /// **'Nov'**
  String get historialMesNov;

  /// No description provided for @historialMesDic.
  ///
  /// In es, this message translates to:
  /// **'Dic'**
  String get historialMesDic;

  /// No description provided for @solicitudesVerOfertas.
  ///
  /// In es, this message translates to:
  /// **'Ver {cantidad, plural, =1{1 oferta} other{{cantidad} ofertas}}'**
  String solicitudesVerOfertas(int cantidad);

  /// No description provided for @solicitudesPilotosOfertaron.
  ///
  /// In es, this message translates to:
  /// **'{cantidad, plural, =1{1 piloto ofertó} other{{cantidad} pilotos ofertaron}}. Compáralas y elige la que prefieras.'**
  String solicitudesPilotosOfertaron(int cantidad);

  /// No description provided for @solicitudesComentarioEntreComillas.
  ///
  /// In es, this message translates to:
  /// **'«{comentario}»'**
  String solicitudesComentarioEntreComillas(String comentario);

  /// No description provided for @historialEnServicios.
  ///
  /// In es, this message translates to:
  /// **'en {cantidad, plural, =1{1 servicio} other{{cantidad} servicios}}'**
  String historialEnServicios(int cantidad);

  /// No description provided for @historialSemanticaHectareasPorMes.
  ///
  /// In es, this message translates to:
  /// **'Hectáreas fumigadas por mes: {detalle}'**
  String historialSemanticaHectareasPorMes(String detalle);

  /// No description provided for @calificarTocaEstrella.
  ///
  /// In es, this message translates to:
  /// **'Toca una estrella'**
  String get calificarTocaEstrella;

  /// No description provided for @calificarMalo.
  ///
  /// In es, this message translates to:
  /// **'Malo'**
  String get calificarMalo;

  /// No description provided for @calificarRegular.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get calificarRegular;

  /// No description provided for @calificarBueno.
  ///
  /// In es, this message translates to:
  /// **'Bueno'**
  String get calificarBueno;

  /// No description provided for @calificarMuyBueno.
  ///
  /// In es, this message translates to:
  /// **'Muy bueno'**
  String get calificarMuyBueno;

  /// No description provided for @calificarExcelente.
  ///
  /// In es, this message translates to:
  /// **'Excelente'**
  String get calificarExcelente;

  /// No description provided for @terrenosSubePublicar.
  ///
  /// In es, this message translates to:
  /// **'se sube al publicar'**
  String get terrenosSubePublicar;

  /// No description provided for @terrenosPudoSubir.
  ///
  /// In es, this message translates to:
  /// **'no se pudo subir'**
  String get terrenosPudoSubir;

  /// No description provided for @terrenosFotosDelTerreno.
  ///
  /// In es, this message translates to:
  /// **'Fotos del terreno'**
  String get terrenosFotosDelTerreno;

  /// No description provided for @terrenosClienteSubioFotosDel.
  ///
  /// In es, this message translates to:
  /// **'El cliente no subió fotos del terreno. Si te eligen, pregúntale por el estado del lote en el chat.'**
  String get terrenosClienteSubioFotosDel;

  /// No description provided for @terrenosFoto.
  ///
  /// In es, this message translates to:
  /// **'Foto {_actual} de {fotos}'**
  String terrenosFoto(int _actual, int fotos);

  /// No description provided for @terrenosCerrar.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get terrenosCerrar;

  /// No description provided for @terrenosFotos.
  ///
  /// In es, this message translates to:
  /// **'{fotos} de {maximo} fotos'**
  String terrenosFotos(int fotos, int maximo);

  /// No description provided for @terrenosAgregaFotosDelEstado.
  ///
  /// In es, this message translates to:
  /// **'Agrega fotos del estado del terreno: el piloto las ve antes de ofertar y ajusta mejor su precio.'**
  String get terrenosAgregaFotosDelEstado;

  /// No description provided for @terrenosSubenCuandoPubliquesSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Se suben cuando publiques la solicitud.'**
  String get terrenosSubenCuandoPubliquesSolicitud;

  /// No description provided for @terrenosPilotoLasAntesOfertar.
  ///
  /// In es, this message translates to:
  /// **'El piloto las ve antes de ofertar.'**
  String get terrenosPilotoLasAntesOfertar;

  /// No description provided for @terrenosTomarUnaFoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar una foto'**
  String get terrenosTomarUnaFoto;

  /// No description provided for @terrenosElegirGaleria.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get terrenosElegirGaleria;

  /// No description provided for @terrenosAgregarUnaFotoDel.
  ///
  /// In es, this message translates to:
  /// **'Agregar una foto del terreno'**
  String get terrenosAgregarUnaFotoDel;

  /// No description provided for @terrenosAgregar.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get terrenosAgregar;

  /// No description provided for @proveedorDronDronRegistrado.
  ///
  /// In es, this message translates to:
  /// **'1 dron registrado'**
  String get proveedorDronDronRegistrado;

  /// No description provided for @proveedorDronDronesRegistrados.
  ///
  /// In es, this message translates to:
  /// **'{drones} drones registrados'**
  String proveedorDronDronesRegistrados(int drones);

  /// No description provided for @proveedorDronMisDrones.
  ///
  /// In es, this message translates to:
  /// **'Mis drones'**
  String get proveedorDronMisDrones;

  /// No description provided for @proveedorDronPudimosCargarTusDrones.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus drones'**
  String get proveedorDronPudimosCargarTusDrones;

  /// No description provided for @proveedorDronRevisaConexionVolveIntentar.
  ///
  /// In es, this message translates to:
  /// **'Revisa la conexión y vuelve a intentarlo.'**
  String get proveedorDronRevisaConexionVolveIntentar;

  /// No description provided for @proveedorDronTodaviaRegistrasteDrones.
  ///
  /// In es, this message translates to:
  /// **'Todavía no registraste drones'**
  String get proveedorDronTodaviaRegistrasteDrones;

  /// No description provided for @proveedorDronSinDronAprobadoLlegan.
  ///
  /// In es, this message translates to:
  /// **'Sin un dron aprobado no llegan ofertas. Cada dron lo aprueba un administrador.'**
  String get proveedorDronSinDronAprobadoLlegan;

  /// No description provided for @pagoPagoConfirmado.
  ///
  /// In es, this message translates to:
  /// **'Pago confirmado. {detalle}'**
  String pagoPagoConfirmado(String detalle);

  /// No description provided for @pagoPagoConfirmado2.
  ///
  /// In es, this message translates to:
  /// **'Pago confirmado'**
  String get pagoPagoConfirmado2;

  /// No description provided for @pagoQuedoRegistradoClienteHay.
  ///
  /// In es, this message translates to:
  /// **'Ya quedó registrado y el cliente lo ve. No hay nada más que hacer.'**
  String get pagoQuedoRegistradoClienteHay;

  /// No description provided for @pagoPilotoConfirmoQueRecibio.
  ///
  /// In es, this message translates to:
  /// **'El piloto confirmó que recibió el pago. Gracias por usar Agrocom.'**
  String get pagoPilotoConfirmoQueRecibio;

  /// No description provided for @pagoPudimosRevisarPago.
  ///
  /// In es, this message translates to:
  /// **'No pudimos revisar el pago.'**
  String get pagoPudimosRevisarPago;

  /// No description provided for @pagoReintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get pagoReintentar;

  /// No description provided for @pagoPagoPendiente.
  ///
  /// In es, this message translates to:
  /// **'Pago pendiente'**
  String get pagoPagoPendiente;

  /// No description provided for @pagoPagasPilotoDirectamenteCuando.
  ///
  /// In es, this message translates to:
  /// **'Le pagas al piloto directamente. Cuando él confirme que lo recibió, lo verás aquí.'**
  String get pagoPagasPilotoDirectamenteCuando;

  /// No description provided for @pagoConfirmasQueRecibistePago.
  ///
  /// In es, this message translates to:
  /// **'¿Confirmas que recibiste el pago?'**
  String get pagoConfirmasQueRecibistePago;

  /// No description provided for @pagoSoloPuedeConfirmarUna.
  ///
  /// In es, this message translates to:
  /// **'Solo se puede confirmar una vez. El cliente verá que el pago quedó confirmado.'**
  String get pagoSoloPuedeConfirmarUna;

  /// No description provided for @pagoTodavia.
  ///
  /// In es, this message translates to:
  /// **'Todavía no'**
  String get pagoTodavia;

  /// No description provided for @pagoRecibi.
  ///
  /// In es, this message translates to:
  /// **'Sí, lo recibí'**
  String get pagoRecibi;

  /// No description provided for @pagoPagaron.
  ///
  /// In es, this message translates to:
  /// **'¿Ya te pagaron?'**
  String get pagoPagaron;

  /// No description provided for @pagoClientePagaDirectamenteCuando.
  ///
  /// In es, this message translates to:
  /// **'El cliente te paga directamente. Cuando lo recibas, confírmalo aquí: la app no cobra ni mueve dinero.'**
  String get pagoClientePagaDirectamenteCuando;

  /// No description provided for @pagoComoPagoOpcional.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te pagó? (opcional)'**
  String get pagoComoPagoOpcional;

  /// No description provided for @pagoPudimosConfirmarPago.
  ///
  /// In es, this message translates to:
  /// **'No pudimos confirmar el pago.'**
  String get pagoPudimosConfirmarPago;

  /// No description provided for @pagoRecibiPago.
  ///
  /// In es, this message translates to:
  /// **'Ya recibí el pago'**
  String get pagoRecibiPago;

  /// No description provided for @marketplaceAccesoFumigacionConDron.
  ///
  /// In es, this message translates to:
  /// **'Fumigación con dron'**
  String get marketplaceAccesoFumigacionConDron;

  /// No description provided for @marketplaceAccesoFumigacionConDronPrecio.
  ///
  /// In es, this message translates to:
  /// **'Fumigación con dron, al precio que acuerdes'**
  String get marketplaceAccesoFumigacionConDronPrecio;

  /// No description provided for @marketplaceAccesoPublicaLoteRecibeOfertas.
  ///
  /// In es, this message translates to:
  /// **'Publica tu lote, recibe ofertas de pilotos y elige. El pago es directo con el piloto.'**
  String get marketplaceAccesoPublicaLoteRecibeOfertas;

  /// No description provided for @marketplaceAccesoComoVasUsarAgrocom.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo vas a usar Agrocom?'**
  String get marketplaceAccesoComoVasUsarAgrocom;

  /// No description provided for @marketplaceAccesoEligeRol.
  ///
  /// In es, this message translates to:
  /// **'Elige tu rol'**
  String get marketplaceAccesoEligeRol;

  /// No description provided for @marketplaceAccesoContinuarComo.
  ///
  /// In es, this message translates to:
  /// **'Continuar como {enBoton}'**
  String marketplaceAccesoContinuarComo(String enBoton);

  /// No description provided for @marketplaceAccesoTengoCuenta.
  ///
  /// In es, this message translates to:
  /// **'Ya tengo cuenta'**
  String get marketplaceAccesoTengoCuenta;

  /// No description provided for @fotoPerfilFotoPerfilTocaPara.
  ///
  /// In es, this message translates to:
  /// **'Foto de perfil de {nombre}. Toca para cambiarla'**
  String fotoPerfilFotoPerfilTocaPara(String nombre);

  /// No description provided for @fotoPerfilSinFotoPerfilToca.
  ///
  /// In es, this message translates to:
  /// **'Sin foto de perfil. Toca para agregar una'**
  String get fotoPerfilSinFotoPerfilToca;

  /// No description provided for @fotoPerfilSubiendoFoto.
  ///
  /// In es, this message translates to:
  /// **'Subiendo foto…'**
  String get fotoPerfilSubiendoFoto;

  /// No description provided for @fotoPerfilCambiarFoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get fotoPerfilCambiarFoto;

  /// No description provided for @fotoPerfilAgregarFoto.
  ///
  /// In es, this message translates to:
  /// **'Agregar foto'**
  String get fotoPerfilAgregarFoto;

  /// No description provided for @fotoPerfilQuitar.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get fotoPerfilQuitar;

  /// No description provided for @fotoPerfilConUnaFotoCliente.
  ///
  /// In es, this message translates to:
  /// **'Con una foto, el cliente te reconoce al llegar al lote.'**
  String get fotoPerfilConUnaFotoCliente;

  /// No description provided for @fotoPerfilReintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get fotoPerfilReintentar;

  /// No description provided for @fotoPerfilTomarUnaFoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar una foto'**
  String get fotoPerfilTomarUnaFoto;

  /// No description provided for @fotoPerfilElegirGaleria.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get fotoPerfilElegirGaleria;

  /// No description provided for @fotoPerfilQuitarFoto.
  ///
  /// In es, this message translates to:
  /// **'Quitar la foto'**
  String get fotoPerfilQuitarFoto;

  /// No description provided for @fotoSinConexionReintentar.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu señal y vuelve a intentarlo.'**
  String get fotoSinConexionReintentar;

  /// No description provided for @fotoPerfilNoPreparada.
  ///
  /// In es, this message translates to:
  /// **'No pudimos preparar la foto. Prueba con otra.'**
  String get fotoPerfilNoPreparada;

  /// No description provided for @fotoPerfilQuitada.
  ///
  /// In es, this message translates to:
  /// **'Quitamos tu foto. Verás tus iniciales.'**
  String get fotoPerfilQuitada;

  /// No description provided for @fotoPerfilNoQuitada.
  ///
  /// In es, this message translates to:
  /// **'No pudimos quitar la foto. Vuelve a intentarlo.'**
  String get fotoPerfilNoQuitada;

  /// No description provided for @fotoPerfilActualizada.
  ///
  /// In es, this message translates to:
  /// **'Listo: tu foto de perfil está actualizada.'**
  String get fotoPerfilActualizada;

  /// No description provided for @fotoPerfilNoSubida.
  ///
  /// In es, this message translates to:
  /// **'No pudimos subir la foto. Vuelve a intentarlo.'**
  String get fotoPerfilNoSubida;

  /// No description provided for @pagoNoPudimosRevisar.
  ///
  /// In es, this message translates to:
  /// **'No pudimos revisar el pago. Vuelve a intentarlo.'**
  String get pagoNoPudimosRevisar;

  /// No description provided for @pagoNoPudimosConfirmar.
  ///
  /// In es, this message translates to:
  /// **'No pudimos confirmar el pago. Tu confirmación no se perdió: vuelve a intentarlo.'**
  String get pagoNoPudimosConfirmar;

  /// No description provided for @pagoSoloTitular.
  ///
  /// In es, this message translates to:
  /// **'Solo el titular del proveedor puede confirmar el pago. Pídele que lo haga desde su cuenta.'**
  String get pagoSoloTitular;

  /// No description provided for @terrenosFotosMaximo.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes {maximo} fotos, el máximo. Quita una para agregar otra.'**
  String terrenosFotosMaximo(int maximo);

  /// No description provided for @terrenosFotoNoPreparada.
  ///
  /// In es, this message translates to:
  /// **'No pudimos preparar la foto. Prueba con otra.'**
  String get terrenosFotoNoPreparada;

  /// No description provided for @terrenosFotoGuardada.
  ///
  /// In es, this message translates to:
  /// **'Foto guardada.'**
  String get terrenosFotoGuardada;

  /// No description provided for @terrenosFotoNoSubida.
  ///
  /// In es, this message translates to:
  /// **'No pudimos subir la foto. Vuelve a intentarlo.'**
  String get terrenosFotoNoSubida;

  /// No description provided for @terrenosFotoQuitada.
  ///
  /// In es, this message translates to:
  /// **'Quitamos la foto.'**
  String get terrenosFotoQuitada;

  /// No description provided for @terrenosFotoNoQuitada.
  ///
  /// In es, this message translates to:
  /// **'No pudimos quitar la foto. Vuelve a intentarlo.'**
  String get terrenosFotoNoQuitada;

  /// No description provided for @fotoMuyPesada.
  ///
  /// In es, this message translates to:
  /// **'La foto es muy pesada. Elige otra o toma una nueva.'**
  String get fotoMuyPesada;

  /// No description provided for @componentesEnviando.
  ///
  /// In es, this message translates to:
  /// **'Enviando…'**
  String get componentesEnviando;

  /// No description provided for @componentesAceptarServicio.
  ///
  /// In es, this message translates to:
  /// **'Aceptar servicio'**
  String get componentesAceptarServicio;

  /// No description provided for @uiMapaDelLote.
  ///
  /// In es, this message translates to:
  /// **'Mapa del lote {nombre}, {zona}'**
  String uiMapaDelLote(String nombre, String zona);

  /// No description provided for @uiMapaLotes.
  ///
  /// In es, this message translates to:
  /// **'Mapa de lotes'**
  String get uiMapaLotes;

  /// No description provided for @uiEstado.
  ///
  /// In es, this message translates to:
  /// **'Estado: {etiqueta}'**
  String uiEstado(String etiqueta);

  /// No description provided for @uiCurso.
  ///
  /// In es, this message translates to:
  /// **'{texto}, en curso'**
  String uiCurso(String texto);

  /// No description provided for @uiMostrarContrasena.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get uiMostrarContrasena;

  /// No description provided for @uiOcultarContrasena.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get uiOcultarContrasena;

  /// No description provided for @proveedorDronBateriaCiclosPorCiento.
  ///
  /// In es, this message translates to:
  /// **'Batería: {ciclosBateria} de {cicloMaximoBateria} ciclos, {porcentaje} por ciento de la vida útil'**
  String proveedorDronBateriaCiclosPorCiento(
    int ciclosBateria,
    int cicloMaximoBateria,
    int porcentaje,
  );

  /// No description provided for @proveedorDronCiclosBateria.
  ///
  /// In es, this message translates to:
  /// **'CICLOS DE BATERÍA'**
  String get proveedorDronCiclosBateria;

  /// No description provided for @proveedorDronDe.
  ///
  /// In es, this message translates to:
  /// **' de {cicloMaximoBateria}'**
  String proveedorDronDe(int cicloMaximoBateria);

  /// No description provided for @proveedorDronBateriaCumplioVidaUtil.
  ///
  /// In es, this message translates to:
  /// **'La batería cumplió su vida útil. Hay que cambiarla.'**
  String get proveedorDronBateriaCumplioVidaUtil;

  /// No description provided for @proveedorDronQuedanCiclosPlanificaRecambio.
  ///
  /// In es, this message translates to:
  /// **'Quedan {ciclosRestantes} ciclos. Planifica el recambio.'**
  String proveedorDronQuedanCiclosPlanificaRecambio(int ciclosRestantes);

  /// No description provided for @proveedorDronQuedanCiclosVidaUtil.
  ///
  /// In es, this message translates to:
  /// **'Quedan {ciclosRestantes} ciclos de vida útil.'**
  String proveedorDronQuedanCiclosVidaUtil(int ciclosRestantes);

  /// No description provided for @proveedorPerfilEstasHabilitadoParaRecibir.
  ///
  /// In es, this message translates to:
  /// **'Estás habilitado para recibir ofertas.'**
  String get proveedorPerfilEstasHabilitadoParaRecibir;

  /// No description provided for @proveedorPerfilAdministradorEstaRevisandoTus.
  ///
  /// In es, this message translates to:
  /// **'Un administrador está revisando tus datos. Te avisamos cuando puedas recibir ofertas.'**
  String get proveedorPerfilAdministradorEstaRevisandoTus;

  /// No description provided for @proveedorPerfilRecibisOfertasMientrasDure.
  ///
  /// In es, this message translates to:
  /// **'No recibes ofertas mientras dure la suspensión.'**
  String get proveedorPerfilRecibisOfertasMientrasDure;

  /// No description provided for @proveedorPerfilSolicitudAproboPodesCorregir.
  ///
  /// In es, this message translates to:
  /// **'Tu registro no se aprobó. Puedes corregir los datos y reenviarlo.'**
  String get proveedorPerfilSolicitudAproboPodesCorregir;

  /// No description provided for @proveedorPerfilMotivo.
  ///
  /// In es, this message translates to:
  /// **'Motivo: {motivo}'**
  String proveedorPerfilMotivo(String motivo);

  /// No description provided for @proveedorPerfilServicios.
  ///
  /// In es, this message translates to:
  /// **'SERVICIOS'**
  String get proveedorPerfilServicios;

  /// No description provided for @proveedorPerfilHectareas.
  ///
  /// In es, this message translates to:
  /// **'HECTÁREAS'**
  String get proveedorPerfilHectareas;

  /// No description provided for @proveedorPerfilCancelacion.
  ///
  /// In es, this message translates to:
  /// **'CANCELACIÓN'**
  String get proveedorPerfilCancelacion;

  /// No description provided for @proveedorPerfilVencio.
  ///
  /// In es, this message translates to:
  /// **'Venció el {vence}'**
  String proveedorPerfilVencio(String vence);

  /// No description provided for @proveedorPerfilVence.
  ///
  /// In es, this message translates to:
  /// **'Vence el {vence}'**
  String proveedorPerfilVence(String vence);

  /// No description provided for @proveedorPerfilCalificacionPromedioSobreCalificaciones.
  ///
  /// In es, this message translates to:
  /// **'Calificación promedio {promedio} de 5, sobre {total} calificaciones'**
  String proveedorPerfilCalificacionPromedioSobreCalificaciones(
    String promedio,
    int total,
  );

  /// No description provided for @proveedorPerfilCalificacion.
  ///
  /// In es, this message translates to:
  /// **'1 calificación'**
  String get proveedorPerfilCalificacion;

  /// No description provided for @proveedorPerfilCalificaciones.
  ///
  /// In es, this message translates to:
  /// **'{total} calificaciones'**
  String proveedorPerfilCalificaciones(int total);

  /// No description provided for @terrenosFotoDelTerreno.
  ///
  /// In es, this message translates to:
  /// **'Foto {numero} del terreno, {estado}'**
  String terrenosFotoDelTerreno(int numero, String estado);

  /// No description provided for @terrenosReintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get terrenosReintentar;

  /// No description provided for @terrenosQuitarFoto.
  ///
  /// In es, this message translates to:
  /// **'Quitar la foto {numero}'**
  String terrenosQuitarFoto(int numero);

  /// No description provided for @proveedorAccesoEntraCuenta.
  ///
  /// In es, this message translates to:
  /// **'Ingresa a tu cuenta'**
  String get proveedorAccesoEntraCuenta;

  /// No description provided for @proveedorAccesoConUsuarioContrasena.
  ///
  /// In es, this message translates to:
  /// **'Con tu usuario y tu contraseña.'**
  String get proveedorAccesoConUsuarioContrasena;

  /// No description provided for @proveedorAccesoUsuario.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get proveedorAccesoUsuario;

  /// No description provided for @proveedorAccesoEscribeUsuario.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu usuario.'**
  String get proveedorAccesoEscribeUsuario;

  /// No description provided for @proveedorAccesoContrasena.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get proveedorAccesoContrasena;

  /// No description provided for @proveedorAccesoEscribeContrasena.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu contraseña.'**
  String get proveedorAccesoEscribeContrasena;

  /// No description provided for @proveedorAccesoEntrar.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get proveedorAccesoEntrar;

  /// No description provided for @proveedorAccesoSoyPilotoQuieroRegistrarme.
  ///
  /// In es, this message translates to:
  /// **'Soy piloto y quiero registrarme'**
  String get proveedorAccesoSoyPilotoQuieroRegistrarme;

  /// No description provided for @proveedorAccesoDatosPersonales.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get proveedorAccesoDatosPersonales;

  /// No description provided for @proveedorAccesoLicencia.
  ///
  /// In es, this message translates to:
  /// **'Tu licencia'**
  String get proveedorAccesoLicencia;

  /// No description provided for @proveedorAccesoEquipo.
  ///
  /// In es, this message translates to:
  /// **'Tu equipo'**
  String get proveedorAccesoEquipo;

  /// No description provided for @proveedorAccesoFotosDelDron.
  ///
  /// In es, this message translates to:
  /// **'Fotos del dron'**
  String get proveedorAccesoFotosDelDron;

  /// No description provided for @proveedorAccesoAsiIdentificamosContactanLos.
  ///
  /// In es, this message translates to:
  /// **'Así te identificamos y te contactan los clientes.'**
  String get proveedorAccesoAsiIdentificamosContactanLos;

  /// No description provided for @proveedorAccesoAdministradorRevisaAntesQue.
  ///
  /// In es, this message translates to:
  /// **'Un administrador la revisa antes de que veas solicitudes.'**
  String get proveedorAccesoAdministradorRevisaAntesQue;

  /// No description provided for @proveedorAccesoDronVehiculoRevisamosAntes.
  ///
  /// In es, this message translates to:
  /// **'Tu dron es tu vehículo: lo revisamos antes de aprobarlo.'**
  String get proveedorAccesoDronVehiculoRevisamosAntes;

  /// No description provided for @proveedorAccesoFrontalLateralPlacaSerie.
  ///
  /// In es, this message translates to:
  /// **'Frontal, lateral y placa de serie.'**
  String get proveedorAccesoFrontalLateralPlacaSerie;

  /// No description provided for @proveedorAccesoEligeFecha.
  ///
  /// In es, this message translates to:
  /// **'Elige la fecha'**
  String get proveedorAccesoEligeFecha;

  /// No description provided for @proveedorAccesoEligeUnaFecha.
  ///
  /// In es, this message translates to:
  /// **'Elige una fecha.'**
  String get proveedorAccesoEligeUnaFecha;

  /// No description provided for @proveedorAccesoCarnetIdentidad.
  ///
  /// In es, this message translates to:
  /// **'Carnet de identidad'**
  String get proveedorAccesoCarnetIdentidad;

  /// No description provided for @proveedorAccesoFechaNacimiento.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get proveedorAccesoFechaNacimiento;

  /// No description provided for @proveedorAccesoTelefono.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get proveedorAccesoTelefono;

  /// No description provided for @proveedorAccesoConEsteUsuarioEntras.
  ///
  /// In es, this message translates to:
  /// **'Con este usuario ingresas a la app. No usa correo.'**
  String get proveedorAccesoConEsteUsuarioEntras;

  /// No description provided for @proveedorAccesoUsaMenosCaracteres.
  ///
  /// In es, this message translates to:
  /// **'Usa al menos 8 caracteres.'**
  String get proveedorAccesoUsaMenosCaracteres;

  /// No description provided for @proveedorAccesoNumeroLicenciaPiloto.
  ///
  /// In es, this message translates to:
  /// **'Número de licencia de piloto'**
  String get proveedorAccesoNumeroLicenciaPiloto;

  /// No description provided for @proveedorAccesoVence.
  ///
  /// In es, this message translates to:
  /// **'Vence el'**
  String get proveedorAccesoVence;

  /// No description provided for @proveedorAccesoCategoriaHabilitacion.
  ///
  /// In es, this message translates to:
  /// **'Categoría de habilitación'**
  String get proveedorAccesoCategoriaHabilitacion;

  /// No description provided for @proveedorAccesoComoFiguraLicencia.
  ///
  /// In es, this message translates to:
  /// **'Como figura en tu licencia.'**
  String get proveedorAccesoComoFiguraLicencia;

  /// No description provided for @proveedorAccesoRevisionTerminarRegistro.
  ///
  /// In es, this message translates to:
  /// **'En revisión al terminar el registro'**
  String get proveedorAccesoRevisionTerminarRegistro;

  /// No description provided for @proveedorAccesoNumeroSerie.
  ///
  /// In es, this message translates to:
  /// **'Número de serie'**
  String get proveedorAccesoNumeroSerie;

  /// No description provided for @proveedorAccesoAnoOpcional.
  ///
  /// In es, this message translates to:
  /// **'Año (opcional)'**
  String get proveedorAccesoAnoOpcional;

  /// No description provided for @proveedorAccesoCapacidadDelTanqueLitros.
  ///
  /// In es, this message translates to:
  /// **'Capacidad del tanque (litros)'**
  String get proveedorAccesoCapacidadDelTanqueLitros;

  /// No description provided for @proveedorAccesoAnchoPasadaMetros.
  ///
  /// In es, this message translates to:
  /// **'Ancho de pasada (metros)'**
  String get proveedorAccesoAnchoPasadaMetros;

  /// No description provided for @proveedorAccesoRegistroPiloto.
  ///
  /// In es, this message translates to:
  /// **'Registro de piloto'**
  String get proveedorAccesoRegistroPiloto;

  /// No description provided for @proveedorAccesoPasoAnterior.
  ///
  /// In es, this message translates to:
  /// **'Paso anterior'**
  String get proveedorAccesoPasoAnterior;

  /// No description provided for @proveedorAccesoContinuar.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get proveedorAccesoContinuar;

  /// No description provided for @proveedorAccesoCrearCuenta.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get proveedorAccesoCrearCuenta;

  /// No description provided for @proveedorAccesoReintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get proveedorAccesoReintentar;

  /// No description provided for @proveedorAccesoFaltanLasFotosObligatorias.
  ///
  /// In es, this message translates to:
  /// **'Faltan las fotos obligatorias: frontal, lateral y placa de serie.'**
  String get proveedorAccesoFaltanLasFotosObligatorias;

  /// No description provided for @proveedorAccesoPaso.
  ///
  /// In es, this message translates to:
  /// **'Paso {paso} de {total}, {titulo}'**
  String proveedorAccesoPaso(int paso, int total, String titulo);

  /// No description provided for @proveedorAccesoPaso2.
  ///
  /// In es, this message translates to:
  /// **'PASO {paso} DE {total}'**
  String proveedorAccesoPaso2(int paso, int total);

  /// No description provided for @proveedorAccesoAdministradorLasRevisaAntes.
  ///
  /// In es, this message translates to:
  /// **'Un administrador las revisa antes de aprobar tu dron. Cada foto se comprime sola a menos de 300 KB.'**
  String get proveedorAccesoAdministradorLasRevisaAntes;

  /// No description provided for @proveedorAccesoFoto.
  ///
  /// In es, this message translates to:
  /// **'Foto {etiqueta}'**
  String proveedorAccesoFoto(String etiqueta);

  /// No description provided for @proveedorAccesoLista.
  ///
  /// In es, this message translates to:
  /// **'Lista'**
  String get proveedorAccesoLista;

  /// No description provided for @proveedorAccesoFalta.
  ///
  /// In es, this message translates to:
  /// **'Falta'**
  String get proveedorAccesoFalta;

  /// No description provided for @proveedorAccesoFotoDelDron.
  ///
  /// In es, this message translates to:
  /// **'Foto {etiqueta} del dron'**
  String proveedorAccesoFotoDelDron(String etiqueta);

  /// No description provided for @proveedorAccesoTomarOtra.
  ///
  /// In es, this message translates to:
  /// **'Tomar otra'**
  String get proveedorAccesoTomarOtra;

  /// No description provided for @proveedorAccesoCamara.
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get proveedorAccesoCamara;

  /// No description provided for @proveedorAccesoGaleria.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get proveedorAccesoGaleria;

  /// No description provided for @proveedorAccesoQuitar.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get proveedorAccesoQuitar;

  /// No description provided for @proveedorAccesoRegistroEstaRevision.
  ///
  /// In es, this message translates to:
  /// **'Tu registro está en revisión'**
  String get proveedorAccesoRegistroEstaRevision;

  /// No description provided for @proveedorAccesoAdministradorRevisaLicenciaDron.
  ///
  /// In es, this message translates to:
  /// **'Un administrador revisa tu licencia y tu dron. Mientras tanto no verás solicitudes; te avisamos cuando estés aprobado.'**
  String get proveedorAccesoAdministradorRevisaLicenciaDron;

  /// No description provided for @proveedorAccesoEntrarApp.
  ///
  /// In es, this message translates to:
  /// **'Ingresar a la app'**
  String get proveedorAccesoEntrarApp;

  /// No description provided for @proveedorNegociacionLasSolicitudesLasOfertas.
  ///
  /// In es, this message translates to:
  /// **'las solicitudes y las ofertas necesitan red.'**
  String get proveedorNegociacionLasSolicitudesLasOfertas;

  /// No description provided for @proveedorNegociacionBuscarZonaLote.
  ///
  /// In es, this message translates to:
  /// **'Buscar zona o lote'**
  String get proveedorNegociacionBuscarZonaLote;

  /// No description provided for @proveedorNegociacionFiltrosHayFiltrosAplicados.
  ///
  /// In es, this message translates to:
  /// **'Filtros, hay filtros aplicados'**
  String get proveedorNegociacionFiltrosHayFiltrosAplicados;

  /// No description provided for @proveedorNegociacionFiltros.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get proveedorNegociacionFiltros;

  /// No description provided for @proveedorNegociacionCerca.
  ///
  /// In es, this message translates to:
  /// **'Cerca de mí'**
  String get proveedorNegociacionCerca;

  /// No description provided for @proveedorNegociacion50Ha.
  ///
  /// In es, this message translates to:
  /// **'+50 ha'**
  String get proveedorNegociacion50Ha;

  /// No description provided for @proveedorNegociacionVenceHoy.
  ///
  /// In es, this message translates to:
  /// **'Vence hoy'**
  String get proveedorNegociacionVenceHoy;

  /// No description provided for @proveedorNegociacionAbierta.
  ///
  /// In es, this message translates to:
  /// **'Abierta'**
  String get proveedorNegociacionAbierta;

  /// No description provided for @proveedorNegociacionSolicitudAbierta.
  ///
  /// In es, this message translates to:
  /// **'Solicitud abierta'**
  String get proveedorNegociacionSolicitudAbierta;

  /// No description provided for @proveedorNegociacionLote.
  ///
  /// In es, this message translates to:
  /// **'Lote de {cultivo}'**
  String proveedorNegociacionLote(String cultivo);

  /// No description provided for @proveedorNegociacionAceptarNecesitaRedReintenta.
  ///
  /// In es, this message translates to:
  /// **'aceptar necesita red. Vuelve a intentarlo con señal.'**
  String get proveedorNegociacionAceptarNecesitaRedReintenta;

  /// No description provided for @proveedorNegociacionOfertaEnviadaPorSigues.
  ///
  /// In es, this message translates to:
  /// **'Oferta enviada a {precioHa} por ha. La sigues en «Ofertas».'**
  String proveedorNegociacionOfertaEnviadaPorSigues(String precioHa);

  /// No description provided for @proveedorNegociacionNegociacionEstaSolicitudCerro.
  ///
  /// In es, this message translates to:
  /// **'Tu negociación en esta solicitud ya se cerró. No puedes ofertar de nuevo.'**
  String get proveedorNegociacionNegociacionEstaSolicitudCerro;

  /// No description provided for @proveedorNegociacionOfertasteAquiSigueNegociacion.
  ///
  /// In es, this message translates to:
  /// **'Ya ofertaste aquí. Sigue la negociación en «Ofertas».'**
  String get proveedorNegociacionOfertasteAquiSigueNegociacion;

  /// No description provided for @proveedorNegociacionContraofertar.
  ///
  /// In es, this message translates to:
  /// **'Contraofertar'**
  String get proveedorNegociacionContraofertar;

  /// No description provided for @proveedorNegociacionAceptar.
  ///
  /// In es, this message translates to:
  /// **'Aceptar {precioHaPropuesto}'**
  String proveedorNegociacionAceptar(String precioHaPropuesto);

  /// No description provided for @proveedorNegociacionVerDetalleDelLote.
  ///
  /// In es, this message translates to:
  /// **'Ver detalle del lote'**
  String get proveedorNegociacionVerDetalleDelLote;

  /// No description provided for @proveedorNegociacionSinConexion.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get proveedorNegociacionSinConexion;

  /// No description provided for @proveedorNegociacionMapaSolicitudesNecesitaSenal.
  ///
  /// In es, this message translates to:
  /// **'El mapa de solicitudes necesita señal para mostrar lo que hay disponible. Vuelve a intentarlo cuando tengas señal.'**
  String get proveedorNegociacionMapaSolicitudesNecesitaSenal;

  /// No description provided for @proveedorNegociacionPudimosCargarLasSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar las solicitudes'**
  String get proveedorNegociacionPudimosCargarLasSolicitudes;

  /// No description provided for @proveedorNegociacionIntentaNuevoMomento.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a intentarlo en un momento.'**
  String get proveedorNegociacionIntentaNuevoMomento;

  /// No description provided for @proveedorNegociacionNingunaSolicitudConEstos.
  ///
  /// In es, this message translates to:
  /// **'Ninguna solicitud con estos filtros'**
  String get proveedorNegociacionNingunaSolicitudConEstos;

  /// No description provided for @proveedorNegociacionHaySolicitudesAbiertasAhora.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes abiertas ahora'**
  String get proveedorNegociacionHaySolicitudesAbiertasAhora;

  /// No description provided for @proveedorNegociacionQuitaAlgunFiltroPrueba.
  ///
  /// In es, this message translates to:
  /// **'Quita algún filtro o prueba con otra zona.'**
  String get proveedorNegociacionQuitaAlgunFiltroPrueba;

  /// No description provided for @proveedorNegociacionActivaLosAvisosPerfil.
  ///
  /// In es, this message translates to:
  /// **'Activa las notificaciones en tu perfil y te avisamos cuando llegue una en tus zonas.'**
  String get proveedorNegociacionActivaLosAvisosPerfil;

  /// No description provided for @proveedorNegociacionCargando.
  ///
  /// In es, this message translates to:
  /// **'Cargando…'**
  String get proveedorNegociacionCargando;

  /// No description provided for @proveedorNegociacionVerMasSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Ver más solicitudes'**
  String get proveedorNegociacionVerMasSolicitudes;

  /// No description provided for @proveedorNegociacionDondeHayTrabajo.
  ///
  /// In es, this message translates to:
  /// **'Dónde hay trabajo'**
  String get proveedorNegociacionDondeHayTrabajo;

  /// No description provided for @proveedorNegociacionOtrasZonas.
  ///
  /// In es, this message translates to:
  /// **'Otras zonas'**
  String get proveedorNegociacionOtrasZonas;

  /// No description provided for @proveedorNegociacionSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'{nombre}: {cuantas} solicitudes, {ha}'**
  String proveedorNegociacionSolicitudes(String nombre, int cuantas, String ha);

  /// No description provided for @proveedorNegociacionHa.
  ///
  /// In es, this message translates to:
  /// **'{cuantas} · {ha} ha'**
  String proveedorNegociacionHa(int cuantas, String ha);

  /// No description provided for @proveedorNegociacionOfertaste.
  ///
  /// In es, this message translates to:
  /// **'Ofertaste'**
  String get proveedorNegociacionOfertaste;

  /// No description provided for @proveedorNegociacionCerrada.
  ///
  /// In es, this message translates to:
  /// **'Cerrada'**
  String get proveedorNegociacionCerrada;

  /// No description provided for @proveedorNegociacionTotal.
  ///
  /// In es, this message translates to:
  /// **'total {montoPropuesto}'**
  String proveedorNegociacionTotal(String montoPropuesto);

  /// No description provided for @proveedorNegociacionSinOfertas.
  ///
  /// In es, this message translates to:
  /// **'sin ofertas'**
  String get proveedorNegociacionSinOfertas;

  /// No description provided for @proveedorNegociacionFiltrarSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Filtrar solicitudes'**
  String get proveedorNegociacionFiltrarSolicitudes;

  /// No description provided for @proveedorNegociacionHectareasDesde.
  ///
  /// In es, this message translates to:
  /// **'Hectáreas desde'**
  String get proveedorNegociacionHectareasDesde;

  /// No description provided for @proveedorNegociacionHectareasHasta.
  ///
  /// In es, this message translates to:
  /// **'Hectáreas hasta'**
  String get proveedorNegociacionHectareasHasta;

  /// No description provided for @proveedorNegociacionPorDesde.
  ///
  /// In es, this message translates to:
  /// **'Bs por ha desde'**
  String get proveedorNegociacionPorDesde;

  /// No description provided for @proveedorNegociacionPorHasta.
  ///
  /// In es, this message translates to:
  /// **'Bs por ha hasta'**
  String get proveedorNegociacionPorHasta;

  /// No description provided for @proveedorNegociacionCultivo.
  ///
  /// In es, this message translates to:
  /// **'Cultivo'**
  String get proveedorNegociacionCultivo;

  /// No description provided for @proveedorNegociacionOrdenarPor.
  ///
  /// In es, this message translates to:
  /// **'Ordenar por'**
  String get proveedorNegociacionOrdenarPor;

  /// No description provided for @proveedorNegociacionVerSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Ver solicitudes'**
  String get proveedorNegociacionVerSolicitudes;

  /// No description provided for @proveedorNegociacionQuitarFiltros.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtros'**
  String get proveedorNegociacionQuitarFiltros;

  /// No description provided for @proveedorNegociacionAvisos.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get proveedorNegociacionAvisos;

  /// No description provided for @proveedorNegociacionPudimosCargarTusAvisos.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus notificaciones'**
  String get proveedorNegociacionPudimosCargarTusAvisos;

  /// No description provided for @proveedorNegociacionEligeQueQuieresEnterarte.
  ///
  /// In es, this message translates to:
  /// **'Elige de qué quieres recibir notificaciones. Las de adjudicación, cierre, cuenta y reclamos no se pueden desactivar.'**
  String get proveedorNegociacionEligeQueQuieresEnterarte;

  /// No description provided for @proveedorNegociacionNuevasSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Nuevas solicitudes'**
  String get proveedorNegociacionNuevasSolicitudes;

  /// No description provided for @proveedorNegociacionAvisamosCuandoClientePublica.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos cuando un cliente publica una solicitud en tus zonas. Así ofertas antes que los demás.'**
  String get proveedorNegociacionAvisamosCuandoClientePublica;

  /// No description provided for @proveedorNegociacionZonas.
  ///
  /// In es, this message translates to:
  /// **'Zonas'**
  String get proveedorNegociacionZonas;

  /// No description provided for @proveedorNegociacionTodasLasZonas.
  ///
  /// In es, this message translates to:
  /// **'Todas las zonas'**
  String get proveedorNegociacionTodasLasZonas;

  /// No description provided for @proveedorNegociacionHectareasMinimas.
  ///
  /// In es, this message translates to:
  /// **'Hectáreas mínimas'**
  String get proveedorNegociacionHectareasMinimas;

  /// No description provided for @proveedorNegociacionCualquiera.
  ///
  /// In es, this message translates to:
  /// **'Cualquiera'**
  String get proveedorNegociacionCualquiera;

  /// No description provided for @proveedorNegociacionHa2.
  ///
  /// In es, this message translates to:
  /// **'{ha} ha'**
  String proveedorNegociacionHa2(String ha);

  /// No description provided for @proveedorNegociacionOfertasContraofertas.
  ///
  /// In es, this message translates to:
  /// **'Ofertas y contraofertas'**
  String get proveedorNegociacionOfertasContraofertas;

  /// No description provided for @proveedorNegociacionCuandoClienteRespondeOferta.
  ///
  /// In es, this message translates to:
  /// **'Cuando el cliente responde a tu oferta.'**
  String get proveedorNegociacionCuandoClienteRespondeOferta;

  /// No description provided for @proveedorNegociacionMensajes.
  ///
  /// In es, this message translates to:
  /// **'Mensajes'**
  String get proveedorNegociacionMensajes;

  /// No description provided for @proveedorNegociacionCuandoClienteEscribeChat.
  ///
  /// In es, this message translates to:
  /// **'Cuando el cliente te escribe en el chat.'**
  String get proveedorNegociacionCuandoClienteEscribeChat;

  /// No description provided for @proveedorNegociacionCalificaciones.
  ///
  /// In es, this message translates to:
  /// **'Calificaciones'**
  String get proveedorNegociacionCalificaciones;

  /// No description provided for @proveedorNegociacionCuandoClienteCalifica.
  ///
  /// In es, this message translates to:
  /// **'Cuando un cliente te califica.'**
  String get proveedorNegociacionCuandoClienteCalifica;

  /// No description provided for @proveedorNegociacionSuperficie.
  ///
  /// In es, this message translates to:
  /// **'Superficie'**
  String get proveedorNegociacionSuperficie;

  /// No description provided for @proveedorNegociacionPrecioOfrecido.
  ///
  /// In es, this message translates to:
  /// **'Precio ofrecido'**
  String get proveedorNegociacionPrecioOfrecido;

  /// No description provided for @proveedorNegociacionSinConexionVesLos.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Ves los mensajes que ya recibimos; los nuevos llegan cuando vuelva la señal.'**
  String get proveedorNegociacionSinConexionVesLos;

  /// No description provided for @proveedorNegociacionTodaviaHayMensajes.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay mensajes'**
  String get proveedorNegociacionTodaviaHayMensajes;

  /// No description provided for @proveedorNegociacionEscribeleClienteParaCoordinar.
  ///
  /// In es, this message translates to:
  /// **'Escríbele al cliente para coordinar cómo llegar al lote y a qué hora.'**
  String get proveedorNegociacionEscribeleClienteParaCoordinar;

  /// No description provided for @proveedorNegociacionServicioCerroPuedesLeer.
  ///
  /// In es, this message translates to:
  /// **'El servicio ya cerró: puedes leer la conversación pero no escribir.'**
  String get proveedorNegociacionServicioCerroPuedesLeer;

  /// No description provided for @proveedorNegociacionEscribeMensaje.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje'**
  String get proveedorNegociacionEscribeMensaje;

  /// No description provided for @proveedorNegociacionEnviarMensaje.
  ///
  /// In es, this message translates to:
  /// **'Enviar mensaje'**
  String get proveedorNegociacionEnviarMensaje;

  /// No description provided for @proveedorNegociacionSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Solicitud'**
  String get proveedorNegociacionSolicitud;

  /// No description provided for @proveedorNegociacionPudimosAbrirSolicitud.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir la solicitud'**
  String get proveedorNegociacionPudimosAbrirSolicitud;

  /// No description provided for @proveedorNegociacionParaVerDetalleOfertar.
  ///
  /// In es, this message translates to:
  /// **'Para ver el detalle y ofertar necesitas señal. Vuelve a intentarlo cuando tengas señal.'**
  String get proveedorNegociacionParaVerDetalleOfertar;

  /// No description provided for @proveedorNegociacionClientePropone.
  ///
  /// In es, this message translates to:
  /// **'El cliente propone'**
  String get proveedorNegociacionClientePropone;

  /// No description provided for @proveedorNegociacionPor.
  ///
  /// In es, this message translates to:
  /// **'{precioHaPropuesto} por ha'**
  String proveedorNegociacionPor(String precioHaPropuesto);

  /// No description provided for @proveedorNegociacionTotalEstimado.
  ///
  /// In es, this message translates to:
  /// **'Total estimado {montoPropuesto}'**
  String proveedorNegociacionTotalEstimado(String montoPropuesto);

  /// No description provided for @proveedorNegociacionTodaviaTieneOfertasPrimero.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tiene ofertas: sé el primero.'**
  String get proveedorNegociacionTodaviaTieneOfertasPrimero;

  /// No description provided for @proveedorNegociacionTieneOfertaVigente.
  ///
  /// In es, this message translates to:
  /// **'Ya tiene 1 oferta vigente.'**
  String get proveedorNegociacionTieneOfertaVigente;

  /// No description provided for @proveedorNegociacionTieneOfertasVigentes.
  ///
  /// In es, this message translates to:
  /// **'Ya tiene {ofertasVigentes} ofertas vigentes.'**
  String proveedorNegociacionTieneOfertasVigentes(int ofertasVigentes);

  /// No description provided for @proveedorNegociacionContactoConClienteLlega.
  ///
  /// In es, this message translates to:
  /// **'Los datos de contacto del cliente se muestran solo si te elige. Hasta entonces no ves su nombre, teléfono ni dirección.'**
  String get proveedorNegociacionContactoConClienteLlega;

  /// No description provided for @proveedorNegociacionOfertaEnviadaPorVes.
  ///
  /// In es, this message translates to:
  /// **'Oferta enviada: {precioHa} por ha. La ves en «Mis ofertas».'**
  String proveedorNegociacionOfertaEnviadaPorVes(String precioHa);

  /// No description provided for @proveedorNegociacionFechaDeseada.
  ///
  /// In es, this message translates to:
  /// **'Fecha deseada'**
  String get proveedorNegociacionFechaDeseada;

  /// No description provided for @proveedorNegociacionAl.
  ///
  /// In es, this message translates to:
  /// **'{ventanaDesde} al {ventanaHasta}'**
  String proveedorNegociacionAl(String ventanaDesde, String ventanaHasta);

  /// No description provided for @proveedorNegociacionAplicacion.
  ///
  /// In es, this message translates to:
  /// **'Aplicación'**
  String get proveedorNegociacionAplicacion;

  /// No description provided for @proveedorNegociacionProducto.
  ///
  /// In es, this message translates to:
  /// **'Producto'**
  String get proveedorNegociacionProducto;

  /// No description provided for @proveedorNegociacionPoneProducto.
  ///
  /// In es, this message translates to:
  /// **'Quién aporta el producto'**
  String get proveedorNegociacionPoneProducto;

  /// No description provided for @proveedorNegociacionCliente.
  ///
  /// In es, this message translates to:
  /// **'El cliente'**
  String get proveedorNegociacionCliente;

  /// No description provided for @proveedorNegociacionTu.
  ///
  /// In es, this message translates to:
  /// **'Tú'**
  String get proveedorNegociacionTu;

  /// No description provided for @proveedorNegociacionUrgencia.
  ///
  /// In es, this message translates to:
  /// **'Urgencia'**
  String get proveedorNegociacionUrgencia;

  /// No description provided for @proveedorNegociacionPideAtencionPronta.
  ///
  /// In es, this message translates to:
  /// **'Lo necesita pronto'**
  String get proveedorNegociacionPideAtencionPronta;

  /// No description provided for @proveedorNegociacionEstadoDelTerreno.
  ///
  /// In es, this message translates to:
  /// **'Estado del terreno'**
  String get proveedorNegociacionEstadoDelTerreno;

  /// No description provided for @proveedorNegociacionAccesoDificil.
  ///
  /// In es, this message translates to:
  /// **'Acceso difícil'**
  String get proveedorNegociacionAccesoDificil;

  /// No description provided for @proveedorNegociacionAccesoNormal.
  ///
  /// In es, this message translates to:
  /// **'Acceso normal'**
  String get proveedorNegociacionAccesoNormal;

  /// No description provided for @proveedorNegociacionComoLlegar.
  ///
  /// In es, this message translates to:
  /// **'Cómo llegar'**
  String get proveedorNegociacionComoLlegar;

  /// No description provided for @proveedorNegociacionCuidar.
  ///
  /// In es, this message translates to:
  /// **'Colindantes sensibles'**
  String get proveedorNegociacionCuidar;

  /// No description provided for @proveedorNegociacionObservaciones.
  ///
  /// In es, this message translates to:
  /// **'Observaciones'**
  String get proveedorNegociacionObservaciones;

  /// No description provided for @proveedorNegociacionAbiertaHasta.
  ///
  /// In es, this message translates to:
  /// **'Abierta hasta'**
  String get proveedorNegociacionAbiertaHasta;

  /// No description provided for @proveedorNegociacionAceptarPor.
  ///
  /// In es, this message translates to:
  /// **'Aceptar {precioHaPropuesto} por ha'**
  String proveedorNegociacionAceptarPor(String precioHaPropuesto);

  /// No description provided for @proveedorNegociacionContraofertarPrecio.
  ///
  /// In es, this message translates to:
  /// **'Contraofertar mi precio'**
  String get proveedorNegociacionContraofertarPrecio;

  /// No description provided for @proveedorNegociacionEscribePrecioMayorCero.
  ///
  /// In es, this message translates to:
  /// **'Escribe un precio mayor a cero.'**
  String get proveedorNegociacionEscribePrecioMayorCero;

  /// No description provided for @proveedorNegociacionMismoPrecioCambialoAcepta.
  ///
  /// In es, this message translates to:
  /// **'Es el mismo precio. Cámbialo o acepta el actual.'**
  String get proveedorNegociacionMismoPrecioCambialoAcepta;

  /// No description provided for @proveedorNegociacionPor2.
  ///
  /// In es, this message translates to:
  /// **'{etiquetaReferencia}: {precioReferencia} por ha'**
  String proveedorNegociacionPor2(
    String etiquetaReferencia,
    String precioReferencia,
  );

  /// No description provided for @proveedorNegociacionPrecioPorHectarea.
  ///
  /// In es, this message translates to:
  /// **'Tu precio por hectárea (Bs)'**
  String get proveedorNegociacionPrecioPorHectarea;

  /// No description provided for @proveedorNegociacionTotalApareceCuandoEscribes.
  ///
  /// In es, this message translates to:
  /// **'El total aparece cuando escribes el precio.'**
  String get proveedorNegociacionTotalApareceCuandoEscribes;

  /// No description provided for @proveedorNegociacionMensajeParaClienteOpcional.
  ///
  /// In es, this message translates to:
  /// **'Mensaje para el cliente (opcional)'**
  String get proveedorNegociacionMensajeParaClienteOpcional;

  /// No description provided for @proveedorNegociacionTusOfertasVenCon.
  ///
  /// In es, this message translates to:
  /// **'tus ofertas se ven con red.'**
  String get proveedorNegociacionTusOfertasVenCon;

  /// No description provided for @proveedorNegociacionQueVesPuedeEstar.
  ///
  /// In es, this message translates to:
  /// **'lo que ves puede estar desactualizado.'**
  String get proveedorNegociacionQueVesPuedeEstar;

  /// No description provided for @proveedorNegociacionMisOfertas.
  ///
  /// In es, this message translates to:
  /// **'Mis ofertas'**
  String get proveedorNegociacionMisOfertas;

  /// No description provided for @proveedorNegociacionActivas.
  ///
  /// In es, this message translates to:
  /// **'Activas'**
  String get proveedorNegociacionActivas;

  /// No description provided for @proveedorNegociacionGanadas.
  ///
  /// In es, this message translates to:
  /// **'Ganadas'**
  String get proveedorNegociacionGanadas;

  /// No description provided for @proveedorNegociacionCerradas.
  ///
  /// In es, this message translates to:
  /// **'Cerradas'**
  String get proveedorNegociacionCerradas;

  /// No description provided for @proveedorNegociacionParaVerResponderTus.
  ///
  /// In es, this message translates to:
  /// **'Para ver y responder tus ofertas necesitas señal. Vuelve a intentarlo cuando tengas señal.'**
  String get proveedorNegociacionParaVerResponderTus;

  /// No description provided for @proveedorNegociacionPudimosCargarTusOfertas.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus ofertas'**
  String get proveedorNegociacionPudimosCargarTusOfertas;

  /// No description provided for @proveedorNegociacionTodaviaHicisteOfertas.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hiciste ofertas'**
  String get proveedorNegociacionTodaviaHicisteOfertas;

  /// No description provided for @proveedorNegociacionAbreUnaSolicitudMapa.
  ///
  /// In es, this message translates to:
  /// **'Abre una solicitud en el mapa y acepta el precio del cliente o propón el tuyo.'**
  String get proveedorNegociacionAbreUnaSolicitudMapa;

  /// No description provided for @proveedorNegociacionTienesNegociacionesActivas.
  ///
  /// In es, this message translates to:
  /// **'No tienes negociaciones activas'**
  String get proveedorNegociacionTienesNegociacionesActivas;

  /// No description provided for @proveedorNegociacionCuandoOfertesMapaConversacion.
  ///
  /// In es, this message translates to:
  /// **'Cuando ofertes en el mapa, la conversación aparece aquí.'**
  String get proveedorNegociacionCuandoOfertesMapaConversacion;

  /// No description provided for @proveedorNegociacionAunGanasteNinguna.
  ///
  /// In es, this message translates to:
  /// **'Aún no ganaste ninguna'**
  String get proveedorNegociacionAunGanasteNinguna;

  /// No description provided for @proveedorNegociacionLasSolicitudesLasQue.
  ///
  /// In es, this message translates to:
  /// **'Las solicitudes en las que el cliente te elige quedan aquí.'**
  String get proveedorNegociacionLasSolicitudesLasQue;

  /// No description provided for @proveedorNegociacionNadaCerradoTodavia.
  ///
  /// In es, this message translates to:
  /// **'Nada cerrado todavía'**
  String get proveedorNegociacionNadaCerradoTodavia;

  /// No description provided for @proveedorNegociacionLasOfertasRechazadasRetiradas.
  ///
  /// In es, this message translates to:
  /// **'Las ofertas rechazadas, retiradas o vencidas se guardan aquí.'**
  String get proveedorNegociacionLasOfertasRechazadasRetiradas;

  /// No description provided for @proveedorNegociacionTurno.
  ///
  /// In es, this message translates to:
  /// **'Tu turno · R{rondaQueSigue}/5'**
  String proveedorNegociacionTurno(int rondaQueSigue);

  /// No description provided for @proveedorNegociacionEsperando.
  ///
  /// In es, this message translates to:
  /// **'Esperando · R{rondaQueSigue}/5'**
  String proveedorNegociacionEsperando(int rondaQueSigue);

  /// No description provided for @proveedorNegociacionAceptada.
  ///
  /// In es, this message translates to:
  /// **'Aceptada'**
  String get proveedorNegociacionAceptada;

  /// No description provided for @proveedorNegociacionRechazada.
  ///
  /// In es, this message translates to:
  /// **'Rechazada'**
  String get proveedorNegociacionRechazada;

  /// No description provided for @proveedorNegociacionSolicitud2.
  ///
  /// In es, this message translates to:
  /// **'Solicitud {solicitudId}'**
  String proveedorNegociacionSolicitud2(int solicitudId);

  /// No description provided for @proveedorNegociacionHa3.
  ///
  /// In es, this message translates to:
  /// **'{hectareas} ha'**
  String proveedorNegociacionHa3(String hectareas);

  /// No description provided for @proveedorNegociacionCliente2.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get proveedorNegociacionCliente2;

  /// No description provided for @proveedorNegociacionVenceLas.
  ///
  /// In es, this message translates to:
  /// **'Vence {venceEn} a las {venceEn2}'**
  String proveedorNegociacionVenceLas(String venceEn, String venceEn2);

  /// No description provided for @proveedorNegociacionOfertarNecesitaRedPrecio.
  ///
  /// In es, this message translates to:
  /// **'ofertar necesita red. Tu precio se conserva y no se envió nada.'**
  String get proveedorNegociacionOfertarNecesitaRedPrecio;

  /// No description provided for @proveedorNegociacionVolver.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get proveedorNegociacionVolver;

  /// No description provided for @proveedorNegociacionNegociacionConCliente.
  ///
  /// In es, this message translates to:
  /// **'Negociación con el cliente'**
  String get proveedorNegociacionNegociacionConCliente;

  /// No description provided for @proveedorNegociacionRonda.
  ///
  /// In es, this message translates to:
  /// **'Ronda {ronda} de {total}'**
  String proveedorNegociacionRonda(int ronda, int total);

  /// No description provided for @proveedorNegociacionAbrirNegociacionNecesitaRed.
  ///
  /// In es, this message translates to:
  /// **'abrir la negociación necesita red.'**
  String get proveedorNegociacionAbrirNegociacionNecesitaRed;

  /// No description provided for @proveedorNegociacionNegociarEntreDosPersonas.
  ///
  /// In es, this message translates to:
  /// **'Negociar necesita señal. No se perdió nada: vuelve a intentarlo cuando tengas señal.'**
  String get proveedorNegociacionNegociarEntreDosPersonas;

  /// No description provided for @proveedorNegociacionPudimosAbrirNegociacion.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir la negociación'**
  String get proveedorNegociacionPudimosAbrirNegociacion;

  /// No description provided for @proveedorNegociacionTu2.
  ///
  /// In es, this message translates to:
  /// **'TÚ'**
  String get proveedorNegociacionTu2;

  /// No description provided for @proveedorNegociacionPublicado.
  ///
  /// In es, this message translates to:
  /// **'Publicado'**
  String get proveedorNegociacionPublicado;

  /// No description provided for @proveedorNegociacionAceptasteSolicitudTuyaContacto.
  ///
  /// In es, this message translates to:
  /// **'Aceptaste la oferta: la solicitud es tuya. Los datos del cliente aparecen en «Servicio».'**
  String get proveedorNegociacionAceptasteSolicitudTuyaContacto;

  /// No description provided for @proveedorNegociacionRechazasteOfertaNegociacionCerro.
  ///
  /// In es, this message translates to:
  /// **'Rechazaste la oferta. La negociación se cerró.'**
  String get proveedorNegociacionRechazasteOfertaNegociacionCerro;

  /// No description provided for @proveedorNegociacionRetirasteOfertaNegociacionCerro.
  ///
  /// In es, this message translates to:
  /// **'Retiraste tu oferta. La negociación se cerró.'**
  String get proveedorNegociacionRetirasteOfertaNegociacionCerro;

  /// No description provided for @proveedorNegociacionEsperandoClienteAvisamosCuando.
  ///
  /// In es, this message translates to:
  /// **'Esperando al cliente · te avisamos cuando responda'**
  String get proveedorNegociacionEsperandoClienteAvisamosCuando;

  /// No description provided for @proveedorNegociacionEstaNegociacionCerroPuede.
  ///
  /// In es, this message translates to:
  /// **'Esta negociación ya se cerró. No se puede ofertar de nuevo.'**
  String get proveedorNegociacionEstaNegociacionCerroPuede;

  /// No description provided for @proveedorNegociacionTurnoRondaFinalAceptas.
  ///
  /// In es, this message translates to:
  /// **'Tu turno · es la ronda final: aceptas o la negociación se cierra'**
  String get proveedorNegociacionTurnoRondaFinalAceptas;

  /// No description provided for @proveedorNegociacionTurnoDespuesSoloQueda.
  ///
  /// In es, this message translates to:
  /// **'Tu turno · después solo queda la ronda {rondasMaximas}'**
  String proveedorNegociacionTurnoDespuesSoloQueda(int rondasMaximas);

  /// No description provided for @proveedorNegociacionTurnoRonda.
  ///
  /// In es, this message translates to:
  /// **'Tu turno · ronda {ronda} de {rondasMaximas}'**
  String proveedorNegociacionTurnoRonda(int ronda, int rondasMaximas);

  /// No description provided for @proveedorNegociacionVerMisOfertas.
  ///
  /// In es, this message translates to:
  /// **'Ver mis ofertas'**
  String get proveedorNegociacionVerMisOfertas;

  /// No description provided for @proveedorNegociacionRetirarOferta.
  ///
  /// In es, this message translates to:
  /// **'Retirar mi oferta'**
  String get proveedorNegociacionRetirarOferta;

  /// No description provided for @proveedorNegociacionPrecioPorHectarea2.
  ///
  /// In es, this message translates to:
  /// **'Tu precio por hectárea'**
  String get proveedorNegociacionPrecioPorHectarea2;

  /// No description provided for @proveedorNegociacionTotal2.
  ///
  /// In es, this message translates to:
  /// **'total {total}'**
  String proveedorNegociacionTotal2(String total);

  /// No description provided for @proveedorNegociacionAceptar2.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get proveedorNegociacionAceptar2;

  /// No description provided for @proveedorNegociacionAceptar3.
  ///
  /// In es, this message translates to:
  /// **'Aceptar {aceptable}'**
  String proveedorNegociacionAceptar3(String aceptable);

  /// No description provided for @proveedorNegociacionReintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar {precio}'**
  String proveedorNegociacionReintentar(int precio);

  /// No description provided for @proveedorNegociacionEnviar.
  ///
  /// In es, this message translates to:
  /// **'Enviar {precio}'**
  String proveedorNegociacionEnviar(int precio);

  /// No description provided for @proveedorNegociacionRechazar.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get proveedorNegociacionRechazar;

  /// No description provided for @proveedorEjecucionServicio.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get proveedorEjecucionServicio;

  /// No description provided for @proveedorEjecucionPudimosLeerTusServicios.
  ///
  /// In es, this message translates to:
  /// **'No pudimos leer tus servicios'**
  String get proveedorEjecucionPudimosLeerTusServicios;

  /// No description provided for @proveedorEjecucionCierraAbreAppQue.
  ///
  /// In es, this message translates to:
  /// **'Cierra la app y vuelve a abrirla. Lo que guardaste sigue aquí.'**
  String get proveedorEjecucionCierraAbreAppQue;

  /// No description provided for @proveedorEjecucionTodaviaTienesServicioAdjudicado.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes un servicio adjudicado'**
  String get proveedorEjecucionTodaviaTienesServicioAdjudicado;

  /// No description provided for @proveedorEjecucionCuandoClienteElijaServicio.
  ///
  /// In es, this message translates to:
  /// **'Cuando un cliente te elija, el servicio aparece aquí con sus datos de contacto. Desliza hacia abajo para actualizar.'**
  String get proveedorEjecucionCuandoClienteElijaServicio;

  /// No description provided for @proveedorEjecucionSinAvanceMarcado.
  ///
  /// In es, this message translates to:
  /// **'Sin avance marcado'**
  String get proveedorEjecucionSinAvanceMarcado;

  /// No description provided for @proveedorEjecucionRegistroRechazado.
  ///
  /// In es, this message translates to:
  /// **'1 envío rechazado'**
  String get proveedorEjecucionRegistroRechazado;

  /// No description provided for @proveedorEjecucionRegistrosRechazados.
  ///
  /// In es, this message translates to:
  /// **'{rechazos} envíos rechazados'**
  String proveedorEjecucionRegistrosRechazados(int rechazos);

  /// No description provided for @proveedorEjecucionCosaPorSubir.
  ///
  /// In es, this message translates to:
  /// **'1 envío por subir'**
  String get proveedorEjecucionCosaPorSubir;

  /// No description provided for @proveedorEjecucionCosasPorSubir.
  ///
  /// In es, this message translates to:
  /// **'{pendientes} envíos por subir'**
  String proveedorEjecucionCosasPorSubir(int pendientes);

  /// No description provided for @proveedorEjecucionChatConCliente.
  ///
  /// In es, this message translates to:
  /// **'Chat con el cliente'**
  String get proveedorEjecucionChatConCliente;

  /// No description provided for @proveedorEjecucionEncontramosEsteServicio.
  ///
  /// In es, this message translates to:
  /// **'No encontramos este servicio'**
  String get proveedorEjecucionEncontramosEsteServicio;

  /// No description provided for @proveedorEjecucionPuedeQueClienteHaya.
  ///
  /// In es, this message translates to:
  /// **'Puede que el cliente lo haya cancelado. Vuelve a la lista y actualiza.'**
  String get proveedorEjecucionPuedeQueClienteHaya;

  /// No description provided for @proveedorEjecucionTusFotosAvancesQuedan.
  ///
  /// In es, this message translates to:
  /// **'tus fotos y avances quedan guardados y se suben solos.'**
  String get proveedorEjecucionTusFotosAvancesQuedan;

  /// No description provided for @proveedorEjecucionServidorAceptoAlgoQue.
  ///
  /// In es, this message translates to:
  /// **'No pudimos aceptar algo de lo que guardaste. Avisa a soporte desde tu perfil.'**
  String get proveedorEjecucionServidorAceptoAlgoQue;

  /// No description provided for @proveedorEjecucionEstaGuardadoEsteCelular.
  ///
  /// In es, this message translates to:
  /// **'Está guardado en este teléfono y se sube solo cuando vuelva la señal.'**
  String get proveedorEjecucionEstaGuardadoEsteCelular;

  /// No description provided for @proveedorEjecucionAvance.
  ///
  /// In es, this message translates to:
  /// **'Avance'**
  String get proveedorEjecucionAvance;

  /// No description provided for @proveedorEjecucionAvancePorCiento.
  ///
  /// In es, this message translates to:
  /// **'Avance {porcentaje} por ciento'**
  String proveedorEjecucionAvancePorCiento(String porcentaje);

  /// No description provided for @proveedorEjecucionTodaviaMarcasteAvance.
  ///
  /// In es, this message translates to:
  /// **'Todavía no marcaste avance.'**
  String get proveedorEjecucionTodaviaMarcasteAvance;

  /// No description provided for @proveedorEjecucionSinFotosAvance.
  ///
  /// In es, this message translates to:
  /// **'Sin fotos de avance'**
  String get proveedorEjecucionSinFotosAvance;

  /// No description provided for @proveedorEjecucionFotoAvance.
  ///
  /// In es, this message translates to:
  /// **'1 foto de avance'**
  String get proveedorEjecucionFotoAvance;

  /// No description provided for @proveedorEjecucionFotosAvance.
  ///
  /// In es, this message translates to:
  /// **'{fotosTotal} fotos de avance'**
  String proveedorEjecucionFotosAvance(int fotosTotal);

  /// No description provided for @proveedorEjecucionMarcarEjecucion.
  ///
  /// In es, this message translates to:
  /// **'Marcar en ejecución'**
  String get proveedorEjecucionMarcarEjecucion;

  /// No description provided for @proveedorEjecucionMarcaloCuandoEmpiecesLote.
  ///
  /// In es, this message translates to:
  /// **'Márcalo cuando empieces en el lote. El cliente recibe una notificación.'**
  String get proveedorEjecucionMarcaloCuandoEmpiecesLote;

  /// No description provided for @proveedorEjecucionSubirFotoAvance.
  ///
  /// In es, this message translates to:
  /// **'Subir foto de avance'**
  String get proveedorEjecucionSubirFotoAvance;

  /// No description provided for @proveedorEjecucionMarcarAvance.
  ///
  /// In es, this message translates to:
  /// **'Marcar avance'**
  String get proveedorEjecucionMarcarAvance;

  /// No description provided for @proveedorEjecucionFinalizarServicio.
  ///
  /// In es, this message translates to:
  /// **'Finalizar servicio'**
  String get proveedorEjecucionFinalizarServicio;

  /// No description provided for @proveedorEjecucionEscribeNumeroMayorCero.
  ///
  /// In es, this message translates to:
  /// **'Escribe un número mayor a cero.'**
  String get proveedorEjecucionEscribeNumeroMayorCero;

  /// No description provided for @proveedorEjecucionPuedePasarLasHectareas.
  ///
  /// In es, this message translates to:
  /// **'No puede ser mayor que las hectáreas del servicio.'**
  String get proveedorEjecucionPuedePasarLasHectareas;

  /// No description provided for @proveedorEjecucionPuedePasar100.
  ///
  /// In es, this message translates to:
  /// **'No puede ser mayor que 100 %.'**
  String get proveedorEjecucionPuedePasar100;

  /// No description provided for @proveedorEjecucionHectareas.
  ///
  /// In es, this message translates to:
  /// **'Hectáreas'**
  String get proveedorEjecucionHectareas;

  /// No description provided for @proveedorEjecucionPorcentaje.
  ///
  /// In es, this message translates to:
  /// **'Porcentaje'**
  String get proveedorEjecucionPorcentaje;

  /// No description provided for @proveedorEjecucionHectareasEjecutadasTotal.
  ///
  /// In es, this message translates to:
  /// **'Hectáreas ejecutadas en total'**
  String get proveedorEjecucionHectareasEjecutadasTotal;

  /// No description provided for @proveedorEjecucionPorcentajeEjecutadoTotal.
  ///
  /// In es, this message translates to:
  /// **'Porcentaje ejecutado en total'**
  String get proveedorEjecucionPorcentajeEjecutadoTotal;

  /// No description provided for @proveedorEjecucionMenosQueUltimoAvance.
  ///
  /// In es, this message translates to:
  /// **'Es menos que tu último avance. Cuéntanos por qué lo corriges.'**
  String get proveedorEjecucionMenosQueUltimoAvance;

  /// No description provided for @proveedorEjecucionMotivoCorreccion.
  ///
  /// In es, this message translates to:
  /// **'Motivo de la corrección'**
  String get proveedorEjecucionMotivoCorreccion;

  /// No description provided for @proveedorEjecucionMotivoObligatorio.
  ///
  /// In es, this message translates to:
  /// **'El motivo es obligatorio.'**
  String get proveedorEjecucionMotivoObligatorio;

  /// No description provided for @proveedorEjecucionNotaOpcional.
  ///
  /// In es, this message translates to:
  /// **'Nota (opcional)'**
  String get proveedorEjecucionNotaOpcional;

  /// No description provided for @proveedorEjecucionGuardarAvance.
  ///
  /// In es, this message translates to:
  /// **'Guardar avance'**
  String get proveedorEjecucionGuardarAvance;

  /// No description provided for @proveedorEjecucionEscribeLasHectareasRealmente.
  ///
  /// In es, this message translates to:
  /// **'Escribe las hectáreas realmente ejecutadas.'**
  String get proveedorEjecucionEscribeLasHectareasRealmente;

  /// No description provided for @proveedorEjecucionFinalizarServicio2.
  ///
  /// In es, this message translates to:
  /// **'Finalizar el servicio'**
  String get proveedorEjecucionFinalizarServicio2;

  /// No description provided for @proveedorEjecucionConfirmaLasHectareasQue.
  ///
  /// In es, this message translates to:
  /// **'Confirma las hectáreas que realmente ejecutaste. El precio final es hectáreas ejecutadas por el precio acordado.'**
  String get proveedorEjecucionConfirmaLasHectareasQue;

  /// No description provided for @proveedorEjecucionHectareasEjecutadas.
  ///
  /// In es, this message translates to:
  /// **'Hectáreas ejecutadas'**
  String get proveedorEjecucionHectareasEjecutadas;

  /// No description provided for @proveedorEjecucionPagar.
  ///
  /// In es, this message translates to:
  /// **'A pagar: {monto} ({ha} × {precioHaAcordado})'**
  String proveedorEjecucionPagar(
    String monto,
    String ha,
    String precioHaAcordado,
  );

  /// No description provided for @proveedorEjecucionFinalizar.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get proveedorEjecucionFinalizar;

  /// No description provided for @proveedorEjecucionPrecioFinalPagar.
  ///
  /// In es, this message translates to:
  /// **'Precio final a pagar'**
  String get proveedorEjecucionPrecioFinalPagar;

  /// No description provided for @proveedorEjecucionPrecioEstimado.
  ///
  /// In es, this message translates to:
  /// **'Precio estimado'**
  String get proveedorEjecucionPrecioEstimado;

  /// No description provided for @proveedorEjecucionCalculando.
  ///
  /// In es, this message translates to:
  /// **'Calculando…'**
  String get proveedorEjecucionCalculando;

  /// No description provided for @proveedorEjecucionHectareasEjecutadasPorPrecio.
  ///
  /// In es, this message translates to:
  /// **'Hectáreas ejecutadas por el precio acordado.'**
  String get proveedorEjecucionHectareasEjecutadasPorPrecio;

  /// No description provided for @proveedorEjecucionClientePagaDirectamenteApp.
  ///
  /// In es, this message translates to:
  /// **'El cliente te paga directamente: la app no cobra.'**
  String get proveedorEjecucionClientePagaDirectamenteApp;

  /// No description provided for @proveedorEjecucionUnaEstimacionHechaEste.
  ///
  /// In es, this message translates to:
  /// **'Es una estimación hecha en este teléfono. Agrocom confirma el monto final cuando haya señal.'**
  String get proveedorEjecucionUnaEstimacionHechaEste;

  /// No description provided for @proveedorEjecucionCompartiendoUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Compartiendo tu ubicación'**
  String get proveedorEjecucionCompartiendoUbicacion;

  /// No description provided for @proveedorEjecucionSinSenalReanudaSola.
  ///
  /// In es, this message translates to:
  /// **'Sin señal: se reanuda sola. Nada se guarda en el teléfono.'**
  String get proveedorEjecucionSinSenalReanudaSola;

  /// No description provided for @proveedorEjecucionClienteUltimaPosicionMapa.
  ///
  /// In es, this message translates to:
  /// **'El cliente ve tu última posición en un mapa mientras esta pantalla esté abierta.'**
  String get proveedorEjecucionClienteUltimaPosicionMapa;

  /// No description provided for @proveedorEjecucionUbicacionBloqueada.
  ///
  /// In es, this message translates to:
  /// **'Ubicación bloqueada'**
  String get proveedorEjecucionUbicacionBloqueada;

  /// No description provided for @proveedorEjecucionActivalaDesdeLosAjustes.
  ///
  /// In es, this message translates to:
  /// **'Actívala desde los ajustes del teléfono si quieres que el cliente vea dónde estás.'**
  String get proveedorEjecucionActivalaDesdeLosAjustes;

  /// No description provided for @proveedorEjecucionUbicacionDelTelefonoEsta.
  ///
  /// In es, this message translates to:
  /// **'La ubicación del teléfono está apagada'**
  String get proveedorEjecucionUbicacionDelTelefonoEsta;

  /// No description provided for @proveedorEjecucionEnciendelaParaQueCliente.
  ///
  /// In es, this message translates to:
  /// **'Enciéndela para que el cliente vea tu última posición.'**
  String get proveedorEjecucionEnciendelaParaQueCliente;

  /// No description provided for @proveedorEjecucionDileClienteDondeEstas.
  ///
  /// In es, this message translates to:
  /// **'Dile al cliente dónde estás'**
  String get proveedorEjecucionDileClienteDondeEstas;

  /// No description provided for @proveedorEjecucionAceptasCompartimosUltimaPosicion.
  ///
  /// In es, this message translates to:
  /// **'Si lo aceptas, compartimos tu última posición con el cliente mientras el servicio esté en ejecución y esta pantalla abierta. Se deja de compartir al cerrarla o al finalizar. No guardamos tu recorrido.'**
  String get proveedorEjecucionAceptasCompartimosUltimaPosicion;

  /// No description provided for @proveedorEjecucionCompartirUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Compartir mi ubicación'**
  String get proveedorEjecucionCompartirUbicacion;

  /// No description provided for @proveedorEjecucionUltimaVez.
  ///
  /// In es, this message translates to:
  /// **'Última vez {ultimaEn}'**
  String proveedorEjecucionUltimaVez(String ultimaEn);

  /// No description provided for @proveedorEjecucionPrecioAcordado.
  ///
  /// In es, this message translates to:
  /// **'Precio acordado'**
  String get proveedorEjecucionPrecioAcordado;

  /// No description provided for @proveedorEjecucionPor.
  ///
  /// In es, this message translates to:
  /// **'{precioHaAcordado} por ha'**
  String proveedorEjecucionPor(String precioHaAcordado);

  /// No description provided for @proveedorEjecucionFecha.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get proveedorEjecucionFecha;

  /// No description provided for @proveedorEjecucionAl.
  ///
  /// In es, this message translates to:
  /// **'{ventanaDesde} al {ventanaHasta}'**
  String proveedorEjecucionAl(String ventanaDesde, String ventanaHasta);

  /// No description provided for @proveedorEjecucionProducto.
  ///
  /// In es, this message translates to:
  /// **'Producto'**
  String get proveedorEjecucionProducto;

  /// No description provided for @proveedorEjecucionPoneProducto.
  ///
  /// In es, this message translates to:
  /// **'Quién aporta el producto'**
  String get proveedorEjecucionPoneProducto;

  /// No description provided for @proveedorEjecucionCliente.
  ///
  /// In es, this message translates to:
  /// **'El cliente'**
  String get proveedorEjecucionCliente;

  /// No description provided for @proveedorEjecucionTu.
  ///
  /// In es, this message translates to:
  /// **'Tú'**
  String get proveedorEjecucionTu;

  /// No description provided for @proveedorEjecucionEstadoDelTerreno.
  ///
  /// In es, this message translates to:
  /// **'Estado del terreno'**
  String get proveedorEjecucionEstadoDelTerreno;

  /// No description provided for @proveedorEjecucionAccesoDificil.
  ///
  /// In es, this message translates to:
  /// **'Acceso difícil'**
  String get proveedorEjecucionAccesoDificil;

  /// No description provided for @proveedorEjecucionAccesoNormal.
  ///
  /// In es, this message translates to:
  /// **'Acceso normal'**
  String get proveedorEjecucionAccesoNormal;

  /// No description provided for @proveedorEjecucionComoLlegar.
  ///
  /// In es, this message translates to:
  /// **'Cómo llegar'**
  String get proveedorEjecucionComoLlegar;

  /// No description provided for @proveedorEjecucionCuidar.
  ///
  /// In es, this message translates to:
  /// **'Colindantes sensibles'**
  String get proveedorEjecucionCuidar;

  /// No description provided for @proveedorEjecucionObservaciones.
  ///
  /// In es, this message translates to:
  /// **'Observaciones'**
  String get proveedorEjecucionObservaciones;

  /// No description provided for @proveedorEjecucionMarcasteServicioEjecucion.
  ///
  /// In es, this message translates to:
  /// **'Marcaste el servicio en ejecución.'**
  String get proveedorEjecucionMarcasteServicioEjecucion;

  /// No description provided for @proveedorEjecucionAvanceGuardado.
  ///
  /// In es, this message translates to:
  /// **'Avance guardado.'**
  String get proveedorEjecucionAvanceGuardado;

  /// No description provided for @proveedorEjecucionServicioFinalizadoPrecioPagar.
  ///
  /// In es, this message translates to:
  /// **'Servicio finalizado. El precio a pagar queda a la vista.'**
  String get proveedorEjecucionServicioFinalizadoPrecioPagar;

  /// No description provided for @proveedorEjecucionFotoGuardadaSubeSola.
  ///
  /// In es, this message translates to:
  /// **'Foto guardada. Se sube sola cuando haya señal.'**
  String get proveedorEjecucionFotoGuardadaSubeSola;

  /// No description provided for @proveedorEjecucionPudimosAchicarFotoSuficiente.
  ///
  /// In es, this message translates to:
  /// **'No pudimos reducir el tamaño de la foto lo suficiente. Toma otra con menos detalle.'**
  String get proveedorEjecucionPudimosAchicarFotoSuficiente;

  /// No description provided for @proveedorEjecucionPudimosGuardarloIntentaNuevo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardarlo. Vuelve a intentarlo.'**
  String get proveedorEjecucionPudimosGuardarloIntentaNuevo;

  /// No description provided for @proveedorAccesoPudimosAchicarEsaFoto.
  ///
  /// In es, this message translates to:
  /// **'No pudimos reducir el tamaño de esa foto. Prueba con otra o tómala de nuevo.'**
  String get proveedorAccesoPudimosAchicarEsaFoto;

  /// No description provided for @proveedorAccesoSinConexionQueEscribiste.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Lo que escribiste se conserva: vuelve a intentarlo con señal y seguimos donde quedó.'**
  String get proveedorAccesoSinConexionQueEscribiste;

  /// No description provided for @proveedorAccesoSinConexionQueEscribiste2.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Lo que escribiste se conserva: vuelve a intentarlo con señal.'**
  String get proveedorAccesoSinConexionQueEscribiste2;

  /// No description provided for @proveedorAccesoCuentaQuedoCreadaPero.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta quedó creada, pero no pudimos ingresar. Vuelve al ingreso e inicia sesión.'**
  String get proveedorAccesoCuentaQuedoCreadaPero;

  /// No description provided for @proveedorAccesoRevisaLosDatosMarcados.
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos marcados y vuelve a intentarlo.'**
  String get proveedorAccesoRevisaLosDatosMarcados;

  /// No description provided for @proveedorAccesoPudimosCompletarRegistroIntenta.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar el registro. Vuelve a intentarlo.'**
  String get proveedorAccesoPudimosCompletarRegistroIntenta;

  /// No description provided for @proveedorAccesoSesionVencioEntraNuevo.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión venció. Ingresa de nuevo.'**
  String get proveedorAccesoSesionVencioEntraNuevo;

  /// No description provided for @proveedorAccesoUsuarioContrasenaIncorrectosRevisa.
  ///
  /// In es, this message translates to:
  /// **'Usuario o contraseña incorrectos. Revísalos y vuelve a intentarlo.'**
  String get proveedorAccesoUsuarioContrasenaIncorrectosRevisa;

  /// No description provided for @proveedorAccesoSinConexionNecesitasSenal.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Necesitas señal para ingresar; lo que ya guardaste en el teléfono sigue ahí.'**
  String get proveedorAccesoSinConexionNecesitasSenal;

  /// No description provided for @proveedorAccesoEstaCuentaEstaApp.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta no es de esta app.'**
  String get proveedorAccesoEstaCuentaEstaApp;

  /// No description provided for @proveedorAccesoPudimosEntrarIntentaNuevo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos ingresar. Vuelve a intentarlo en un momento.'**
  String get proveedorAccesoPudimosEntrarIntentaNuevo;

  /// No description provided for @proveedorNegociacionSinConexionPuedeQue.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: puede que lo que ves esté desactualizado.'**
  String get proveedorNegociacionSinConexionPuedeQue;

  /// No description provided for @proveedorNegociacionListoClienteEligioPuedes.
  ///
  /// In es, this message translates to:
  /// **'¡Listo! El cliente te eligió. Ya puedes escribirle desde «Servicio».'**
  String get proveedorNegociacionListoClienteEligioPuedes;

  /// No description provided for @proveedorNegociacionRechazasteOfertaDelCliente.
  ///
  /// In es, this message translates to:
  /// **'Rechazaste la oferta del cliente.'**
  String get proveedorNegociacionRechazasteOfertaDelCliente;

  /// No description provided for @proveedorNegociacionRetirasteOferta.
  ///
  /// In es, this message translates to:
  /// **'Retiraste tu oferta.'**
  String get proveedorNegociacionRetirasteOferta;

  /// No description provided for @proveedorNegociacionEnviasteContraoferta.
  ///
  /// In es, this message translates to:
  /// **'Enviaste tu contraoferta.'**
  String get proveedorNegociacionEnviasteContraoferta;

  /// No description provided for @proveedorNegociacionHayConexionEnvioNada.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. No se envió nada: vuelve a intentarlo cuando tengas señal.'**
  String get proveedorNegociacionHayConexionEnvioNada;

  /// No description provided for @proveedorNegociacionEsaOfertaEstaVigente.
  ///
  /// In es, this message translates to:
  /// **'Esa oferta ya no está vigente: el cliente respondió o venció. Actualizamos tu lista.'**
  String get proveedorNegociacionEsaOfertaEstaVigente;

  /// No description provided for @proveedorNegociacionClienteEligioOtroPiloto.
  ///
  /// In es, this message translates to:
  /// **'El cliente ya eligió a otro piloto para esta solicitud.'**
  String get proveedorNegociacionClienteEligioOtroPiloto;

  /// No description provided for @proveedorNegociacionEquipoEstaDisponiblePara.
  ///
  /// In es, this message translates to:
  /// **'Tu equipo no está disponible para esas fechas. Revisa tus drones.'**
  String get proveedorNegociacionEquipoEstaDisponiblePara;

  /// No description provided for @proveedorNegociacionSinConexionMensajeSigue.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Tu mensaje sigue aquí: vuelve a intentarlo.'**
  String get proveedorNegociacionSinConexionMensajeSigue;

  /// No description provided for @proveedorNegociacionRetiroReintentaCuandoTengas.
  ///
  /// In es, this message translates to:
  /// **'No se retiró. Vuelve a intentarlo cuando tengas señal.'**
  String get proveedorNegociacionRetiroReintentaCuandoTengas;

  /// No description provided for @proveedorNegociacionEnvioPrecioSigueAqui.
  ///
  /// In es, this message translates to:
  /// **'No se envió. Tu precio sigue aquí: vuelve a intentarlo cuando tengas señal.'**
  String get proveedorNegociacionEnvioPrecioSigueAqui;

  /// No description provided for @proveedorNegociacionEsaOfertaEstaVigente2.
  ///
  /// In es, this message translates to:
  /// **'Esa oferta ya no está vigente: el cliente respondió o venció.'**
  String get proveedorNegociacionEsaOfertaEstaVigente2;

  /// No description provided for @proveedorNegociacionHayConexionQueEscribiste.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Lo que escribiste se conserva: vuelve a intentarlo cuando tengas señal.'**
  String get proveedorNegociacionHayConexionQueEscribiste;

  /// No description provided for @proveedorDronFotos.
  ///
  /// In es, this message translates to:
  /// **'Fotos: {detalle}'**
  String proveedorDronFotos(String detalle);

  /// No description provided for @proveedorEjecucionServicioSemantica.
  ///
  /// In es, this message translates to:
  /// **'{hectareas}{cultivo}, {estado}{pendientes}'**
  String proveedorEjecucionServicioSemantica(
    String hectareas,
    String cultivo,
    String estado,
    String pendientes,
  );

  /// No description provided for @proveedorEjecucionDeCultivo.
  ///
  /// In es, this message translates to:
  /// **' de {cultivo}'**
  String proveedorEjecucionDeCultivo(String cultivo);

  /// No description provided for @proveedorEjecucionPendientesSufijo.
  ///
  /// In es, this message translates to:
  /// **', {cantidad} por subir'**
  String proveedorEjecucionPendientesSufijo(int cantidad);

  /// No description provided for @proveedorEjecucionAvanceResumen.
  ///
  /// In es, this message translates to:
  /// **'{ejecutadas} de {total} · {porcentaje} %'**
  String proveedorEjecucionAvanceResumen(
    String ejecutadas,
    String total,
    String porcentaje,
  );

  /// No description provided for @proveedorPerfilGraficoBarras.
  ///
  /// In es, this message translates to:
  /// **'Gráfico de barras de hectáreas por mes: {detalle}'**
  String proveedorPerfilGraficoBarras(String detalle);

  /// No description provided for @proveedorNegociacionTotalPrecioCliente.
  ///
  /// In es, this message translates to:
  /// **'Total al precio del cliente: {monto}{ofertas}'**
  String proveedorNegociacionTotalPrecioCliente(String monto, String ofertas);

  /// No description provided for @proveedorNegociacionOfertasSufijo.
  ///
  /// In es, this message translates to:
  /// **' · {cantidad, plural, =1{1 oferta} other{{cantidad} ofertas}}'**
  String proveedorNegociacionOfertasSufijo(int cantidad);

  /// No description provided for @proveedorNegociacionSolicitudSemantica.
  ///
  /// In es, this message translates to:
  /// **'Solicitud en {zona}, {hectareas}, {precio} por hectárea, {cantidad, plural, =1{1 oferta} other{{cantidad} ofertas}}{vence}'**
  String proveedorNegociacionSolicitudSemantica(
    String zona,
    String hectareas,
    String precio,
    int cantidad,
    String vence,
  );

  /// No description provided for @proveedorNegociacionZonaSinNombre.
  ///
  /// In es, this message translates to:
  /// **'zona sin nombre'**
  String get proveedorNegociacionZonaSinNombre;

  /// No description provided for @proveedorNegociacionAvisosSinConexion.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Las notificaciones se configuran con señal.'**
  String get proveedorNegociacionAvisosSinConexion;

  /// No description provided for @proveedorNegociacionAvisosNoGuardado.
  ///
  /// In es, this message translates to:
  /// **'No se guardó: no hay conexión. Vuelve a intentarlo con señal.'**
  String get proveedorNegociacionAvisosNoGuardado;

  /// No description provided for @proveedorNegociacionMapaSemantica.
  ///
  /// In es, this message translates to:
  /// **'Mapa de solicitudes abiertas, {cantidad, plural, =1{1 solicitud} other{{cantidad} solicitudes}}'**
  String proveedorNegociacionMapaSemantica(int cantidad);

  /// No description provided for @proveedorNegociacionChatConCliente.
  ///
  /// In es, this message translates to:
  /// **'Chat con el cliente'**
  String get proveedorNegociacionChatConCliente;

  /// No description provided for @proveedorNegociacionEnviarContraoferta.
  ///
  /// In es, this message translates to:
  /// **'Enviar contraoferta'**
  String get proveedorNegociacionEnviarContraoferta;

  /// No description provided for @proveedorNegociacionOfertaSemantica.
  ///
  /// In es, this message translates to:
  /// **'{titulo}, {detalle}, {etiqueta}{cliente}{mia}'**
  String proveedorNegociacionOfertaSemantica(
    String titulo,
    String detalle,
    String etiqueta,
    String cliente,
    String mia,
  );

  /// No description provided for @proveedorNegociacionPrecioClienteSufijo.
  ///
  /// In es, this message translates to:
  /// **', cliente {precio} bolivianos por hectárea'**
  String proveedorNegociacionPrecioClienteSufijo(String precio);

  /// No description provided for @proveedorNegociacionPrecioMioSufijo.
  ///
  /// In es, this message translates to:
  /// **', tú {precio}'**
  String proveedorNegociacionPrecioMioSufijo(String precio);

  /// No description provided for @proveedorNegociacionRondaSemantica.
  ///
  /// In es, this message translates to:
  /// **'Ronda {ronda} de {total}{turno}'**
  String proveedorNegociacionRondaSemantica(int ronda, int total, String turno);

  /// No description provided for @proveedorNegociacionEsTuTurno.
  ///
  /// In es, this message translates to:
  /// **', es tu turno'**
  String get proveedorNegociacionEsTuTurno;

  /// No description provided for @terrenosFotoSemantica.
  ///
  /// In es, this message translates to:
  /// **'Foto {numero} de {total} del terreno{descripcion}'**
  String terrenosFotoSemantica(int numero, int total, String descripcion);

  /// No description provided for @terrenosFotoDescripcionSufijo.
  ///
  /// In es, this message translates to:
  /// **': {descripcion}'**
  String terrenosFotoDescripcionSufijo(String descripcion);

  /// No description provided for @accesoRolCliente.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get accesoRolCliente;

  /// No description provided for @accesoRolClienteDetalle.
  ///
  /// In es, this message translates to:
  /// **'Publico lotes y elijo al piloto'**
  String get accesoRolClienteDetalle;

  /// No description provided for @accesoRolClienteBoton.
  ///
  /// In es, this message translates to:
  /// **'cliente'**
  String get accesoRolClienteBoton;

  /// No description provided for @accesoRolPiloto.
  ///
  /// In es, this message translates to:
  /// **'Piloto'**
  String get accesoRolPiloto;

  /// No description provided for @accesoRolPilotoDetalle.
  ///
  /// In es, this message translates to:
  /// **'Busco lotes y negocio el precio'**
  String get accesoRolPilotoDetalle;

  /// No description provided for @accesoRolPilotoBoton.
  ///
  /// In es, this message translates to:
  /// **'piloto'**
  String get accesoRolPilotoBoton;

  /// No description provided for @proveedorNegociacionVenceHoySufijo.
  ///
  /// In es, this message translates to:
  /// **', vence hoy'**
  String get proveedorNegociacionVenceHoySufijo;

  /// No description provided for @proveedorAccesoDatoObligatorio.
  ///
  /// In es, this message translates to:
  /// **'Este dato es obligatorio.'**
  String get proveedorAccesoDatoObligatorio;

  /// No description provided for @proveedorAccesoNumeroMayorCero.
  ///
  /// In es, this message translates to:
  /// **'Escribe un número mayor a cero.'**
  String get proveedorAccesoNumeroMayorCero;

  /// No description provided for @componentesSinSenal.
  ///
  /// In es, this message translates to:
  /// **'Sin señal'**
  String get componentesSinSenal;

  /// No description provided for @componentesNuevoServicio.
  ///
  /// In es, this message translates to:
  /// **'NUEVO SERVICIO'**
  String get componentesNuevoServicio;

  /// No description provided for @componentesTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get componentesTotal;

  /// No description provided for @componentesSyncEnDispositivo.
  ///
  /// In es, this message translates to:
  /// **'En este teléfono'**
  String get componentesSyncEnDispositivo;

  /// No description provided for @componentesSyncSincronizando.
  ///
  /// In es, this message translates to:
  /// **'Sincronizando'**
  String get componentesSyncSincronizando;

  /// No description provided for @componentesSyncSincronizado.
  ///
  /// In es, this message translates to:
  /// **'Sincronizado'**
  String get componentesSyncSincronizado;

  /// No description provided for @componentesSyncSinSincronizar.
  ///
  /// In es, this message translates to:
  /// **'Sin sincronizar'**
  String get componentesSyncSinSincronizar;

  /// No description provided for @solicitudesAvanceHectareas.
  ///
  /// In es, this message translates to:
  /// **'{ejecutadas} / {total} ha'**
  String solicitudesAvanceHectareas(String ejecutadas, String total);

  /// No description provided for @proveedorEjecucionDeTotal.
  ///
  /// In es, this message translates to:
  /// **'{ejecutadas} de {total}'**
  String proveedorEjecucionDeTotal(String ejecutadas, String total);

  /// No description provided for @proveedorEjecucionHectareasPorPrecio.
  ///
  /// In es, this message translates to:
  /// **'{hectareas} × {precio} por ha'**
  String proveedorEjecucionHectareasPorPrecio(String hectareas, String precio);

  /// No description provided for @permisosCamaraTitulo.
  ///
  /// In es, this message translates to:
  /// **'Usar la cámara'**
  String get permisosCamaraTitulo;

  /// No description provided for @permisosCamaraMotivo.
  ///
  /// In es, this message translates to:
  /// **'Tomamos las fotos en el momento: tu selfie, tus documentos y las fotos del avance. Para eso no usamos tu galería.'**
  String get permisosCamaraMotivo;

  /// No description provided for @permisosCamaraQuienVe.
  ///
  /// In es, this message translates to:
  /// **'Solo las ve el equipo de Agrocom que las revisa y, en las fotos de avance, el cliente del servicio.'**
  String get permisosCamaraQuienVe;

  /// No description provided for @permisosCamaraSin.
  ///
  /// In es, this message translates to:
  /// **'Sin la cámara no puedes enviar fotos desde la app.'**
  String get permisosCamaraSin;

  /// No description provided for @permisosUbicacionTitulo.
  ///
  /// In es, this message translates to:
  /// **'Compartir tu ubicación'**
  String get permisosUbicacionTitulo;

  /// No description provided for @permisosUbicacionMotivo.
  ///
  /// In es, this message translates to:
  /// **'Mientras tienes un servicio en ejecución, el cliente ve tu última posición. También la usamos una sola vez si pulsas el botón de auxilio o reportas una incidencia. Nunca la usamos en segundo plano.'**
  String get permisosUbicacionMotivo;

  /// No description provided for @permisosUbicacionQuienVe.
  ///
  /// In es, this message translates to:
  /// **'La ve el cliente del servicio en curso y, solo en un auxilio, soporte de Agrocom. Puedes desactivarla cuando quieras.'**
  String get permisosUbicacionQuienVe;

  /// No description provided for @permisosUbicacionSin.
  ///
  /// In es, this message translates to:
  /// **'Sin la ubicación no puedes compartir tu posición con el cliente ni avisar dónde estás en un auxilio.'**
  String get permisosUbicacionSin;

  /// No description provided for @permisosNotificacionesTitulo.
  ///
  /// In es, this message translates to:
  /// **'Recibir avisos'**
  String get permisosNotificacionesTitulo;

  /// No description provided for @permisosNotificacionesMotivo.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos cuando hay una solicitud nueva, cuando el cliente responde tu oferta o cuando te escribe.'**
  String get permisosNotificacionesMotivo;

  /// No description provided for @permisosNotificacionesQuienVe.
  ///
  /// In es, this message translates to:
  /// **'Los avisos solo llegan a este teléfono. En Avisos puedes apagar los que no quieras.'**
  String get permisosNotificacionesQuienVe;

  /// No description provided for @permisosNotificacionesSin.
  ///
  /// In es, this message translates to:
  /// **'Sin avisos solo te enteras de las novedades al abrir la app.'**
  String get permisosNotificacionesSin;

  /// No description provided for @permisosContinuar.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get permisosContinuar;

  /// No description provided for @permisosAhoraNo.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get permisosAhoraNo;

  /// No description provided for @permisosDenegadoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Permiso desactivado'**
  String get permisosDenegadoTitulo;

  /// No description provided for @permisosDenegadoAjustes.
  ///
  /// In es, this message translates to:
  /// **'Puedes activarlo en los ajustes del teléfono. Al volver, la app lo toma al instante.'**
  String get permisosDenegadoAjustes;

  /// No description provided for @permisosDenegadoReintento.
  ///
  /// In es, this message translates to:
  /// **'Si cambias de idea, te lo volvemos a pedir cuando lo necesites.'**
  String get permisosDenegadoReintento;

  /// No description provided for @permisosAbrirAjustes.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get permisosAbrirAjustes;

  /// No description provided for @permisosCerrar.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get permisosCerrar;

  /// No description provided for @biometriaBloqueadaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Sesión bloqueada'**
  String get biometriaBloqueadaTitulo;

  /// No description provided for @biometriaBloqueadaDetalle.
  ///
  /// In es, this message translates to:
  /// **'Usa tu huella o tu rostro para entrar. Lo que hayas guardado en el teléfono sigue a salvo.'**
  String get biometriaBloqueadaDetalle;

  /// No description provided for @biometriaDesbloquear.
  ///
  /// In es, this message translates to:
  /// **'Desbloquear'**
  String get biometriaDesbloquear;

  /// No description provided for @biometriaUsarContrasena.
  ///
  /// In es, this message translates to:
  /// **'Entrar con mi contraseña'**
  String get biometriaUsarContrasena;

  /// No description provided for @biometriaMotivoDesbloqueo.
  ///
  /// In es, this message translates to:
  /// **'Confirma que eres tú para abrir Agrocom'**
  String get biometriaMotivoDesbloqueo;

  /// No description provided for @biometriaMotivoActivar.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu huella o rostro para activar el desbloqueo'**
  String get biometriaMotivoActivar;

  /// No description provided for @biometriaUsaContrasena.
  ///
  /// In es, this message translates to:
  /// **'No pudimos usar la huella o el rostro. Entra con tu contraseña.'**
  String get biometriaUsaContrasena;

  /// No description provided for @biometriaAjusteTitulo.
  ///
  /// In es, this message translates to:
  /// **'Desbloquear con huella o rostro'**
  String get biometriaAjusteTitulo;

  /// No description provided for @biometriaAjusteDetalle.
  ///
  /// In es, this message translates to:
  /// **'Al abrir la app te pedimos tu huella o rostro en vez de entrar directo. No se envía a Agrocom.'**
  String get biometriaAjusteDetalle;

  /// No description provided for @biometriaAjusteSinRegistrar.
  ///
  /// In es, this message translates to:
  /// **'Registra una huella o un rostro en los ajustes del teléfono para activarlo.'**
  String get biometriaAjusteSinRegistrar;

  /// No description provided for @biometriaAjusteSinHardware.
  ///
  /// In es, this message translates to:
  /// **'Este teléfono no tiene lector de huella ni de rostro.'**
  String get biometriaAjusteSinHardware;

  /// No description provided for @biometriaNoConfirmada.
  ///
  /// In es, this message translates to:
  /// **'No pudimos confirmar tu huella o rostro. El desbloqueo sigue desactivado.'**
  String get biometriaNoConfirmada;

  /// No description provided for @cuentaEnRevisionTitulo.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta está en revisión'**
  String get cuentaEnRevisionTitulo;

  /// No description provided for @cuentaRechazadaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta fue rechazada'**
  String get cuentaRechazadaTitulo;

  /// No description provided for @cuentaSuspendidaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta está suspendida'**
  String get cuentaSuspendidaTitulo;

  /// No description provided for @cuentaEnRevisionDetalle.
  ///
  /// In es, this message translates to:
  /// **'Un administrador revisa tus datos y documentos. Mientras tanto puedes ver tu perfil y tu dron, pero todavía no ves el mapa de solicitudes ni puedes ofertar.'**
  String get cuentaEnRevisionDetalle;

  /// No description provided for @cuentaRechazadaDetalle.
  ///
  /// In es, this message translates to:
  /// **'Corrige lo que te indicamos, vuelve a subir lo que haga falta y envíala otra vez a revisión.'**
  String get cuentaRechazadaDetalle;

  /// No description provided for @cuentaSuspendidaDetalle.
  ///
  /// In es, this message translates to:
  /// **'No puedes ver el mapa ni ofertar mientras dure la suspensión. Escríbenos si necesitas ayuda.'**
  String get cuentaSuspendidaDetalle;

  /// No description provided for @cuentaMotivo.
  ///
  /// In es, this message translates to:
  /// **'Motivo: {motivo}'**
  String cuentaMotivo(String motivo);

  /// No description provided for @cuentaQueFalta.
  ///
  /// In es, this message translates to:
  /// **'Qué falta'**
  String get cuentaQueFalta;

  /// No description provided for @cuentaNadaFalta.
  ///
  /// In es, this message translates to:
  /// **'No te falta ningún documento. Te avisamos cuando te aprueben.'**
  String get cuentaNadaFalta;

  /// No description provided for @cuentaSubirDocumentos.
  ///
  /// In es, this message translates to:
  /// **'Subir documentos'**
  String get cuentaSubirDocumentos;

  /// No description provided for @cuentaReenviar.
  ///
  /// In es, this message translates to:
  /// **'Volver a enviar a revisión'**
  String get cuentaReenviar;

  /// No description provided for @cuentaActualizar.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get cuentaActualizar;

  /// No description provided for @cuentaErrorCarga.
  ///
  /// In es, this message translates to:
  /// **'No pudimos revisar el estado de tu cuenta'**
  String get cuentaErrorCarga;

  /// No description provided for @cuentaErrorDetalle.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a intentarlo en un momento.'**
  String get cuentaErrorDetalle;

  /// No description provided for @cuentaSinRed.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Necesitamos señal para revisar tu cuenta.'**
  String get cuentaSinRed;

  /// No description provided for @cuentaActualizandoSemantica.
  ///
  /// In es, this message translates to:
  /// **'Actualizando el estado de tu cuenta'**
  String get cuentaActualizandoSemantica;

  /// No description provided for @documentosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Mis documentos'**
  String get documentosTitulo;

  /// No description provided for @documentosIntro.
  ///
  /// In es, this message translates to:
  /// **'Toma una foto de cada documento con la cámara. Se envían por conexión segura y no se guardan en tu teléfono.'**
  String get documentosIntro;

  /// No description provided for @documentosTipoIdentidad.
  ///
  /// In es, this message translates to:
  /// **'Documento de identidad'**
  String get documentosTipoIdentidad;

  /// No description provided for @documentosTipoLicenciaPiloto.
  ///
  /// In es, this message translates to:
  /// **'Licencia de piloto'**
  String get documentosTipoLicenciaPiloto;

  /// No description provided for @documentosTipoHabilitacionDron.
  ///
  /// In es, this message translates to:
  /// **'Habilitación del dron'**
  String get documentosTipoHabilitacionDron;

  /// No description provided for @documentosTipoSeguroResponsabilidad.
  ///
  /// In es, this message translates to:
  /// **'Seguro de responsabilidad'**
  String get documentosTipoSeguroResponsabilidad;

  /// No description provided for @documentosTipoRegistroDron.
  ///
  /// In es, this message translates to:
  /// **'Matrícula del dron'**
  String get documentosTipoRegistroDron;

  /// No description provided for @documentosTipoCertificadoFumigacion.
  ///
  /// In es, this message translates to:
  /// **'Certificado de fumigación'**
  String get documentosTipoCertificadoFumigacion;

  /// No description provided for @documentosTipoAntecedentes.
  ///
  /// In es, this message translates to:
  /// **'Antecedentes'**
  String get documentosTipoAntecedentes;

  /// No description provided for @documentosTipoOtro.
  ///
  /// In es, this message translates to:
  /// **'Otro documento'**
  String get documentosTipoOtro;

  /// No description provided for @documentosEtapaFaltante.
  ///
  /// In es, this message translates to:
  /// **'Falta'**
  String get documentosEtapaFaltante;

  /// No description provided for @documentosEtapaSubiendo.
  ///
  /// In es, this message translates to:
  /// **'Subiendo'**
  String get documentosEtapaSubiendo;

  /// No description provided for @documentosEtapaEnRevision.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get documentosEtapaEnRevision;

  /// No description provided for @documentosEtapaAprobado.
  ///
  /// In es, this message translates to:
  /// **'Aprobado'**
  String get documentosEtapaAprobado;

  /// No description provided for @documentosEtapaRechazado.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get documentosEtapaRechazado;

  /// No description provided for @documentosEtapaVencido.
  ///
  /// In es, this message translates to:
  /// **'Vencido'**
  String get documentosEtapaVencido;

  /// No description provided for @documentosEtapaError.
  ///
  /// In es, this message translates to:
  /// **'No se envió'**
  String get documentosEtapaError;

  /// No description provided for @documentosTomarFoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get documentosTomarFoto;

  /// No description provided for @documentosVolverATomar.
  ///
  /// In es, this message translates to:
  /// **'Volver a tomar'**
  String get documentosVolverATomar;

  /// No description provided for @documentosReintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get documentosReintentar;

  /// No description provided for @documentosVence.
  ///
  /// In es, this message translates to:
  /// **'Vence el {fecha}'**
  String documentosVence(String fecha);

  /// No description provided for @documentosPreguntaVence.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo vence este documento?'**
  String get documentosPreguntaVence;

  /// No description provided for @documentosErrorSinRed.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. La foto sigue aquí: reintenta cuando tengas señal.'**
  String get documentosErrorSinRed;

  /// No description provided for @documentosErrorCarga.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus documentos'**
  String get documentosErrorCarga;

  /// No description provided for @documentosVacio.
  ///
  /// In es, this message translates to:
  /// **'No te pedimos ningún documento por ahora.'**
  String get documentosVacio;

  /// No description provided for @documentosVacioDetalle.
  ///
  /// In es, this message translates to:
  /// **'Si falta algo, te lo mostramos aquí.'**
  String get documentosVacioDetalle;

  /// No description provided for @documentosSemantica.
  ///
  /// In es, this message translates to:
  /// **'{documento}, {estado}'**
  String documentosSemantica(String documento, String estado);

  /// No description provided for @disponibilidadTitulo.
  ///
  /// In es, this message translates to:
  /// **'Disponibilidad'**
  String get disponibilidadTitulo;

  /// No description provided for @disponibilidadIntro.
  ///
  /// In es, this message translates to:
  /// **'Ocupado o en trabajo, dejas de recibir avisos de solicitudes nuevas. Sigues viendo el mapa y puedes ofertar.'**
  String get disponibilidadIntro;

  /// No description provided for @disponibilidadDisponible.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get disponibilidadDisponible;

  /// No description provided for @disponibilidadDisponibleDetalle.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos de las solicitudes nuevas.'**
  String get disponibilidadDisponibleDetalle;

  /// No description provided for @disponibilidadOcupado.
  ///
  /// In es, this message translates to:
  /// **'Ocupado'**
  String get disponibilidadOcupado;

  /// No description provided for @disponibilidadOcupadoDetalle.
  ///
  /// In es, this message translates to:
  /// **'No te avisamos de solicitudes nuevas.'**
  String get disponibilidadOcupadoDetalle;

  /// No description provided for @disponibilidadEnTrabajo.
  ///
  /// In es, this message translates to:
  /// **'En trabajo'**
  String get disponibilidadEnTrabajo;

  /// No description provided for @disponibilidadEnTrabajoDetalle.
  ///
  /// In es, this message translates to:
  /// **'No te avisamos mientras estás trabajando.'**
  String get disponibilidadEnTrabajoDetalle;

  /// No description provided for @disponibilidadEmpresaTeMarco.
  ///
  /// In es, this message translates to:
  /// **'Tu empresa te marcó como {estado}'**
  String disponibilidadEmpresaTeMarco(String estado);

  /// No description provided for @disponibilidadEmpresaOcupada.
  ///
  /// In es, this message translates to:
  /// **'Tu empresa está {estado}: no recibes avisos de solicitudes nuevas aunque tú estés disponible.'**
  String disponibilidadEmpresaOcupada(String estado);

  /// No description provided for @disponibilidadSinRed.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Tu disponibilidad no cambió: inténtalo cuando tengas señal.'**
  String get disponibilidadSinRed;

  /// No description provided for @disponibilidadErrorCarga.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu disponibilidad'**
  String get disponibilidadErrorCarga;

  /// No description provided for @disponibilidadErrorDetalle.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a intentarlo en un momento.'**
  String get disponibilidadErrorDetalle;

  /// No description provided for @disponibilidadTusAvisos.
  ///
  /// In es, this message translates to:
  /// **'Tus avisos'**
  String get disponibilidadTusAvisos;

  /// No description provided for @disponibilidadAvisosActivos.
  ///
  /// In es, this message translates to:
  /// **'Avisos de solicitudes nuevas: activados'**
  String get disponibilidadAvisosActivos;

  /// No description provided for @disponibilidadAvisosApagados.
  ///
  /// In es, this message translates to:
  /// **'Avisos de solicitudes nuevas: desactivados'**
  String get disponibilidadAvisosApagados;

  /// No description provided for @disponibilidadHectareasMinimas.
  ///
  /// In es, this message translates to:
  /// **'Hectáreas mínimas: {hectareas}'**
  String disponibilidadHectareasMinimas(String hectareas);

  /// No description provided for @disponibilidadCualquiera.
  ///
  /// In es, this message translates to:
  /// **'cualquiera'**
  String get disponibilidadCualquiera;

  /// No description provided for @disponibilidadDepartamentosExcluidos.
  ///
  /// In es, this message translates to:
  /// **'{cantidad, plural, =0{Sin departamentos excluidos} =1{1 departamento excluido} other{{cantidad} departamentos excluidos}}'**
  String disponibilidadDepartamentosExcluidos(int cantidad);

  /// No description provided for @disponibilidadTiposExcluidos.
  ///
  /// In es, this message translates to:
  /// **'{cantidad, plural, =0{Sin tipos de aplicación excluidos} =1{1 tipo de aplicación excluido} other{{cantidad} tipos de aplicación excluidos}}'**
  String disponibilidadTiposExcluidos(int cantidad);

  /// No description provided for @disponibilidadAjustarAvisos.
  ///
  /// In es, this message translates to:
  /// **'Ajustar avisos'**
  String get disponibilidadAjustarAvisos;

  /// No description provided for @disponibilidadEstadoActual.
  ///
  /// In es, this message translates to:
  /// **'Estado actual: {estado}'**
  String disponibilidadEstadoActual(String estado);

  /// No description provided for @perfilCuentaDocumentos.
  ///
  /// In es, this message translates to:
  /// **'Mis documentos'**
  String get perfilCuentaDocumentos;

  /// No description provided for @perfilCuentaDocumentosDetalle.
  ///
  /// In es, this message translates to:
  /// **'Licencia, matrícula y lo que falta para tu aprobación'**
  String get perfilCuentaDocumentosDetalle;

  /// No description provided for @perfilCuentaDisponibilidad.
  ///
  /// In es, this message translates to:
  /// **'Disponibilidad'**
  String get perfilCuentaDisponibilidad;

  /// No description provided for @perfilCuentaDisponibilidadDetalle.
  ///
  /// In es, this message translates to:
  /// **'Ponte ocupado para no recibir avisos'**
  String get perfilCuentaDisponibilidadDetalle;

  /// No description provided for @precioJustificacionEtiqueta.
  ///
  /// In es, this message translates to:
  /// **'Justificación del precio (opcional)'**
  String get precioJustificacionEtiqueta;

  /// No description provided for @precioJustificacionAyuda.
  ///
  /// In es, this message translates to:
  /// **'Explica por qué propones este precio. La otra parte lo verá.'**
  String get precioJustificacionAyuda;

  /// No description provided for @precioJustificacionContador.
  ///
  /// In es, this message translates to:
  /// **'{usados} de {maximo}'**
  String precioJustificacionContador(int usados, int maximo);

  /// No description provided for @precioJustificacionTitulo.
  ///
  /// In es, this message translates to:
  /// **'Justificación del precio'**
  String get precioJustificacionTitulo;

  /// No description provided for @precioTotalEtiqueta.
  ///
  /// In es, this message translates to:
  /// **'Total estimado'**
  String get precioTotalEtiqueta;

  /// No description provided for @precioTotalSinPrecio.
  ///
  /// In es, this message translates to:
  /// **'Escribe el precio'**
  String get precioTotalSinPrecio;

  /// No description provided for @precioTotalSoloLectura.
  ///
  /// In es, this message translates to:
  /// **'Se calcula con las hectáreas; no se escribe'**
  String get precioTotalSoloLectura;

  /// No description provided for @precioTotalCalculo.
  ///
  /// In es, this message translates to:
  /// **'{hectareas} × {precio}'**
  String precioTotalCalculo(String hectareas, String precio);

  /// No description provided for @ofertasOrdenRecomendado.
  ///
  /// In es, this message translates to:
  /// **'Recomendado'**
  String get ofertasOrdenRecomendado;

  /// No description provided for @ofertasOrdenReciente.
  ///
  /// In es, this message translates to:
  /// **'Más reciente'**
  String get ofertasOrdenReciente;

  /// No description provided for @ofertasFiltros.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get ofertasFiltros;

  /// No description provided for @ofertasFiltrosConActivos.
  ///
  /// In es, this message translates to:
  /// **'Filtros ({cantidad})'**
  String ofertasFiltrosConActivos(int cantidad);

  /// No description provided for @ofertasFiltrosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Ordenar y filtrar ofertas'**
  String get ofertasFiltrosTitulo;

  /// No description provided for @ofertasFiltrosOrdenarPor.
  ///
  /// In es, this message translates to:
  /// **'Ordenar por'**
  String get ofertasFiltrosOrdenarPor;

  /// No description provided for @ofertasFiltroPrecioMin.
  ///
  /// In es, this message translates to:
  /// **'Precio mínimo (Bs/ha)'**
  String get ofertasFiltroPrecioMin;

  /// No description provided for @ofertasFiltroPrecioMax.
  ///
  /// In es, this message translates to:
  /// **'Precio máximo (Bs/ha)'**
  String get ofertasFiltroPrecioMax;

  /// No description provided for @ofertasFiltroTotalMax.
  ///
  /// In es, this message translates to:
  /// **'Total máximo (Bs)'**
  String get ofertasFiltroTotalMax;

  /// No description provided for @ofertasFiltroCalificacionMin.
  ///
  /// In es, this message translates to:
  /// **'Calificación mínima'**
  String get ofertasFiltroCalificacionMin;

  /// No description provided for @ofertasFiltroCalificacionCualquiera.
  ///
  /// In es, this message translates to:
  /// **'Cualquiera'**
  String get ofertasFiltroCalificacionCualquiera;

  /// No description provided for @ofertasFiltroCalificacionDesde.
  ///
  /// In es, this message translates to:
  /// **'{minima} o más'**
  String ofertasFiltroCalificacionDesde(String minima);

  /// No description provided for @ofertasFiltroTipo.
  ///
  /// In es, this message translates to:
  /// **'Tipo de proveedor'**
  String get ofertasFiltroTipo;

  /// No description provided for @ofertasFiltroTipoTodos.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get ofertasFiltroTipoTodos;

  /// No description provided for @ofertasFiltroTipoPropio.
  ///
  /// In es, this message translates to:
  /// **'Agrocom'**
  String get ofertasFiltroTipoPropio;

  /// No description provided for @ofertasFiltroTipoIndependiente.
  ///
  /// In es, this message translates to:
  /// **'Independiente'**
  String get ofertasFiltroTipoIndependiente;

  /// No description provided for @ofertasFiltroTipoTercero.
  ///
  /// In es, this message translates to:
  /// **'Dueño de drones'**
  String get ofertasFiltroTipoTercero;

  /// No description provided for @ofertasFiltroTanqueMin.
  ///
  /// In es, this message translates to:
  /// **'Tanque mínimo (litros)'**
  String get ofertasFiltroTanqueMin;

  /// No description provided for @ofertasFiltrosAplicar.
  ///
  /// In es, this message translates to:
  /// **'Ver ofertas'**
  String get ofertasFiltrosAplicar;

  /// No description provided for @ofertasFiltrosQuitar.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtros'**
  String get ofertasFiltrosQuitar;

  /// No description provided for @ofertasFiltrosNumeroInvalido.
  ///
  /// In es, this message translates to:
  /// **'Escribe un número, por ejemplo 120'**
  String get ofertasFiltrosNumeroInvalido;

  /// No description provided for @ofertasFiltrosRangoInvalido.
  ///
  /// In es, this message translates to:
  /// **'El máximo no puede ser menor que el mínimo'**
  String get ofertasFiltrosRangoInvalido;

  /// No description provided for @ofertasNuevaOferta.
  ///
  /// In es, this message translates to:
  /// **'Llegó una oferta nueva. Compárala con las demás.'**
  String get ofertasNuevaOferta;

  /// No description provided for @ofertasSinResultadosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Ninguna oferta cumple tus filtros'**
  String get ofertasSinResultadosTitulo;

  /// No description provided for @ofertasSinResultadosDetalle.
  ///
  /// In es, this message translates to:
  /// **'Quita algún filtro para ver las demás ofertas.'**
  String get ofertasSinResultadosDetalle;

  /// No description provided for @ofertasActualizandoLista.
  ///
  /// In es, this message translates to:
  /// **'Actualizando ofertas'**
  String get ofertasActualizandoLista;

  /// No description provided for @ofertasPorQueEsePrecio.
  ///
  /// In es, this message translates to:
  /// **'Por qué ese precio'**
  String get ofertasPorQueEsePrecio;

  /// No description provided for @avisosCanalNuevasSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Nuevas solicitudes'**
  String get avisosCanalNuevasSolicitudes;

  /// No description provided for @avisosCanalNuevasSolicitudesDetalle.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes abiertas que puedes ofertar'**
  String get avisosCanalNuevasSolicitudesDetalle;

  /// No description provided for @avisosCanalOfertas.
  ///
  /// In es, this message translates to:
  /// **'Ofertas y contraofertas'**
  String get avisosCanalOfertas;

  /// No description provided for @avisosCanalOfertasDetalle.
  ///
  /// In es, this message translates to:
  /// **'Precios que recibes, respuestas y adjudicaciones'**
  String get avisosCanalOfertasDetalle;

  /// No description provided for @avisosCanalMensajes.
  ///
  /// In es, this message translates to:
  /// **'Mensajes'**
  String get avisosCanalMensajes;

  /// No description provided for @avisosCanalMensajesDetalle.
  ///
  /// In es, this message translates to:
  /// **'Chat con la otra parte del servicio'**
  String get avisosCanalMensajesDetalle;

  /// No description provided for @avisosCanalEjecucion.
  ///
  /// In es, this message translates to:
  /// **'Ejecución del servicio'**
  String get avisosCanalEjecucion;

  /// No description provided for @avisosCanalEjecucionDetalle.
  ///
  /// In es, this message translates to:
  /// **'Inicio, avance, cierre y precio final'**
  String get avisosCanalEjecucionDetalle;

  /// No description provided for @avisosCanalCuenta.
  ///
  /// In es, this message translates to:
  /// **'Cuenta y avisos'**
  String get avisosCanalCuenta;

  /// No description provided for @avisosCanalCuentaDetalle.
  ///
  /// In es, this message translates to:
  /// **'Aprobación, documentos, calificaciones y avisos del sistema'**
  String get avisosCanalCuentaDetalle;

  /// No description provided for @avisosTodos.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get avisosTodos;

  /// No description provided for @avisosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Mis notificaciones'**
  String get avisosTitulo;

  /// No description provided for @avisosCampana.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get avisosCampana;

  /// No description provided for @avisosCampanaConPendientes.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones, {cantidad} sin leer'**
  String avisosCampanaConPendientes(int cantidad);

  /// No description provided for @avisosVacioTitulo.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes notificaciones'**
  String get avisosVacioTitulo;

  /// No description provided for @avisosVacioDetalle.
  ///
  /// In es, this message translates to:
  /// **'Aquí verás lo que pase con tus solicitudes y ofertas, apenas ocurra.'**
  String get avisosVacioDetalle;

  /// No description provided for @avisosVacioCanal.
  ///
  /// In es, this message translates to:
  /// **'No hay notificaciones en este grupo'**
  String get avisosVacioCanal;

  /// No description provided for @avisosErrorTitulo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus notificaciones'**
  String get avisosErrorTitulo;

  /// No description provided for @avisosErrorDetalle.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión y vuelve a intentar.'**
  String get avisosErrorDetalle;

  /// No description provided for @avisosSinLeer.
  ///
  /// In es, this message translates to:
  /// **'Sin leer'**
  String get avisosSinLeer;

  /// No description provided for @avisosLeida.
  ///
  /// In es, this message translates to:
  /// **'Leída'**
  String get avisosLeida;

  /// No description provided for @avisosAjustesCanales.
  ///
  /// In es, this message translates to:
  /// **'Ajustes de notificaciones'**
  String get avisosAjustesCanales;

  /// No description provided for @avisosCanalesTitulo.
  ///
  /// In es, this message translates to:
  /// **'Canales de notificación'**
  String get avisosCanalesTitulo;

  /// No description provided for @avisosCanalesIntro.
  ///
  /// In es, this message translates to:
  /// **'Elige qué avisos suenan en este teléfono y a qué hora. Lo que se te avisa lo decide el servidor con tus preferencias.'**
  String get avisosCanalesIntro;

  /// No description provided for @avisosCanalObligatorio.
  ///
  /// In es, this message translates to:
  /// **'Siempre activo: son avisos de tu cuenta'**
  String get avisosCanalObligatorio;

  /// No description provided for @avisosCanalActivo.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get avisosCanalActivo;

  /// No description provided for @avisosCanalSilenciado.
  ///
  /// In es, this message translates to:
  /// **'Silenciado'**
  String get avisosCanalSilenciado;

  /// No description provided for @avisosHorarioSilencio.
  ///
  /// In es, this message translates to:
  /// **'Horario de silencio'**
  String get avisosHorarioSilencio;

  /// No description provided for @avisosHorarioSilencioDetalle.
  ///
  /// In es, this message translates to:
  /// **'No suena entre {desde} y {hasta}'**
  String avisosHorarioSilencioDetalle(String desde, String hasta);

  /// No description provided for @avisosSinHorario.
  ///
  /// In es, this message translates to:
  /// **'Sin horario de silencio'**
  String get avisosSinHorario;

  /// No description provided for @avisosHorarioDesde.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get avisosHorarioDesde;

  /// No description provided for @avisosHorarioHasta.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get avisosHorarioHasta;

  /// No description provided for @avisosQuitarHorario.
  ///
  /// In es, this message translates to:
  /// **'Quitar horario'**
  String get avisosQuitarHorario;

  /// No description provided for @avisosLlegaronNuevos.
  ///
  /// In es, this message translates to:
  /// **'Llegó una notificación nueva'**
  String get avisosLlegaronNuevos;

  /// No description provided for @avisosNotificacionDe.
  ///
  /// In es, this message translates to:
  /// **'{canal}: {titulo}'**
  String avisosNotificacionDe(String canal, String titulo);

  /// No description provided for @avisosVariosNuevos.
  ///
  /// In es, this message translates to:
  /// **'{cantidad} notificaciones nuevas'**
  String avisosVariosNuevos(int cantidad);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
