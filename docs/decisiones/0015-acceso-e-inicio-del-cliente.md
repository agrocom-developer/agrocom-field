# ADR 0015 — Acceso e inicio del flavor cliente

**Estado:** Aceptada (decisión revisable) · **Serie:** ADR propios de `agrocom-field`.

## Contexto

El flavor `cliente` necesita un recorrido de entrada completo (arranque, presentación, ingreso, registro) y un inicio que resuma lo que le importa a quien solicita servicios. El contrato de autenticación del cliente lo publica `agrocom-api`; la interfaz se construye contra interfaces de repositorio y repositorios demo (ADR 0010), de modo que el repositorio de red reemplace al demo sin tocar pantallas.

## Decisión

### Una puerta por encima de la navegación

`PuertaAccesoCliente` es el `home` de `AppCliente`. Lee `ArranqueCubit` y muestra una sola de estas etapas, fundiendo una con la siguiente (`MovimientoCampo.lenta`):

| Etapa | Pantalla | Cuándo |
|---|---|---|
| `resolviendo` | `SplashPantalla` | Mientras se lee la sesión guardada y dura la secuencia del logo |
| `onboarding` | `OnboardingPantalla` | Primer uso: la presentación de tres pasos no se vio |
| `acceso` | `LoginClientePantalla` o `RegistroClientePantalla` | No hay sesión |
| `dentro` | `ShellCliente` | Hay sesión |
| `error` | Aviso con «Reintentar» | No se pudo leer el estado guardado |

Ingreso y registro se alternan con estado local dentro de la puerta, no con rutas apiladas: al iniciar sesión no queda ninguna pantalla de acceso debajo de la navegación principal. El cierre de sesión (pestaña Cuenta) vuelve a la etapa `acceso`.

### Un Cubit por pantalla, una interfaz por feature

- `lib/cliente/acceso/`: `AccesoRepositorio` (sesión actual, presentación vista, iniciar sesión, registrar, cerrar sesión), `ReglasAcceso` (validación local) y los cubits `ArranqueCubit`, `OnboardingCubit`, `LoginClienteCubit` y `RegistroClienteCubit`. Los fallos llegan como `AccesoExcepcion` con un motivo (`credencialesInvalidas`, `sinConexion`, `validacion`, `desconocido`) y, para un `422`, el mensaje por campo.
- `lib/cliente/inicio/`: `InicioClienteRepositorio` emite un `ResumenInicio` ya resuelto (servicio activo principal, cantidad de otros activos, por calificar, historial reciente y avisos). `ReglasInicioCliente.resumir` es la regla pura que lo arma; la pantalla no filtra ni ordena. `InicioClienteCubit` vive en `ShellCliente`, así volver a la pestaña Inicio no repite la carga.
- Iniciar sesión y registrarse requieren red (ADR 0009). Sin red, la pantalla lo dice y el formulario conserva lo escrito. La contraseña no se guarda en el dispositivo.
- La recuperación de contraseña no se ofrece mientras el contrato no la publique.

### Diseño

- Una acción principal por pantalla: «Continuar», «Ingresar», «Crear cuenta» y, en el inicio, «Solicitar un servicio» dentro de una tarjeta destacada. «Seguir en vivo» y «Calificar» son botones de contorno.
- Componentes compartidos en `lib/nucleo/marketplace/ui/`, todos sobre `PaletaCampo` (claro y oscuro): `CampoFormularioMarketplace` (etiqueta visible, error en línea, ver u ocultar contraseña), `BotonPrincipalMarketplace` (ancho completo, estado de envío, escala al presionar) y `AparicionMarketplace` (entrada en cascada de los bloques).
- Movimiento: la splash es una secuencia única de 1400 ms (logo desde escala 0,95, línea lima, frase); los cambios de paso y de etapa duran entre 160 y 320 ms; el inicio entra en cascada con 50 ms entre bloques. Con «reducir movimiento» no hay desplazamientos ni escalas y la splash no espera.
- Carga con `EsqueletoCampo` con la forma del inicio; vacío que orienta («No tienes servicios en curso»); error con salida («Reintentar»); sin conexión dicho de forma explícita.
- Adaptativo: en ancho expandido (iPad horizontal) el acceso suma un panel de marca con foto y la presentación pone foto y texto lado a lado; desde 600 px el inicio pasa a dos columnas (lo que pide acción a la izquierda, lo informativo a la derecha).

### Modo demo

- `main_cliente.dart` con `MODO_DEMO` arranca como una instalación nueva: `DependenciasCliente.demo(primerUso: true)`. `DependenciasCliente.demo()` sin argumentos abre con la sesión iniciada, que es lo que usan los tests de navegación.
- `AccesoDemo` no tiene cuentas: cualquier correo bien escrito entra con una contraseña de 8 caracteres o más. Tres valores fijos muestran los estados de error: el correo `sinred@agrocom.example` responde sin conexión, la contraseña `incorrecta` responde credenciales inválidas y registrarse con `ocupado@agrocom.example` devuelve un error junto al campo del correo.
- La pantalla de ingreso muestra una nota de entorno solo cuando `DependenciasCliente.notaAcceso` la define (modo demo).

## Consecuencias

- El repositorio de red de acceso implementa `AccesoRepositorio` sobre `TokenStoreSeguro` y `ApiClient` y se enchufa en `DependenciasCliente`; las pantallas y los cubits no cambian.
- `test/ui/ui_acceso_cliente/` guarda los goldens de cada pantalla y estado en claro y oscuro, a texto 200 % en 360 x 640 y en iPad vertical y horizontal. Se generan en macOS y en Linux (CI) se omiten.
- Los avisos del inicio se descartan solo en memoria; persistirlos queda para cuando el contrato defina de dónde vienen.
