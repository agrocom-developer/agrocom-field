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
      'Sin conexión. El reporte no se envió; vuelve a intentarlo cuando tengas señal.';

  @override
  String get problemaErrorEnvio =>
      'No pudimos enviar el reporte. Vuelve a intentarlo.';

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
  String get perfilMisCampos => 'Mis lotes';

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
  String get perfilErrorCargaTitulo => 'No pudimos cargar tu perfil';

  @override
  String get perfilErrorCargaDetalle =>
      'Revisa tu conexión y vuelve a intentarlo.';

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
  String get perfilProveedorRolPiloto => 'Piloto';

  @override
  String get perfilProveedorAjustes => 'Ajustes';

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
  String get perfilProveedorHectareasMes => 'Hectáreas por mes';

  @override
  String get perfilProveedorHectareasMesVacio =>
      'Las hectáreas de cada mes aparecen aquí después de tu primer servicio.';

  @override
  String get perfilProveedorDocumentos => 'Documentos';

  @override
  String get perfilProveedorDocumentosVacio =>
      'Todavía no subiste documentos. Sin ellos no se puede aprobar tu perfil.';

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
      'Las calificaciones de tus clientes aparecen aquí después de cada servicio.';

  @override
  String get perfilProveedorErrorTitulo => 'No pudimos cargar tu perfil';

  @override
  String get perfilProveedorErrorDetalle =>
      'Revisa tu conexión y vuelve a intentarlo.';

  @override
  String get perfilProveedorAvisos => 'Notificaciones';

  @override
  String get perfilProveedorAvisosDetalle =>
      'Nuevas solicitudes en tus zonas, mensajes y ofertas';

  @override
  String get perfilProveedorCerrarSesionDetalle =>
      'Lo que aún no se subió se conserva en este teléfono';

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
  String get contactosCelular => 'Teléfono';

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
  String get contactosQuitar => 'Eliminar contacto';

  @override
  String contactosQuitarPregunta(String nombre) {
    return '¿Eliminar a $nombre?';
  }

  @override
  String get contactosQuitarAviso =>
      'Las solicitudes que ya publicaste conservan a esta persona.';

  @override
  String get contactosUnicoAviso =>
      'Una empresa necesita al menos un contacto: agrega otro antes de eliminar a este.';

  @override
  String get contactosErrorNombre => 'Escribe el nombre.';

  @override
  String get contactosErrorCelular =>
      'Escribe un teléfono de al menos 7 dígitos.';

  @override
  String get contactosSinConexion =>
      'Sin conexión. No se guardó nada; vuelve a intentarlo cuando tengas señal.';

  @override
  String get contactosErrorGuardar =>
      'No pudimos guardar el contacto. Vuelve a intentarlo.';

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
      'Tu nombre y teléfono quedan como contacto principal. Después puedes agregar a otras personas desde tu perfil.';

  @override
  String get chatTitulo => 'Chat con el piloto';

  @override
  String get chatHoy => 'HOY';

  @override
  String chatCabecera(String lote, String estado) {
    return '$lote · $estado';
  }

  @override
  String chatFotoDe(String nombre) {
    return 'Foto de $nombre';
  }

  @override
  String get chatVacioTitulo => 'Todavía no hay mensajes';

  @override
  String get chatVacioDetalle =>
      'Escríbele al piloto para coordinar el día de la visita y los accesos al lote.';

  @override
  String get chatSinConexionAviso =>
      'Sin conexión. Los mensajes nuevos llegan cuando vuelva la señal.';

  @override
  String get chatCerradoAviso =>
      'El chat se cerró. Puedes leer lo conversado, pero ya no escribir.';

  @override
  String get chatEscribe => 'Escribe un mensaje';

  @override
  String get chatEnviar => 'Enviar';

  @override
  String get chatEnviarSemantica => 'Enviar mensaje';

  @override
  String get chatEnviando => 'Enviando';

  @override
  String get chatAdjuntar => 'Enviar una foto';

  @override
  String get chatFotoCamara => 'Tomar una foto';

  @override
  String get chatFotoGaleria => 'Elegir de la galería';

  @override
  String get chatFalloSinConexion =>
      'Sin conexión. Tu mensaje sigue aquí; envíalo cuando vuelva la señal.';

  @override
  String get chatFalloCerrado => 'El chat se cerró y no se envió tu mensaje.';

  @override
  String get chatFalloDesconocido =>
      'No pudimos enviarlo. Tu mensaje sigue aquí; vuelve a intentarlo.';

  @override
  String get chatFalloFoto => 'No pudimos enviar la foto. Vuelve a intentarlo.';

  @override
  String get chatAutorTu => 'Tú';

  @override
  String get chatAutorPiloto => 'Piloto';

  @override
  String chatMensajeSemantica(String autor, String hora, String texto) {
    return '$autor, $hora: $texto';
  }

  @override
  String chatFotoSemantica(String autor, String hora, String pie) {
    return '$autor, $hora: foto. $pie';
  }

  @override
  String get precioFinalConfirmar => 'Confirmar precio final';

  @override
  String get precioFinalPorConfirmar => 'POR CONFIRMAR';

  @override
  String get precioFinalConfirmado => 'CONFIRMADO';

  @override
  String get precioFinalConfirmadoAviso =>
      'Confirmaste el precio final. El pago sigue siendo directo al piloto.';

  @override
  String get precioFinalFalloSinConexion =>
      'Sin conexión. No se confirmó nada; vuelve a intentarlo cuando tengas señal.';

  @override
  String get precioFinalFalloRechazado =>
      'El servicio todavía no terminó, así que no se puede confirmar el precio.';

  @override
  String get precioFinalFalloDesconocido =>
      'No pudimos confirmar el precio final. Vuelve a intentarlo.';

  @override
  String get precioFinalAbrirDisputa => 'Abrir un reclamo';

  @override
  String get contactoPilotoTitulo => 'Persona de contacto';

  @override
  String get estadoReintentarAhora => 'Reintentar ahora';

  @override
  String get estadoSinSenalBanner => 'reintentando';

  @override
  String get estadoSinConexionTitulo => 'Sin conexión';

  @override
  String estadoSinConexionDetalle(String queNoCargo) {
    return 'Necesitamos señal para cargar $queNoCargo. Revisa tu conexión y vuelve a intentarlo.';
  }

  @override
  String get estadoErrorTitulo => 'Algo salió mal';

  @override
  String estadoErrorDetalle(String queNoCargo) {
    return 'No pudimos cargar $queNoCargo. Vuelve a intentarlo en un momento.';
  }

  @override
  String get estadoTablaTitulo => 'Qué funciona sin red';

  @override
  String get estadoTablaFotos => 'Fotos y avance';

  @override
  String get estadoTablaFuncionan => 'Funcionan sin red';

  @override
  String get estadoTablaOfertas => 'Ofertas y chat';

  @override
  String get estadoTablaRequieren => 'Requieren red';

  @override
  String get estadoErrorEstaPantalla => 'esta pantalla';

  @override
  String get envioErrorTitulo => 'No se envió tu solicitud';

  @override
  String get envioErrorDetalleSinRed =>
      'Lo que escribiste sigue aquí. Cuando vuelva la señal, toca «Reintentar ahora»: no se publica dos veces.';

  @override
  String get envioErrorDetalleRechazo =>
      'No pudimos publicarla. Lo que escribiste sigue aquí.';

  @override
  String get envioErrorVolver => 'Volver al formulario';

  @override
  String get listaVerLotesMapa => 'Ver lotes en el mapa';

  @override
  String get redSinSenalTitulo => 'Sin señal';

  @override
  String get redSinSenalMensaje =>
      'lo que ya cargaste sigue a la vista. Publicar u ofertar necesita red.';

  @override
  String componentesCalificacion(int valor) {
    return 'Calificación: $valor de 5';
  }

  @override
  String componentesPorHectarea(String valor) {
    return 'Bs $valor por hectárea';
  }

  @override
  String componentesBs(String valor) {
    return 'Bs $valor';
  }

  @override
  String componentesRonda(int hechas, int total) {
    return 'Ronda $hechas de $total';
  }

  @override
  String componentesRonda2(int hechas, int total) {
    return 'RONDA $hechas/$total';
  }

  @override
  String get componentesVolver => 'Volver';

  @override
  String get componentesCargando => 'Cargando';

  @override
  String componentesSincronizacion(String texto) {
    return 'Sincronización: $texto';
  }

  @override
  String get componentesArrastraParaVerMas => 'Arrastra para ver más o menos';

  @override
  String get componentesAgrocom => 'Agrocom';

  @override
  String componentesOfertaServicioQuedanPara(
    String titulo,
    String monto,
    String tiempo,
  ) {
    return 'Oferta de servicio: $titulo, $monto, quedan $tiempo para responder';
  }

  @override
  String get componentesPago => 'PAGO';

  @override
  String get componentesDistancia => 'DISTANCIA';

  @override
  String get componentesSinConexionParaResponder =>
      'Sin conexión. Para responder necesitas red.';

  @override
  String get componentesRechazar => 'Rechazar';

  @override
  String get componentesVerDetalleMapa => 'Ver detalle y mapa';

  @override
  String get componentesElegido => 'ELEGIDO';

  @override
  String componentesPedido(String numero, String estado) {
    return 'Solicitud $numero, $estado';
  }

  @override
  String get uiPosicionDelDron => 'Posición del dron';

  @override
  String get uiOpenstreetmap => 'OpenStreetMap';

  @override
  String componentesRondaSemantica(
    Object ronda,
    Object totalRondas,
    String autor,
    Object precio,
    Object total,
    String nota,
    String turno,
  ) {
    return 'Ronda $ronda de $totalRondas, $autor: $precio bolivianos por hectárea, total $total bolivianos$nota$turno';
  }

  @override
  String componentesNotaSufijo(String nota) {
    return ', $nota';
  }

  @override
  String get componentesTurnoSufijo => ', turno de responder';

  @override
  String get componentesPilotoMinuscula => 'piloto';

  @override
  String get componentesClienteMinuscula => 'cliente';

  @override
  String get componentesPilotoMayuscula => 'PILOTO';

  @override
  String get componentesClienteMayuscula => 'CLIENTE';

  @override
  String componentesOfertaSemantica(
    String piloto,
    Object precio,
    Object total,
    String elegida,
  ) {
    return 'Oferta de $piloto: $precio bolivianos por hectárea, total $total bolivianos$elegida';
  }

  @override
  String get componentesElegidaSufijo => ', elegida';

  @override
  String componentesCalificacionPromedioSemantica(
    String valor,
    String detalle,
  ) {
    return 'Calificación $valor de 5$detalle';
  }

  @override
  String componentesStepperSemantica(
    String etiqueta,
    Object valor,
    String unidad,
  ) {
    return '$etiqueta: $valor$unidad';
  }

  @override
  String componentesStepperUnidad(String unidad) {
    return ' $unidad';
  }

  @override
  String get accesoFumigacionConDronesPedido =>
      'Fumigación con drones cuando la necesites';

  @override
  String get accesoSolicitaServicioSigueVuelo =>
      'Solicita el servicio, sigue el vuelo en vivo y califica al piloto.';

  @override
  String get accesoIngresaCuenta => 'Ingresa a tu cuenta';

  @override
  String get accesoSolicitaServicioSigueloVivo =>
      'Solicita un servicio y síguelo en vivo.';

  @override
  String get accesoUsuario => 'Usuario';

  @override
  String get accesoContrasena => 'Contraseña';

  @override
  String get accesoIngresar => 'Ingresar';

  @override
  String get accesoPrimeraVezAgrocom => '¿Primera vez en Agrocom?';

  @override
  String get accesoCrearCuenta => 'Crear cuenta';

  @override
  String get accesoComenzar => 'Comenzar';

  @override
  String get accesoTengoCuenta => 'Ya tengo cuenta';

  @override
  String get accesoSaltar => 'Saltar';

  @override
  String accesoPortada(int i, int _portadas) {
    return 'Portada $i de $_portadas';
  }

  @override
  String get accesoHectareasPublicadas => 'hectáreas publicadas';

  @override
  String get accesoPrecioFinal => 'Precio final';

  @override
  String get accesoPudimosAbrirSesion => 'No pudimos abrir tu sesión';

  @override
  String get accesoIntentaNuevoMomento => 'Vuelve a intentarlo en un momento.';

  @override
  String get accesoReintentar => 'Reintentar';

  @override
  String get accesoVolverIngreso => 'Volver al ingreso';

  @override
  String get accesoCreaCuenta => 'Crea tu cuenta';

  @override
  String get accesoTomaMenosMinuto => 'Toma menos de un minuto.';

  @override
  String get accesoNombreCompleto => 'Nombre completo';

  @override
  String get accesoTelefono => 'Teléfono';

  @override
  String get accesoConQueVasEntrar =>
      'Con este usuario ingresas a la app. Sin espacios ni correo.';

  @override
  String accesoMinimoCaracteresConLetras(int largoMinimoContrasena) {
    return 'Mínimo $largoMinimoContrasena caracteres, con letras y números.';
  }

  @override
  String get calificarGraciasPorCalificarServicio =>
      'Gracias por calificar el servicio';

  @override
  String get calificarOmitir => 'Omitir';

  @override
  String get calificarComentarioOpcional => 'Comentario opcional';

  @override
  String comunAvance(String etiqueta) {
    return 'Avance: $etiqueta';
  }

  @override
  String get comunPrecioPorHectarea => 'Precio por hectárea';

  @override
  String get comunBsHa => 'Bs/ha';

  @override
  String get comunMensajeParaPilotoOpcional =>
      'Mensaje para el piloto (opcional)';

  @override
  String get comunAvanceSolicitud => 'Avance de la solicitud';

  @override
  String get inicioSolicitudActiva => 'Solicitud activa';

  @override
  String get inicioCompararOfertas => 'Comparar ofertas';

  @override
  String get inicioVerSeguimiento => 'Ver seguimiento';

  @override
  String get inicioCalificar => 'Calificar';

  @override
  String inicioHola(String nombre) {
    return 'Hola, $nombre';
  }

  @override
  String get inicioPerfil => 'Tu perfil';

  @override
  String get inicioPublicarLote => 'Publicar lote';

  @override
  String get inicioTienesSolicitudesCurso => 'No tienes solicitudes en curso';

  @override
  String get inicioTocaPublicarLoteMarca =>
      'Toca «Publicar lote», marca tu lote y compara las ofertas de los pilotos.';

  @override
  String get inicioDescartarAviso => 'Descartar notificación';

  @override
  String inicioCalificasteCon(int puntajeDelCliente) {
    return 'Calificaste con $puntajeDelCliente de 5';
  }

  @override
  String get inicioReintentar => 'Reintentar';

  @override
  String get ofertasCompararOfertas => 'Comparar ofertas';

  @override
  String get ofertasEncontramosEstaSolicitud => 'No encontramos esta solicitud';

  @override
  String get ofertasVuelveSolicitudesAbrelaNuevo =>
      'Vuelve a «Solicitudes» y ábrela de nuevo.';

  @override
  String ofertasElegir(String nombre) {
    return '¿Elegir a $nombre?';
  }

  @override
  String ofertasQuedanAcordadosPorHectarea(
    String precioHa,
    String montoEstimado,
  ) {
    return 'Quedan acordados $precioHa por hectárea ($montoEstimado estimados). Las demás ofertas se cierran y el piloto recibe tu contacto.';
  }

  @override
  String get ofertasVolver => 'Volver';

  @override
  String get ofertasElegirPiloto => 'Elegir piloto';

  @override
  String ofertasPideProponPrecioPiloto(String precioHa) {
    return 'Pide $precioHa/ha. Propón tu precio; el piloto puede aceptar o responder.';
  }

  @override
  String get ofertasSinConexionVesUltimo =>
      'Sin conexión. Ves lo último que cargamos; puede estar desactualizado.';

  @override
  String ofertasOfertasOrden(String etiqueta) {
    return 'OFERTAS · ORDEN: $etiqueta';
  }

  @override
  String ofertasElegir2(String primerNombre, String montoEstimado) {
    return 'Elegir a $primerNombre · $montoEstimado';
  }

  @override
  String get ofertasContraofertar => 'Contraofertar';

  @override
  String get ofertasRechazar => 'Rechazar';

  @override
  String get ofertasUltimaRondaSoloPuedes =>
      'Última ronda: solo puedes elegirlo o rechazarlo.';

  @override
  String ofertasEsperandoRespuesta(String primerNombre) {
    return 'Esperando la respuesta de $primerNombre';
  }

  @override
  String get ofertasTodaviaHayOfertas => 'Todavía no hay ofertas';

  @override
  String get ofertasLosPilotosZonaVen =>
      'Los pilotos de la zona ya ven tu solicitud. Cuando alguno ofrezca, te avisamos. Si tarda, puedes subir tu precio.';

  @override
  String ofertasFoto(String nombre) {
    return 'Foto de $nombre';
  }

  @override
  String ofertasFotoDelDron(String dron) {
    return 'Foto del dron $dron';
  }

  @override
  String get ofertasRondas => 'RONDAS';

  @override
  String ofertasRonda(String precioHa, int numero) {
    return '$precioHa/ha · ronda $numero';
  }

  @override
  String ofertasBsHa(String precioHa) {
    return 'Bs $precioHa/ha';
  }

  @override
  String get seguimientoEncontramosEsteServicio =>
      'No encontramos este servicio';

  @override
  String get seguimientoVuelveSolicitudesAbreloNuevo =>
      'Vuelve a «Solicitudes» y ábrelo de nuevo.';

  @override
  String get seguimientoPrecioFinal => 'Precio final';

  @override
  String seguimientoSonMenosQueLas(String menos, String hectareas) {
    return 'Son $menos menos que las publicadas ($hectareas). El total sale de lo que el piloto ejecutó.';
  }

  @override
  String get seguimientoPagoDirectoPilotoAgrocom =>
      'El pago es directo al piloto. Agrocom no cobra dentro de la app.';

  @override
  String seguimientoReportasteProblemaCasoSoporte(String numeroCaso) {
    return 'Reportaste un problema (caso $numeroCaso). Soporte te responde en 24 horas hábiles.';
  }

  @override
  String get seguimientoCalificacion => 'Tu calificación';

  @override
  String get seguimientoCalificarPiloto => 'Calificar al piloto';

  @override
  String get seguimientoSinConexionVesUltimo =>
      'Sin conexión. Ves lo último que cargamos; puede estar desactualizado.';

  @override
  String get seguimientoPilotoConfirmado => 'Piloto confirmado';

  @override
  String get seguimientoInicioVuelo => 'Inicio de vuelo';

  @override
  String get seguimientoAcuerdenFechaPorChat =>
      'Acuerda la fecha con el piloto por el chat.';

  @override
  String get seguimientoCierrePrecioFinal => 'Cierre y precio final';

  @override
  String get seguimientoTerminarLote => 'Al terminar el lote';

  @override
  String seguimientoHa(String total) {
    return ' / $total ha';
  }

  @override
  String get seguimientoPilotoTodaviaEmpezoAcuerden =>
      'El piloto todavía no empezó. Acuerda la fecha con él por el chat.';

  @override
  String seguimientoUltimaActualizacion(String ahora) {
    return 'Última actualización $ahora';
  }

  @override
  String get seguimientoPrecioFinalPagar => 'Precio final a pagar';

  @override
  String get seguimientoPagasPilotoFueraApp =>
      'Le pagas al piloto fuera de la app.';

  @override
  String seguimientoFoto(String nombre) {
    return 'Foto de $nombre';
  }

  @override
  String get seguimientoPiloto => 'Tu piloto';

  @override
  String get seguimientoChat => 'Chat';

  @override
  String get seguimientoTodaviaHayFotosPiloto =>
      'Todavía no hay fotos. El piloto las sube a medida que avanza, y las verás aquí.';

  @override
  String get seguimientoFotoDelAvance => 'Foto del avance';

  @override
  String get seguimientoCerrar => 'Cerrar';

  @override
  String seguimientoFotoDelAvance2(String subidaEn) {
    return 'Foto del avance, $subidaEn';
  }

  @override
  String get seguimientoUltimaFotoDelAvance => 'Última foto del avance';

  @override
  String get seguimientoFotoAnteriorDelAvance => 'Foto anterior del avance';

  @override
  String seguimientoFotoDelAvanceToca(String subidaEn, String subidaEn2) {
    return 'Foto del avance, $subidaEn $subidaEn2. Toca para ampliar';
  }

  @override
  String seguimientoHitoAvance(String porcentaje) {
    return 'Avance $porcentaje %';
  }

  @override
  String seguimientoHitoFotos(int fotos, String hace) {
    String _temp0 = intl.Intl.pluralLogic(
      fotos,
      locale: localeName,
      other: '$fotos fotos',
      one: '1 foto',
    );
    return '$_temp0$hace';
  }

  @override
  String seguimientoHitoHaceSufijo(String hace) {
    return ' · $hace';
  }

  @override
  String ofertasContraofertarA(String nombre) {
    return 'Contraofertar a $nombre';
  }

  @override
  String get ofertasOfertaRecibida => '1 oferta recibida';

  @override
  String ofertasOfertasRecibidas(int recibidas) {
    return '$recibidas ofertas recibidas';
  }

  @override
  String get ofertasLasOfertas => 'las ofertas';

  @override
  String get ofertasEnviarContraoferta => 'Enviar contraoferta';

  @override
  String ofertasPedido(String id) {
    return 'SOLICITUD #$id';
  }

  @override
  String get ofertasSolicitudExpiroAbrelaNuevo =>
      'La solicitud expiró. Ábrela de nuevo para recibir ofertas.';

  @override
  String get ofertasSolicitudCancelo => 'La solicitud se canceló.';

  @override
  String get ofertasElegistePilotoParaEsta =>
      'Ya elegiste a un piloto para esta solicitud.';

  @override
  String get ofertasOfertasCerradas => 'Ofertas cerradas';

  @override
  String get ofertasSinCalificaciones => 'Sin calificaciones';

  @override
  String get ofertasAceptoPrecio => 'Aceptó tu precio';

  @override
  String ofertasContraoferta(int numero, int maximo) {
    return 'Tu contraoferta · R$numero/$maximo';
  }

  @override
  String get ofertasEnviamosContraofertaPilotoTiene =>
      'Enviamos tu contraoferta. El piloto tiene que responder.';

  @override
  String get ofertasRechazasteOfertaLasDemas =>
      'Rechazaste la oferta. Las demás siguen abiertas.';

  @override
  String get ofertasSinConexionEnviamosRespuesta =>
      'Sin conexión. No se envió tu respuesta; vuelve a intentarlo cuando tengas señal.';

  @override
  String get ofertasPudimosEnviarRespuesta =>
      'No pudimos enviar tu respuesta. Vuelve a intentarlo.';

  @override
  String ofertasContraofertaRonda(int numero) {
    return 'Tu contraoferta · ronda $numero';
  }

  @override
  String get ofertasAceptaPrecio => 'Acepta tu precio';

  @override
  String ofertasPideMasQuePrecio(String dif) {
    return 'Pide $dif/ha más que tu precio';
  }

  @override
  String get ofertasIgualaPrecio => 'Iguala tu precio';

  @override
  String ofertasOfreceMenosQuePrecio(String dif) {
    return 'Ofrece $dif/ha menos que tu precio';
  }

  @override
  String ofertasLote(String distanciaKm) {
    return 'A $distanciaKm de tu lote';
  }

  @override
  String ofertasCanceloSusServicios(int porcentaje) {
    return 'Canceló $porcentaje % de sus servicios';
  }

  @override
  String get ofertasOfertaVencio => 'La oferta venció';

  @override
  String ofertasVence(String inMinutes) {
    return 'Vence en $inMinutes';
  }

  @override
  String get ofertasVencida => 'Vencida';

  @override
  String get seguimientoChat2 => 'el chat';

  @override
  String seguimientoMapaDelLoteSin(String nombre) {
    return 'Mapa del lote $nombre, sin ubicación del piloto';
  }

  @override
  String seguimientoMapaDelLoteCon(String nombre) {
    return 'Mapa del lote $nombre con la última ubicación del piloto';
  }

  @override
  String seguimientoServicioTerminado(String nombre) {
    return '$nombre · servicio terminado';
  }

  @override
  String get seguimientoPrecioFinal2 => 'el precio final';

  @override
  String seguimientoPedido(String id) {
    return 'SOLICITUD #$id';
  }

  @override
  String get seguimientoTotalPagarPiloto => 'Total a pagar al piloto';

  @override
  String get seguimientoReportarProblema => 'Reportar un problema';

  @override
  String get seguimientoServicioTerminado2 => 'Servicio terminado';

  @override
  String get seguimientoServicioCurso => 'Servicio en curso';

  @override
  String get seguimientoSeguimiento => 'Seguimiento';

  @override
  String get seguimientoSeguimiento2 => 'el seguimiento';

  @override
  String get seguimientoMasFotosDelAvance => 'Más fotos del avance';

  @override
  String get seguimientoDondeEstaPiloto => 'Dónde está el piloto';

  @override
  String get seguimientoNotasDelPiloto => 'Notas del piloto';

  @override
  String seguimientoDeHa(String hechas, String total) {
    return '$hechas de $total ha';
  }

  @override
  String seguimientoPropuesto(String precioHaPropuesto) {
    return '$precioHaPropuesto/ha propuesto';
  }

  @override
  String seguimientoAcordado(String precioHaAcordado) {
    return '$precioHaAcordado/ha acordado';
  }

  @override
  String get seguimientoPilotoComparteUbicacionCuando =>
      'El piloto comparte su ubicación cuando empieza el trabajo.';

  @override
  String get seguimientoSinUbicacionRecienteEscribele =>
      'Sin ubicación reciente. Escríbele por el chat si necesitas saber dónde está.';

  @override
  String seguimientoUltimaUbicacion(String ahora) {
    return 'Última ubicación $ahora.';
  }

  @override
  String seguimientoSinUbicacionRecienteUltima(String ahora) {
    return 'Sin ubicación reciente. La última fue $ahora.';
  }

  @override
  String ofertasRondaCorta(int numero, int maximo) {
    return 'R$numero/$maximo';
  }

  @override
  String ofertasNotaCalificaciones(String nota, int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$cantidad calificaciones',
      one: '1 calificación',
    );
    return '$nota/5 · $_temp0';
  }

  @override
  String get ofertasOrdenPrecio => 'Menor precio';

  @override
  String get ofertasOrdenCalificacion => 'Mejor calificación';

  @override
  String get ofertasOrdenDistancia => 'Más cerca';

  @override
  String get ofertasOfertaCambio => 'La oferta cambió.';

  @override
  String ofertasActualizamosLista(String motivo) {
    return '$motivo Actualizamos la lista.';
  }

  @override
  String get seguimientoElPiloto => 'El piloto';

  @override
  String seguimientoHoraUltima(String hora) {
    return '$hora · ÚLTIMA';
  }

  @override
  String get seguimientoFotosUnidad => 'fotos';

  @override
  String get seguimientoDelServicio => 'del servicio';

  @override
  String get solicitarTodaviaTienesLotesGuardados =>
      'Todavía no tienes lotes guardados';

  @override
  String get solicitarPasaDibujarMarcaLas =>
      'Pasa a «Dibujar» y marca las esquinas en el mapa.';

  @override
  String get solicitarDeshacer => 'Deshacer';

  @override
  String get solicitarBorrarTodo => 'Borrar todo';

  @override
  String get solicitarHectareasFumigar => 'Hectáreas a fumigar';

  @override
  String get solicitarHa => 'ha';

  @override
  String get solicitarPedirloParaMananaMarca =>
      'Si la necesitas para mañana, tu solicitud se marca como urgente. Los pilotos con el dron libre responden más rápido.';

  @override
  String get solicitarComoLlegaLoteOpcional =>
      'Cómo se llega al lote (opcional)';

  @override
  String get solicitarCaminoPortonReferencias => 'Camino, portón, referencias';

  @override
  String get solicitarObservacionesOpcional => 'Observaciones (opcional)';

  @override
  String get solicitarCultivosVecinosLineasElectricas =>
      'Cultivos vecinos, líneas eléctricas, estado del lote';

  @override
  String get solicitarLosPilotosPuedenAceptar =>
      'Los pilotos pueden aceptar tu precio o proponer el suyo. Tú eliges la oferta que prefieras.';

  @override
  String get solicitarPrecioPorHectarea => 'Precio por hectárea';

  @override
  String get solicitarPrecioExactoPorHectarea => 'Precio exacto por hectárea';

  @override
  String get solicitarPrecioExacto => 'Precio exacto';

  @override
  String get solicitarBs => 'Bs ';

  @override
  String get solicitarPor => 'por ha';

  @override
  String get solicitarTotalEstimado => 'Total estimado';

  @override
  String get solicitarBs2 => 'Bs —';

  @override
  String get solicitarPrecioFinalCalculaCon =>
      'El precio final se calcula con las hectáreas realmente ejecutadas. Le pagas al piloto al terminar, fuera de la app.';

  @override
  String get solicitarPasoAnterior => 'Paso anterior';

  @override
  String solicitarPaso(int indice, int total, String etiqueta) {
    return 'Paso $indice de $total · $etiqueta';
  }

  @override
  String get solicitarPublicarLote => 'Publicar lote';

  @override
  String get solicitarPudimosCargarTusLotes => 'No pudimos cargar tus lotes';

  @override
  String get solicitarPublicarUnaSolicitudNecesita =>
      'Publicar una solicitud necesita conexión. Revisa la señal y vuelve a intentarlo.';

  @override
  String get solicitarReintentar => 'Reintentar';

  @override
  String solicitarSuperficie(String texto) {
    return 'Superficie: $texto';
  }

  @override
  String solicitarEsquinaDelLote(int numero) {
    return 'Esquina $numero del lote';
  }

  @override
  String get solicitudesSuperficie => 'Superficie';

  @override
  String get solicitudesTotal => 'Total';

  @override
  String solicitudesCalificasteCon(int puntajeDelCliente) {
    return 'Calificaste con $puntajeDelCliente';
  }

  @override
  String get solicitudesSolicitud => 'Solicitud';

  @override
  String get solicitudesEncontramosEstaSolicitud =>
      'No encontramos esta solicitud';

  @override
  String get solicitudesVuelveSolicitudesAbrelaNuevo =>
      'Vuelve a «Solicitudes» y ábrela de nuevo.';

  @override
  String get solicitudesCambiarPrecio => 'Cambiar tu precio';

  @override
  String get solicitudesLasOfertasQueRecibiste =>
      'Las ofertas que ya recibiste no cambian; los pilotos que negocian contigo reciben una notificación.';

  @override
  String get solicitudesVerLasOfertas => 'Ver las ofertas';

  @override
  String get solicitudesVerSeguimientoChat => 'Ver seguimiento y chat';

  @override
  String get solicitudesCalificarPiloto => 'Calificar al piloto';

  @override
  String get solicitudesVolverAbrirSolicitud => 'Volver a abrir la solicitud';

  @override
  String get solicitudesEditarPrecio => 'Editar precio';

  @override
  String solicitudesVence(String venceEn) {
    return 'Vence el $venceEn';
  }

  @override
  String get solicitudesCultivo => 'Cultivo';

  @override
  String get solicitudesDesde => 'Desde';

  @override
  String get solicitudesReintentar => 'Reintentar';

  @override
  String get solicitudesCancelarSolicitud => 'Cancelar la solicitud';

  @override
  String get solicitudesReportarProblema => 'Reportar un problema';

  @override
  String get solicitudesVolver => 'Volver';

  @override
  String get solicitudesPrecioFinalPagar => 'Precio final a pagar';

  @override
  String solicitudesEjecutadas(String ejecutadas, String precioHaVigente) {
    return '$ejecutadas ejecutadas × $precioHaVigente/ha';
  }

  @override
  String get solicitudesPagasPilotoDirectamenteFuera =>
      'Le pagas al piloto directamente, fuera de la app. Agrocom no cobra ni suma nada a este monto.';

  @override
  String solicitudesReportasteProblemaCasoSoporte(
    String etiqueta,
    String numeroCaso,
    String etiqueta2,
  ) {
    return 'Reportaste un problema: $etiqueta. Caso $numeroCaso, $etiqueta2. Soporte te responde en 24 horas hábiles.';
  }

  @override
  String get solicitudesCancelarSolicitud2 => '¿Cancelar la solicitud?';

  @override
  String get solicitudesGratisLosPilotosCon =>
      'Es gratis. Los pilotos con ofertas verán que se cerró.';

  @override
  String get solicitudesMotivo => 'Motivo';

  @override
  String get solicitudesCancelarSolicitud3 => 'Cancelar solicitud';

  @override
  String get solicitudesMisSolicitudes => 'Mis solicitudes';

  @override
  String get solicitudesSinConexionVesUltimo =>
      'Sin conexión. Ves lo último que cargamos; puede estar desactualizado.';

  @override
  String get solicitudesTodos => 'Todas';

  @override
  String get solicitudesActivos => 'Activas';

  @override
  String get solicitudesListos => 'Terminadas';

  @override
  String get solicitudesFumigadoConAgrocom => 'Fumigado con Agrocom';

  @override
  String get solicitarQueLoteFumigamos => '¿Qué lote fumigamos?';

  @override
  String get solicitarTocaMapaCadaEsquina =>
      'Toca el mapa en cada esquina del lote. Con tres esquinas ya se calcula la superficie.';

  @override
  String get solicitarBienMarcaDosEsquinas => 'Bien. Marca dos esquinas más.';

  @override
  String get solicitarFaltaUnaEsquinaPara =>
      'Falta una esquina para cerrar el lote.';

  @override
  String get solicitarContornoListoArrastraUna =>
      'Contorno listo. Arrastra una esquina para ajustarla o sigue agregando puntos.';

  @override
  String get solicitarQueVamosAplicar => '¿Qué vamos a aplicar?';

  @override
  String get solicitarCultivo => 'Cultivo';

  @override
  String get solicitarProducto => 'Producto';

  @override
  String get solicitarCuandoNecesitas => '¿Cuándo lo necesitas?';

  @override
  String get solicitarDatosParaLosPilotos => 'Datos para los pilotos';

  @override
  String get solicitarCuantoPagasPorHectarea => '¿Cuánto pagas por hectárea?';

  @override
  String get solicitarEscribePrecioParaVer =>
      'Escribe un precio para ver cuánto sería.';

  @override
  String solicitarHa2(String precio, String hectareas) {
    return '$precio/ha × $hectareas';
  }

  @override
  String get solicitarLote => 'Lote';

  @override
  String get solicitarSuperficie2 => 'Superficie';

  @override
  String get solicitarFecha => 'Fecha';

  @override
  String get solicitarReintentarPublicacion => 'Reintentar publicación';

  @override
  String get solicitarPublicarSolicitud => 'Publicar solicitud';

  @override
  String get solicitarContinuar => 'Continuar';

  @override
  String solicitarMapaParaDibujarContorno(int vertices) {
    return 'Mapa para dibujar el contorno del lote. $vertices esquinas marcadas.';
  }

  @override
  String solicitarMapaLoteElegido(String nombre, String zona) {
    return 'Mapa. Lote elegido: $nombre, $zona.';
  }

  @override
  String get solicitarMapaTusLotesToca =>
      'Mapa de tus lotes. Toca uno para elegirlo.';

  @override
  String get solicitarArrastraParaMoverla => 'Arrastra para moverla';

  @override
  String get calificarComoFueServicio => '¿Cómo fue el servicio?';

  @override
  String calificarComoFueServicio2(String primerNombre) {
    return '¿Cómo fue el servicio de $primerNombre?';
  }

  @override
  String get calificarSinConexionCalificacionEnvio =>
      'Sin conexión. Tu calificación no se envió; vuelve a intentarlo cuando tengas señal.';

  @override
  String get calificarPudimosEnviarCalificacionPrueba =>
      'No pudimos enviar tu calificación. Vuelve a intentarlo.';

  @override
  String get calificarReintentar => 'Reintentar';

  @override
  String get calificarEnviarCalificacion => 'Enviar calificación';

  @override
  String get calificarQueDestacas => '¿Qué destacas?';

  @override
  String get calificarQuePuedeMejorar => '¿Qué se puede mejorar?';

  @override
  String get accesoSesionVencioEntraNuevo =>
      'Tu sesión venció. Ingresa de nuevo.';

  @override
  String get accesoTusDatos => 'Tus datos';

  @override
  String get accesoAcceso => 'Tu acceso';

  @override
  String get acceso118 => '118 ha × 64';

  @override
  String get acceso552 => 'Bs 7.552';

  @override
  String get inicioVerOtraSolicitudActiva => 'Ver la otra solicitud activa';

  @override
  String inicioVerLasOtrasSolicitudes(int otrosActivos) {
    return 'Ver las otras $otrosActivos solicitudes activas';
  }

  @override
  String get inicioPorCalificar => 'Por calificar';

  @override
  String get inicioAvisos => 'Notificaciones';

  @override
  String get inicioHistorialReciente => 'Historial reciente';

  @override
  String get inicioVerTodo => 'Ver todo';

  @override
  String get inicioSinConexion => 'Sin conexión';

  @override
  String get inicioPudimosCargarInicio => 'No pudimos cargar tu inicio';

  @override
  String get inicioRevisaSenalIntentaNuevo =>
      'Revisa tu señal y vuelve a intentarlo. Publicar una solicitud requiere conexión.';

  @override
  String get inicioIntentaNuevoMomento => 'Vuelve a intentarlo en un momento.';

  @override
  String comunEnviando(String texto) {
    return '$texto, enviando';
  }

  @override
  String get comunFoto => 'Foto';

  @override
  String get comunEscribePrecioParaVer =>
      'Escribe un precio para ver el total.';

  @override
  String comunTotalEstimadoPor(String valor, String hectareas) {
    return 'Total estimado: $valor por $hectareas';
  }

  @override
  String get solicitudesPrecioAcordado => 'Precio acordado';

  @override
  String get solicitudesPrecio => 'Tu precio';

  @override
  String get solicitudesSolicitud2 => 'la solicitud';

  @override
  String get solicitudesGuardarPrecio => 'Guardar precio';

  @override
  String solicitudesPublicada(String zona, String publicadaEn) {
    return '$zona · publicada el $publicadaEn';
  }

  @override
  String get solicitudesSinConexionGuardoCambio =>
      'Sin conexión. No se guardó el cambio; vuelve a intentarlo cuando tengas señal.';

  @override
  String get solicitudesPudimosCompletarOperacion =>
      'No pudimos completar la operación. Vuelve a intentarlo.';

  @override
  String get solicitudesSinConexionFaltanCargar =>
      'Sin conexión. No pudimos cargar tu calificación ni el reclamo.';

  @override
  String get solicitudesPudimosCargarCalificacionReclamo =>
      'No pudimos cargar tu calificación y el reclamo.';

  @override
  String get solicitudesCancelasteEstaSolicitudPuedes =>
      'Cancelaste esta solicitud. Puedes publicar otra desde «Solicitar».';

  @override
  String solicitudesCancelasteEstaSolicitudPuedes2(String motivoCancelacion) {
    return 'Cancelaste esta solicitud: $motivoCancelacion. Puedes publicar otra desde «Solicitar».';
  }

  @override
  String get solicitudesEstado => 'Estado';

  @override
  String get solicitudesQuienFumiga => 'Quién fumiga';

  @override
  String get solicitudesQuePediste => 'Lo que solicitaste';

  @override
  String get solicitudesProducto => 'Producto';

  @override
  String get solicitudesFechaDeseada => 'Fecha deseada';

  @override
  String get solicitudesAccesos => 'Accesos';

  @override
  String get solicitudesObservaciones => 'Observaciones';

  @override
  String get solicitudesCalificacion => 'Tu calificación';

  @override
  String get solicitudesTusSolicitudes => 'tus solicitudes';

  @override
  String get solicitudesTodaviaPublicasteSolicitudes =>
      'Todavía no publicaste solicitudes';

  @override
  String get solicitudesHaySolicitudesCurso => 'No hay solicitudes en curso';

  @override
  String get solicitudesTodaviaHayServiciosTerminados =>
      'Todavía no hay servicios terminados';

  @override
  String get solicitudesCuandoPilotoTerminaQueda =>
      'Cuando un piloto termina, queda guardado aquí con sus fotos y el precio final.';

  @override
  String get solicitudesPublicaLoteComparaLas =>
      'Publica un lote, compara las ofertas de los pilotos y elige.';

  @override
  String get solicitarErrorHectareasVacio =>
      'Indica cuántas hectáreas quieres fumigar.';

  @override
  String get solicitarErrorNoEsNumeroHectareas =>
      'Escribe un número, por ejemplo 85,5.';

  @override
  String get solicitarErrorHectareasNoPositivas =>
      'La superficie tiene que ser mayor a 0.';

  @override
  String get solicitarErrorDosDecimales => 'Usa como máximo dos decimales.';

  @override
  String solicitarErrorHectareasMaximas(String maximo) {
    return 'Una solicitud admite hasta $maximo ha.';
  }

  @override
  String solicitarErrorHectareasSobreLote(String tope) {
    return 'El lote tiene $tope ha: no puedes solicitar más.';
  }

  @override
  String get solicitarErrorPrecioVacio =>
      'Propón cuánto pagarías por hectárea.';

  @override
  String get solicitarErrorNoEsNumeroPrecio =>
      'Escribe un número, por ejemplo 120.';

  @override
  String get solicitarErrorPrecioNoPositivo =>
      'El precio tiene que ser mayor a 0.';

  @override
  String solicitarHectareasDelContorno(String hectareas) {
    return 'Del contorno salen $hectareas. Ajústalas si vas a fumigar otra superficie.';
  }

  @override
  String solicitarHectareasDelLote(String hectareas) {
    return 'El lote tiene $hectareas. Ajústalas si vas a fumigar otra superficie.';
  }

  @override
  String get solicitarMisLotes => 'Mis lotes';

  @override
  String get solicitarDibujar => 'Dibujar';

  @override
  String get solicitarEnviandoSolicitud => 'Enviando la solicitud';

  @override
  String get solicitarPasoLote => 'Lote';

  @override
  String get solicitarPasoAplicacion => 'Aplicación';

  @override
  String get solicitarPasoCuando => 'Cuándo';

  @override
  String get solicitarPasoPrecio => 'Precio';

  @override
  String get accesoErrorCredenciales =>
      'El usuario o la contraseña no coinciden. Revísalos y vuelve a intentarlo.';

  @override
  String get accesoErrorSinConexion =>
      'Sin conexión. Lo que escribiste sigue aquí: vuelve a intentarlo cuando tengas señal.';

  @override
  String get accesoErrorDesconocido =>
      'No pudimos completar la operación. Vuelve a intentarlo en un momento.';

  @override
  String get accesoPortadaPublicaTitulo => 'Publica tu lote en el mapa';

  @override
  String get accesoPortadaPublicaDetalle =>
      'Marca el área, define tu precio por hectárea y recibe ofertas de pilotos cercanos.';

  @override
  String get accesoPortadaNegociaTitulo => 'Negocia hasta 5 rondas';

  @override
  String get accesoPortadaNegociaDetalle =>
      'Cada piloto acepta tu precio o contraoferta. Tú eliges con quién trabajar.';

  @override
  String get accesoPortadaPagasTitulo => 'Pagas lo que se fumigó';

  @override
  String get accesoPortadaPagasDetalle =>
      'Precio final = hectáreas ejecutadas × precio acordado. El pago es directo con el piloto.';

  @override
  String get historialMesEne => 'Ene';

  @override
  String get historialMesFeb => 'Feb';

  @override
  String get historialMesMar => 'Mar';

  @override
  String get historialMesAbr => 'Abr';

  @override
  String get historialMesMay => 'May';

  @override
  String get historialMesJun => 'Jun';

  @override
  String get historialMesJul => 'Jul';

  @override
  String get historialMesAgo => 'Ago';

  @override
  String get historialMesSep => 'Sep';

  @override
  String get historialMesOct => 'Oct';

  @override
  String get historialMesNov => 'Nov';

  @override
  String get historialMesDic => 'Dic';

  @override
  String solicitudesVerOfertas(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$cantidad ofertas',
      one: '1 oferta',
    );
    return 'Ver $_temp0';
  }

  @override
  String solicitudesPilotosOfertaron(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$cantidad pilotos ofertaron',
      one: '1 piloto ofertó',
    );
    return '$_temp0. Compáralas y elige la que prefieras.';
  }

  @override
  String solicitudesComentarioEntreComillas(String comentario) {
    return '«$comentario»';
  }

  @override
  String historialEnServicios(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$cantidad servicios',
      one: '1 servicio',
    );
    return 'en $_temp0';
  }

  @override
  String historialSemanticaHectareasPorMes(String detalle) {
    return 'Hectáreas fumigadas por mes: $detalle';
  }

  @override
  String get calificarTocaEstrella => 'Toca una estrella';

  @override
  String get calificarMalo => 'Malo';

  @override
  String get calificarRegular => 'Regular';

  @override
  String get calificarBueno => 'Bueno';

  @override
  String get calificarMuyBueno => 'Muy bueno';

  @override
  String get calificarExcelente => 'Excelente';

  @override
  String get terrenosSubePublicar => 'se sube al publicar';

  @override
  String get terrenosPudoSubir => 'no se pudo subir';

  @override
  String get terrenosFotosDelTerreno => 'Fotos del terreno';

  @override
  String get terrenosClienteSubioFotosDel =>
      'El cliente no subió fotos del terreno. Si te eligen, pregúntale por el estado del lote en el chat.';

  @override
  String terrenosFoto(int _actual, int fotos) {
    return 'Foto $_actual de $fotos';
  }

  @override
  String get terrenosCerrar => 'Cerrar';

  @override
  String terrenosFotos(int fotos, int maximo) {
    return '$fotos de $maximo fotos';
  }

  @override
  String get terrenosAgregaFotosDelEstado =>
      'Agrega fotos del estado del terreno: el piloto las ve antes de ofertar y ajusta mejor su precio.';

  @override
  String get terrenosSubenCuandoPubliquesSolicitud =>
      'Se suben cuando publiques la solicitud.';

  @override
  String get terrenosPilotoLasAntesOfertar =>
      'El piloto las ve antes de ofertar.';

  @override
  String get terrenosTomarUnaFoto => 'Tomar una foto';

  @override
  String get terrenosElegirGaleria => 'Elegir de la galería';

  @override
  String get terrenosAgregarUnaFotoDel => 'Agregar una foto del terreno';

  @override
  String get terrenosAgregar => 'Agregar';

  @override
  String get proveedorDronDronRegistrado => '1 dron registrado';

  @override
  String proveedorDronDronesRegistrados(int drones) {
    return '$drones drones registrados';
  }

  @override
  String get proveedorDronMisDrones => 'Mis drones';

  @override
  String get proveedorDronPudimosCargarTusDrones =>
      'No pudimos cargar tus drones';

  @override
  String get proveedorDronRevisaConexionVolveIntentar =>
      'Revisa la conexión y vuelve a intentarlo.';

  @override
  String get proveedorDronTodaviaRegistrasteDrones =>
      'Todavía no registraste drones';

  @override
  String get proveedorDronSinDronAprobadoLlegan =>
      'Sin un dron aprobado no llegan ofertas. Cada dron lo aprueba un administrador.';

  @override
  String pagoPagoConfirmado(String detalle) {
    return 'Pago confirmado. $detalle';
  }

  @override
  String get pagoPagoConfirmado2 => 'Pago confirmado';

  @override
  String get pagoQuedoRegistradoClienteHay =>
      'Ya quedó registrado y el cliente lo ve. No hay nada más que hacer.';

  @override
  String get pagoPilotoConfirmoQueRecibio =>
      'El piloto confirmó que recibió el pago. Gracias por usar Agrocom.';

  @override
  String get pagoPudimosRevisarPago => 'No pudimos revisar el pago.';

  @override
  String get pagoReintentar => 'Reintentar';

  @override
  String get pagoPagoPendiente => 'Pago pendiente';

  @override
  String get pagoPagasPilotoDirectamenteCuando =>
      'Le pagas al piloto directamente. Cuando él confirme que lo recibió, lo verás aquí.';

  @override
  String get pagoConfirmasQueRecibistePago =>
      '¿Confirmas que recibiste el pago?';

  @override
  String get pagoSoloPuedeConfirmarUna =>
      'Solo se puede confirmar una vez. El cliente verá que el pago quedó confirmado.';

  @override
  String get pagoTodavia => 'Todavía no';

  @override
  String get pagoRecibi => 'Sí, lo recibí';

  @override
  String get pagoPagaron => '¿Ya te pagaron?';

  @override
  String get pagoClientePagaDirectamenteCuando =>
      'El cliente te paga directamente. Cuando lo recibas, confírmalo aquí: la app no cobra ni mueve dinero.';

  @override
  String get pagoComoPagoOpcional => '¿Cómo te pagó? (opcional)';

  @override
  String get pagoPudimosConfirmarPago => 'No pudimos confirmar el pago.';

  @override
  String get pagoRecibiPago => 'Ya recibí el pago';

  @override
  String get marketplaceAccesoFumigacionConDron => 'Fumigación con dron';

  @override
  String get marketplaceAccesoFumigacionConDronPrecio =>
      'Fumigación con dron, al precio que acuerdes';

  @override
  String get marketplaceAccesoPublicaLoteRecibeOfertas =>
      'Publica tu lote, recibe ofertas de pilotos y elige. El pago es directo con el piloto.';

  @override
  String get marketplaceAccesoComoVasUsarAgrocom => '¿Cómo vas a usar Agrocom?';

  @override
  String get marketplaceAccesoEligeRol => 'Elige tu rol';

  @override
  String marketplaceAccesoContinuarComo(String enBoton) {
    return 'Continuar como $enBoton';
  }

  @override
  String get marketplaceAccesoTengoCuenta => 'Ya tengo cuenta';

  @override
  String fotoPerfilFotoPerfilTocaPara(String nombre) {
    return 'Foto de perfil de $nombre. Toca para cambiarla';
  }

  @override
  String get fotoPerfilSinFotoPerfilToca =>
      'Sin foto de perfil. Toca para agregar una';

  @override
  String get fotoPerfilSubiendoFoto => 'Subiendo foto…';

  @override
  String get fotoPerfilCambiarFoto => 'Cambiar foto';

  @override
  String get fotoPerfilAgregarFoto => 'Agregar foto';

  @override
  String get fotoPerfilQuitar => 'Quitar';

  @override
  String get fotoPerfilConUnaFotoCliente =>
      'Con una foto, el cliente te reconoce al llegar al lote.';

  @override
  String get fotoPerfilReintentar => 'Reintentar';

  @override
  String get fotoPerfilTomarUnaFoto => 'Tomar una foto';

  @override
  String get fotoPerfilElegirGaleria => 'Elegir de la galería';

  @override
  String get fotoPerfilQuitarFoto => 'Quitar la foto';

  @override
  String get fotoSinConexionReintentar =>
      'Sin conexión. Revisa tu señal y vuelve a intentarlo.';

  @override
  String get fotoPerfilNoPreparada =>
      'No pudimos preparar la foto. Prueba con otra.';

  @override
  String get fotoPerfilQuitada => 'Quitamos tu foto. Verás tus iniciales.';

  @override
  String get fotoPerfilNoQuitada =>
      'No pudimos quitar la foto. Vuelve a intentarlo.';

  @override
  String get fotoPerfilActualizada =>
      'Listo: tu foto de perfil está actualizada.';

  @override
  String get fotoPerfilNoSubida =>
      'No pudimos subir la foto. Vuelve a intentarlo.';

  @override
  String get pagoNoPudimosRevisar =>
      'No pudimos revisar el pago. Vuelve a intentarlo.';

  @override
  String get pagoNoPudimosConfirmar =>
      'No pudimos confirmar el pago. Tu confirmación no se perdió: vuelve a intentarlo.';

  @override
  String get pagoSoloTitular =>
      'Solo el titular del proveedor puede confirmar el pago. Pídele que lo haga desde su cuenta.';

  @override
  String terrenosFotosMaximo(int maximo) {
    return 'Ya tienes $maximo fotos, el máximo. Quita una para agregar otra.';
  }

  @override
  String get terrenosFotoNoPreparada =>
      'No pudimos preparar la foto. Prueba con otra.';

  @override
  String get terrenosFotoGuardada => 'Foto guardada.';

  @override
  String get terrenosFotoNoSubida =>
      'No pudimos subir la foto. Vuelve a intentarlo.';

  @override
  String get terrenosFotoQuitada => 'Quitamos la foto.';

  @override
  String get terrenosFotoNoQuitada =>
      'No pudimos quitar la foto. Vuelve a intentarlo.';

  @override
  String get fotoMuyPesada =>
      'La foto es muy pesada. Elige otra o toma una nueva.';

  @override
  String get componentesEnviando => 'Enviando…';

  @override
  String get componentesAceptarServicio => 'Aceptar servicio';

  @override
  String uiMapaDelLote(String nombre, String zona) {
    return 'Mapa del lote $nombre, $zona';
  }

  @override
  String get uiMapaLotes => 'Mapa de lotes';

  @override
  String uiEstado(String etiqueta) {
    return 'Estado: $etiqueta';
  }

  @override
  String uiCurso(String texto) {
    return '$texto, en curso';
  }

  @override
  String get uiMostrarContrasena => 'Mostrar contraseña';

  @override
  String get uiOcultarContrasena => 'Ocultar contraseña';

  @override
  String proveedorDronBateriaCiclosPorCiento(
    int ciclosBateria,
    int cicloMaximoBateria,
    int porcentaje,
  ) {
    return 'Batería: $ciclosBateria de $cicloMaximoBateria ciclos, $porcentaje por ciento de la vida útil';
  }

  @override
  String get proveedorDronCiclosBateria => 'CICLOS DE BATERÍA';

  @override
  String proveedorDronDe(int cicloMaximoBateria) {
    return ' de $cicloMaximoBateria';
  }

  @override
  String get proveedorDronBateriaCumplioVidaUtil =>
      'La batería cumplió su vida útil. Hay que cambiarla.';

  @override
  String proveedorDronQuedanCiclosPlanificaRecambio(int ciclosRestantes) {
    return 'Quedan $ciclosRestantes ciclos. Planifica el recambio.';
  }

  @override
  String proveedorDronQuedanCiclosVidaUtil(int ciclosRestantes) {
    return 'Quedan $ciclosRestantes ciclos de vida útil.';
  }

  @override
  String get proveedorPerfilEstasHabilitadoParaRecibir =>
      'Estás habilitado para recibir ofertas.';

  @override
  String get proveedorPerfilAdministradorEstaRevisandoTus =>
      'Un administrador está revisando tus datos. Te avisamos cuando puedas recibir ofertas.';

  @override
  String get proveedorPerfilRecibisOfertasMientrasDure =>
      'No recibes ofertas mientras dure la suspensión.';

  @override
  String get proveedorPerfilSolicitudAproboPodesCorregir =>
      'Tu registro no se aprobó. Puedes corregir los datos y reenviarlo.';

  @override
  String proveedorPerfilMotivo(String motivo) {
    return 'Motivo: $motivo';
  }

  @override
  String get proveedorPerfilServicios => 'SERVICIOS';

  @override
  String get proveedorPerfilHectareas => 'HECTÁREAS';

  @override
  String get proveedorPerfilCancelacion => 'CANCELACIÓN';

  @override
  String proveedorPerfilVencio(String vence) {
    return 'Venció el $vence';
  }

  @override
  String proveedorPerfilVence(String vence) {
    return 'Vence el $vence';
  }

  @override
  String proveedorPerfilCalificacionPromedioSobreCalificaciones(
    String promedio,
    int total,
  ) {
    return 'Calificación promedio $promedio de 5, sobre $total calificaciones';
  }

  @override
  String get proveedorPerfilCalificacion => '1 calificación';

  @override
  String proveedorPerfilCalificaciones(int total) {
    return '$total calificaciones';
  }

  @override
  String terrenosFotoDelTerreno(int numero, String estado) {
    return 'Foto $numero del terreno, $estado';
  }

  @override
  String get terrenosReintentar => 'Reintentar';

  @override
  String terrenosQuitarFoto(int numero) {
    return 'Quitar la foto $numero';
  }

  @override
  String get proveedorAccesoEntraCuenta => 'Ingresa a tu cuenta';

  @override
  String get proveedorAccesoConUsuarioContrasena =>
      'Con tu usuario y tu contraseña.';

  @override
  String get proveedorAccesoUsuario => 'Usuario';

  @override
  String get proveedorAccesoEscribeUsuario => 'Escribe tu usuario.';

  @override
  String get proveedorAccesoContrasena => 'Contraseña';

  @override
  String get proveedorAccesoEscribeContrasena => 'Escribe tu contraseña.';

  @override
  String get proveedorAccesoEntrar => 'Ingresar';

  @override
  String get proveedorAccesoSoyPilotoQuieroRegistrarme =>
      'Soy piloto y quiero registrarme';

  @override
  String get proveedorAccesoDatosPersonales => 'Datos personales';

  @override
  String get proveedorAccesoLicencia => 'Tu licencia';

  @override
  String get proveedorAccesoEquipo => 'Tu equipo';

  @override
  String get proveedorAccesoFotosDelDron => 'Fotos del dron';

  @override
  String get proveedorAccesoAsiIdentificamosContactanLos =>
      'Así te identificamos y te contactan los clientes.';

  @override
  String get proveedorAccesoAdministradorRevisaAntesQue =>
      'Un administrador la revisa antes de que veas solicitudes.';

  @override
  String get proveedorAccesoDronVehiculoRevisamosAntes =>
      'Tu dron es tu vehículo: lo revisamos antes de aprobarlo.';

  @override
  String get proveedorAccesoFrontalLateralPlacaSerie =>
      'Frontal, lateral y placa de serie.';

  @override
  String get proveedorAccesoEligeFecha => 'Elige la fecha';

  @override
  String get proveedorAccesoEligeUnaFecha => 'Elige una fecha.';

  @override
  String get proveedorAccesoCarnetIdentidad => 'Carnet de identidad';

  @override
  String get proveedorAccesoFechaNacimiento => 'Fecha de nacimiento';

  @override
  String get proveedorAccesoTelefono => 'Teléfono';

  @override
  String get proveedorAccesoConEsteUsuarioEntras =>
      'Con este usuario ingresas a la app. No usa correo.';

  @override
  String get proveedorAccesoUsaMenosCaracteres => 'Usa al menos 8 caracteres.';

  @override
  String get proveedorAccesoNumeroLicenciaPiloto =>
      'Número de licencia de piloto';

  @override
  String get proveedorAccesoVence => 'Vence el';

  @override
  String get proveedorAccesoCategoriaHabilitacion =>
      'Categoría de habilitación';

  @override
  String get proveedorAccesoComoFiguraLicencia => 'Como figura en tu licencia.';

  @override
  String get proveedorAccesoRevisionTerminarRegistro =>
      'En revisión al terminar el registro';

  @override
  String get proveedorAccesoNumeroSerie => 'Número de serie';

  @override
  String get proveedorAccesoAnoOpcional => 'Año (opcional)';

  @override
  String get proveedorAccesoCapacidadDelTanqueLitros =>
      'Capacidad del tanque (litros)';

  @override
  String get proveedorAccesoAnchoPasadaMetros => 'Ancho de pasada (metros)';

  @override
  String get proveedorAccesoRegistroPiloto => 'Registro de piloto';

  @override
  String get proveedorAccesoPasoAnterior => 'Paso anterior';

  @override
  String get proveedorAccesoContinuar => 'Continuar';

  @override
  String get proveedorAccesoCrearCuenta => 'Crear cuenta';

  @override
  String get proveedorAccesoReintentar => 'Reintentar';

  @override
  String get proveedorAccesoFaltanLasFotosObligatorias =>
      'Faltan las fotos obligatorias: frontal, lateral y placa de serie.';

  @override
  String proveedorAccesoPaso(int paso, int total, String titulo) {
    return 'Paso $paso de $total, $titulo';
  }

  @override
  String proveedorAccesoPaso2(int paso, int total) {
    return 'PASO $paso DE $total';
  }

  @override
  String get proveedorAccesoAdministradorLasRevisaAntes =>
      'Un administrador las revisa antes de aprobar tu dron. Cada foto se comprime sola a menos de 300 KB.';

  @override
  String proveedorAccesoFoto(String etiqueta) {
    return 'Foto $etiqueta';
  }

  @override
  String get proveedorAccesoLista => 'Lista';

  @override
  String get proveedorAccesoFalta => 'Falta';

  @override
  String proveedorAccesoFotoDelDron(String etiqueta) {
    return 'Foto $etiqueta del dron';
  }

  @override
  String get proveedorAccesoTomarOtra => 'Tomar otra';

  @override
  String get proveedorAccesoCamara => 'Cámara';

  @override
  String get proveedorAccesoGaleria => 'Galería';

  @override
  String get proveedorAccesoQuitar => 'Quitar';

  @override
  String get proveedorAccesoRegistroEstaRevision =>
      'Tu registro está en revisión';

  @override
  String get proveedorAccesoAdministradorRevisaLicenciaDron =>
      'Un administrador revisa tu licencia y tu dron. Mientras tanto no verás solicitudes; te avisamos cuando estés aprobado.';

  @override
  String get proveedorAccesoEntrarApp => 'Ingresar a la app';

  @override
  String get proveedorNegociacionLasSolicitudesLasOfertas =>
      'las solicitudes y las ofertas necesitan red.';

  @override
  String get proveedorNegociacionBuscarZonaLote => 'Buscar zona o lote';

  @override
  String get proveedorNegociacionFiltrosHayFiltrosAplicados =>
      'Filtros, hay filtros aplicados';

  @override
  String get proveedorNegociacionFiltros => 'Filtros';

  @override
  String get proveedorNegociacionCerca => 'Cerca de mí';

  @override
  String get proveedorNegociacion50Ha => '+50 ha';

  @override
  String get proveedorNegociacionVenceHoy => 'Vence hoy';

  @override
  String get proveedorNegociacionAbierta => 'Abierta';

  @override
  String get proveedorNegociacionSolicitudAbierta => 'Solicitud abierta';

  @override
  String proveedorNegociacionLote(String cultivo) {
    return 'Lote de $cultivo';
  }

  @override
  String get proveedorNegociacionAceptarNecesitaRedReintenta =>
      'aceptar necesita red. Vuelve a intentarlo con señal.';

  @override
  String proveedorNegociacionOfertaEnviadaPorSigues(String precioHa) {
    return 'Oferta enviada a $precioHa por ha. La sigues en «Ofertas».';
  }

  @override
  String get proveedorNegociacionNegociacionEstaSolicitudCerro =>
      'Tu negociación en esta solicitud ya se cerró. No puedes ofertar de nuevo.';

  @override
  String get proveedorNegociacionOfertasteAquiSigueNegociacion =>
      'Ya ofertaste aquí. Sigue la negociación en «Ofertas».';

  @override
  String get proveedorNegociacionContraofertar => 'Contraofertar';

  @override
  String proveedorNegociacionAceptar(String precioHaPropuesto) {
    return 'Aceptar $precioHaPropuesto';
  }

  @override
  String get proveedorNegociacionVerDetalleDelLote => 'Ver detalle del lote';

  @override
  String get proveedorNegociacionSinConexion => 'Sin conexión';

  @override
  String get proveedorNegociacionMapaSolicitudesNecesitaSenal =>
      'El mapa de solicitudes necesita señal para mostrar lo que hay disponible. Vuelve a intentarlo cuando tengas señal.';

  @override
  String get proveedorNegociacionPudimosCargarLasSolicitudes =>
      'No pudimos cargar las solicitudes';

  @override
  String get proveedorNegociacionIntentaNuevoMomento =>
      'Vuelve a intentarlo en un momento.';

  @override
  String get proveedorNegociacionNingunaSolicitudConEstos =>
      'Ninguna solicitud con estos filtros';

  @override
  String get proveedorNegociacionHaySolicitudesAbiertasAhora =>
      'No hay solicitudes abiertas ahora';

  @override
  String get proveedorNegociacionQuitaAlgunFiltroPrueba =>
      'Quita algún filtro o prueba con otra zona.';

  @override
  String get proveedorNegociacionActivaLosAvisosPerfil =>
      'Activa las notificaciones en tu perfil y te avisamos cuando llegue una en tus zonas.';

  @override
  String get proveedorNegociacionCargando => 'Cargando…';

  @override
  String get proveedorNegociacionVerMasSolicitudes => 'Ver más solicitudes';

  @override
  String get proveedorNegociacionDondeHayTrabajo => 'Dónde hay trabajo';

  @override
  String get proveedorNegociacionOtrasZonas => 'Otras zonas';

  @override
  String proveedorNegociacionSolicitudes(
    String nombre,
    int cuantas,
    String ha,
  ) {
    return '$nombre: $cuantas solicitudes, $ha';
  }

  @override
  String proveedorNegociacionHa(int cuantas, String ha) {
    return '$cuantas · $ha ha';
  }

  @override
  String get proveedorNegociacionOfertaste => 'Ofertaste';

  @override
  String get proveedorNegociacionCerrada => 'Cerrada';

  @override
  String proveedorNegociacionTotal(String montoPropuesto) {
    return 'total $montoPropuesto';
  }

  @override
  String get proveedorNegociacionSinOfertas => 'sin ofertas';

  @override
  String get proveedorNegociacionFiltrarSolicitudes => 'Filtrar solicitudes';

  @override
  String get proveedorNegociacionHectareasDesde => 'Hectáreas desde';

  @override
  String get proveedorNegociacionHectareasHasta => 'Hectáreas hasta';

  @override
  String get proveedorNegociacionPorDesde => 'Bs por ha desde';

  @override
  String get proveedorNegociacionPorHasta => 'Bs por ha hasta';

  @override
  String get proveedorNegociacionCultivo => 'Cultivo';

  @override
  String get proveedorNegociacionOrdenarPor => 'Ordenar por';

  @override
  String get proveedorNegociacionVerSolicitudes => 'Ver solicitudes';

  @override
  String get proveedorNegociacionQuitarFiltros => 'Quitar filtros';

  @override
  String get proveedorNegociacionAvisos => 'Notificaciones';

  @override
  String get proveedorNegociacionPudimosCargarTusAvisos =>
      'No pudimos cargar tus notificaciones';

  @override
  String get proveedorNegociacionEligeQueQuieresEnterarte =>
      'Elige de qué quieres recibir notificaciones. Las de adjudicación, cierre, cuenta y reclamos no se pueden desactivar.';

  @override
  String get proveedorNegociacionNuevasSolicitudes => 'Nuevas solicitudes';

  @override
  String get proveedorNegociacionAvisamosCuandoClientePublica =>
      'Te avisamos cuando un cliente publica una solicitud en tus zonas. Así ofertas antes que los demás.';

  @override
  String get proveedorNegociacionZonas => 'Zonas';

  @override
  String get proveedorNegociacionTodasLasZonas => 'Todas las zonas';

  @override
  String get proveedorNegociacionHectareasMinimas => 'Hectáreas mínimas';

  @override
  String get proveedorNegociacionCualquiera => 'Cualquiera';

  @override
  String proveedorNegociacionHa2(String ha) {
    return '$ha ha';
  }

  @override
  String get proveedorNegociacionOfertasContraofertas =>
      'Ofertas y contraofertas';

  @override
  String get proveedorNegociacionCuandoClienteRespondeOferta =>
      'Cuando el cliente responde a tu oferta.';

  @override
  String get proveedorNegociacionMensajes => 'Mensajes';

  @override
  String get proveedorNegociacionCuandoClienteEscribeChat =>
      'Cuando el cliente te escribe en el chat.';

  @override
  String get proveedorNegociacionCalificaciones => 'Calificaciones';

  @override
  String get proveedorNegociacionCuandoClienteCalifica =>
      'Cuando un cliente te califica.';

  @override
  String get proveedorNegociacionSuperficie => 'Superficie';

  @override
  String get proveedorNegociacionPrecioOfrecido => 'Precio ofrecido';

  @override
  String get proveedorNegociacionSinConexionVesLos =>
      'Sin conexión. Ves los mensajes que ya recibimos; los nuevos llegan cuando vuelva la señal.';

  @override
  String get proveedorNegociacionTodaviaHayMensajes =>
      'Todavía no hay mensajes';

  @override
  String get proveedorNegociacionEscribeleClienteParaCoordinar =>
      'Escríbele al cliente para coordinar cómo llegar al lote y a qué hora.';

  @override
  String get proveedorNegociacionServicioCerroPuedesLeer =>
      'El servicio ya cerró: puedes leer la conversación pero no escribir.';

  @override
  String get proveedorNegociacionEscribeMensaje => 'Escribe un mensaje';

  @override
  String get proveedorNegociacionEnviarMensaje => 'Enviar mensaje';

  @override
  String get proveedorNegociacionSolicitud => 'Solicitud';

  @override
  String get proveedorNegociacionPudimosAbrirSolicitud =>
      'No pudimos abrir la solicitud';

  @override
  String get proveedorNegociacionParaVerDetalleOfertar =>
      'Para ver el detalle y ofertar necesitas señal. Vuelve a intentarlo cuando tengas señal.';

  @override
  String get proveedorNegociacionClientePropone => 'El cliente propone';

  @override
  String proveedorNegociacionPor(String precioHaPropuesto) {
    return '$precioHaPropuesto por ha';
  }

  @override
  String proveedorNegociacionTotalEstimado(String montoPropuesto) {
    return 'Total estimado $montoPropuesto';
  }

  @override
  String get proveedorNegociacionTodaviaTieneOfertasPrimero =>
      'Todavía no tiene ofertas: sé el primero.';

  @override
  String get proveedorNegociacionTieneOfertaVigente =>
      'Ya tiene 1 oferta vigente.';

  @override
  String proveedorNegociacionTieneOfertasVigentes(int ofertasVigentes) {
    return 'Ya tiene $ofertasVigentes ofertas vigentes.';
  }

  @override
  String get proveedorNegociacionContactoConClienteLlega =>
      'Los datos de contacto del cliente se muestran solo si te elige. Hasta entonces no ves su nombre, teléfono ni dirección.';

  @override
  String proveedorNegociacionOfertaEnviadaPorVes(String precioHa) {
    return 'Oferta enviada: $precioHa por ha. La ves en «Mis ofertas».';
  }

  @override
  String get proveedorNegociacionFechaDeseada => 'Fecha deseada';

  @override
  String proveedorNegociacionAl(String ventanaDesde, String ventanaHasta) {
    return '$ventanaDesde al $ventanaHasta';
  }

  @override
  String get proveedorNegociacionAplicacion => 'Aplicación';

  @override
  String get proveedorNegociacionProducto => 'Producto';

  @override
  String get proveedorNegociacionPoneProducto => 'Quién aporta el producto';

  @override
  String get proveedorNegociacionCliente => 'El cliente';

  @override
  String get proveedorNegociacionTu => 'Tú';

  @override
  String get proveedorNegociacionUrgencia => 'Urgencia';

  @override
  String get proveedorNegociacionPideAtencionPronta => 'Lo necesita pronto';

  @override
  String get proveedorNegociacionEstadoDelTerreno => 'Estado del terreno';

  @override
  String get proveedorNegociacionAccesoDificil => 'Acceso difícil';

  @override
  String get proveedorNegociacionAccesoNormal => 'Acceso normal';

  @override
  String get proveedorNegociacionComoLlegar => 'Cómo llegar';

  @override
  String get proveedorNegociacionCuidar => 'Colindantes sensibles';

  @override
  String get proveedorNegociacionObservaciones => 'Observaciones';

  @override
  String get proveedorNegociacionAbiertaHasta => 'Abierta hasta';

  @override
  String proveedorNegociacionAceptarPor(String precioHaPropuesto) {
    return 'Aceptar $precioHaPropuesto por ha';
  }

  @override
  String get proveedorNegociacionContraofertarPrecio =>
      'Contraofertar mi precio';

  @override
  String get proveedorNegociacionEscribePrecioMayorCero =>
      'Escribe un precio mayor a cero.';

  @override
  String get proveedorNegociacionMismoPrecioCambialoAcepta =>
      'Es el mismo precio. Cámbialo o acepta el actual.';

  @override
  String proveedorNegociacionPor2(
    String etiquetaReferencia,
    String precioReferencia,
  ) {
    return '$etiquetaReferencia: $precioReferencia por ha';
  }

  @override
  String get proveedorNegociacionPrecioPorHectarea =>
      'Tu precio por hectárea (Bs)';

  @override
  String get proveedorNegociacionTotalApareceCuandoEscribes =>
      'El total aparece cuando escribes el precio.';

  @override
  String get proveedorNegociacionMensajeParaClienteOpcional =>
      'Mensaje para el cliente (opcional)';

  @override
  String get proveedorNegociacionTusOfertasVenCon =>
      'tus ofertas se ven con red.';

  @override
  String get proveedorNegociacionQueVesPuedeEstar =>
      'lo que ves puede estar desactualizado.';

  @override
  String get proveedorNegociacionMisOfertas => 'Mis ofertas';

  @override
  String get proveedorNegociacionActivas => 'Activas';

  @override
  String get proveedorNegociacionGanadas => 'Ganadas';

  @override
  String get proveedorNegociacionCerradas => 'Cerradas';

  @override
  String get proveedorNegociacionParaVerResponderTus =>
      'Para ver y responder tus ofertas necesitas señal. Vuelve a intentarlo cuando tengas señal.';

  @override
  String get proveedorNegociacionPudimosCargarTusOfertas =>
      'No pudimos cargar tus ofertas';

  @override
  String get proveedorNegociacionTodaviaHicisteOfertas =>
      'Todavía no hiciste ofertas';

  @override
  String get proveedorNegociacionAbreUnaSolicitudMapa =>
      'Abre una solicitud en el mapa y acepta el precio del cliente o propón el tuyo.';

  @override
  String get proveedorNegociacionTienesNegociacionesActivas =>
      'No tienes negociaciones activas';

  @override
  String get proveedorNegociacionCuandoOfertesMapaConversacion =>
      'Cuando ofertes en el mapa, la conversación aparece aquí.';

  @override
  String get proveedorNegociacionAunGanasteNinguna => 'Aún no ganaste ninguna';

  @override
  String get proveedorNegociacionLasSolicitudesLasQue =>
      'Las solicitudes en las que el cliente te elige quedan aquí.';

  @override
  String get proveedorNegociacionNadaCerradoTodavia => 'Nada cerrado todavía';

  @override
  String get proveedorNegociacionLasOfertasRechazadasRetiradas =>
      'Las ofertas rechazadas, retiradas o vencidas se guardan aquí.';

  @override
  String proveedorNegociacionTurno(int rondaQueSigue) {
    return 'Tu turno · R$rondaQueSigue/5';
  }

  @override
  String proveedorNegociacionEsperando(int rondaQueSigue) {
    return 'Esperando · R$rondaQueSigue/5';
  }

  @override
  String get proveedorNegociacionAceptada => 'Aceptada';

  @override
  String get proveedorNegociacionRechazada => 'Rechazada';

  @override
  String proveedorNegociacionSolicitud2(int solicitudId) {
    return 'Solicitud $solicitudId';
  }

  @override
  String proveedorNegociacionHa3(String hectareas) {
    return '$hectareas ha';
  }

  @override
  String get proveedorNegociacionCliente2 => 'Cliente';

  @override
  String proveedorNegociacionVenceLas(String venceEn, String venceEn2) {
    return 'Vence $venceEn a las $venceEn2';
  }

  @override
  String get proveedorNegociacionOfertarNecesitaRedPrecio =>
      'ofertar necesita red. Tu precio se conserva y no se envió nada.';

  @override
  String get proveedorNegociacionVolver => 'Volver';

  @override
  String get proveedorNegociacionNegociacionConCliente =>
      'Negociación con el cliente';

  @override
  String proveedorNegociacionRonda(int ronda, int total) {
    return 'Ronda $ronda de $total';
  }

  @override
  String get proveedorNegociacionAbrirNegociacionNecesitaRed =>
      'abrir la negociación necesita red.';

  @override
  String get proveedorNegociacionNegociarEntreDosPersonas =>
      'Negociar necesita señal. No se perdió nada: vuelve a intentarlo cuando tengas señal.';

  @override
  String get proveedorNegociacionPudimosAbrirNegociacion =>
      'No pudimos abrir la negociación';

  @override
  String get proveedorNegociacionTu2 => 'TÚ';

  @override
  String get proveedorNegociacionPublicado => 'Publicado';

  @override
  String get proveedorNegociacionAceptasteSolicitudTuyaContacto =>
      'Aceptaste la oferta: la solicitud es tuya. Los datos del cliente aparecen en «Servicio».';

  @override
  String get proveedorNegociacionRechazasteOfertaNegociacionCerro =>
      'Rechazaste la oferta. La negociación se cerró.';

  @override
  String get proveedorNegociacionRetirasteOfertaNegociacionCerro =>
      'Retiraste tu oferta. La negociación se cerró.';

  @override
  String get proveedorNegociacionEsperandoClienteAvisamosCuando =>
      'Esperando al cliente · te avisamos cuando responda';

  @override
  String get proveedorNegociacionEstaNegociacionCerroPuede =>
      'Esta negociación ya se cerró. No se puede ofertar de nuevo.';

  @override
  String get proveedorNegociacionTurnoRondaFinalAceptas =>
      'Tu turno · es la ronda final: aceptas o la negociación se cierra';

  @override
  String proveedorNegociacionTurnoDespuesSoloQueda(int rondasMaximas) {
    return 'Tu turno · después solo queda la ronda $rondasMaximas';
  }

  @override
  String proveedorNegociacionTurnoRonda(int ronda, int rondasMaximas) {
    return 'Tu turno · ronda $ronda de $rondasMaximas';
  }

  @override
  String get proveedorNegociacionVerMisOfertas => 'Ver mis ofertas';

  @override
  String get proveedorNegociacionRetirarOferta => 'Retirar mi oferta';

  @override
  String get proveedorNegociacionPrecioPorHectarea2 => 'Tu precio por hectárea';

  @override
  String proveedorNegociacionTotal2(String total) {
    return 'total $total';
  }

  @override
  String get proveedorNegociacionAceptar2 => 'Aceptar';

  @override
  String proveedorNegociacionAceptar3(String aceptable) {
    return 'Aceptar $aceptable';
  }

  @override
  String proveedorNegociacionReintentar(int precio) {
    return 'Reintentar $precio';
  }

  @override
  String proveedorNegociacionEnviar(int precio) {
    return 'Enviar $precio';
  }

  @override
  String get proveedorNegociacionRechazar => 'Rechazar';

  @override
  String get proveedorEjecucionServicio => 'Servicio';

  @override
  String get proveedorEjecucionPudimosLeerTusServicios =>
      'No pudimos leer tus servicios';

  @override
  String get proveedorEjecucionCierraAbreAppQue =>
      'Cierra la app y vuelve a abrirla. Lo que guardaste sigue aquí.';

  @override
  String get proveedorEjecucionTodaviaTienesServicioAdjudicado =>
      'Todavía no tienes un servicio adjudicado';

  @override
  String get proveedorEjecucionCuandoClienteElijaServicio =>
      'Cuando un cliente te elija, el servicio aparece aquí con sus datos de contacto. Desliza hacia abajo para actualizar.';

  @override
  String get proveedorEjecucionSinAvanceMarcado => 'Sin avance marcado';

  @override
  String get proveedorEjecucionRegistroRechazado => '1 envío rechazado';

  @override
  String proveedorEjecucionRegistrosRechazados(int rechazos) {
    return '$rechazos envíos rechazados';
  }

  @override
  String get proveedorEjecucionCosaPorSubir => '1 envío por subir';

  @override
  String proveedorEjecucionCosasPorSubir(int pendientes) {
    return '$pendientes envíos por subir';
  }

  @override
  String get proveedorEjecucionChatConCliente => 'Chat con el cliente';

  @override
  String get proveedorEjecucionEncontramosEsteServicio =>
      'No encontramos este servicio';

  @override
  String get proveedorEjecucionPuedeQueClienteHaya =>
      'Puede que el cliente lo haya cancelado. Vuelve a la lista y actualiza.';

  @override
  String get proveedorEjecucionTusFotosAvancesQuedan =>
      'tus fotos y avances quedan guardados y se suben solos.';

  @override
  String get proveedorEjecucionServidorAceptoAlgoQue =>
      'No pudimos aceptar algo de lo que guardaste. Avisa a soporte desde tu perfil.';

  @override
  String get proveedorEjecucionEstaGuardadoEsteCelular =>
      'Está guardado en este teléfono y se sube solo cuando vuelva la señal.';

  @override
  String get proveedorEjecucionAvance => 'Avance';

  @override
  String proveedorEjecucionAvancePorCiento(String porcentaje) {
    return 'Avance $porcentaje por ciento';
  }

  @override
  String get proveedorEjecucionTodaviaMarcasteAvance =>
      'Todavía no marcaste avance.';

  @override
  String get proveedorEjecucionSinFotosAvance => 'Sin fotos de avance';

  @override
  String get proveedorEjecucionFotoAvance => '1 foto de avance';

  @override
  String proveedorEjecucionFotosAvance(int fotosTotal) {
    return '$fotosTotal fotos de avance';
  }

  @override
  String get proveedorEjecucionMarcarEjecucion => 'Marcar en ejecución';

  @override
  String get proveedorEjecucionMarcaloCuandoEmpiecesLote =>
      'Márcalo cuando empieces en el lote. El cliente recibe una notificación.';

  @override
  String get proveedorEjecucionSubirFotoAvance => 'Subir foto de avance';

  @override
  String get proveedorEjecucionMarcarAvance => 'Marcar avance';

  @override
  String get proveedorEjecucionFinalizarServicio => 'Finalizar servicio';

  @override
  String get proveedorEjecucionEscribeNumeroMayorCero =>
      'Escribe un número mayor a cero.';

  @override
  String get proveedorEjecucionPuedePasarLasHectareas =>
      'No puede ser mayor que las hectáreas del servicio.';

  @override
  String get proveedorEjecucionPuedePasar100 => 'No puede ser mayor que 100 %.';

  @override
  String get proveedorEjecucionHectareas => 'Hectáreas';

  @override
  String get proveedorEjecucionPorcentaje => 'Porcentaje';

  @override
  String get proveedorEjecucionHectareasEjecutadasTotal =>
      'Hectáreas ejecutadas en total';

  @override
  String get proveedorEjecucionPorcentajeEjecutadoTotal =>
      'Porcentaje ejecutado en total';

  @override
  String get proveedorEjecucionMenosQueUltimoAvance =>
      'Es menos que tu último avance. Cuéntanos por qué lo corriges.';

  @override
  String get proveedorEjecucionMotivoCorreccion => 'Motivo de la corrección';

  @override
  String get proveedorEjecucionMotivoObligatorio => 'El motivo es obligatorio.';

  @override
  String get proveedorEjecucionNotaOpcional => 'Nota (opcional)';

  @override
  String get proveedorEjecucionGuardarAvance => 'Guardar avance';

  @override
  String get proveedorEjecucionEscribeLasHectareasRealmente =>
      'Escribe las hectáreas realmente ejecutadas.';

  @override
  String get proveedorEjecucionFinalizarServicio2 => 'Finalizar el servicio';

  @override
  String get proveedorEjecucionConfirmaLasHectareasQue =>
      'Confirma las hectáreas que realmente ejecutaste. El precio final es hectáreas ejecutadas por el precio acordado.';

  @override
  String get proveedorEjecucionHectareasEjecutadas => 'Hectáreas ejecutadas';

  @override
  String proveedorEjecucionPagar(
    String monto,
    String ha,
    String precioHaAcordado,
  ) {
    return 'A pagar: $monto ($ha × $precioHaAcordado)';
  }

  @override
  String get proveedorEjecucionFinalizar => 'Finalizar';

  @override
  String get proveedorEjecucionPrecioFinalPagar => 'Precio final a pagar';

  @override
  String get proveedorEjecucionPrecioEstimado => 'Precio estimado';

  @override
  String get proveedorEjecucionCalculando => 'Calculando…';

  @override
  String get proveedorEjecucionHectareasEjecutadasPorPrecio =>
      'Hectáreas ejecutadas por el precio acordado.';

  @override
  String get proveedorEjecucionClientePagaDirectamenteApp =>
      'El cliente te paga directamente: la app no cobra.';

  @override
  String get proveedorEjecucionUnaEstimacionHechaEste =>
      'Es una estimación hecha en este teléfono. Agrocom confirma el monto final cuando haya señal.';

  @override
  String get proveedorEjecucionCompartiendoUbicacion =>
      'Compartiendo tu ubicación';

  @override
  String get proveedorEjecucionSinSenalReanudaSola =>
      'Sin señal: se reanuda sola. Nada se guarda en el teléfono.';

  @override
  String get proveedorEjecucionClienteUltimaPosicionMapa =>
      'El cliente ve tu última posición en un mapa mientras esta pantalla esté abierta.';

  @override
  String get proveedorEjecucionUbicacionBloqueada => 'Ubicación bloqueada';

  @override
  String get proveedorEjecucionActivalaDesdeLosAjustes =>
      'Actívala desde los ajustes del teléfono si quieres que el cliente vea dónde estás.';

  @override
  String get proveedorEjecucionUbicacionDelTelefonoEsta =>
      'La ubicación del teléfono está apagada';

  @override
  String get proveedorEjecucionEnciendelaParaQueCliente =>
      'Enciéndela para que el cliente vea tu última posición.';

  @override
  String get proveedorEjecucionDileClienteDondeEstas =>
      'Dile al cliente dónde estás';

  @override
  String get proveedorEjecucionAceptasCompartimosUltimaPosicion =>
      'Si lo aceptas, compartimos tu última posición con el cliente mientras el servicio esté en ejecución y esta pantalla abierta. Se deja de compartir al cerrarla o al finalizar. No guardamos tu recorrido.';

  @override
  String get proveedorEjecucionCompartirUbicacion => 'Compartir mi ubicación';

  @override
  String proveedorEjecucionUltimaVez(String ultimaEn) {
    return 'Última vez $ultimaEn';
  }

  @override
  String get proveedorEjecucionPrecioAcordado => 'Precio acordado';

  @override
  String proveedorEjecucionPor(String precioHaAcordado) {
    return '$precioHaAcordado por ha';
  }

  @override
  String get proveedorEjecucionFecha => 'Fecha';

  @override
  String proveedorEjecucionAl(String ventanaDesde, String ventanaHasta) {
    return '$ventanaDesde al $ventanaHasta';
  }

  @override
  String get proveedorEjecucionProducto => 'Producto';

  @override
  String get proveedorEjecucionPoneProducto => 'Quién aporta el producto';

  @override
  String get proveedorEjecucionCliente => 'El cliente';

  @override
  String get proveedorEjecucionTu => 'Tú';

  @override
  String get proveedorEjecucionEstadoDelTerreno => 'Estado del terreno';

  @override
  String get proveedorEjecucionAccesoDificil => 'Acceso difícil';

  @override
  String get proveedorEjecucionAccesoNormal => 'Acceso normal';

  @override
  String get proveedorEjecucionComoLlegar => 'Cómo llegar';

  @override
  String get proveedorEjecucionCuidar => 'Colindantes sensibles';

  @override
  String get proveedorEjecucionObservaciones => 'Observaciones';

  @override
  String get proveedorEjecucionMarcasteServicioEjecucion =>
      'Marcaste el servicio en ejecución.';

  @override
  String get proveedorEjecucionAvanceGuardado => 'Avance guardado.';

  @override
  String get proveedorEjecucionServicioFinalizadoPrecioPagar =>
      'Servicio finalizado. El precio a pagar queda a la vista.';

  @override
  String get proveedorEjecucionFotoGuardadaSubeSola =>
      'Foto guardada. Se sube sola cuando haya señal.';

  @override
  String get proveedorEjecucionPudimosAchicarFotoSuficiente =>
      'No pudimos reducir el tamaño de la foto lo suficiente. Toma otra con menos detalle.';

  @override
  String get proveedorEjecucionPudimosGuardarloIntentaNuevo =>
      'No pudimos guardarlo. Vuelve a intentarlo.';

  @override
  String get proveedorAccesoPudimosAchicarEsaFoto =>
      'No pudimos reducir el tamaño de esa foto. Prueba con otra o tómala de nuevo.';

  @override
  String get proveedorAccesoSinConexionQueEscribiste =>
      'Sin conexión. Lo que escribiste se conserva: vuelve a intentarlo con señal y seguimos donde quedó.';

  @override
  String get proveedorAccesoSinConexionQueEscribiste2 =>
      'Sin conexión. Lo que escribiste se conserva: vuelve a intentarlo con señal.';

  @override
  String get proveedorAccesoCuentaQuedoCreadaPero =>
      'Tu cuenta quedó creada, pero no pudimos ingresar. Vuelve al ingreso e inicia sesión.';

  @override
  String get proveedorAccesoRevisaLosDatosMarcados =>
      'Revisa los datos marcados y vuelve a intentarlo.';

  @override
  String get proveedorAccesoPudimosCompletarRegistroIntenta =>
      'No pudimos completar el registro. Vuelve a intentarlo.';

  @override
  String get proveedorAccesoSesionVencioEntraNuevo =>
      'Tu sesión venció. Ingresa de nuevo.';

  @override
  String get proveedorAccesoUsuarioContrasenaIncorrectosRevisa =>
      'Usuario o contraseña incorrectos. Revísalos y vuelve a intentarlo.';

  @override
  String get proveedorAccesoSinConexionNecesitasSenal =>
      'Sin conexión. Necesitas señal para ingresar; lo que ya guardaste en el teléfono sigue ahí.';

  @override
  String get proveedorAccesoEstaCuentaEstaApp =>
      'Esta cuenta no es de esta app.';

  @override
  String get proveedorAccesoPudimosEntrarIntentaNuevo =>
      'No pudimos ingresar. Vuelve a intentarlo en un momento.';

  @override
  String get proveedorNegociacionSinConexionPuedeQue =>
      'Sin conexión: puede que lo que ves esté desactualizado.';

  @override
  String get proveedorNegociacionListoClienteEligioPuedes =>
      '¡Listo! El cliente te eligió. Ya puedes escribirle desde «Servicio».';

  @override
  String get proveedorNegociacionRechazasteOfertaDelCliente =>
      'Rechazaste la oferta del cliente.';

  @override
  String get proveedorNegociacionRetirasteOferta => 'Retiraste tu oferta.';

  @override
  String get proveedorNegociacionEnviasteContraoferta =>
      'Enviaste tu contraoferta.';

  @override
  String get proveedorNegociacionHayConexionEnvioNada =>
      'Sin conexión. No se envió nada: vuelve a intentarlo cuando tengas señal.';

  @override
  String get proveedorNegociacionEsaOfertaEstaVigente =>
      'Esa oferta ya no está vigente: el cliente respondió o venció. Actualizamos tu lista.';

  @override
  String get proveedorNegociacionClienteEligioOtroPiloto =>
      'El cliente ya eligió a otro piloto para esta solicitud.';

  @override
  String get proveedorNegociacionEquipoEstaDisponiblePara =>
      'Tu equipo no está disponible para esas fechas. Revisa tus drones.';

  @override
  String get proveedorNegociacionSinConexionMensajeSigue =>
      'Sin conexión. Tu mensaje sigue aquí: vuelve a intentarlo.';

  @override
  String get proveedorNegociacionRetiroReintentaCuandoTengas =>
      'No se retiró. Vuelve a intentarlo cuando tengas señal.';

  @override
  String get proveedorNegociacionEnvioPrecioSigueAqui =>
      'No se envió. Tu precio sigue aquí: vuelve a intentarlo cuando tengas señal.';

  @override
  String get proveedorNegociacionEsaOfertaEstaVigente2 =>
      'Esa oferta ya no está vigente: el cliente respondió o venció.';

  @override
  String get proveedorNegociacionHayConexionQueEscribiste =>
      'Sin conexión. Lo que escribiste se conserva: vuelve a intentarlo cuando tengas señal.';

  @override
  String proveedorDronFotos(String detalle) {
    return 'Fotos: $detalle';
  }

  @override
  String proveedorEjecucionServicioSemantica(
    String hectareas,
    String cultivo,
    String estado,
    String pendientes,
  ) {
    return '$hectareas$cultivo, $estado$pendientes';
  }

  @override
  String proveedorEjecucionDeCultivo(String cultivo) {
    return ' de $cultivo';
  }

  @override
  String proveedorEjecucionPendientesSufijo(int cantidad) {
    return ', $cantidad por subir';
  }

  @override
  String proveedorEjecucionAvanceResumen(
    String ejecutadas,
    String total,
    String porcentaje,
  ) {
    return '$ejecutadas de $total · $porcentaje %';
  }

  @override
  String proveedorPerfilGraficoBarras(String detalle) {
    return 'Gráfico de barras de hectáreas por mes: $detalle';
  }

  @override
  String proveedorNegociacionTotalPrecioCliente(String monto, String ofertas) {
    return 'Total al precio del cliente: $monto$ofertas';
  }

  @override
  String proveedorNegociacionOfertasSufijo(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$cantidad ofertas',
      one: '1 oferta',
    );
    return ' · $_temp0';
  }

  @override
  String proveedorNegociacionSolicitudSemantica(
    String zona,
    String hectareas,
    String precio,
    int cantidad,
    String vence,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$cantidad ofertas',
      one: '1 oferta',
    );
    return 'Solicitud en $zona, $hectareas, $precio por hectárea, $_temp0$vence';
  }

  @override
  String get proveedorNegociacionZonaSinNombre => 'zona sin nombre';

  @override
  String get proveedorNegociacionAvisosSinConexion =>
      'Sin conexión. Las notificaciones se configuran con señal.';

  @override
  String get proveedorNegociacionAvisosNoGuardado =>
      'No se guardó: no hay conexión. Vuelve a intentarlo con señal.';

  @override
  String proveedorNegociacionMapaSemantica(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$cantidad solicitudes',
      one: '1 solicitud',
    );
    return 'Mapa de solicitudes abiertas, $_temp0';
  }

  @override
  String get proveedorNegociacionChatConCliente => 'Chat con el cliente';

  @override
  String get proveedorNegociacionEnviarContraoferta => 'Enviar contraoferta';

  @override
  String proveedorNegociacionOfertaSemantica(
    String titulo,
    String detalle,
    String etiqueta,
    String cliente,
    String mia,
  ) {
    return '$titulo, $detalle, $etiqueta$cliente$mia';
  }

  @override
  String proveedorNegociacionPrecioClienteSufijo(String precio) {
    return ', cliente $precio bolivianos por hectárea';
  }

  @override
  String proveedorNegociacionPrecioMioSufijo(String precio) {
    return ', tú $precio';
  }

  @override
  String proveedorNegociacionRondaSemantica(
    int ronda,
    int total,
    String turno,
  ) {
    return 'Ronda $ronda de $total$turno';
  }

  @override
  String get proveedorNegociacionEsTuTurno => ', es tu turno';

  @override
  String terrenosFotoSemantica(int numero, int total, String descripcion) {
    return 'Foto $numero de $total del terreno$descripcion';
  }

  @override
  String terrenosFotoDescripcionSufijo(String descripcion) {
    return ': $descripcion';
  }

  @override
  String get accesoRolCliente => 'Cliente';

  @override
  String get accesoRolClienteDetalle => 'Publico lotes y elijo al piloto';

  @override
  String get accesoRolClienteBoton => 'cliente';

  @override
  String get accesoRolPiloto => 'Piloto';

  @override
  String get accesoRolPilotoDetalle => 'Busco lotes y negocio el precio';

  @override
  String get accesoRolPilotoBoton => 'piloto';

  @override
  String get proveedorNegociacionVenceHoySufijo => ', vence hoy';

  @override
  String get proveedorAccesoDatoObligatorio => 'Este dato es obligatorio.';

  @override
  String get proveedorAccesoNumeroMayorCero =>
      'Escribe un número mayor a cero.';

  @override
  String get componentesSinSenal => 'Sin señal';

  @override
  String get componentesNuevoServicio => 'NUEVO SERVICIO';

  @override
  String get componentesTotal => 'Total';

  @override
  String get componentesSyncEnDispositivo => 'En este teléfono';

  @override
  String get componentesSyncSincronizando => 'Sincronizando';

  @override
  String get componentesSyncSincronizado => 'Sincronizado';

  @override
  String get componentesSyncSinSincronizar => 'Sin sincronizar';

  @override
  String solicitudesAvanceHectareas(String ejecutadas, String total) {
    return '$ejecutadas / $total ha';
  }

  @override
  String proveedorEjecucionDeTotal(String ejecutadas, String total) {
    return '$ejecutadas de $total';
  }

  @override
  String proveedorEjecucionHectareasPorPrecio(String hectareas, String precio) {
    return '$hectareas × $precio por ha';
  }

  @override
  String perfilUxCalificacionSemantica(String valor) {
    return 'Calificación $valor de 5, ver calificaciones';
  }

  @override
  String get perfilUxCalificacionesTitulo => 'Calificaciones';

  @override
  String get perfilUxCalificacionesVacioTitulo => 'Aún no hay calificaciones';

  @override
  String get perfilUxCalificacionesVacioDetalle =>
      'Cuando termines un servicio, aquí verás lo que opinan de ti.';

  @override
  String get perfilUxMenuMas => 'Más opciones';

  @override
  String get ajustesTitulo => 'Ajustes';

  @override
  String get ajustesApariencia => 'Apariencia';

  @override
  String get ajustesAparienciaDetalle => 'Tema claro u oscuro';

  @override
  String get ajustesCuenta => 'Cuenta';

  @override
  String get ajustesCerrarSesion => 'Cerrar sesión';

  @override
  String get ajustesCerrarSesionDetalle => 'Salir de este dispositivo';

  @override
  String get ajustesCerrarSesionPregunta => '¿Cerrar sesión?';

  @override
  String get ajustesCerrarSesionAviso =>
      'Tendrás que volver a entrar para usar la app.';

  @override
  String get ajustesCancelar => 'Cancelar';

  @override
  String get aparienciaTitulo => 'Apariencia';

  @override
  String get aparienciaTema => 'Tema';

  @override
  String get aparienciaTemaClaro => 'Claro';

  @override
  String get aparienciaTemaOscuro => 'Oscuro';

  @override
  String get perfilCliMetricas => 'Métricas';

  @override
  String perfilCliMisLotesDetalle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n lotes registrados',
      one: '1 lote registrado',
    );
    return '$_temp0';
  }

  @override
  String perfilCliCalificacionesDetalle(String promedio, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n calificaciones',
      one: '1 calificación',
    );
    return '$promedio · $_temp0';
  }

  @override
  String get perfilCliCalificacionesSinDatos => 'Aún sin calificaciones';

  @override
  String get perfilPilMisDrones => 'Mis drones';

  @override
  String get perfilPilDocumentosDetalle =>
      'Licencia, matrícula, seguro y certificado';

  @override
  String get perfilPilCalificaciones => 'Calificaciones';

  @override
  String perfilPilCalificacionesDetalle(String promedio, int total) {
    return '$promedio · $total calificaciones';
  }

  @override
  String get perfilPilActividad => 'Hectáreas y zonas';

  @override
  String get perfilPilActividadDetalle =>
      'Hectáreas por mes y zonas de cobertura';

  @override
  String get perfilPilAjustesDetalle => 'Apariencia, notificaciones y cuenta';

  @override
  String get datosPersonalesTitulo => 'Datos personales';

  @override
  String get datosPersonalesAjustesDetalle => 'Revisa o corrige tus datos';

  @override
  String get datosPersonalesAvisoUnaVez =>
      'Puedes editar tus datos una sola vez. Revísalos bien antes de guardar.';

  @override
  String get datosPersonalesNombre => 'Nombre completo';

  @override
  String get datosPersonalesCorreo => 'Correo electrónico';

  @override
  String get datosPersonalesTelefono => 'Teléfono';

  @override
  String get datosPersonalesEmpresa => 'Empresa';

  @override
  String get datosPersonalesDocumento => 'Documento';

  @override
  String get datosPersonalesNombreObligatorio => 'Escribe tu nombre.';

  @override
  String get datosPersonalesEmpresaObligatoria =>
      'Escribe el nombre de la empresa.';

  @override
  String get datosPersonalesCorreoInvalido =>
      'Escribe un correo válido, por ejemplo nombre@correo.com.';

  @override
  String get datosPersonalesTelefonoInvalido =>
      'Escribe un teléfono válido, con al menos 8 dígitos.';

  @override
  String get datosPersonalesGuardar => 'Guardar cambios';

  @override
  String get datosPersonalesConfirmarTitulo => '¿Guardar tus datos?';

  @override
  String get datosPersonalesConfirmarAviso =>
      'Después solo podrás pedir cambios a atención al cliente.';

  @override
  String get datosPersonalesRevisar => 'Revisar';

  @override
  String get datosPersonalesConfirmarSi => 'Sí, guardar';

  @override
  String get datosPersonalesGuardado => 'Guardamos tus datos.';

  @override
  String get datosPersonalesYaEditado =>
      'Ya usaste tu edición. Para cambiar un dato, pide el cambio a atención al cliente.';

  @override
  String get datosPersonalesEdicionAgotada =>
      'Tus datos ya se editaron desde otro dispositivo. Para cambiar algo, pide el cambio a atención al cliente.';

  @override
  String get datosPersonalesSolicitar => 'Solicitar un cambio';

  @override
  String get datosPersonalesSolicitudEnRevision =>
      'Tu solicitud de cambio está en revisión. Te avisamos cuando tengamos respuesta.';

  @override
  String get datosPersonalesErrorTitulo => 'No pudimos cargar tus datos';

  @override
  String get datosPersonalesErrorDetalle =>
      'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get datosPersonalesErrorGuardar =>
      'No pudimos guardar tus datos. Inténtalo de nuevo.';

  @override
  String get datosPersonalesErrorSinConexion =>
      'Sin conexión. Conéctate y vuelve a intentar.';

  @override
  String get datosPersonalesSolicitarIntro =>
      'Cuéntanos qué dato quieres cambiar y por qué. Atención al cliente lo revisa y, si corresponde, lo corrige por ti.';

  @override
  String get datosPersonalesMotivo => '¿Qué quieres cambiar y por qué?';

  @override
  String get datosPersonalesMotivoAyuda =>
      'Por ejemplo: mi teléfono cambió porque perdí el chip.';

  @override
  String get datosPersonalesMotivoCorto =>
      'Cuéntanos un poco más (mínimo 10 caracteres).';

  @override
  String get datosPersonalesEnviar => 'Enviar solicitud';

  @override
  String get datosPersonalesEnviada => 'Recibimos tu solicitud';

  @override
  String get datosPersonalesEnviadaDetalle =>
      'Atención al cliente la revisará y te responderá. Mientras tanto tus datos siguen igual.';

  @override
  String get datosPersonalesListo => 'Listo';

  @override
  String get datosPersonalesErrorEnviar =>
      'No pudimos enviar tu solicitud. Inténtalo de nuevo.';

  @override
  String get datosPersonalesSolicitudAbierta =>
      'Ya tienes una solicitud en revisión.';

  @override
  String get contrasenaTitulo => 'Cambiar contraseña';

  @override
  String get contrasenaFilaAjustes => 'Cambiar contraseña';

  @override
  String get contrasenaFilaAjustesDetalle => 'Con un código que te enviamos';

  @override
  String get contrasenaCanalTitulo => '¿Dónde te enviamos el código?';

  @override
  String get contrasenaCanalDetalle =>
      'Te mandamos un código de 6 números. Vale 10 minutos.';

  @override
  String get contrasenaCanalWhatsapp => 'WhatsApp';

  @override
  String get contrasenaCanalSms => 'Mensaje de texto';

  @override
  String get contrasenaCanalCorreo => 'Correo electrónico';

  @override
  String get contrasenaEnviarCodigo => 'Enviar código';

  @override
  String get contrasenaCodigoTitulo => 'Escribe el código';

  @override
  String contrasenaCodigoEnviadoA(String destino) {
    return 'Lo enviamos a $destino.';
  }

  @override
  String get contrasenaCampoCodigo => 'Código de 6 números';

  @override
  String get contrasenaCampoNueva => 'Contraseña nueva';

  @override
  String get contrasenaCampoNuevaAyuda => 'Usa al menos 4 caracteres.';

  @override
  String get contrasenaCampoRepetir => 'Repite la contraseña nueva';

  @override
  String get contrasenaPedirOtro => 'No me llegó, pedir otro código';

  @override
  String get contrasenaGuardar => 'Cambiar contraseña';

  @override
  String get contrasenaListoTitulo => 'Listo, cambiamos tu contraseña';

  @override
  String get contrasenaListoDetalle =>
      'Tus otros dispositivos tendrán que iniciar sesión de nuevo.';

  @override
  String get contrasenaVolverAjustes => 'Volver a Ajustes';

  @override
  String get permisosCamaraTitulo => 'Usar la cámara';

  @override
  String get permisosCamaraMotivo =>
      'Necesitamos la cámara para tomar la foto que vas a subir. Solo se abre cuando tú lo pides y la foto la ve quien participa del servicio.';

  @override
  String get permisosUbicacionTitulo => 'Usar tu ubicación';

  @override
  String get permisosUbicacionMotivo =>
      'Para centrar el mapa en donde estás y mostrarte las solicitudes cercanas. Solo se usa mientras miras el mapa y no se guarda.';

  @override
  String get permisosNotificacionesTitulo => 'Avisos de solicitudes nuevas';

  @override
  String get permisosNotificacionesMotivo =>
      'Te avisamos cuando llegue una solicitud en tus zonas. Puedes desactivarlos cuando quieras.';

  @override
  String get permisosContinuar => 'Continuar';

  @override
  String get permisosAhoraNo => 'Ahora no';

  @override
  String get permisosDenegadoTitulo => 'Permiso desactivado';

  @override
  String get permisosDenegadoCamara =>
      'Sin la cámara no podemos tomar la foto. Puedes elegir una de tu galería o intentarlo de nuevo cuando quieras.';

  @override
  String get permisosDenegadoUbicacion =>
      'Sin tu ubicación el mapa sigue funcionando, pero no se centra donde estás. Puedes intentarlo de nuevo cuando quieras.';

  @override
  String get permisosDenegadoNotificaciones =>
      'Sin este permiso no te avisamos de solicitudes nuevas. Puedes activarlo cuando quieras.';

  @override
  String get permisosBloqueadoDetalle =>
      'Lo desactivaste en los ajustes del teléfono. Actívalo ahí para continuar.';

  @override
  String get permisosAbrirAjustes => 'Abrir ajustes';

  @override
  String get permisosEntendido => 'Entendido';

  @override
  String get permisosMiUbicacion => 'Usar mi ubicación';

  @override
  String get permisosUbicacionNoDisponible =>
      'No pudimos leer tu ubicación. Revisa que la ubicación del teléfono esté activa.';

  @override
  String get perfilCli2Notificaciones => 'Notificaciones';

  @override
  String get perfilCli2NotificacionesDetalle =>
      'Mensajes de pilotos y de Agrocom';

  @override
  String get perfilCli2EstadHectareas => 'hectáreas';

  @override
  String get perfilPil2BandejaDetalle => 'Mensajes de clientes y de Agrocom';

  @override
  String get perfilPil2AvisosConfigDetalle => 'Nuevas solicitudes por zona';

  @override
  String perfilPil2DronesDetalle(String cantidad) {
    return '$cantidad · Dron y licencia';
  }

  @override
  String get perfilPil2Cobertura => 'Cobertura';

  @override
  String get bandejaTitulo => 'Notificaciones';

  @override
  String get bandejaFiltroTodas => 'Todas';

  @override
  String get bandejaFiltroMensajes => 'Mensajes';

  @override
  String get bandejaFiltroSistema => 'Sistema';

  @override
  String get bandejaGrupoHoy => 'Hoy';

  @override
  String get bandejaGrupoAyer => 'Ayer';

  @override
  String get bandejaGrupoAntes => 'Antes';

  @override
  String get bandejaMarcarTodas => 'Marcar todas como leídas';

  @override
  String get bandejaNoLeida => 'No leída';

  @override
  String get bandejaOrigenSistema => 'Agrocom';

  @override
  String get bandejaVacioTitulo => 'Aquí te avisamos lo importante';

  @override
  String get bandejaVacioDetalle =>
      'Ofertas nuevas, mensajes de la otra parte y cambios en tus servicios aparecerán en esta lista.';

  @override
  String get bandejaVacioMensajesTitulo => 'Todavía no hay mensajes';

  @override
  String get bandejaVacioMensajesDetalle =>
      'Cuando alguien te escriba por un servicio, lo verás aquí.';

  @override
  String get bandejaVacioSistemaTitulo => 'Sin avisos del sistema';

  @override
  String get bandejaVacioSistemaDetalle =>
      'Te avisamos aquí cuando cambie el estado de tus servicios o de tu cuenta.';

  @override
  String get bandejaErrorTitulo => 'No pudimos cargar tus notificaciones';

  @override
  String get bandejaErrorDetalle => 'Revisa tu conexión y vuelve a intentarlo.';
}
