import React, { useState } from "react";
import { Link } from "react-router-dom";
import SectionHeader from "../../components/ui/SectionHeader";
import SurfaceCard from "../../components/ui/SurfaceCard";
import StatusPill from "../../components/ui/StatusPill";
import LoadingState from "../../components/ui/LoadingState";
import EmptyState from "../../components/ui/EmptyState";
import { useAuth } from "../../context/AuthContext";
import api from "../../services/api";
import useLoader from "../../utils/useLoader";
import { formatDate, stageLabel, taskStatusLabel } from "../../utils/labels";

const FILTERS = [["all", "Tudo"], ["tasks", "Tarefas"], ["goals", "Metas"], ["rehearsals", "Ensaios"]];
const GOAL_LABEL = { PLANNED: "Planejada", IN_PROGRESS: "Em andamento", DONE: "Concluída" };

// Agenda pessoal: tarefas atribuidas a mim, minhas metas e proximos ensaios de todos os projetos.
export default function ResponsibilitiesPage() {
  const { user } = useAuth();
  const [filter, setFilter] = useState("all");
  const { data, loading, error } = useLoader(async () => {
    const [tasks, goals, rehearsals] = await Promise.all([
      api.tasks.mine(),
      api.goals.mine(user.artistId),
      api.rehearsals.mine(),
    ]);
    const today = new Date().toISOString().slice(0, 10);
    return {
      tasks: tasks
        .filter((t) => t.assigneeArtistId === user.artistId && t.status !== "DONE")
        .sort((a, b) => (a.dueDate || "9").localeCompare(b.dueDate || "9")),
      goals: goals.filter((g) => g.status !== "DONE"),
      rehearsals: rehearsals
        .filter((r) => r.status === "SCHEDULED" && r.date >= today)
        .sort((a, b) => `${a.date}${a.time}`.localeCompare(`${b.date}${b.time}`)),
    };
  }, [user.artistId]);

  const show = (kind) => filter === "all" || filter === kind;

  return (
    <div className="page-stack">
      <SectionHeader
        eyebrow="Responsabilidades"
        title="O que está com você"
        subtitle="Tarefas atribuídas, metas da semana e próximos ensaios de todos os seus projetos."
      />
      <div className="segmented">
        {FILTERS.map(([key, label]) => (
          <button key={key} type="button" className={filter === key ? "active" : ""} onClick={() => setFilter(key)}>{label}</button>
        ))}
      </div>
      {loading ? <LoadingState /> : null}
      {error ? <div className="form-error">{error}</div> : null}
      {data ? (
        <div className="card-stack">
          {show("tasks") && data.tasks.map((task) => (
            <Item key={`t${task.id}`} kind="Tarefa" title={task.title} projectId={task.projectId} tab="workflow"
              detail={`${task.projectTitle} · ${stageLabel(task.stage)} · prazo ${formatDate(task.dueDate)}`}
              pill={task.overdue ? <StatusPill tone="danger">Atrasada</StatusPill> : <StatusPill tone="accent">{taskStatusLabel(task.status)}</StatusPill>} />
          ))}
          {show("goals") && data.goals.map((goal) => (
            <Item key={`g${goal.id}`} kind="Meta" title={goal.title} projectId={goal.projectId} tab="rotina"
              detail={`${goal.projectTitle} · ${goal.weekLabel}${goal.dueDate ? ` · até ${formatDate(goal.dueDate)}` : ""}`}
              pill={<StatusPill tone="neutral">{GOAL_LABEL[goal.status]}</StatusPill>} />
          ))}
          {show("rehearsals") && data.rehearsals.map((r) => (
            <Item key={`r${r.id}`} kind="Ensaio" title={r.title} projectId={r.projectId} tab="rotina"
              detail={`${r.projectTitle} · ${formatDate(r.date)} às ${r.time?.slice(0, 5)} · ${r.location}`}
              pill={<StatusPill tone="success">Agendado</StatusPill>} />
          ))}
          {(show("tasks") ? data.tasks.length : 0) + (show("goals") ? data.goals.length : 0) + (show("rehearsals") ? data.rehearsals.length : 0) === 0 ? (
            <EmptyState title="Nada pendente" description="Nenhum item nesta categoria." />
          ) : null}
        </div>
      ) : null}
    </div>
  );
}

function Item({ kind, title, detail, pill, projectId, tab }) {
  return (
    <SurfaceCard>
      <div className="row-between">
        <div>
          <span className="section-eyebrow">{kind}</span>
          <div><strong>{title}</strong></div>
          <p className="muted small">{detail}</p>
        </div>
        <div className="align-right">
          {pill}
          <div><Link className="small" to={`/projetos/${projectId}/${tab}`}>Abrir</Link></div>
        </div>
      </div>
    </SurfaceCard>
  );
}
