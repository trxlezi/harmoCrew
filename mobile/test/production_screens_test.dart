import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/auth/data/auth_store.dart';
import 'package:mobile/features/auth/domain/auth_user.dart';
import 'package:mobile/features/production/screens/decision_center_screen.dart';
import 'package:mobile/features/production/screens/matching_screen.dart';
import 'package:mobile/features/production/screens/notifications_screen.dart';
import 'package:mobile/features/production/screens/performance_dashboard_screen.dart';
import 'package:mobile/features/production/screens/workflow_timeline_screen.dart';

/*
 * Renderiza as telas das 4 funcionalidades novas com respostas no formato
 * real da API (MockClient), garantindo que montam sem erro de layout.
 */
void main() {
  final today = DateTime.now();
  String day(int offset) =>
      today.add(Duration(days: offset)).toIso8601String().split('T').first;

  Map<String, dynamic> task(
    int id,
    String stage,
    String status,
    int start,
    int due, {
    bool overdue = false,
  }) => {
    'id': id,
    'title': 'Tarefa $id',
    'status': status,
    'priority': 'MEDIUM',
    'dueDate': day(due),
    'startDate': day(start),
    'responsibleName': 'Equipe',
    'projectId': 1,
    'projectTitle': 'Single',
    'stage': stage,
    'assigneeArtistId': 7,
    'assigneeName': 'Ana',
    'overdue': overdue,
    'updatedAt': '${day(0)}T10:00:00',
  };

  final version = {
    'id': 11,
    'fileId': 3,
    'versionNumber': 2,
    'url': '/media/abc.pdf',
    'originalFilename': 'arranjo.pdf',
    'sha256': 'ab12cd34ef',
    'note': 'Ponte nova',
    'uploadedByName': 'Ana',
    'uploadedAt': '${day(0)}T10:00:00',
    'decided': true,
  };
  final file = {
    'id': 3,
    'projectId': 1,
    'name': 'Arranjo',
    'category': 'ARRANGEMENT',
    'locked': true,
    'lockedVersionNumber': 2,
    'currentVersion': version,
    'versions': [version],
  };

  final responses = <String, Object>{
    '/api/projects': [
      {
        'id': 1,
        'title': 'Single',
        'musicalStyle': 'pop',
        'status': 'ACTIVE',
        'needs': [],
        'startDate': day(-30),
        'artists': [],
      },
    ],
    '/api/projects/1/matches': [
      {
        'artistId': 7,
        'stageName': 'Ana',
        'mainSpecialty': 'Baixo',
        'city': 'Sao Paulo',
        'musicalStyles': ['pop'],
        'instruments': ['baixo'],
        'influences': ['Tim Maia'],
        'audioUrl': '/media/a.mp3',
        'score': 92,
        'member': false,
        'breakdown': [
          {'criterion': 'STYLE', 'weight': 35, 'score': 100, 'applied': true},
          {'criterion': 'LOCATION', 'weight': 15, 'score': 0, 'applied': false},
        ],
        'matchedInstruments': ['baixo'],
        'matchedInfluences': [],
        'applicationId': 5,
        'applicationStatus': 'UNDER_REVIEW',
      },
    ],
    '/api/projects/1/applications/ranked': [
      {
        'id': 5,
        'message': 'Quero tocar',
        'specialty': 'Baixo',
        'availability': 'Noites',
        'status': 'UNDER_REVIEW',
        'createdAt': '${day(-1)}T09:00:00',
        'artistId': 7,
        'artistName': 'Ana',
        'projectId': 1,
        'matchScore': 92,
        'evaluationNote': 'Ouvindo',
        'statusUpdatedAt': '${day(0)}T09:00:00',
        'artistAudioUrl': '/media/a.mp3',
      },
    ],
    '/api/projects/1/files': [file],
    '/api/projects/1/polls': [
      {
        'id': 4,
        'projectId': 1,
        'question': 'Qual versao?',
        'status': 'CLOSED',
        'totalVotes': 3,
        'winningOptionId': 21,
        'decisionRecordId': 9,
        'createdAt': '${day(-1)}T09:00:00',
        'options': [
          {
            'id': 20,
            'label': 'Versao 1',
            'position': 0,
            'votes': 1,
            'voters': ['Bia'],
          },
          {
            'id': 21,
            'label': 'Versao 2',
            'position': 1,
            'votes': 2,
            'voters': ['Ana', 'Caio'],
            'fileVersionNumber': 2,
          },
        ],
      },
    ],
    '/api/projects/1/audit-logs': [
      {
        'id': 1,
        'projectId': 1,
        'action': 'FILE_LOCKED',
        'entityType': 'ProjectFile',
        'entityId': 3,
        'actorName': 'Ana',
        'details': 'Arranjo travado na v2',
        'createdAt': '${day(0)}T10:00:00',
      },
    ],
    '/api/projects/1/timeline': {
      'projectId': 1,
      'projectTitle': 'Single',
      'currentStage': 'ARRANGEMENT',
      'stages': [
        for (final (i, stage) in [
          'COMPOSITION',
          'ARRANGEMENT',
          'RECORDING',
          'MIXING',
          'RELEASE',
        ].indexed)
          {
            'stage': stage,
            'label': stage,
            'order': i + 1,
            'totalTasks': i < 2 ? 1 : 0,
            'doneTasks': i == 0 ? 1 : 0,
            'progressPercent': i == 0 ? 100 : 0,
            'overdueTasks': i == 1 ? 1 : 0,
            'tasks': [
              if (i == 0) task(1, stage, 'DONE', -10, -3),
              if (i == 1) task(2, stage, 'IN_PROGRESS', -5, -1, overdue: true),
            ],
          },
      ],
      'unstagedTasks': [],
    },
    '/api/dashboard': {
      'scope': 'COLLECTIVE',
      'totalTasks': 3,
      'doneTasks': 1,
      'inProgressTasks': 1,
      'todoTasks': 1,
      'overdueTasks': 1,
      'completionPercent': 33,
      'onTimePercent': 100,
      'averageCompletionDays': 7.0,
      'weeklyGoalsTotal': 2,
      'weeklyGoalsDone': 1,
      'weeklyGoalsPercent': 50,
      'rehearsalsCompleted': 2,
      'attendancePercent': 75,
      'openPolls': 0,
      'decisionsRegistered': 1,
      'pendingApplications': 1,
      'tasksByStatus': {'TODO': 1, 'IN_PROGRESS': 1, 'DONE': 1},
      'tasksByStage': {
        'COMPOSITION': 1,
        'ARRANGEMENT': 1,
        'RECORDING': 1,
        'MIXING': 0,
        'RELEASE': 0,
        'NONE': 0,
      },
      'weeklyThroughput': [
        for (var w = 7; w >= 0; w--)
          {'weekStart': day(-7 * w), 'created': w % 3, 'completed': w % 2},
      ],
      'members': [
        {
          'artistId': 7,
          'name': 'Ana',
          'assignedTasks': 2,
          'doneTasks': 1,
          'overdueTasks': 1,
          'rehearsalsInvited': 2,
          'rehearsalsAttended': 2,
          'attendancePercent': 100,
        },
      ],
      'projects': [
        {
          'projectId': 1,
          'title': 'Single',
          'totalTasks': 3,
          'doneTasks': 1,
          'overdueTasks': 1,
          'completionPercent': 33,
          'currentStage': 'ARRANGEMENT',
        },
      ],
      'recentTasks': [
        task(2, 'ARRANGEMENT', 'IN_PROGRESS', -5, -1, overdue: true),
      ],
      'upcomingDeadlines': [task(3, 'RECORDING', 'TODO', 2, 7)],
      'importantFiles': [file],
    },
    '/api/notifications': [
      {
        'id': 1,
        'recipientArtistId': 7,
        'type': 'TASK_OVERDUE',
        'title': 'Prazo estourado: Arranjo',
        'body': 'Venceu ontem',
        'read': false,
        'createdAt': '${day(0)}T08:00:00',
      },
    ],
  };

  final mock = MockClient((request) async {
    final body = responses[request.url.path];
    // Demais listas carregadas pela store do app (artistas, tarefas...).
    if (body == null) {
      return http.Response(
        '[]',
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      200,
      headers: {'content-type': 'application/json'},
    );
  });

  setUp(() {
    AuthStore.currentUser = const AuthUser(
      name: 'Ana',
      email: 'a@a.com',
      password: '',
      artistId: '7',
    );
  });

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(1200, 2400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(home: screen));
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
    }, () => mock);
  }

  testWidgets('dashboard de performance mostra KPIs e graficos', (
    tester,
  ) async {
    await pump(tester, const PerformanceDashboardScreen());
    expect(find.text('33%'), findsWidgets);
    expect(find.text('Assiduidade'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Desempenho por integrante'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Desempenho por integrante'), findsOneWidget);
  });

  testWidgets('timeline mostra etapas do workflow e o gantt', (tester) async {
    await pump(tester, const WorkflowTimelineScreen());
    expect(find.textContaining('COMPOSITION 100%'), findsOneWidget);
    expect(find.textContaining('Tarefa 2 (Ana)'), findsOneWidget);
  });

  testWidgets('central de decisoes lista arquivos versionados', (tester) async {
    await pump(tester, const DecisionCenterScreen());
    expect(find.text('Arranjo'), findsOneWidget);
    expect(find.textContaining('decidido: v2'), findsOneWidget);
    await tester.tap(find.text('Enquetes'));
    await tester.pumpAndSettle();
    expect(find.text('Qual versao?'), findsOneWidget);
    await tester.tap(find.text('Auditoria'));
    await tester.pumpAndSettle();
    expect(find.text('Arranjo travado na v2'), findsOneWidget);
  });

  testWidgets('selecao de musicos mostra ranking e candidaturas', (
    tester,
  ) async {
    await pump(tester, const MatchingScreen());
    expect(find.text('1. Ana'), findsOneWidget);
    expect(find.text('92'), findsOneWidget);
    await tester.tap(find.textContaining('Candidaturas'));
    await tester.pumpAndSettle();
    expect(find.text('Em avaliacao'), findsOneWidget);
    expect(find.text('Ouvir audio'), findsOneWidget);
  });

  testWidgets('alertas listam notificacoes do usuario', (tester) async {
    await pump(tester, const NotificationsScreen());
    expect(find.text('Prazo estourado: Arranjo'), findsOneWidget);
  });

  testWidgets('telas cabem na largura de celular', (tester) async {
    for (final screen in const <Widget>[
      PerformanceDashboardScreen(),
      WorkflowTimelineScreen(),
      DecisionCenterScreen(),
      MatchingScreen(),
    ]) {
      await pump(tester, screen, size: const Size(360, 740));
      expect(tester.takeException(), isNull, reason: '$screen');
    }
  });

  test('cliente le eventos SSE de alertas', () async {
    final client = ApiClient(
      baseUrl: 'http://api',
      httpClient: MockClient.streaming((request, _) async {
        expect(request.headers['Accept'], 'text/event-stream');
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              'event:ready\ndata:{"unread":2}\n\n'
              'event:notification\ndata:{"id":5,"title":"Prazo estourado"}\n\n',
            ),
          ),
          200,
        );
      }),
    );
    final events = await client.events('/api/notifications/stream').toList();
    expect(events.map((e) => e.event), ['ready', 'notification']);
    expect((events.last.data as Map)['title'], 'Prazo estourado');
  });
}
