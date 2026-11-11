import 'package:flutter/material.dart';

import '../data/production_api_service.dart';
import '../data/realtime_alerts.dart';
import '../widgets/production_common.dart';

// Central de alertas do usuario (Funcionalidade 3).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const routeName = '/notifications';

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ProductionApiService();
  List<Map<String, dynamic>> _items = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    RealtimeAlerts.instance.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    RealtimeAlerts.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final artistId = currentArtistId;
    if (artistId == null || _loading) return;
    setState(() => _loading = true);
    try {
      final items = await _api.notifications(artistId);
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) showMessage(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _readAll() async {
    final artistId = currentArtistId;
    if (artistId == null) return;
    await _api.markAllNotificationsRead(artistId);
    RealtimeAlerts.instance.setUnread(0);
  }

  IconData _icon(String type) => switch (type) {
    'TASK_OVERDUE' => Icons.alarm,
    'TASK_ASSIGNED' => Icons.assignment_ind,
    'TASK_STATUS_CHANGED' => Icons.sync_alt,
    'APPLICATION_STATUS_CHANGED' => Icons.person_search,
    'POLL_OPENED' || 'POLL_CLOSED' => Icons.how_to_vote,
    'FILE_VERSION_UPLOADED' => Icons.upload_file,
    _ => Icons.notifications,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        actions: [
          TextButton(
            onPressed: _readAll,
            child: const Text('Marcar todos como lidos'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          itemCount: _items.isEmpty ? 1 : _items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (_items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _loading ? 'Carregando...' : 'Nenhum alerta ainda.',
                ),
              );
            }
            final item = _items[index];
            final read = item.b('read');
            return ListTile(
              leading: Icon(
                _icon(item.s('type')),
                color: item.s('type') == 'TASK_OVERDUE'
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
              title: Text(
                item.s('title'),
                style: TextStyle(
                  fontWeight: read ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${item.s('body')}\n${formatDateTime(item.s('createdAt'))}',
              ),
              isThreeLine: true,
              trailing: read ? null : const Icon(Icons.circle, size: 10),
              onTap: read
                  ? null
                  : () async {
                      await _api.markNotificationRead(item.i('id'));
                      RealtimeAlerts.instance.setUnread(
                        (RealtimeAlerts.instance.unread - 1).clamp(0, 1 << 30),
                      );
                    },
            );
          },
        ),
      ),
    );
  }
}

/// Sino com contador de nao lidos, usado na AppBar.
class AlertsBell extends StatelessWidget {
  const AlertsBell({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RealtimeAlerts.instance,
      builder: (context, _) {
        final unread = RealtimeAlerts.instance.unread;
        return IconButton(
          tooltip: 'Alertas',
          onPressed: () =>
              Navigator.pushNamed(context, NotificationsScreen.routeName),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 99 ? '99+' : '$unread'),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}
