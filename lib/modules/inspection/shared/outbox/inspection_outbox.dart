import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_api.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_repository.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether [failure] says the inspection never reached the server (no
/// connection, or the server out of reach for now), so sending it again
/// later is what to do.
bool isUnreachable(AppException failure) =>
    failure is NetworkException ||
    (failure is ServerException &&
        const {'502', '503'}.contains(failure.status));

/// A finished inspection waiting on the phone to go out: what it is, its
/// answers as the server takes them, and the face checks it is signed
/// with, sent with them.
@immutable
class OutboxItem {
  const OutboxItem({
    required this.id,
    required this.api,
    required this.title,
    required this.payload,
    required this.signatures,
    required this.queuedAt,
    this.subtitle,
    this.employee,
    this.attempts = 0,
    this.error,
    this.refused = false,
  });

  final String id;
  final InspectionApi api;

  /// The kind of inspection, as "Station inspection".
  final String title;

  /// What was inspected, as the station.
  final String? subtitle;

  /// The answers, without the face checks.
  final Map<String, dynamic> payload;
  final InspectionSignatures signatures;
  final DateTime queuedAt;

  /// Who it was inspected by, so it goes out only signed in as them.
  final String? employee;
  final int attempts;

  /// Why the last try didn't go through.
  final String? error;

  /// The server, or the face check, turned it down: it waits for the
  /// inspector, not for a connection.
  final bool refused;

  /// What goes to the server: the answers and the face checks.
  Map<String, dynamic> get body => {...payload, ...signatures.toJson()};

  OutboxItem copyWith({
    InspectionSignatures? signatures,
    int? attempts,
    String? error,
    bool? refused,
  }) => OutboxItem(
    id: id,
    api: api,
    title: title,
    subtitle: subtitle,
    payload: payload,
    signatures: signatures ?? this.signatures,
    queuedAt: queuedAt,
    employee: employee,
    attempts: attempts ?? this.attempts,
    error: error ?? this.error,
    refused: refused ?? this.refused,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'api': api.name,
    'title': title,
    'subtitle': ?subtitle,
    'payload': payload,
    'signatures': signatures.toStoreJson(),
    'queued_at': queuedAt.toIso8601String(),
    'employee': ?employee,
    'attempts': attempts,
    'error': ?error,
    'refused': refused,
  };

  static OutboxItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final api = InspectionApi.named(json['api']?.toString());
    final id = json['id']?.toString();
    final payload = json['payload'];
    if (api == null || id == null || payload is! Map) return null;
    return OutboxItem(
      id: id,
      api: api,
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      payload: Map<String, dynamic>.from(payload),
      signatures: InspectionSignatures.fromJson(json['signatures']),
      queuedAt:
          DateTime.tryParse(json['queued_at']?.toString() ?? '') ??
          DateTime.now(),
      employee: json['employee']?.toString(),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      error: json['error']?.toString(),
      refused: json['refused'] == true,
    );
  }
}

/// How a round of sending went.
typedef OutboxRound = ({int sent, int waiting, int refused});

/// The finished inspections that couldn't go out when they were submitted,
/// kept on the phone until they can.
///
/// Each goes out by itself, oldest first, as soon as there is a
/// connection: when the app opens, when the phone comes back online, and
/// whenever [send] is asked. A face check taken offline is matched first.
/// One the server turns down waits, saying why, for the inspector to try
/// again or remove.
class InspectionOutbox extends ChangeNotifier {
  InspectionOutbox({
    required InspectionRepository repository,
    required InspectionFaceMatcher matcher,
    Stream<List<ConnectivityResult>>? connectivity,
    Future<String?> Function()? employee,
  }) : _repository = repository,
       _matcher = matcher,
       _connectivity = connectivity,
       _employee = employee ?? _signedIn;

  final InspectionRepository _repository;
  final InspectionFaceMatcher _matcher;
  final Stream<List<ConnectivityResult>>? _connectivity;
  final Future<String?> Function() _employee;

  static const String _key = 'inspection_outbox';

  List<OutboxItem> _items = const [];
  bool _loaded = false;
  Future<OutboxRound>? _sending;
  StreamSubscription<List<ConnectivityResult>>? _online;
  AppLifecycleListener? _lifecycle;

  /// What is waiting, oldest first.
  List<OutboxItem> get items => _items;

  /// What is waiting for a connection, not turned down.
  int get waiting => _items.where((item) => !item.refused).length;

  /// A round of sending is under way.
  bool get sending => _sending != null;

  static Future<String?> _signedIn() async =>
      (await StorageService.getUser())?.user?.empid?.toString();

  /// Reads what was waiting, sends what it can, and sends again each time
  /// the phone comes back online or the app back to the front.
  Future<void> start() async {
    await _load();
    _online ??= (_connectivity ?? Connectivity().onConnectivityChanged).listen((
      links,
    ) {
      if (links.any((link) => link != ConnectivityResult.none)) {
        unawaited(send());
      }
    });
    _lifecycle ??= AppLifecycleListener(onResume: () => unawaited(send()));
    unawaited(send());
  }

  @override
  void dispose() {
    unawaited(_online?.cancel());
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      _items = [
        for (final json in jsonDecode(raw) as List) ?OutboxItem.fromJson(json),
      ];
      notifyListeners();
    } on Object catch (e) {
      debugPrint('Inspection outbox could not be read: $e');
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final item in _items) item.toJson()]),
    );
    notifyListeners();
  }

  void _put(OutboxItem item) {
    _items = [
      for (final kept in _items)
        if (kept.id == item.id) item else kept,
    ];
  }

  /// Keeps [item] to go out once there is a connection.
  Future<void> add(OutboxItem item) async {
    await _load();
    final signedBy = item.employee ?? await _employee();
    final kept = OutboxItem.fromJson({
      ...item.toJson(),
      'employee': ?signedBy,
    })!;
    _items = [
      for (final other in _items)
        if (other.id != kept.id) other,
      kept,
    ];
    await _save();
  }

  /// Takes [id] off the phone, sent or not.
  Future<void> remove(String id) async {
    await _load();
    _items = [
      for (final item in _items)
        if (item.id != id) item,
    ];
    await _save();
  }

  /// Sends what is waiting, oldest first, stopping at the first that can't
  /// reach the server. With [retry], what was turned down is tried again
  /// too.
  Future<OutboxRound> send({bool retry = false}) {
    final under = _sending;
    if (under != null) return under;
    final round = _send(retry: retry).whenComplete(() {
      _sending = null;
      notifyListeners();
    });
    _sending = round;
    notifyListeners();
    return round;
  }

  Future<OutboxRound> _send({required bool retry}) async {
    await _load();
    final me = await _employee();
    var sent = 0;
    for (final queued in List.of(_items)) {
      if (queued.refused && !retry) continue;
      // Only the inspector who signed it sends it.
      if (queued.employee != null && queued.employee != me) continue;
      var item = queued;
      if (!item.signatures.matched) {
        final matched = await matchSignatures(item.signatures, _matcher);
        final failure = matched.fold<AppException?>((e) => e, (_) => null);
        if (failure != null) {
          if (isUnreachable(failure)) {
            _put(item.copyWith(attempts: item.attempts + 1));
            break;
          }
          _put(item.copyWith(refused: true, error: failure.message));
          await _save();
          continue;
        }
        item = item.copyWith(
          signatures: matched.fold((_) => item.signatures, (s) => s),
        );
        _put(item);
        await _save();
      }
      final result = await _repository.submit(item.api, item.body);
      final failure = result.fold<AppException?>((e) => e, (_) => null);
      if (failure == null) {
        _items = [
          for (final other in _items)
            if (other.id != item.id) other,
        ];
        sent++;
        await _save();
        continue;
      }
      if (isUnreachable(failure)) {
        _put(item.copyWith(attempts: item.attempts + 1, refused: false));
        await _save();
        break;
      }
      _put(
        item.copyWith(
          attempts: item.attempts + 1,
          refused: true,
          error: failure.message,
        ),
      );
      await _save();
    }
    return (
      sent: sent,
      waiting: _items.where((item) => !item.refused).length,
      refused: _items.where((item) => item.refused).length,
    );
  }
}

/// Sends a finished inspection now, or keeps it in [outbox] to go out by
/// itself when it can't reach the server: what the server said, or that
/// it waits. A face check taken offline is matched first.
Future<Either<AppException, InspectionDelivery>> deliverInspection(
  OutboxItem item, {
  required InspectionOutbox outbox,
  required InspectionRepository repository,
  required InspectionFaceMatcher matcher,
}) async {
  var signed = item;
  if (!item.signatures.matched) {
    final matched = await matchSignatures(item.signatures, matcher);
    final failure = matched.fold<AppException?>((e) => e, (_) => null);
    if (failure != null) {
      if (!isUnreachable(failure)) return Left(failure);
      await outbox.add(item);
      return const Right(InspectionDelivery.queued());
    }
    signed = item.copyWith(
      signatures: matched.fold((_) => item.signatures, (s) => s),
    );
  }
  final result = await repository.submit(signed.api, signed.body);
  final failure = result.fold<AppException?>((e) => e, (_) => null);
  if (failure == null) {
    return Right(
      InspectionDelivery.sent(result.fold((_) => '', (done) => done.message)),
    );
  }
  if (!isUnreachable(failure)) return Left(failure);
  await outbox.add(signed);
  return const Right(InspectionDelivery.queued());
}

/// What became of an inspection submitted: sent, with the server's word,
/// or kept to go out later.
@immutable
class InspectionDelivery {
  const InspectionDelivery.sent(this.message) : queued = false;

  const InspectionDelivery.queued() : message = '', queued = true;

  final String message;
  final bool queued;
}
