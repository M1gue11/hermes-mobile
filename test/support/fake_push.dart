import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:hermes_mobile/data/config/push_registration_store.dart';
import 'package:hermes_mobile/domain/repositories/local_notifier.dart';
import 'package:hermes_mobile/domain/repositories/push_transport.dart';

/// Distribuidor UnifiedPush de mentira. Por padrão responde ao [register]
/// com [endpoint], como o app ntfy faz.
class FakePushTransport implements PushTransport {
  FakePushTransport({
    this.installed = const ['io.heckel.ntfy'],
    this.current,
    this.endpoint = 'https://ntfy.example.org/upAbc123?up=1',
    this.answerRegister = true,
  });

  final _events = StreamController<PushTransportEvent>.broadcast();
  List<String> installed;
  String? current;
  String endpoint;
  bool answerRegister;
  int registrations = 0;
  int unregistrations = 0;

  void emit(PushTransportEvent event) => _events.add(event);

  void push(Map<String, Object?> envelope) => emit(
    PushMessageReceived(
      Uint8List.fromList(utf8.encode(jsonEncode(envelope))),
      decrypted: true,
    ),
  );

  @override
  Stream<PushTransportEvent> get events => _events.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<String>> distributors() async => installed;

  @override
  Future<String?> currentDistributor() async => current;

  @override
  Future<void> useDistributor(String distributor) async =>
      current = distributor;

  @override
  Future<void> register() async {
    registrations++;
    if (answerRegister) {
      scheduleMicrotask(
        () => emit(
          PushEndpointIssued(
            url: endpoint,
            p256dh: 'pub-key',
            auth: 'auth-key',
          ),
        ),
      );
    }
  }

  @override
  Future<void> unregister() async {
    unregistrations++;
    current = null;
  }
}

class FakeLocalNotifier implements LocalNotifier {
  FakeLocalNotifier({this.allowed = true});

  bool allowed;
  final List<LocalNotice> shown = [];
  final List<int> cancelled = [];
  final _taps = StreamController<String>.broadcast();
  String? launch;

  void tap(String payload) => _taps.add(payload);

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> launchPayload() async => launch;

  @override
  Future<bool> requestPermission() async => allowed;

  @override
  Future<bool> permitted() async => allowed;

  @override
  Future<void> show(LocalNotice notice) async => shown.add(notice);

  @override
  Future<void> cancel(int id) async => cancelled.add(id);
}

class MemoryPushRegistrationStore implements PushRegistrationStore {
  MemoryPushRegistrationStore([StoredPushRegistration? initial])
    : value =
          initial ??
          (
            deviceId: 'phone-0001',
            enabled: false,
            endpoint: null,
            p256dh: null,
            auth: null,
            syncedEndpoint: null,
          );

  StoredPushRegistration value;

  @override
  Future<StoredPushRegistration> read() async => value;

  @override
  Future<void> save(StoredPushRegistration registration) async =>
      value = registration;
}
