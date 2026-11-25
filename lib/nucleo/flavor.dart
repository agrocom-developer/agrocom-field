/// Determina qué entry point instaló esta APK — no se elige en pantalla
/// (a diferencia del panel web). Ver docs/vision.md, "Las dos superficies
/// móviles" y ADR 0021 (retiro del flavor auxiliar).
enum Flavor { cliente, piloto }
