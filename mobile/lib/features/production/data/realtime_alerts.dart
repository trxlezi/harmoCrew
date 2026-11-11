import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/native/native_features_store.dart';

/*
 * Alertas em tempo real (Funcionalidade 3).
 *
 * Mantem aberto o stream SSE /api/notifications/stream. Cada alerta recebido
 * (prazo estourado, mudanca de status, novo responsavel, enquete, retorno de
 * candidatura) incrementa o contador do sino e vira notificacao local.
 * Se a conexao cair, reconecta com espera crescente.
 */
class RealtimeAlerts extends ChangeNotifier {
  RealtimeAlerts._();

  static final RealtimeAlerts instance = RealtimeAlerts._();

  final ApiClient _client = ApiClient();
  StreamSubscription<({String event, dynamic data})>? _subscription;
  String? _artistId;
  int _unread = 0;
  int _retrySeconds = 2;
  Timer? _retryTimer;
  Map<String, dynamic>? _latest;

  int get unread => _unread;
  Map<String, dynamic>? get latest => _latest;
  bool get connected => _subscription != null;

  void start(String? artistId) {
    if (artistId == null || artistId == _artistId) return;
    stop();
    _artistId = artistId;
    _connect();
  }

  void stop() {
    _retryTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _artistId = null;
    _unread = 0;
    notifyListeners();
  }

  void setUnread(int value) {
    _unread = value;
    notifyListeners();
  }

  void _connect() {
    final artistId = _artistId;
    if (artistId == null) return;
    _subscription = _client
        .events('/api/notifications/stream?artistId=$artistId')
        .listen(
          _onEvent,
          onError: (_) => _scheduleReconnect(),
          onDone: _scheduleReconnect,
          cancelOnError: true,
        );
  }

  void _onEvent(({String event, dynamic data}) message) {
    _retrySeconds = 2;
    final data = message.data;
    if (message.event == 'ready' && data is Map) {
      _unread = (data['unread'] as num?)?.toInt() ?? 0;
    } else if (message.event == 'notification' &&
        data is Map<String, dynamic>) {
      _unread++;
      _latest = data;
      NativeFeaturesStore.instance.showAlert(
        (data['id'] as num?)?.toInt() ?? DateTime.now().millisecond,
        (data['title'] ?? 'HarmoCrew').toString(),
        (data['body'] ?? '').toString(),
      );
    }
    notifyListeners();
  }

  void _scheduleReconnect() {
    _subscription = null;
    if (_artistId == null) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: _retrySeconds), _connect);
    _retrySeconds = (_retrySeconds * 2).clamp(2, 60);
  }
}
