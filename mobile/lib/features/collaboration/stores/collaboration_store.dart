import '../data/application_api_service.dart';
import '../data/decision_api_service.dart';
import '../data/message_api_service.dart';
import '../data/rehearsal_api_service.dart';
import '../data/task_api_service.dart';
import '../data/weekly_goal_api_service.dart';
import '../models/application.dart';
import '../models/artist_profile.dart';
import '../models/collaboration_message.dart';
import '../models/decision_record.dart';
import '../models/project.dart';
import '../models/project_task.dart';
import '../models/rehearsal.dart';
import '../models/weekly_goal.dart';
import '../../members/data/artist_api_service.dart';
import '../../members/domain/member.dart';
import '../../projects/data/project_api_service.dart';

class CollaborationStore {
  CollaborationStore({
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

  factory CollaborationStore.empty() {
    return CollaborationStore(
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

  static final CollaborationStore instance = CollaborationStore.empty();

  final ArtistApiService _artistApiService = ArtistApiService();
  final ProjectApiService _projectApiService = ProjectApiService();
  final TaskApiService _taskApiService = TaskApiService();
  final ApplicationApiService _applicationApiService = ApplicationApiService();
  final RehearsalApiService _rehearsalApiService = RehearsalApiService();
  final DecisionApiService _decisionApiService = DecisionApiService();
  final MessageApiService _messageApiService = MessageApiService();
  final WeeklyGoalApiService _weeklyGoalApiService = WeeklyGoalApiService();

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
  void addApplication(Application application) => _applications.add(application);
  void addTask(ProjectTask task) => _tasks.add(task);

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

  Future<void> syncAll() async {
    final artists = await _artistApiService.listArtists();
    final projects = await _projectApiService.listProjects();
    final tasks = await _taskApiService.listTasks();
    final applications = await _applicationApiService.listApplications();
    final rehearsals = await _rehearsalApiService.listRehearsals();
    final decisions = await _decisionApiService.listDecisions();
    final messages = await _messageApiService.listMessages();
    final weeklyGoals = await _weeklyGoalApiService.listWeeklyGoals();

    _artists
      ..clear()
      ..addAll(artists);
    _projects
      ..clear()
      ..addAll(projects);
    _tasks
      ..clear()
      ..addAll(tasks);
    _applications
      ..clear()
      ..addAll(applications);
    _rehearsals
      ..clear()
      ..addAll(rehearsals);
    _decisions
      ..clear()
      ..addAll(decisions);
    _messages
      ..clear()
      ..addAll(messages);
    _weeklyGoals
      ..clear()
      ..addAll(weeklyGoals);
  }

  Future<void> syncCoreFromApi() {
    return syncAll();
  }

  Future<ArtistProfile> createArtistFromApi(Member member) async {
    final artist = await _artistApiService.createArtist(member);
    addArtist(artist);
    return artist;
  }

  Future<ProjectTask> createTaskFromApi(ProjectTask task) async {
    final created = await _taskApiService.createTask(task);
    addTask(created);
    return created;
  }

  Future<ProjectTask> updateTaskStatusFromApi(
    String id,
    ProjectTaskStatus status,
  ) async {
    final updated = await _taskApiService.updateStatus(id, status);
    _replaceTask(id, (_) => updated);
    return updated;
  }

  Future<Application> createApplicationFromApi(Application application) async {
    final created = await _applicationApiService.createApplication(application);
    addApplication(created);
    return created;
  }

  Future<Application> updateApplicationStatusFromApi(
    String id,
    ApplicationStatus status,
  ) async {
    final updated = await _applicationApiService.updateStatus(id, status);
    _replaceApplication(id, (_) => updated);
    return updated;
  }

  Future<Rehearsal> createRehearsalFromApi(Rehearsal rehearsal) async {
    final created = await _rehearsalApiService.createRehearsal(rehearsal);
    _rehearsals.add(created);
    return created;
  }

  Future<Rehearsal> updateRehearsalStatusFromApi(
    String id,
    RehearsalStatus status,
  ) async {
    final updated = await _rehearsalApiService.updateStatus(id, status);
    _replaceRehearsal(id, (_) => updated);
    return updated;
  }

  Future<DecisionRecord> createDecisionFromApi(
    DecisionRecord decision,
  ) async {
    final created = await _decisionApiService.createDecision(decision);
    _decisions.add(created);
    return created;
  }

  Future<DecisionRecord> updateDecisionStatusFromApi(
    String id,
    DecisionStatus status,
  ) async {
    final updated = await _decisionApiService.updateStatus(id, status);
    _replaceDecision(id, (_) => updated);
    return updated;
  }

  Future<CollaborationMessage> createMessageFromApi(
    CollaborationMessage message,
  ) async {
    final created = await _messageApiService.createMessage(message);
    _messages.add(created);
    return created;
  }

  Future<WeeklyGoal> createWeeklyGoalFromApi(WeeklyGoal goal) async {
    final created = await _weeklyGoalApiService.createWeeklyGoal(goal);
    _weeklyGoals.add(created);
    return created;
  }

  Future<WeeklyGoal> updateWeeklyGoalFromApi(WeeklyGoal goal) async {
    final updated = await _weeklyGoalApiService.updateWeeklyGoal(goal);
    _replaceWeeklyGoal(goal.id, (_) => updated);
    return updated;
  }

  Future<WeeklyGoal> updateWeeklyGoalStatusFromApi(
    String id,
    WeeklyGoalStatus status,
  ) async {
    final updated = await _weeklyGoalApiService.updateStatus(id, status);
    _replaceWeeklyGoal(id, (_) => updated);
    return updated;
  }

  Future<void> removeWeeklyGoalFromApi(String id) async {
    await _weeklyGoalApiService.deleteWeeklyGoal(id);
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
