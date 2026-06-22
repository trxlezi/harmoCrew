import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

abstract class LocalPreferencesGateway {
  Future<void> initialize();

  bool get notificationsEnabled;
  String? get profileImagePath;

  Future<void> setNotificationsEnabled(bool value);
  Future<void> setProfileImagePath(String? value);
}

class HiveLocalPreferencesGateway implements LocalPreferencesGateway {
  HiveLocalPreferencesGateway();

  static const _boxName = 'harmocrew_preferences';
  static const _notificationsEnabledKey = 'notificationsEnabled';
  static const _profileImagePathKey = 'profileImagePath';

  Box<dynamic>? _box;

  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  @override
  bool get notificationsEnabled =>
      (_box?.get(_notificationsEnabledKey) as bool?) ?? false;

  @override
  String? get profileImagePath => _box?.get(_profileImagePathKey) as String?;

  @override
  Future<void> setNotificationsEnabled(bool value) async {
    await _box?.put(_notificationsEnabledKey, value);
  }

  @override
  Future<void> setProfileImagePath(String? value) async {
    if (value == null || value.isEmpty) {
      await _box?.delete(_profileImagePathKey);
      return;
    }
    await _box?.put(_profileImagePathKey, value);
  }
}

abstract class NotificationGateway {
  Future<void> initialize();
  Future<void> showDemoNotification();
}

class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
  }

  @override
  Future<void> showDemoNotification() async {
    const android = AndroidNotificationDetails(
      'harmocrew_demo',
      'HarmoCrew',
      channelDescription: 'Notificacoes locais de demonstracao do HarmoCrew',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: android);

    await _plugin.show(
      1,
      'HarmoCrew',
      'Notificacao local ativa para acompanhar o projeto musical.',
      details,
    );
  }
}

class NativeFeaturesStore extends ChangeNotifier {
  NativeFeaturesStore({
    required LocalPreferencesGateway preferences,
    required NotificationGateway notifications,
    ImagePicker? imagePicker,
  }) : _preferences = preferences,
       _notifications = notifications,
       _imagePicker = imagePicker ?? ImagePicker();

  static final NativeFeaturesStore instance = NativeFeaturesStore(
    preferences: HiveLocalPreferencesGateway(),
    notifications: LocalNotificationGateway(),
  );

  final LocalPreferencesGateway _preferences;
  final NotificationGateway _notifications;
  final ImagePicker _imagePicker;

  bool _initialized = false;
  bool _notificationsEnabled = false;
  String? _profileImagePath;

  bool get initialized => _initialized;
  bool get notificationsEnabled => _notificationsEnabled;
  String? get profileImagePath => _profileImagePath;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _preferences.initialize();
    await _notifications.initialize();
    _notificationsEnabled = _preferences.notificationsEnabled;
    _profileImagePath = _preferences.profileImagePath;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _preferences.setNotificationsEnabled(value);
    notifyListeners();
  }

  Future<void> pickProfileImageFromGallery() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) {
      return;
    }

    _profileImagePath = image.path;
    await _preferences.setProfileImagePath(image.path);
    notifyListeners();
  }

  Future<void> showDemoNotification() async {
    if (!_notificationsEnabled) {
      return;
    }
    await _notifications.showDemoNotification();
  }
}
