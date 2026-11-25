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
  /// **'Sin conexión. El reporte no se envió; prueba de nuevo cuando tengas señal.'**
  String get problemaSinConexion;

  /// No description provided for @problemaErrorEnvio.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enviar el reporte. Prueba de nuevo.'**
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
  /// **'Mis campos'**
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
  /// **'Revisa tu conexión y vuelve a intentar.'**
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
  /// **'Todavía no cargaste documentos. Sin ellos no se puede aprobar tu perfil.'**
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
  /// **'Las reseñas de tus clientes aparecen aquí después de cada servicio.'**
  String get perfilProveedorResenasVacio;

  /// No description provided for @perfilProveedorErrorTitulo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu perfil'**
  String get perfilProveedorErrorTitulo;

  /// No description provided for @perfilProveedorErrorDetalle.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión y vuelve a intentar.'**
  String get perfilProveedorErrorDetalle;

  /// No description provided for @perfilProveedorAvisos.
  ///
  /// In es, this message translates to:
  /// **'Avisos'**
  String get perfilProveedorAvisos;

  /// No description provided for @perfilProveedorAvisosDetalle.
  ///
  /// In es, this message translates to:
  /// **'Nuevas solicitudes en tus zonas, mensajes y ofertas'**
  String get perfilProveedorAvisosDetalle;

  /// No description provided for @perfilProveedorCerrarSesionDetalle.
  ///
  /// In es, this message translates to:
  /// **'Lo que aún no se subió se conserva en este celular'**
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
  /// **'Celular'**
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
  /// **'Quitar contacto'**
  String get contactosQuitar;

  /// No description provided for @contactosQuitarPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar a {nombre}?'**
  String contactosQuitarPregunta(String nombre);

  /// No description provided for @contactosQuitarAviso.
  ///
  /// In es, this message translates to:
  /// **'Las solicitudes que ya publicaste conservan a esta persona.'**
  String get contactosQuitarAviso;

  /// No description provided for @contactosUnicoAviso.
  ///
  /// In es, this message translates to:
  /// **'Una empresa necesita al menos un contacto: agrega otro antes de quitar a este.'**
  String get contactosUnicoAviso;

  /// No description provided for @contactosErrorNombre.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre.'**
  String get contactosErrorNombre;

  /// No description provided for @contactosErrorCelular.
  ///
  /// In es, this message translates to:
  /// **'Escribe un celular de al menos 7 dígitos.'**
  String get contactosErrorCelular;

  /// No description provided for @contactosSinConexion.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. No se guardó nada; prueba de nuevo cuando tengas señal.'**
  String get contactosSinConexion;

  /// No description provided for @contactosErrorGuardar.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el contacto. Prueba de nuevo.'**
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
  /// **'Tu nombre y celular quedan como contacto principal. Después puedes agregar a otras personas desde tu perfil.'**
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
  /// **'No pudimos enviarlo. Tu mensaje sigue aquí; prueba de nuevo.'**
  String get chatFalloDesconocido;

  /// No description provided for @chatFalloFoto.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enviar la foto. Prueba de nuevo.'**
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
  /// **'Sin conexión. No se confirmó nada; prueba de nuevo cuando tengas señal.'**
  String get precioFinalFalloSinConexion;

  /// No description provided for @precioFinalFalloRechazado.
  ///
  /// In es, this message translates to:
  /// **'El servicio todavía no terminó, así que no se puede confirmar el precio.'**
  String get precioFinalFalloRechazado;

  /// No description provided for @precioFinalFalloDesconocido.
  ///
  /// In es, this message translates to:
  /// **'No pudimos confirmar el precio final. Prueba de nuevo.'**
  String get precioFinalFalloDesconocido;

  /// No description provided for @precioFinalAbrirDisputa.
  ///
  /// In es, this message translates to:
  /// **'Abrir disputa'**
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
  /// **'Necesitamos señal para cargar {queNoCargo}. Revisa tu conexión y prueba de nuevo.'**
  String estadoSinConexionDetalle(String queNoCargo);

  /// No description provided for @estadoErrorTitulo.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal'**
  String get estadoErrorTitulo;

  /// No description provided for @estadoErrorDetalle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar {queNoCargo}. Prueba de nuevo en un momento.'**
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
  /// **'lo que ya cargaste sigue a la vista. Pedir u ofertar necesita red.'**
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
  /// **'Pedido {numero}, {estado}'**
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

  /// No description provided for @versionActualizacionObligatoria.
  ///
  /// In es, this message translates to:
  /// **'Actualización obligatoria'**
  String get versionActualizacionObligatoria;

  /// No description provided for @versionEstaVersionAppEsta.
  ///
  /// In es, this message translates to:
  /// **'Esta versión de la app ya no está autorizada. Instalá la versión {version} o superior para seguir usándola.'**
  String versionEstaVersionAppEsta(String version);

  /// No description provided for @versionDescargalaDesde.
  ///
  /// In es, this message translates to:
  /// **'DESCÁRGALA DESDE'**
  String get versionDescargalaDesde;

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
  /// **'Fumigación con drones, a pedido'**
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
  /// **'Intenta de nuevo en un momento.'**
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
  /// **'Es con lo que vas a entrar. Sin espacios ni correo.'**
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

  /// No description provided for @inicioBuenClimaParaAplicar.
  ///
  /// In es, this message translates to:
  /// **'Buen clima para aplicar mañana'**
  String get inicioBuenClimaParaAplicar;

  /// No description provided for @inicioVientoSinLluviaHasta.
  ///
  /// In es, this message translates to:
  /// **'Viento de 8 km/h y sin lluvia hasta el mediodía en Cuatro Cañadas.'**
  String get inicioVientoSinLluviaHasta;

  /// No description provided for @inicioBuenPrecioAtraeMas.
  ///
  /// In es, this message translates to:
  /// **'Un buen precio atrae más ofertas'**
  String get inicioBuenPrecioAtraeMas;

  /// No description provided for @inicioLosPilotosComparanPrecio.
  ///
  /// In es, this message translates to:
  /// **'Los pilotos comparan el precio por hectárea: si tardan en ofertar, puedes subirlo.'**
  String get inicioLosPilotosComparanPrecio;

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
  /// **'Descartar aviso'**
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
