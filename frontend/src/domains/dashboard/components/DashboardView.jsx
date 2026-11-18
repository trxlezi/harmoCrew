import React from "react";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import StatusPill from "../../../components/ui/StatusPill";
import { mediaUrl } from "../../../services/api";
import { FILE_CATEGORY, STAGES, formatDate, formatDateTime, stageLabel, taskStatusLabel } from "../../../utils/labels";

/*
 * Funcionalidade 4 - Dashboard de performance: conclusao, pontualidade,
 * assiduidade, graficos (status, etapas, throughput semanal, membros),
 * resumo de tarefas recentes, proximos prazos e arquivos importantes.
 */
export default function DashboardView({ data, showProjects = false }) {
  const pct = (value) => (value == null ? "—" : `${value}%`);
  return (
    <div className="page-stack">
      <div className="kpi-grid">
        <Kpi label="Conclusão de tarefas" value={pct(data.completionPercent)} detail={`${data.doneTasks}/${data.totalTasks} concluídas`} ring={data.completionPercent} />
        <Kpi label="Pontualidade" value={pct(data.onTimePercent)} detail="entregues até o prazo" ring={data.onTimePercent} />
        <Kpi label="Assiduidade em ensaios" value={pct(data.attendancePercent)} detail={`${data.rehearsalsCompleted} ensaio(s) realizados`} ring={data.attendancePercent} />
        <Kpi label="Tarefas atrasadas" value={data.overdueTasks} detail={`${data.inProgressTasks} em andamento`} tone={data.overdueTasks ? "danger" : "success"} />
        <Kpi label="Metas semanais" value={pct(data.weeklyGoalsPercent)} detail={`${data.weeklyGoalsDone}/${data.weeklyGoalsTotal}`} ring={data.weeklyGoalsPercent} />
        <Kpi label="Decisões / enquetes abertas" value={`${data.decisionsRegistered} / ${data.openPolls}`} detail={`${data.pendingApplications} candidatura(s) pendentes`} />
      </div>

      <div className="two-columns">
        <SurfaceCard>
          <h3>Tarefas criadas × concluídas (8 semanas)</h3>
          <WeeklyChart points={data.weeklyThroughput} />
        </SurfaceCard>
        <SurfaceCard>
          <h3>Andamento por etapa</h3>
          <HBars
            items={STAGES.map(([key, label]) => ({ label, value: data.tasksByStage[key] || 0 }))}
          />
          <h3>Tarefas por status</h3>
          <StackedBar byStatus={data.tasksByStatus} />
        </SurfaceCard>
      </div>

      <div className="two-columns">
        <SurfaceCard>
          <h3>Resumo das tarefas recentes</h3>
          <TaskList tasks={data.recentTasks} empty="Nenhuma tarefa movimentada ainda." showUpdated />
          <h3>Próximos prazos</h3>
          <TaskList tasks={data.upcomingDeadlines} empty="Sem prazos pendentes." />
        </SurfaceCard>
        <SurfaceCard>
          <h3>Desempenho por membro</h3>
          <table className="data-table">
            <thead><tr><th>Membro</th><th>Tarefas</th><th>Concluídas</th><th>Atrasadas</th><th>Presença</th></tr></thead>
            <tbody>
              {data.members.map((m) => (
                <tr key={m.artistId}>
                  <td>{m.name}</td>
                  <td>{m.assignedTasks}</td>
                  <td>
                    <div className="mini-bar"><div style={{ width: `${m.assignedTasks ? (m.doneTasks / m.assignedTasks) * 100 : 0}%` }} /></div>
                    {m.doneTasks}
                  </td>
                  <td className={m.overdueTasks ? "text-danger" : ""}>{m.overdueTasks}</td>
                  <td>{m.attendancePercent == null ? "—" : `${m.attendancePercent}%`}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <h3>Arquivos importantes</h3>
          {data.importantFiles.length === 0 ? <p className="muted">Nenhum arquivo ainda.</p> : (
            <ul className="mini-list-clean">
              {data.importantFiles.map((file) => (
                <li key={file.id}>
                  {file.currentVersion ? (
                    <a href={mediaUrl(file.currentVersion.url)} target="_blank" rel="noreferrer">{file.name}</a>
                  ) : file.name}
                  <span className="muted small"> · {FILE_CATEGORY[file.category]} · v{file.currentVersion?.versionNumber}</span>
                  {file.locked ? <> <StatusPill tone="success">decidido</StatusPill></> : null}
                </li>
              ))}
            </ul>
          )}
        </SurfaceCard>
      </div>

      {showProjects && data.projects.length ? (
        <SurfaceCard>
          <h3>Projetos</h3>
          <table className="data-table">
            <thead><tr><th>Projeto</th><th>Conclusão</th><th>Atrasadas</th><th>Pontualidade</th><th>Assiduidade</th><th>Etapa atual</th></tr></thead>
            <tbody>
              {data.projects.map((p) => (
                <tr key={p.projectId}>
                  <td>{p.title}</td>
                  <td><div className="mini-bar"><div style={{ width: `${p.completionPercent}%` }} /></div>{p.completionPercent}%</td>
                  <td>{p.overdueTasks}</td>
                  <td>{p.onTimePercent == null ? "—" : `${p.onTimePercent}%`}</td>
                  <td>{p.attendancePercent == null ? "—" : `${p.attendancePercent}%`}</td>
                  <td>{p.currentStage ? stageLabel(p.currentStage) : "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </SurfaceCard>
      ) : null}
    </div>
  );
}

function Kpi({ label, value, detail, ring, tone }) {
  return (
    <SurfaceCard className={`kpi${tone ? ` kpi--${tone}` : ""}`}>
      {ring != null ? (
        <div className="ring" style={{ "--p": ring }}><span>{value}</span></div>
      ) : (
        <div className="kpi-value">{value}</div>
      )}
      <div>
        <strong>{label}</strong>
        <p className="muted small">{detail}</p>
      </div>
    </SurfaceCard>
  );
}

function WeeklyChart({ points }) {
  const max = Math.max(1, ...points.flatMap((p) => [p.created, p.completed]));
  const W = 560;
  const H = 180;
  const slot = W / points.length;
  const bar = slot / 3;
  return (
    <>
    <svg viewBox={`0 0 ${W} ${H + 24}`} className="chart" role="img" aria-label="Tarefas por semana">
      {[0.25, 0.5, 0.75, 1].map((f) => (
        <line key={f} x1="0" x2={W} y1={H - H * f} y2={H - H * f} className="grid" />
      ))}
      {points.map((p, i) => {
        const x = i * slot + slot / 6;
        const hc = (p.created / max) * (H - 10);
        const hd = (p.completed / max) * (H - 10);
        return (
          <g key={p.weekStart}>
            <rect x={x} y={H - hc} width={bar} height={hc} className="bar-created" rx="3"><title>{`Criadas: ${p.created}`}</title></rect>
            <rect x={x + bar + 2} y={H - hd} width={bar} height={hd} className="bar-done" rx="3"><title>{`Concluídas: ${p.completed}`}</title></rect>
            <text x={x + bar} y={H + 16} className="axis" textAnchor="middle">{formatDate(p.weekStart).slice(0, 5)}</text>
          </g>
        );
      })}
    </svg>
    <div className="legend">
      <span><i className="dot" style={{ background: "#5b6478" }} />criadas</span>
      <span><i className="dot status-DONE" />concluídas</span>
    </div>
    </>
  );
}

function HBars({ items }) {
  const max = Math.max(1, ...items.map((i) => i.value));
  return (
    <div className="hbars">
      {items.map((item) => (
        <div key={item.label} className="hbar">
          <span>{item.label}</span>
          <div className="bar"><div className="bar-fill" style={{ width: `${(item.value / max) * 100}%` }} /></div>
          <b>{item.value}</b>
        </div>
      ))}
    </div>
  );
}

function StackedBar({ byStatus }) {
  const total = Object.values(byStatus).reduce((a, b) => a + b, 0) || 1;
  return (
    <>
      <div className="stacked">
        {Object.entries(byStatus).map(([status, count]) =>
          count ? <div key={status} className={`status-${status}`} style={{ width: `${(count / total) * 100}%` }} title={`${taskStatusLabel(status)}: ${count}`} /> : null
        )}
      </div>
      <div className="legend">
        {Object.entries(byStatus).map(([status, count]) => (
          <span key={status}><i className={`dot status-${status}`} />{taskStatusLabel(status)} ({count})</span>
        ))}
      </div>
    </>
  );
}

function TaskList({ tasks, empty, showUpdated }) {
  if (!tasks.length) return <p className="muted">{empty}</p>;
  return (
    <ul className="mini-list-clean">
      {tasks.map((task) => (
        <li key={task.id}>
          <strong>{task.title}</strong>
          <span className="muted small">
            {" "}· {taskStatusLabel(task.status)} · {task.assigneeName || task.responsibleName || "—"} ·{" "}
            {showUpdated ? `atualizada ${formatDateTime(task.updatedAt)}` : `prazo ${formatDate(task.dueDate)}`}
            {task.projectTitle ? ` · ${task.projectTitle}` : ""}
          </span>
          {task.overdue ? <> <StatusPill tone="danger">atrasada</StatusPill></> : null}
        </li>
      ))}
    </ul>
  );
}
