import '../data/mock_collaboration_data.dart';
import '../models/application.dart';
import '../models/artist_profile.dart';
import '../models/collaboration_message.dart';
import '../models/decision_record.dart';
import '../models/project.dart';
import '../models/project_task.dart';
import '../models/rehearsal.dart';
import '../models/weekly_goal.dart';

class MockCollaborationStore {
  MockCollaborationStore({
    required List<ArtistProfile> artists,
    required List<Project> projects,
    required List<Application> applications,
    required List<ProjectTask> tasks,
    required List<Rehearsal> rehearsals,
    required List<DecisionRecord> decisions,
    required List<CollaborationMessage> messages,
    required List<WeeklyGoal> weeklyGoals,
  }) : _artists = List<ArtistProfile>.from(artists),
       _projects = List<Project>.from(projects),
       _applications = List<Application>.from(applications),
       _tasks = List<ProjectTask>.from(tasks),
       _rehearsals = List<Rehearsal>.from(rehearsals),
       _decisions = List<DecisionRecord>.from(decisions),
       _messages = List<CollaborationMessage>.from(messages),
       _weeklyGoals = List<WeeklyGoal>.from(weeklyGoals);

  factory MockCollaborationStore.empty() {
    return MockCollaborationStore(
      artists: [],
      projects: [],
      applications: [],
      tasks: [],
      rehearsals: [],
      decisions: [],
      messages: [],
      weeklyGoals: [],
    );
  }

  factory MockCollaborationStore.seeded() {
    return MockCollaborationStore(
      artists: MockCollaborationData.artists(),
      projects: MockCollaborationData.projects(),
      applications: MockCollaborationData.applications(),
      tasks: MockCollaborationData.tasks(),
      rehearsals: MockCollaborationData.rehearsals(),
      decisions: MockCollaborationData.decisions(),
      messages: MockCollaborationData.messages(),
      weeklyGoals: MockCollaborationData.weeklyGoals(),
    );
  }

  static final MockCollaborationStore instance =
      MockCollaborationStore.seeded();

  final List<ArtistProfile> _artists;
  final List<Project> _projects;
  final List<Application> _applications;
  final List<ProjectTask> _tasks;
  final List<Rehearsal> _rehearsals;
  final List<DecisionRecord> _decisions;
  final List<CollaborationMessage> _messages;
  final List<WeeklyGoal> _weeklyGoals;

  List<ArtistProfile> get artists => List.unmodifiable(_artists);
  List<Project> get projects => List.unmodifiable(_projects);
  List<Application> get applications => List.unmodifiable(_applications);
  List<ProjectTask> get tasks => List.unmodifiable(_tasks);
  List<Rehearsal> get rehearsals => List.unmodifiable(_rehearsals);
  List<DecisionRecord> get decisions => List.unmodifiable(_decisions);
  List<CollaborationMessage> get messages => List.unmodifiable(_messages);
  List<WeeklyGoal> get weeklyGoals => List.unmodifiable(_weeklyGoals);

  int get openApplicationCount => _applications
      .where((application) => application.status == ApplicationStatus.pending)
      .length;

  int get pendingTaskCount =>
      _tasks.where((task) => task.status != ProjectTaskStatus.done).length;

  int get openGoalCount =>
      _weeklyGoals.where((goal) => goal.status != WeeklyGoalStatus.done).length;

  List<WeeklyGoal> weeklyGoalsForArtist(String? artistId) {
    if (artistId == null) {
      return weeklyGoals;
    }

    return _weeklyGoals
        .where((goal) => goal.ownerArtistId == artistId)
        .toList(growable: false);
  }

  List<ProjectTask> tasksForProject(String? projectId) {
    if (projectId == null) {
      return tasks;
    }

    return _tasks
        .where((task) => task.projectId == projectId)
        .toList(growable: false);
  }

  List<WeeklyGoal> weeklyGoalsForProject(String? projectId) {
    if (projectId == null) {
      return weeklyGoals;
    }

    return _weeklyGoals
        .where((goal) => goal.projectId == projectId)
        .toList(growable: false);
  }

  List<Rehearsal> rehearsalsForProject(String? projectId) {
    if (projectId == null) {
      return rehearsals;
    }

    return _rehearsals
        .where((rehearsal) => rehearsal.projectId == projectId)
        .toList(growable: false);
  }

  int completedGoalsInWeek(DateTime referenceDate) {
    final start = referenceDate.subtract(
      Duration(days: referenceDate.weekday - 1),
    );
    final startOnly = DateTime(start.year, start.month, start.day);
    final endOnly = startOnly.add(const Duration(days: 7));

    return _weeklyGoals.where((goal) {
      final date = DateTime.tryParse(goal.dueDate);
      if (date == null || goal.status != WeeklyGoalStatus.done) {
        return false;
      }

      final dateOnly = DateTime(date.year, date.month, date.day);
      return !dateOnly.isBefore(startOnly) && dateOnly.isBefore(endOnly);
    }).length;
  }

  List<CollaborationMessage> messagesForProject(String? projectId) {
    if (projectId == null) {
      return messages;
    }

    return _messages
        .where((message) => message.projectId == projectId)
        .toList(growable: false);
  }

  List<DecisionRecord> decisionsForProject(String? projectId) {
    final filtered = projectId == null
        ? _decisions
        : _decisions.where((decision) => decision.projectId == projectId);

    final sorted = List<DecisionRecord>.from(filtered);
    sorted.sort((a, b) => b.decidedAt.compareTo(a.decidedAt));
    return sorted;
  }

  int rehearsalsInWeek(DateTime referenceDate) {
    final start = referenceDate.subtract(
      Duration(days: referenceDate.weekday - 1),
    );
    final startOnly = DateTime(start.year, start.month, start.day);
    final endOnly = startOnly.add(const Duration(days: 7));

    return _rehearsals.where((rehearsal) {
      final date = DateTime.tryParse(rehearsal.date);
      if (date == null || rehearsal.status == RehearsalStatus.canceled) {
        return false;
      }

      final dateOnly = DateTime(date.year, date.month, date.day);
      return !dateOnly.isBefore(startOnly) && dateOnly.isBefore(endOnly);
    }).length;
  }

  void addArtist(ArtistProfile artist) => _artists.add(artist);
  void addProject(Project project) => _projects.add(project);
  void addApplication(Application application) =>
      _applications.add(application);
  void addTask(ProjectTask task) => _tasks.add(task);
  void addRehearsal(Rehearsal rehearsal) => _rehearsals.add(rehearsal);
  void addDecision(DecisionRecord decision) => _decisions.add(decision);
  void addMessage(CollaborationMessage message) => _messages.add(message);
  void addWeeklyGoal(WeeklyGoal goal) => _weeklyGoals.add(goal);

  void editProject(
    String id, {
    String? title,
    String? style,
    String? summary,
    String? status,
    List<String>? needs,
  }) {
    _replaceProject(
      id,
      (project) => project.copyWith(
        title: title,
        style: style,
        summary: summary,
        status: status,
        needs: needs,
      ),
    );
  }

  void editTask(
    String id, {
    String? title,
    String? assignedToArtistId,
    String? dueDate,
    ProjectTaskPriority? priority,
    String? description,
  }) {
    _replaceTask(
      id,
      (task) => task.copyWith(
        title: title,
        assignedToArtistId: assignedToArtistId,
        dueDate: dueDate,
        priority: priority,
        description: description,
      ),
    );
  }

  void updateApplicationStatus(String id, ApplicationStatus status) {
    _replaceApplication(
      id,
      (application) => application.copyWith(status: status),
    );
  }

  void updateTaskStatus(String id, ProjectTaskStatus status) {
    _replaceTask(id, (task) => task.copyWith(status: status));
  }

  void updateRehearsalStatus(String id, RehearsalStatus status) {
    _replaceRehearsal(id, (rehearsal) => rehearsal.copyWith(status: status));
  }

  void updateDecisionStatus(String id, DecisionStatus status) {
    _replaceDecision(id, (decision) => decision.copyWith(status: status));
  }

  void editWeeklyGoal(
    String id, {
    String? title,
    String? description,
    String? ownerArtistId,
    String? weekLabel,
    String? dueDate,
    WeeklyGoalStatus? status,
  }) {
    _replaceWeeklyGoal(
      id,
      (goal) => goal.copyWith(
        title: title,
        description: description,
        ownerArtistId: ownerArtistId,
        weekLabel: weekLabel,
        dueDate: dueDate,
        status: status,
      ),
    );
  }

  void updateWeeklyGoalStatus(String id, WeeklyGoalStatus status) {
    _replaceWeeklyGoal(id, (goal) => goal.copyWith(status: status));
  }

  void removeWeeklyGoal(String id) {
    _weeklyGoals.removeWhere((goal) => goal.id == id);
  }

  void _replaceProject(String id, Project Function(Project project) update) {
    final index = _projects.indexWhere((project) => project.id == id);
    if (index != -1) {
      _projects[index] = update(_projects[index]);
    }
  }

  void _replaceApplication(
    String id,
    Application Function(Application application) update,
  ) {
    final index = _applications.indexWhere(
      (application) => application.id == id,
    );
    if (index != -1) {
      _applications[index] = update(_applications[index]);
    }
  }

  void _replaceTask(String id, ProjectTask Function(ProjectTask task) update) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index] = update(_tasks[index]);
    }
  }

  void _replaceRehearsal(
    String id,
    Rehearsal Function(Rehearsal rehearsal) update,
  ) {
    final index = _rehearsals.indexWhere((rehearsal) => rehearsal.id == id);
    if (index != -1) {
      _rehearsals[index] = update(_rehearsals[index]);
    }
  }

  void _replaceDecision(
    String id,
    DecisionRecord Function(DecisionRecord decision) update,
  ) {
    final index = _decisions.indexWhere((decision) => decision.id == id);
    if (index != -1) {
      _decisions[index] = update(_decisions[index]);
    }
  }

  void _replaceWeeklyGoal(
    String id,
    WeeklyGoal Function(WeeklyGoal goal) update,
  ) {
    final index = _weeklyGoals.indexWhere((goal) => goal.id == id);
    if (index != -1) {
      _weeklyGoals[index] = update(_weeklyGoals[index]);
    }
  }
}
