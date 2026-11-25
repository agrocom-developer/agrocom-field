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

  @override
  String get navInicio => 'Inicio';

  @override
  String get navLotes => 'Lotes';

  @override
  String get navServicios => 'Servicios';

  @override
  String get navPerfil => 'Perfil';

  @override
  String get navMapa => 'Mapa';

  @override
  String get navOfertas => 'Ofertas';

  @override
  String get temaTitulo => 'Tema';

  @override
  String get temaClaro => 'Claro';

  @override
  String get temaOscuro => 'Oscuro';

  @override
  String get temaCampo => 'Campo AAA';

  @override
  String get publicarLote => 'Publicar lote';

  @override
  String get publicarLoteCerrar => 'Cerrar';

  @override
  String get solicitudPublicada =>
      'Publicamos tu solicitud. Te avisamos cuando lleguen ofertas.';

  @override
  String get perfilClienteRol => 'Cliente';

  @override
  String get perfilClienteEstadLotes => 'lotes';

  @override
  String get perfilClienteEstadServicios => 'servicios';

  @override
  String get perfilClienteEstadCalificacion => 'como cliente';

  @override
  String get perfilMisCampos => 'Mis campos';

  @override
  String get perfilAgregarCampo => '+ Agregar';

  @override
  String get perfilMisCamposVacio =>
      'Todavía no tienes lotes. Se guardan al publicar tu primera solicitud.';

  @override
  String perfilHectareasUnidad(String hectareas) {
    return '$hectareas ha';
  }

  @override
  String get perfilLoDicen => 'Lo que dicen de ti';

  @override
  String get perfilCerrarSesion => 'Cerrar sesión';

  @override
  String get perfilDemoAviso =>
      'Modo demo: los datos son ficticios y no hay conexión con el servidor.';

  @override
  String get perfilErrorCargaTitulo => 'No pudimos cargar tu perfil';

  @override
  String get perfilErrorCargaDetalle =>
      'Revisa tu conexión y vuelve a intentar.';

  @override
  String get lotesTitulo => 'Lotes';

  @override
  String get lotesVacioTitulo => 'Todavía no tienes lotes';

  @override
  String get lotesVacioDetalle =>
      'Marca tu primer lote en el mapa al publicar una solicitud. Queda guardado para la próxima vez.';

  @override
  String lotesLoteDetalle(String zona, String cultivo) {
    return '$zona · $cultivo';
  }

  @override
  String get lotesErrorTitulo => 'No pudimos cargar tus lotes';

  @override
  String get lotesErrorDetalle => 'Revisa tu conexión y vuelve a intentar.';

  @override
  String get perfilProveedorRolPiloto => 'Piloto';

  @override
  String get perfilProveedorAjustes => 'Ajustes';

  @override
  String get perfilProveedorEstadCalificacion => 'calificación';

  @override
  String get perfilProveedorEstadServicios => 'servicios';

  @override
  String get perfilProveedorEstadHectareas => 'ha fumigadas';

  @override
  String get perfilProveedorSinCalificaciones => 'Todavía sin calificaciones';

  @override
  String perfilProveedorServicios(int n) {
    return '$n servicios';
  }

  @override
  String perfilProveedorDocumentoAtencion(String nombre) {
    return '«$nombre» necesita tu atención. Un documento vencido suspende las ofertas.';
  }

  @override
  String perfilProveedorDocumentosAtencion(int n) {
    return '$n documentos necesitan tu atención. Un documento vencido suspende las ofertas.';
  }

  @override
  String get perfilProveedorMetricas => 'Métricas';

  @override
  String get perfilProveedorDronLicencia => 'Dron y licencia';

  @override
  String get perfilProveedorDronesUno => '1 dron';

  @override
  String perfilProveedorDronesVarios(int n) {
    return '$n drones';
  }

  @override
  String get perfilProveedorZona => 'Zona de trabajo';

  @override
  String get perfilProveedorHectareasMes => 'Hectáreas por mes';

  @override
  String get perfilProveedorHectareasMesVacio =>
      'Las hectáreas de cada mes aparecen aquí después de tu primer servicio.';

  @override
  String get perfilProveedorDocumentos => 'Documentos';

  @override
  String get perfilProveedorDocumentosVacio =>
      'Todavía no cargaste documentos. Sin ellos no se puede aprobar tu perfil.';

  @override
  String get perfilProveedorZonas => 'Zonas de cobertura';

  @override
  String perfilProveedorZonaSemantica(String zona) {
    return 'Zona: $zona';
  }

  @override
  String get perfilProveedorCalificaciones => 'Calificaciones recibidas';

  @override
  String get perfilProveedorResenasVacio =>
      'Las reseñas de tus clientes aparecen aquí después de cada servicio.';

  @override
  String get perfilProveedorErrorTitulo => 'No pudimos cargar tu perfil';

  @override
  String get perfilProveedorErrorDetalle =>
      'Revisa tu conexión y vuelve a intentar.';

  @override
  String get perfilProveedorAvisos => 'Avisos';

  @override
  String get perfilProveedorAvisosDetalle =>
      'Nuevas solicitudes en tus zonas, mensajes y ofertas';

  @override
  String get perfilProveedorCerrarSesionDetalle =>
      'Lo que aún no se subió se conserva en este celular';

  @override
  String get perfilPublicoTitulo => 'Perfil del piloto';

  @override
  String perfilPublicoOfertaPara(String lote) {
    return 'Oferta para $lote';
  }

  @override
  String get perfilPublicoEstadCalificacion => 'calificación';

  @override
  String get perfilPublicoEstadResenas => 'calificaciones';

  @override
  String get perfilPublicoEstadCumplimiento => 'cancelaciones';

  @override
  String get perfilPublicoSinCalificaciones => 'Aún sin calificaciones';

  @override
  String get perfilPublicoEquipo => 'EQUIPO';

  @override
  String perfilPublicoDron(String dron, String litros) {
    return '$dron · $litros L';
  }

  @override
  String perfilPublicoDronAnio(int anio) {
    return 'Año $anio';
  }

  @override
  String get perfilPublicoSinDron => 'Este piloto aún no muestra su dron.';

  @override
  String get perfilPublicoSuOferta => 'Su oferta';

  @override
  String perfilPublicoTotal(String monto) {
    return 'total $monto';
  }

  @override
  String get perfilPublicoElegir => 'Elegir';

  @override
  String get perfilPublicoVerPerfil => 'Ver perfil';

  @override
  String perfilPublicoFotoDe(String nombre) {
    return 'Foto de $nombre';
  }

  @override
  String get contactosTitulo => 'Contactos de referencia';

  @override
  String get contactosIntro =>
      'El piloto que elijas ve a la persona de contacto de cada solicitud, con su cargo, solo después de adjudicarla.';

  @override
  String get contactosPrincipal => 'Principal';

  @override
  String get contactosAgregar => 'Agregar contacto';

  @override
  String get contactosEditar => 'Editar contacto';

  @override
  String get contactosNuevo => 'Nuevo contacto';

  @override
  String get contactosNombre => 'Nombre completo';

  @override
  String get contactosCelular => 'Celular';

  @override
  String get contactosCargo => 'Cargo (opcional)';

  @override
  String get contactosHacerPrincipal => 'Es el contacto principal';

  @override
  String get contactosHacerPrincipalAyuda =>
      'Se usa cuando una solicitud no elige a otra persona.';

  @override
  String get contactosGuardar => 'Guardar';

  @override
  String get contactosCancelar => 'Cancelar';

  @override
  String get contactosQuitar => 'Quitar contacto';

  @override
  String contactosQuitarPregunta(String nombre) {
    return '¿Quitar a $nombre?';
  }

  @override
  String get contactosQuitarAviso =>
      'Las solicitudes que ya publicaste conservan a esta persona.';

  @override
  String get contactosUnicoAviso =>
      'Una empresa necesita al menos un contacto: agrega otro antes de quitar a este.';

  @override
  String get contactosErrorNombre => 'Escribe el nombre.';

  @override
  String get contactosErrorCelular =>
      'Escribe un celular de al menos 7 dígitos.';

  @override
  String get contactosSinConexion =>
      'Sin conexión. No se guardó nada; prueba de nuevo cuando tengas señal.';

  @override
  String get contactosErrorGuardar =>
      'No pudimos guardar el contacto. Prueba de nuevo.';

  @override
  String contactosFilaSemantica(String nombre, String cargo, String celular) {
    return '$nombre, $cargo, $celular';
  }

  @override
  String get contactosPerfilFila => 'Contactos de referencia';

  @override
  String contactosPerfilDetalle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n personas',
      one: '1 persona',
    );
    return '$_temp0';
  }

  @override
  String get contactosEmpresaPublicar => 'Persona de contacto';

  @override
  String get contactosEmpresaPublicarAyuda =>
      'El piloto elegido verá a quién llamar.';

  @override
  String get contactosErrorCargaTitulo => 'No pudimos cargar tus contactos';

  @override
  String get contactosErrorCargaDetalle =>
      'Revisa tu conexión y vuelve a intentar.';

  @override
  String get registroEmpresaInterruptor => 'Asociar a una empresa';

  @override
  String get registroEmpresaAyuda =>
      'Si publicas lotes a nombre de una empresa, agrégala. Tú quedas como su contacto principal.';

  @override
  String get registroEmpresaRazon => 'Razón social';

  @override
  String get registroEmpresaDocumento => 'NIT';

  @override
  String get registroEmpresaCargo => 'Tu cargo en la empresa (opcional)';

  @override
  String get registroEmpresaContactoNota =>
      'Tu nombre y celular quedan como contacto principal. Después puedes agregar a otras personas desde tu perfil.';
}
