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
      'No pudimos enviarlo. Tu mensaje sigue aquí; prueba de nuevo.';

  @override
  String get chatFalloFoto => 'No pudimos enviar la foto. Prueba de nuevo.';

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
      'Sin conexión. No se confirmó nada; prueba de nuevo cuando tengas señal.';

  @override
  String get precioFinalFalloRechazado =>
      'El servicio todavía no terminó, así que no se puede confirmar el precio.';

  @override
  String get precioFinalFalloDesconocido =>
      'No pudimos confirmar el precio final. Prueba de nuevo.';

  @override
  String get precioFinalAbrirDisputa => 'Abrir disputa';

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
    return 'Necesitamos señal para cargar $queNoCargo. Revisa tu conexión y prueba de nuevo.';
  }

  @override
  String get estadoErrorTitulo => 'Algo salió mal';

  @override
  String estadoErrorDetalle(String queNoCargo) {
    return 'No pudimos cargar $queNoCargo. Prueba de nuevo en un momento.';
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
      'lo que ya cargaste sigue a la vista. Pedir u ofertar necesita red.';

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
    return 'Pedido $numero, $estado';
  }

  @override
  String get uiPosicionDelDron => 'Posición del dron';

  @override
  String get uiOpenstreetmap => 'OpenStreetMap';

  @override
  String get versionActualizacionObligatoria => 'Actualización obligatoria';

  @override
  String versionEstaVersionAppEsta(String version) {
    return 'Esta versión de la app ya no está autorizada. Instalá la versión $version o superior para seguir usándola.';
  }

  @override
  String get versionDescargalaDesde => 'DESCÁRGALA DESDE';

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
      'Fumigación con drones, a pedido';

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
  String get accesoIntentaNuevoMomento => 'Intenta de nuevo en un momento.';

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
      'Es con lo que vas a entrar. Sin espacios ni correo.';

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
  String get inicioBuenClimaParaAplicar => 'Buen clima para aplicar mañana';

  @override
  String get inicioVientoSinLluviaHasta =>
      'Viento de 8 km/h y sin lluvia hasta el mediodía en Cuatro Cañadas.';

  @override
  String get inicioBuenPrecioAtraeMas => 'Un buen precio atrae más ofertas';

  @override
  String get inicioLosPilotosComparanPrecio =>
      'Los pilotos comparan el precio por hectárea: si tardan en ofertar, puedes subirlo.';

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
  String get inicioDescartarAviso => 'Descartar aviso';

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
      'Los pilotos de la zona ya ven tu solicitud. Cuando alguno ofrezca, te avisamos. Si tarda, prueba subir tu precio.';

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
      'Acuerden la fecha por el chat.';

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
      'El piloto todavía no empezó. Acuerden la fecha por el chat.';

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
      'Todavía no hay fotos. El piloto las sube a medida que avanza, y las verás acá.';

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
    return 'PEDIDO #$id';
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
      'Sin conexión. No enviamos tu respuesta; inténtalo con señal.';

  @override
  String get ofertasPudimosEnviarRespuesta => 'No pudimos enviar tu respuesta.';

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
    return 'PEDIDO #$id';
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
}
