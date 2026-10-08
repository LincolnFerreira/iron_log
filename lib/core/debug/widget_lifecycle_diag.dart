import 'package:flutter/widgets.dart';
import 'package:iron_log/core/debug/diag_log.dart';

/// Logs initState / build / dispose for a [StatefulWidget] screen (debug only).
mixin WidgetLifecycleDiag<W extends StatefulWidget> on State<W> {
  String get _widgetLabel => widget.runtimeType.toString();

  @override
  void initState() {
    DiagLog.widget('initState', detail: _widgetLabel);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    DiagLog.widget('build', detail: _widgetLabel);
    return buildWithDiag(context);
  }

  /// Implement screen UI here (called from instrumented [build]).
  Widget buildWithDiag(BuildContext context);

  @override
  void dispose() {
    DiagLog.widget('dispose', detail: _widgetLabel);
    super.dispose();
  }
}
