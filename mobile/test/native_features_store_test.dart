import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/native/native_features_store.dart';

void main() {
  test('loads notification preference and selected image path', () async {
    final preferences = _FakePreferencesGateway(
      notificationsEnabled: true,
      profileImagePath: '/tmp/avatar.png',
    );
    final notifications = _FakeNotificationGateway();
    final store = NativeFeaturesStore(
      preferences: preferences,
      notifications: notifications,
    );

    await store.initialize();

    expect(store.notificationsEnabled, isTrue);
    expect(store.profileImagePath, '/tmp/avatar.png');
  });

  test('persists notification preference changes', () async {
    final preferences = _FakePreferencesGateway();
    final notifications = _FakeNotificationGateway();
    final store = NativeFeaturesStore(
      preferences: preferences,
      notifications: notifications,
    );

    await store.initialize();
    await store.setNotificationsEnabled(true);

    expect(store.notificationsEnabled, isTrue);
    expect(preferences.notificationsEnabled, isTrue);
  });

  test('sends demo notification only when notifications are enabled', () async {
    final preferences = _FakePreferencesGateway(notificationsEnabled: true);
    final notifications = _FakeNotificationGateway();
    final store = NativeFeaturesStore(
      preferences: preferences,
      notifications: notifications,
    );

    await store.initialize();
    await store.showDemoNotification();

    expect(notifications.demoNotificationsSent, 1);

    await store.setNotificationsEnabled(false);
    await store.showDemoNotification();

    expect(notifications.demoNotificationsSent, 1);
  });
}

class _FakePreferencesGateway implements LocalPreferencesGateway {
  _FakePreferencesGateway({
    this.notificationsEnabled = false,
    this.profileImagePath,
  });

  @override
  bool notificationsEnabled;

  @override
  String? profileImagePath;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled = value;
  }

  @override
  Future<void> setProfileImagePath(String? value) async {
    profileImagePath = value;
  }
}

class _FakeNotificationGateway implements NotificationGateway {
  int demoNotificationsSent = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showDemoNotification() async {
    demoNotificationsSent++;
  }
}
