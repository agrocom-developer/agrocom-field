// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get problemaTitulo => 'Reportar un problema';

  @override
  String get problemaPregunta => '¿Qué pasó?';

  @override
  String get problemaMotivoSemantica => 'Motivo del problema';

  @override
  String get problemaDetalleEtiqueta => 'Cuéntanos qué viste';

  @override
  String get problemaDetalleAyuda =>
      'Al menos una oración: dónde, cuándo y qué.';

  @override
  String get problemaSinConexion =>
      'Sin conexión. El reporte no se envió; prueba de nuevo cuando tengas señal.';

  @override
  String get problemaErrorEnvio =>
      'No pudimos enviar el reporte. Prueba de nuevo.';

  @override
  String get problemaAvisoSoporte =>
      'Soporte te responde en 24 horas hábiles. El proveedor también ve el reporte y puede responder.';

  @override
  String get problemaBotonEnviar => 'Enviar reporte';

  @override
  String get problemaBotonReintentar => 'Reintentar';

  @override
  String get problemaBotonVolver => 'Volver al servicio';

  @override
  String get problemaEnviadoTitulo => 'Recibimos tu reporte';

  @override
  String problemaEnviadoCaso(String numero, String motivo) {
    return 'Caso $numero · $motivo';
  }

  @override
  String get problemaEnviadoMensaje =>
      'Soporte te responde en 24 horas hábiles. Mientras tanto, el servicio queda en revisión.';

  @override
  String get problemaMotivoCoberturaIncompleta => 'Cobertura incompleta';

  @override
  String get problemaMotivoCoberturaIncompletaAyuda =>
      'Quedaron partes del lote sin aplicar.';

  @override
  String get problemaMotivoMalaAplicacion => 'Mala aplicación';

  @override
  String get problemaMotivoMalaAplicacionAyuda =>
      'Franjas sin cubrir o con doble pasada.';

  @override
  String get problemaMotivoDanoCultivos => 'Daño a cultivos o a terceros';

  @override
  String get problemaMotivoDanoCultivosAyuda =>
      'La aplicación afectó tu cultivo o un lote vecino.';

  @override
  String get problemaMotivoProductoDistinto => 'Producto distinto al pactado';

  @override
  String get problemaMotivoProductoDistintoAyuda =>
      'Se aplicó otro producto u otra dosis.';

  @override
  String get problemaMotivoEquipoAusente => 'El equipo no se presentó';

  @override
  String get problemaMotivoEquipoAusenteAyuda =>
      'Nadie llegó en la fecha pactada.';

  @override
  String get problemaMotivoEvidenciaFaltante => 'Faltan evidencias';

  @override
  String get problemaMotivoEvidenciaFaltanteAyuda =>
      'No están las fotos o el registro del vuelo.';

  @override
  String get problemaMotivoCobroIndebido => 'Cobro indebido';

  @override
  String get problemaMotivoCobroIndebidoAyuda =>
      'El monto no coincide con lo estimado.';

  @override
  String get problemaMotivoTratoInadecuado => 'Trato inadecuado';

  @override
  String get problemaMotivoTratoInadecuadoAyuda =>
      'Hubo una falta de respeto o de cuidado.';
}
