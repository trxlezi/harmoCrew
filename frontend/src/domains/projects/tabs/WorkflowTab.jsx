import React, { useState } from "react";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import StatusPill from "../../../components/ui/StatusPill";
import LoadingState from "../../../components/ui/LoadingState";
import api, { errorMessage } from "../../../services/api";
import useLoader from "../../../utils/useLoader";
import { PRIORITY, STAGES, TASK_STATUS, formatDate, stageLabel } from "../../../utils/labels";

const DAY = 86400000;
const toTime = (date) => new Date(`${date}T12:00:00`).getTime();

/*
 * Funcionalidade 3 - Workflow musical: tarefas com responsavel e prazo,
 * Kanban por status e timeline (Gantt) pelas etapas de producao.
 * Atribuicoes, mudancas de status e atrasos geram alertas em tempo real.
 */
export default function WorkflowTab({ project }) {
  const [view, setView] = useState("kanban");
  const [feedback, setFeedback] = useState("");
  const { data, loading, error, reload } = useLoader(async () => {
    const [tasks, timeline] = await Promise.all([api.tasks.list(project.id), api.insights.timeline(project.id)]);
    return { tasks, timeline };
  }, [project.id]);

  async function move(task, status) {
    try {
      await api.tasks.updateStatus(task.id, status);
      setFeedback(`"${task.title}" → ${TASK_STATUS.find(([k]) => k === status)[1]}. Responsável notificado.`);
      reload();
    } catch (err) {
      setFeedback(errorMessage(err));
    }
  }

  if (loading) return <LoadingState title="Carregando workflow" />;
  if (error) return <div className="form-error">{error}</div>;

  return (
    <div className="page-stack">
      <TaskForm project={project} onDone={(title) => { setFeedback(`Tarefa "${title}" criada.`); reload(); }} />
      {feedback ? <div className="inline-feedback">{feedback}</div> : null}

      <div className="segmented">
        <button type="button" className={view === "kanban" ? "active" : ""} onClick={() => setView("kanban")}>Kanban</button>
        <button type="button" className={view === "gantt" ? "active" : ""} onClick={() => setView("gantt")}>Timeline (Gantt)</button>
      </div>

      {view === "kanban" ? <Kanban tasks={data.tasks} onMove={move} /> : <Gantt timeline={data.timeline} />}
    </div>
  );
}

function TaskForm({ project, onDone }) {
  const empty = { title: "", stage: "COMPOSITION", priority: "MEDIUM", assigneeArtistId: "", startDate: "", dueDate: "" };
  const [form, setForm] = useState(empty);
  const [error, setError] = useState("");

  async function submit(event) {
    event.preventDefault();
    const assignee = project.artists.find((a) => String(a.id) === form.assigneeArtistId);
    try {
      await api.tasks.create(project.id, {
        ...form,
        status: "TODO",
        assigneeArtistId: assignee ? assignee.id : null,
        responsibleName: assignee ? assignee.stageName : "Banda",
        startDate: form.startDate || null,
        dueDate: form.dueDate || null,
      });
      onDone(form.title);
      setForm(empty);
      setError("");
    } catch (err) {
      setError(errorMessage(err, "Não foi possível criar a tarefa."));
    }
  }

  return (
    <SurfaceCard>
      <form className="filter-bar" onSubmit={submit}>
        <input required placeholder="Nova tarefa (ex.: Gravar baixo)" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
        <select value={form.stage} onChange={(e) => setForm({ ...form, stage: e.target.value })}>
          {STAGES.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
        </select>
        <select value={form.assigneeArtistId} onChange={(e) => setForm({ ...form, assigneeArtistId: e.target.value })}>
          <option value="">Responsável…</option>
          {project.artists.map((a) => <option key={a.id} value={a.id}>{a.stageName}</option>)}
        </select>
        <select value={form.priority} onChange={(e) => setForm({ ...form, priority: e.target.value })}>
          {Object.entries(PRIORITY).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
        </select>
        <label className="inline-label">Início <input type="date" value={form.startDate} onChange={(e) => setForm({ ...form, startDate: e.target.value })} /></label>
        <label className="inline-label">Prazo <input type="date" value={form.dueDate} onChange={(e) => setForm({ ...form, dueDate: e.target.value })} /></label>
        <button type="submit" className="primary-button">Criar</button>
      </form>
      {error ? <div className="form-error">{error}</div> : null}
    </SurfaceCard>
  );
}

function Kanban({ tasks, onMove }) {
  return (
    <div className="kanban">
      {TASK_STATUS.map(([status, label], index) => {
        const column = tasks.filter((task) => task.status === status);
        return (
          <section key={status} className="kanban-column">
            <h3>{label} <span className="muted">({column.length})</span></h3>
            {column.map((task) => (
              <article key={task.id} className={`kanban-card${task.overdue ? " overdue" : ""}`}>
                <strong>{task.title}</strong>
                <p className="muted small">{stageLabel(task.stage)} · {task.assigneeName || task.responsibleName || "sem responsável"}</p>
                <div className="row-between">
                  <span className="small">Prazo: {formatDate(task.dueDate)}</span>
                  {task.overdue ? <StatusPill tone="danger">Atrasada</StatusPill> : <StatusPill tone="neutral">{PRIORITY[task.priority]}</StatusPill>}
                </div>
                <div className="button-row">
                  {index > 0 ? <button type="button" className="ghost-button" onClick={() => onMove(task, TASK_STATUS[index - 1][0])}>←</button> : null}
                  {index < TASK_STATUS.length - 1 ? (
                    <button type="button" className="ghost-button" onClick={() => onMove(task, TASK_STATUS[index + 1][0])}>
                      {TASK_STATUS[index + 1][1]} →
                    </button>
                  ) : null}
                </div>
              </article>
            ))}
          </section>
        );
      })}
    </div>
  );
}

function Gantt({ timeline }) {
  const tasks = timeline.stages.flatMap((stage) => stage.tasks);
  const dates = tasks.flatMap((t) => [t.startDate || t.dueDate, t.dueDate || t.startDate]).filter(Boolean).map(toTime);
  if (dates.length === 0) {
    return <p className="muted">Defina datas de início/prazo nas tarefas para ver a timeline.</p>;
  }
  const today = Date.now();
  const min = Math.min(...dates, today) - DAY;
  const max = Math.max(...dates, today) + DAY;
  const pct = (time) => ((time - min) / (max - min)) * 100;

  return (
    <SurfaceCard className="gantt">
      <div className="gantt-head">
        <span>{new Date(min).toLocaleDateString("pt-BR")}</span>
        <span>Etapa atual: <b>{stageLabel(timeline.currentStage) }</b></span>
        <span>{new Date(max).toLocaleDateString("pt-BR")}</span>
      </div>
      <div className="gantt-body">
        <div className="gantt-today" style={{ "--p": pct(today) }} title="Hoje" />
        {timeline.stages.map((stage) => (
          <div key={stage.stage} className="gantt-stage">
            <div className="gantt-stage-title">
              <strong>{stage.order}. {stage.label}</strong>
              <span className="muted small"> {stage.doneTasks}/{stage.totalTasks} · {stage.progressPercent}%{stage.overdueTasks ? ` · ${stage.overdueTasks} atrasada(s)` : ""}</span>
            </div>
            {stage.tasks.map((task) => {
              const start = toTime(task.startDate || task.dueDate || new Date().toISOString().slice(0, 10));
              const end = toTime(task.dueDate || task.startDate || new Date().toISOString().slice(0, 10)) + DAY;
              return (
                <div key={task.id} className="gantt-row">
                  <span className="gantt-label">{task.title}</span>
                  <div className="gantt-track">
                    <div
                      className={`gantt-bar status-${task.status}${task.overdue ? " overdue" : ""}`}
                      style={{ left: `${pct(start)}%`, width: `${Math.max(pct(end) - pct(start), 1.5)}%` }}
                      title={`${formatDate(task.startDate)} → ${formatDate(task.dueDate)}`}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        ))}
      </div>
      <div className="legend">
        <span><i className="dot status-TODO" />A fazer</span>
        <span><i className="dot status-IN_PROGRESS" />Em andamento</span>
        <span><i className="dot status-DONE" />Concluída</span>
        <span><i className="dot overdue" />Atrasada</span>
      </div>
    </SurfaceCard>
  );
}
