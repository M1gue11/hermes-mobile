import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/repositories/local_notifier.dart';

/// [LocalNotifier] pelas notificações do Android.
///
/// Dois canais, para a pessoa poder silenciar um sem perder o outro nas
/// configurações do sistema: respostas (importância padrão) e "esperando
/// você" (alta, porque o agente está parado até alguém responder).
class SystemLocalNotifier implements LocalNotifier {
  SystemLocalNotifier([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _turnsChannel = AndroidNotificationChannel(
    'hermes_turns',
    'Respostas do agente',
    description: 'Quando um turno termina ou falha.',
  );
  static const _attentionChannel = AndroidNotificationChannel(
    'hermes_attention',
    'Esperando você',
    description: 'Aprovação, pergunta ou sudo pendentes.',
    importance: Importance.high,
  );

  /// Âmbar do Manuscrito; só tinge o ícone pequeno.
  static const _accent = Color(0xFFD8A24A);

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();
  Future<void>? _initializing;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_hermes'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) _taps.add(payload);
      },
    );
    final android = _android;
    if (android != null) {
      await android.createNotificationChannel(_turnsChannel);
      await android.createNotificationChannel(_attentionChannel);
    }
  }

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse?.payload;
  }

  @override
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? true;

  @override
  Future<bool> permitted() async =>
      await _android?.areNotificationsEnabled() ?? true;

  @override
  Future<void> show(LocalNotice notice) async {
    await initialize();
    final channel = notice.urgent ? _attentionChannel : _turnsChannel;
    await _plugin.show(
      id: notice.id,
      title: notice.title,
      body: notice.body,
      payload: notice.payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: notice.urgent ? Priority.high : Priority.defaultPriority,
          color: _accent,
          // O aviso local e o push da mesma conversa usam o mesmo id: o
          // segundo substitui o primeiro sem tocar de novo.
          onlyAlertOnce: true,
          visibility: NotificationVisibility.private,
          category: notice.urgent
              ? AndroidNotificationCategory.reminder
              : AndroidNotificationCategory.message,
        ),
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
  }
}
