/// Determina qué entry point instaló esta APK — no se elige en pantalla
/// (a diferencia del panel web). Ver docs/vision.md, "Las tres superficies
/// móviles" y ADR 0009 (arquitectura de las tres superficies).
enum Flavor { cliente, piloto, auxiliar }
