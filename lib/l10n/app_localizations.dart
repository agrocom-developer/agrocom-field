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
