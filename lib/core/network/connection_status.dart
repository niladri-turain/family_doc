import 'package:flutter/foundation.dart';

/// Whether the last server call got through. [ApiClient] updates it; the
/// app shows an "Offline" bar while [isOffline].
class ConnectionStatus extends ChangeNotifier {
  bool _offline = false;
  bool get isOffline => _offline;

  void update({required bool offline}) {
    if (offline == _offline) return;
    _offline = offline;
    notifyListeners();
  }
}
