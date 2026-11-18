import { render, screen } from "@testing-library/react";
import LoadingState from "./components/ui/LoadingState";
import DashboardView from "./domains/dashboard/components/DashboardView";

test("renders the loading state copy", () => {
  render(<LoadingState title="Carregando harmocrew" description="Preparando o ecossistema musical." />);
  expect(screen.getByText(/carregando harmocrew/i)).toBeInTheDocument();
  expect(screen.getByText(/preparando o ecossistema musical/i)).toBeInTheDocument();
});

test("dashboard shows metrics and recent tasks summary", () => {
  render(
    <DashboardView
      data={{
        totalTasks: 2, doneTasks: 1, inProgressTasks: 0, todoTasks: 1, overdueTasks: 1,
        completionPercent: 50, onTimePercent: 100, averageCompletionDays: 1,
        weeklyGoalsTotal: 0, weeklyGoalsDone: 0, weeklyGoalsPercent: null,
        rehearsalsCompleted: 0, attendancePercent: null, openPolls: 0, decisionsRegistered: 1, pendingApplications: 0,
        tasksByStatus: { TODO: 1, IN_PROGRESS: 0, DONE: 1 },
        tasksByStage: { RECORDING: 2 },
        weeklyThroughput: [{ weekStart: "2026-11-16", created: 2, completed: 1 }],
        members: [], projects: [],
        recentTasks: [{ id: 1, title: "Gravar baixo", status: "DONE", updatedAt: "2026-11-18T10:00:00" }],
        upcomingDeadlines: [], importantFiles: [],
      }}
    />
  );
  expect(screen.getByText("Gravar baixo")).toBeInTheDocument();
  expect(screen.getByText(/resumo das tarefas recentes/i)).toBeInTheDocument();
});
