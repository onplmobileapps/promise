import 'dart:async';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_api.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_repository.dart';
import 'package:railway_hrms/modules/inspection/data/models/inspection_submission.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_review_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';
import 'package:railway_hrms/modules/inspection/shared/outbox/inspection_outbox.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_form_scaffold.dart';
import 'package:railway_hrms/modules/inspection/station/models/station_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_app.dart';

/// A server that is out of reach until [online], and keeps what it takes.
class _Server implements InspectionRepository {
  bool online = false;
  String? refuse;
  final List<(InspectionApi, Map<String, dynamic>)> taken = [];

  @override
  Future<Either<AppException, List<StationItem>>> getUserStations({
    int? section,
  }) async => const Right([]);

  @override
  Future<Either<AppException, InspectionSubmission>> submit(
    InspectionApi api,
    Map<String, dynamic> payload,
  ) async {
    if (!online) return Left(NetworkException());
    if (refuse case final reason?) {
      return Left(ServerException(reason, '400'));
    }
    taken.add((api, payload));
    return const Right(InspectionSubmission(message: 'Report 7 received.'));
  }
}

/// Matches a face taken offline once [online], unless told it isn't the
/// employee's.
class _Matcher implements InspectionFaceMatcher {
  _Matcher(this.server);

  final _Server server;
  bool stranger = false;
  int asked = 0;

  @override
  Future<Either<AppException, InspectionIdentity>> match(
    InspectionIdentity identity,
  ) async {
    asked++;
    if (!server.online) return Left(NetworkException());
    if (stranger) return Left(AppException('Face does not match.'));
    return Right(identity.asMatched());
  }
}

class _Verifier implements InspectionFaceVerifier {
  @override
  Future<FaceCheckResult> verify(
    BuildContext context,
    InspectionMoment moment,
  ) async => FaceCheckPassed(
    InspectionIdentity(photoPath: 'submit.jpg', verifiedAt: DateTime(2026)),
  );
}

final _start = InspectionIdentity(
  photoPath: 'start.jpg',
  verifiedAt: DateTime(2026, 10, 17, 9),
);

final _offlineStart = InspectionIdentity(
  photoPath: 'start.jpg',
  verifiedAt: DateTime(2026, 10, 17, 9),
  matched: false,
  photos: const ['start.jpg', 'start-2.jpg'],
  embeddings: const [
    [0.1, 0.2],
    [0.3, 0.4],
  ],
);

OutboxItem _item(String id, {InspectionIdentity? start}) => OutboxItem(
  id: id,
  api: InspectionApi.station,
  title: 'Station inspection',
  subtitle: 'Lahore Junction',
  payload: {'station': 11, 'sm_uniform': 'YES'},
  signatures: InspectionSignatures(start: start ?? _start),
  queuedAt: DateTime(2026, 10, 17, 10),
);

Future<Uint8List> _noPdf(InspectionReport report, Object l10n, String locale) =>
    Future.error(UnsupportedError('No PDF in tests'));

void main() {
  late _Server server;
  late _Matcher matcher;
  late StreamController<List<ConnectivityResult>> links;

  InspectionOutbox outbox() => InspectionOutbox(
    repository: server,
    matcher: matcher,
    connectivity: links.stream,
    employee: () async => '42',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    server = _Server();
    matcher = _Matcher(server);
    links = StreamController.broadcast();
  });
  tearDown(() => links.close());

  test('a waiting inspection outlives the app and goes out once online, '
      'signed', () async {
    final first = outbox();
    await first.add(_item('station-1'));
    expect((await first.send()).waiting, 1);
    expect(server.taken, isEmpty);

    // The app opens again, still waiting; the phone comes back online.
    final again = outbox();
    await again.start();
    await pumpEventQueue();
    expect(again.items.single.id, 'station-1');
    expect(again.items.single.employee, '42');
    server.online = true;
    links.add([ConnectivityResult.wifi]);
    await pumpEventQueue();
    while (again.sending) {
      await pumpEventQueue();
    }
    expect(again.items, isEmpty);
    final (api, body) = server.taken.single;
    expect(api, InspectionApi.station);
    expect(body['station'], 11);
    expect(body['start_verification'], {
      'photo': 'start.jpg',
      'verified_at': '2026-10-17T09:00:00.000',
    });
    again.dispose();
  });

  test('a face taken offline is matched before the inspection goes out, '
      'and stops it if it is not the employee', () async {
    final box = outbox();
    await box.add(_item('a', start: _offlineStart));
    // Kept with what matching it needs.
    final kept = outbox();
    await kept.send();
    expect(kept.items.single.signatures.matched, isFalse);
    expect(kept.items.single.signatures.start?.embeddings, hasLength(2));

    server.online = true;
    matcher.stranger = true;
    final round = await kept.send();
    expect(round, (sent: 0, waiting: 0, refused: 1));
    expect(kept.items.single.error, 'Face does not match.');
    expect(server.taken, isEmpty);

    matcher.stranger = false;
    // Turned down, it waits for the inspector to try again.
    expect((await kept.send()).sent, 0);
    expect((await kept.send(retry: true)).sent, 1);
    expect(
      server.taken.single.$2['start_verification'],
      isNot(contains('embeddings')),
    );
  });

  test('what the server turns down waits, saying why; what was signed by '
      'someone else stays for them', () async {
    final box = outbox();
    await box.add(_item('mine'));
    await box.add(
      OutboxItem.fromJson({..._item('theirs').toJson(), 'employee': '7'})!,
    );
    server
      ..online = true
      ..refuse = 'Station: this field is required.';
    final round = await box.send();
    expect(round, (sent: 0, waiting: 1, refused: 1));
    expect(
      box.items.firstWhere((i) => i.id == 'mine').error,
      'Station: this field is required.',
    );
    await box.remove('mine');
    expect(box.items.single.id, 'theirs');
  });

  group('submitting', () {
    setUp(() {
      sl
        ..registerSingleton<InspectionRepository>(server)
        ..registerSingleton<InspectionFaceMatcher>(matcher)
        ..registerSingleton<InspectionOutbox>(outbox());
    });
    tearDown(sl.reset);

    Future<void> submitIn(WidgetTester tester, {required bool online}) async {
      server.online = online;
      await pumpScreen(
        tester,
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => reviewAndSubmit(
                context,
                report: InspectionReport(
                  title: 'Station inspection',
                  date: DateTime(2026, 10, 17),
                  sections: [
                    ReportSection(
                      title: 'Office',
                      rows: [ReportRow('Uniform', 'Yes')],
                    ),
                  ],
                ),
                verifier: _Verifier(),
                render: _noPdf,
                send: (signatures) => _item(
                  'station-9',
                ).copyWith(signatures: signatures.copyWith(start: _start)),
              ),
              child: const Text('submit'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('submit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('The report is correct'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify face to submit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit inspection'));
      await tester.pumpAndSettle();
    }

    testWidgets('with no connection it is kept to go out by itself', (
      tester,
    ) async {
      await submitIn(tester, online: false);
      expect(find.text('Saved to send'), findsOneWidget);
      expect(sl<InspectionOutbox>().items.single.id, 'station-9');
      expect(
        sl<InspectionOutbox>().items.single.signatures.submit?.photoPath,
        'submit.jpg',
      );
    });

    testWidgets('online it goes at once', (tester) async {
      await submitIn(tester, online: true);
      expect(find.text('Report 7 received.'), findsOneWidget);
      expect(sl<InspectionOutbox>().items, isEmpty);
      expect(server.taken.single.$2['submit_verification'], isNotNull);
    });
  });

  testWidgets('an answer tapped on the review opens its step on the form, '
      'at the question', (tester) async {
    String? lights;
    var reviews = 0;
    await pumpScreen(
      tester,
      StatefulBuilder(
        builder: (context, setState) => InspectionFormScaffold(
          title: 'Station inspection',
          onReview: () async {
            reviews++;
            await reviewAndSubmit(
              context,
              report: InspectionReport(
                title: 'Station inspection',
                date: DateTime(2026, 10, 17),
                sections: [
                  ReportSection(
                    title: 'Lights',
                    rows: [ReportRow('Platform lights', lights)],
                  ),
                  ReportSection(
                    title: 'Pumps',
                    rows: [ReportRow('Pump 1 · Discharge', 'Faulty')],
                  ),
                ],
              ),
              render: _noPdf,
              submit: (_) async => const Right('Kept.'),
            );
          },
          steps: [
            InspectionStep(
              title: 'Lights',
              builder: (_) => Column(
                children: [
                  for (var i = 0; i < 12; i++)
                    InspectionChoiceInput(
                      label: 'Light $i',
                      options: const ['Yes', 'No'],
                      value: null,
                      onChanged: (_) {},
                    ),
                  InspectionChoiceInput(
                    label: 'Platform lights',
                    options: const ['Working', 'Not working'],
                    value: lights,
                    onChanged: (v) => setState(() => lights = v),
                  ),
                ],
              ),
            ),
            InspectionStep(
              title: 'Pumps',
              builder: (_) => const Text('Discharge'),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review and submit'));
    await tester.pumpAndSettle();
    expect(reviews, 1);
    expect(find.text('Pump 1 · Discharge'), findsOneWidget);

    // Findings only, then all again.
    await tester.tap(find.text('Findings'));
    await tester.pumpAndSettle();
    expect(find.text('Platform lights'), findsNothing);
    await tester.tap(find.text('Blank'));
    await tester.pumpAndSettle();
    expect(find.text('Platform lights'), findsOneWidget);

    await tester.tap(find.text('Platform lights'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 2'), findsOneWidget);
    final question = tester.getRect(find.text('Platform lights'));
    expect(question.top, inInclusiveRange(0, tester.view.physicalSize.height));
    await tester.tap(find.text('Working'));
    await tester.pumpAndSettle();
    expect(lights, 'Working');
    expect(tester.takeException(), isNull);
  });
}
