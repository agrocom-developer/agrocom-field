import 'package:flutter/widgets.dart';

/// `StreamBuilder` que crea su `Stream` una sola vez, al montarse.
///
/// Un `StreamBuilder` cuyo `stream` se arma dentro de `build` se resuscribe
/// en cada reconstrucción y su dato vuelve a nulo por un cuadro. Con un
/// repositorio local (`drift`) esto es un parpadeo; con uno en red, una
/// petición repetida. Todas las pantallas leen por aquí.
class StreamEstable<T> extends StatefulWidget {
  const StreamEstable({required this.crear, required this.builder, super.key});

  final Stream<T> Function() crear;
  final AsyncWidgetBuilder<T> builder;

  @override
  State<StreamEstable<T>> createState() => _StreamEstableState<T>();
}

class _StreamEstableState<T> extends State<StreamEstable<T>> {
  late final Stream<T> _stream = widget.crear();

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<T>(stream: _stream, builder: widget.builder);
}

/// `FutureBuilder` que crea su `Future` una sola vez, al montarse.
class FuturoEstable<T> extends StatefulWidget {
  const FuturoEstable({required this.crear, required this.builder, super.key});

  final Future<T> Function() crear;
  final AsyncWidgetBuilder<T> builder;

  @override
  State<FuturoEstable<T>> createState() => _FuturoEstableState<T>();
}

class _FuturoEstableState<T> extends State<FuturoEstable<T>> {
  late final Future<T> _futuro = widget.crear();

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<T>(future: _futuro, builder: widget.builder);
}
