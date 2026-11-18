import React, { useState } from "react";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import StatusPill from "../../../components/ui/StatusPill";
import LoadingState from "../../../components/ui/LoadingState";
import EmptyState from "../../../components/ui/EmptyState";
import { useAuth } from "../../../context/AuthContext";
import api, { errorMessage } from "../../../services/api";
import useLoader from "../../../utils/useLoader";
import { formatDate } from "../../../utils/labels";

const REHEARSAL_STATUS = { SCHEDULED: ["Agendado", "accent"], COMPLETED: ["Realizado", "success"], CANCELED: ["Cancelado", "danger"] };
const GOAL_STATUS = [["PLANNED", "Planejada"], ["IN_PROGRESS", "Em andamento"], ["DONE", "Concluída"]];

function currentWeekLabel() {
  const now = new Date();
  const start = new Date(now.getFullYear(), 0, 1);
  const week = Math.ceil(((now - start) / 86400000 + start.getDay() + 1) / 7);
  return `${now.getFullYear()}-S${String(week).padStart(2, "0")}`;
}

/*
 * Rotina da banda: ensaios (agenda + lista de presenca, que alimenta a
 * assiduidade do dashboard) e metas semanais por integrante.
 */
export default function RoutineTab({ project }) {
  const [feedback, setFeedback] = useState("");
  const { data, loading, error, reload } = useLoader(async () => {
    const [rehearsals, goals] = await Promise.all([api.rehearsals.list(project.id), api.goals.list(project.id)]);
    return { rehearsals, goals };
  }, [project.id]);

  const act = async (fn, message) => {
    try {
      await fn();
      setFeedback(message);
      reload();
    } catch (err) {
      setFeedback(errorMessage(err));
    }
  };

  if (loading) return <LoadingState title="Carregando ensaios e metas" />;
  if (error) return <div className="form-error">{error}</div>;

  const rehearsals = [...data.rehearsals].sort((a, b) => `${a.date}${a.time}`.localeCompare(`${b.date}${b.time}`));

  return (
    <div className="page-stack">
      {feedback ? <div className="inline-feedback">{feedback}</div> : null}
      <div className="two-columns">
        <section>
          <h2 className="block-title">Ensaios</h2>
          <RehearsalForm project={project} act={act} />
          {rehearsals.length === 0 ? <EmptyState title="Nenhum ensaio" description="Agende o primeiro ensaio da banda." /> : null}
          <div className="card-stack">
            {rehearsals.map((r) => <RehearsalCard key={r.id} rehearsal={r} project={project} act={act} />)}
          </div>
        </section>
        <section>
          <h2 className="block-title">Metas semanais</h2>
          <GoalForm project={project} act={act} />
          {data.goals.length === 0 ? <EmptyState title="Nenhuma meta" description="Defina metas da semana para cada integrante." /> : null}
          <div className="card-stack">
            {data.goals.map((goal) => <GoalCard key={goal.id} goal={goal} project={project} act={act} />)}
          </div>
        </section>
      </div>
    </div>
  );
}

function RehearsalForm({ project, act }) {
  const empty = { title: "", date: "", time: "19:00", location: "", notes: "" };
  const [form, setForm] = useState(empty);
  return (
    <SurfaceCard>
      <form className="filter-bar" onSubmit={(e) => {
        e.preventDefault();
        act(() => api.rehearsals.create(project.id, { ...form, time: `${form.time}:00`, status: "SCHEDULED" }), `Ensaio "${form.title}" agendado.`);
        setForm(empty);
      }}>
        <input required placeholder="Título (ex.: Ensaio geral)" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
        <input required type="date" value={form.date} onChange={(e) => setForm({ ...form, date: e.target.value })} />
        <input required type="time" value={form.time} onChange={(e) => setForm({ ...form, time: e.target.value })} />
        <input required placeholder="Local" value={form.location} onChange={(e) => setForm({ ...form, location: e.target.value })} />
        <button type="submit" className="primary-button">Agendar</button>
      </form>
    </SurfaceCard>
  );
}

function RehearsalCard({ rehearsal, project, act }) {
  const [editing, setEditing] = useState(false);
  const [present, setPresent] = useState(new Set(rehearsal.attendedArtistIds));
  const [label, tone] = REHEARSAL_STATUS[rehearsal.status];
  const name = (id) => project.artists.find((a) => a.id === id)?.stageName || `#${id}`;

  return (
    <SurfaceCard>
      <div className="row-between">
        <div>
          <strong>{rehearsal.title}</strong>
          <p className="muted small">{formatDate(rehearsal.date)} às {rehearsal.time?.slice(0, 5)} · {rehearsal.location}</p>
        </div>
        <StatusPill tone={tone}>{label}</StatusPill>
      </div>
      {rehearsal.status === "COMPLETED" ? (
        <p className="small">
          Presença: {rehearsal.attendedArtistIds.length}/{project.artists.length}
          {rehearsal.attendedArtistIds.length ? ` — ${rehearsal.attendedArtistIds.map(name).join(", ")}` : ""}
        </p>
      ) : null}

      {editing ? (
        <div className="stack-sm">
          <span className="muted small">Quem compareceu?</span>
          {project.artists.map((artist) => (
            <label key={artist.id} className="toggle">
              <input
                type="checkbox"
                checked={present.has(artist.id)}
                onChange={(e) => {
                  const next = new Set(present);
                  if (e.target.checked) next.add(artist.id);
                  else next.delete(artist.id);
                  setPresent(next);
                }}
              />
              {artist.stageName}
            </label>
          ))}
          <div className="button-row">
            <button type="button" className="primary-button" onClick={() => {
              setEditing(false);
              act(() => api.rehearsals.attendance(rehearsal.id, [...present]), "Presença registrada. A assiduidade do dashboard foi atualizada.");
            }}>Salvar presença</button>
            <button type="button" className="ghost-button" onClick={() => setEditing(false)}>Cancelar</button>
          </div>
        </div>
      ) : (
        <div className="button-row">
          {rehearsal.status !== "CANCELED" ? (
            <button type="button" className="secondary-button" onClick={() => setEditing(true)}>
              {rehearsal.status === "COMPLETED" ? "Editar presença" : "Registrar presença"}
            </button>
          ) : null}
          {rehearsal.status === "SCHEDULED" ? (
            <button type="button" className="ghost-button" onClick={() => act(() => api.rehearsals.updateStatus(rehearsal.id, "CANCELED"), "Ensaio cancelado.")}>Cancelar ensaio</button>
          ) : null}
          <button type="button" className="ghost-button" onClick={() => {
            if (window.confirm(`Excluir o ensaio "${rehearsal.title}"?`)) act(() => api.rehearsals.remove(rehearsal.id), "Ensaio excluído.");
          }}>Excluir</button>
        </div>
      )}
    </SurfaceCard>
  );
}

function GoalForm({ project, act }) {
  const { user } = useAuth();
  const empty = { title: "", description: "", ownerArtistId: String(user.artistId), dueDate: "", weekLabel: currentWeekLabel() };
  const [form, setForm] = useState(empty);
  return (
    <SurfaceCard>
      <form className="filter-bar" onSubmit={(e) => {
        e.preventDefault();
        act(() => api.goals.create(project.id, { ...form, ownerArtistId: Number(form.ownerArtistId), dueDate: form.dueDate || null, status: "PLANNED" }), `Meta "${form.title}" criada.`);
        setForm(empty);
      }}>
        <input required placeholder="Meta (ex.: Fechar arranjo do refrão)" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
        <select value={form.ownerArtistId} onChange={(e) => setForm({ ...form, ownerArtistId: e.target.value })}>
          {project.artists.map((a) => <option key={a.id} value={a.id}>{a.stageName}</option>)}
        </select>
        <input placeholder="Semana" value={form.weekLabel} onChange={(e) => setForm({ ...form, weekLabel: e.target.value })} />
        <input type="date" value={form.dueDate} onChange={(e) => setForm({ ...form, dueDate: e.target.value })} />
        <button type="submit" className="primary-button">Criar meta</button>
      </form>
    </SurfaceCard>
  );
}

function GoalCard({ goal, project, act }) {
  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState({ title: goal.title, description: goal.description || "" });
  const index = GOAL_STATUS.findIndex(([k]) => k === goal.status);
  const tone = goal.status === "DONE" ? "success" : goal.status === "IN_PROGRESS" ? "accent" : "neutral";

  const save = () => {
    setEditing(false);
    act(() => api.goals.update(goal.id, {
      ...form, ownerArtistId: goal.ownerArtistId, weekLabel: goal.weekLabel, dueDate: goal.dueDate, status: goal.status,
    }), "Meta atualizada.");
  };

  return (
    <SurfaceCard>
      <div className="row-between">
        {editing ? (
          <input className="inline-input" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
        ) : <strong>{goal.title}</strong>}
        <StatusPill tone={tone}>{GOAL_STATUS[index][1]}</StatusPill>
      </div>
      <p className="muted small">{goal.ownerArtistName} · {goal.weekLabel}{goal.dueDate ? ` · até ${formatDate(goal.dueDate)}` : ""}</p>
      {editing ? (
        <textarea className="inline-input" rows={2} placeholder="Descrição" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
      ) : goal.description ? <p>{goal.description}</p> : null}
      <div className="button-row">
        {editing ? (
          <button type="button" className="primary-button" onClick={save}>Salvar</button>
        ) : (
          <>
            {index > 0 ? <button type="button" className="ghost-button" onClick={() => act(() => api.goals.updateStatus(goal.id, GOAL_STATUS[index - 1][0]), "Status da meta atualizado.")}>←</button> : null}
            {index < 2 ? <button type="button" className="secondary-button" onClick={() => act(() => api.goals.updateStatus(goal.id, GOAL_STATUS[index + 1][0]), "Status da meta atualizado.")}>{GOAL_STATUS[index + 1][1]} →</button> : null}
            <button type="button" className="ghost-button" onClick={() => setEditing(true)}>Editar</button>
            <button type="button" className="ghost-button" onClick={() => {
              if (window.confirm(`Excluir a meta "${goal.title}"?`)) act(() => api.goals.remove(goal.id), "Meta excluída.");
            }}>Excluir</button>
          </>
        )}
      </div>
    </SurfaceCard>
  );
}
