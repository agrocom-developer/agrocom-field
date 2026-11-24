import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/foto_perfil/presentation/foto_perfil_widgets.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../calificar/domain/calificacion_repositorio.dart';
import '../domain/cuenta_repositorio.dart';

/// Cuenta del cliente: datos de contacto y las calificaciones que le dieron
/// los proveedores.
class CuentaPantalla extends StatelessWidget {
  const CuentaPantalla({this.alCerrarSesion, super.key});

  /// Acción de cerrar sesión; sin ella el botón no se muestra.
  final VoidCallback? alCerrarSesion;

  static String _iniciales(String nombre) => nombre
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  static Future<(CuentaCliente, ResumenCalificaciones)> _cargar(
    CuentaRepositorio cuentas,
    CalificacionRepositorio calificaciones,
  ) async => (await cuentas.cuenta(), await calificaciones.recibidas());

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return FuturoEstable<(CuentaCliente, ResumenCalificaciones)>(
      crear: () => _cargar(
        context.read<CuentaRepositorio>(),
        context.read<CalificacionRepositorio>(),
      ),
      builder: (context, snap) {
        final d = snap.data;
        if (d == null) {
          return const Padding(
            padding: EdgeInsets.all(EspaciadoCampo.l),
            child: EsqueletoCampo(alto: 160),
          );
        }
        final (cuenta, resumen) = d;
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            Text('Cuenta', style: texto.headlineMedium),
            const SizedBox(height: 16),
            FotoPerfilProveedor(
              child: SuperficieMarketplace(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        AvatarFotoPerfil(
                          iniciales: _iniciales(cuenta.nombre),
                          nombre: cuenta.nombre,
                          tamano: 64,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cuenta.nombre, style: texto.titleMedium),
                              if (cuenta.empresa.isNotEmpty)
                                Text(
                                  cuenta.empresa,
                                  style: texto.bodyMedium?.copyWith(
                                    color: paleta.textoSecundario,
                                  ),
                                ),
                              Text(
                                cuenta.usuario,
                                style: texto.bodySmall?.copyWith(
                                  color: paleta.textoSecundario,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: EspaciadoCampo.s),
                    const AccionesFotoPerfil(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SuperficieMarketplace(
              child: Row(
                children: [
                  Expanded(
                    child: _Cifra('${cuenta.serviciosTotales}', 'servicios'),
                  ),
                  Expanded(
                    child: _Cifra(
                      resumen.promedio.toStringAsFixed(1).replaceAll('.', ','),
                      'tu calificación',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Lo que dicen de ti', style: texto.titleLarge),
            const SizedBox(height: 12),
            for (final c in resumen.recientes) ...[
              SuperficieMarketplace(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(c.autor, style: texto.titleSmall)),
                        CalificacionCampo(valor: c.puntaje, tamano: 18),
                      ],
                    ),
                    if (c.comentario != null) ...[
                      const SizedBox(height: 6),
                      Text(c.comentario!, style: texto.bodyMedium),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            const AvisoMarketplace(
              mensaje:
                  'Modo demo: los datos son ficticios y no hay conexión con '
                  'el servidor.',
            ),
            if (alCerrarSesion != null) ...[
              const SizedBox(height: EspaciadoCampo.xl),
              OutlinedButton.icon(
                key: const Key('cuenta-cerrar-sesion'),
                onPressed: alCerrarSesion,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(valor, style: texto.headlineSmall),
        Text(
          etiqueta,
          style: texto.bodySmall?.copyWith(
            color: context.paleta.textoSecundario,
          ),
        ),
      ],
    );
  }
}
