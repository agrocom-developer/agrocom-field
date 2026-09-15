import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../componentes/componentes_campo.dart';
import '../imagenes_campo.dart';
import '../tipografia_campo.dart';

/// 02 · Login del dispositivo — vinculación por token, distinta del login
/// real (`LoginVista`: usuario/contraseña, ver `features/auth/`). Mock de
/// UI puro sobre `ImagenesCampo.dronSobreAgua`: el flujo de vinculación
/// por código no existe todavía en `agrocom-api` (ver ADR 0008, "no una
/// especificación de datos").
class LoginDispositivoCampoVitrina extends StatelessWidget {
  const LoginDispositivoCampoVitrina({super.key});

  @override
  Widget build(BuildContext context) {
    return FondoFotoCampo(
      imagen: ImagenesCampo.dronSobreAgua,
      cobertura: CoberturaFondoFoto.superior,
      altoSuperior: 300,
      alineacion: const Alignment(0, -0.2),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LogoAgrocomCampo(ancho: 132),
              const SizedBox(height: 12),
              const Text(
                'Vincular dispositivo',
                style: TipografiaCampo.tituloPantalla,
              ),
              const SizedBox(height: 6),
              Text(
                'El token queda en el equipo. No se pide usuario en cada '
                'vuelo.',
                style: TipografiaCampo.cuerpo,
              ),
              const SizedBox(height: 26),
              const StatChipCampo(
                etiqueta: 'Código de vinculación',
                valor: '•••• ••••',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: StatChipCampo(
                      etiqueta: 'Rol del apk',
                      valor: 'Piloto',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TarjetaCampo(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('ENTORNO', style: TipografiaCampo.etiquetaMono),
                          const SizedBox(height: 8),
                          Text(
                            'Staging',
                            style: TipografiaCampo.tituloSeccion.copyWith(
                              fontSize: 17,
                              color: ColoresCampo.acentoAmbar,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const BannerAlertaCampo(
                texto:
                    'API_BASE_URL inyectada por build. Verificá el '
                    'entorno antes de cargar trabajo real.',
              ),
              const Spacer(),
              BotonPrimarioCampo(texto: 'Vincular', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }
}
