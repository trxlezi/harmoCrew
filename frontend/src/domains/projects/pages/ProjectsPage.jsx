import React, { useState } from "react";
import { Link } from "react-router-dom";
import SectionHeader from "../../../components/ui/SectionHeader";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import StatusPill from "../../../components/ui/StatusPill";
import LoadingState from "../../../components/ui/LoadingState";
import EmptyState from "../../../components/ui/EmptyState";
import { useAuth } from "../../../context/AuthContext";
import api, { errorMessage } from "../../../services/api";
import useLoader from "../../../utils/useLoader";
import { APPLICATION_STATUS, formatDate, splitList } from "../../../utils/labels";

const EMPTY = {
  title: "",
  description: "",
  musicalStyle: "",
  location: "",
  needs: "",
  desiredInfluences: "",
  startDate: new Date().toISOString().slice(0, 10),
};

export default function ProjectsPage() {
  const { user } = useAuth();
  const [form, setForm] = useState(EMPTY);
  const [showForm, setShowForm] = useState(false);
  const [feedback, setFeedback] = useState("");

  const { data, loading, error, reload } = useLoader(async () => {
    const [projects, applications] = await Promise.all([
      api.projects.list(),
      api.applications.mine(user.artistId),
    ]);
    return { projects, applications };
  }, [user.artistId]);

  async function createProject(event) {
    event.preventDefault();
    try {
      await api.projects.create({
        ...form,
        status: "ACTIVE",
        needs: splitList(form.needs),
        desiredInfluences: splitList(form.desiredInfluences),
      });
      setForm(EMPTY);
      setShowForm(false);
      setFeedback("Vaga publicada. Você já é membro do projeto.");
      reload();
    } catch (err) {
      setFeedback(errorMessage(err, "Não foi possível criar a vaga."));
    }
  }

  if (loading) return <LoadingState title="Carregando projetos" />;
  if (error) return <div className="form-error">{error}</div>;

  const isMember = (project) => project.artists.some((artist) => artist.id === user.artistId);
  const myApplications = new Map(data.applications.map((app) => [app.projectId, app]));
  const mine = data.projects.filter(isMember);
  const open = data.projects.filter((project) => !isMember(project));

  return (
    <div className="page-stack">
      <SectionHeader
        eyebrow="Projetos e vagas"
        title="Seus projetos e oportunidades abertas"
        subtitle="Crie uma vaga, receba candidaturas e organize a produção com a banda."
        action={
          <button type="button" className="primary-button" onClick={() => setShowForm((v) => !v)}>
            {showForm ? "Cancelar" : "Nova vaga"}
          </button>
        }
      />

      {feedback ? <div className="inline-feedback">{feedback}</div> : null}

      {showForm ? (
        <SurfaceCard>
          <form className="form-grid" onSubmit={createProject}>
            <Field label="Título" value={form.title} onChange={(v) => setForm({ ...form, title: v })} required />
            <Field label="Estilo musical" value={form.musicalStyle} onChange={(v) => setForm({ ...form, musicalStyle: v })} placeholder="MPB, Rock..." />
            <Field label="Cidade" value={form.location} onChange={(v) => setForm({ ...form, location: v })} />
            <Field label="Início" type="date" value={form.startDate} onChange={(v) => setForm({ ...form, startDate: v })} required />
            <Field label="Instrumentos procurados (vírgula)" value={form.needs} onChange={(v) => setForm({ ...form, needs: v })} placeholder="Baixo, Bateria" />
            <Field label="Influências desejadas (vírgula)" value={form.desiredInfluences} onChange={(v) => setForm({ ...form, desiredInfluences: v })} placeholder="Jorge Ben, Tim Maia" />
            <label className="field form-grid-wide">
              <span>Descrição</span>
              <textarea rows={3} value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
            </label>
            <button type="submit" className="primary-button">Publicar vaga</button>
          </form>
        </SurfaceCard>
      ) : null}

      <h2 className="block-title">Meus projetos</h2>
      {mine.length === 0 ? (
        <EmptyState title="Você ainda não participa de projetos" description="Crie uma vaga ou candidate-se a uma abaixo." />
      ) : (
        <div className="card-grid">
          {mine.map((project) => (
            <ProjectCard key={project.id} project={project}>
              <Link className="primary-button" to={`/projetos/${project.id}`}>Abrir projeto</Link>
            </ProjectCard>
          ))}
        </div>
      )}

      <h2 className="block-title">Vagas abertas</h2>
      {open.length === 0 ? (
        <EmptyState title="Nenhuma vaga aberta" description="Quando outras bandas publicarem vagas, elas aparecem aqui." />
      ) : (
        <div className="card-grid">
          {open.map((project) => (
            <ProjectCard key={project.id} project={project}>
              <ApplyBox project={project} application={myApplications.get(project.id)} onDone={reload} />
            </ProjectCard>
          ))}
        </div>
      )}
    </div>
  );
}

function ProjectCard({ project, children }) {
  return (
    <SurfaceCard className="project-card">
      <div className="project-card-top">
        <h3>{project.title}</h3>
        <StatusPill tone="accent">{project.musicalStyle || "Estilo livre"}</StatusPill>
      </div>
      {project.description ? <p className="muted">{project.description}</p> : null}
      <div className="chip-row">
        {project.needs?.map((need) => <span key={need} className="chip">{need}</span>)}
      </div>
      <p className="muted small">
        {project.location || "Remoto"} · início {formatDate(project.startDate)} · {project.artists.length} membro(s)
      </p>
      {children}
    </SurfaceCard>
  );
}

function ApplyBox({ project, application, onDone }) {
  const { user } = useAuth();
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ message: "", specialty: "", availability: "" });
  const [error, setError] = useState("");

  if (application) {
    const [label, tone] = APPLICATION_STATUS[application.status] || [application.status, "neutral"];
    return (
      <div className="apply-status">
        <span>Sua candidatura:</span> <StatusPill tone={tone}>{label}</StatusPill>
        {application.matchScore != null ? <span className="muted small"> · compatibilidade {application.matchScore}%</span> : null}
        {application.evaluationNote ? <p className="muted small">Retorno: {application.evaluationNote}</p> : null}
      </div>
    );
  }

  async function submit(event) {
    event.preventDefault();
    try {
      await api.applications.create(project.id, { artistId: user.artistId, ...form });
      onDone();
    } catch (err) {
      setError(errorMessage(err, "Não foi possível enviar a candidatura."));
    }
  }

  if (!open) {
    return <button type="button" className="secondary-button" onClick={() => setOpen(true)}>Candidatar-se</button>;
  }
  return (
    <form className="stack-sm" onSubmit={submit}>
      <Field label="Especialidade" value={form.specialty} onChange={(v) => setForm({ ...form, specialty: v })} required />
      <Field label="Disponibilidade" value={form.availability} onChange={(v) => setForm({ ...form, availability: v })} required />
      <label className="field">
        <span>Mensagem</span>
        <textarea rows={2} required value={form.message} onChange={(e) => setForm({ ...form, message: e.target.value })} />
      </label>
      {error ? <div className="form-error">{error}</div> : null}
      <button type="submit" className="primary-button">Enviar candidatura</button>
    </form>
  );
}

export function Field({ label, value, onChange, type = "text", ...rest }) {
  return (
    <label className="field">
      <span>{label}</span>
      <input type={type} value={value} onChange={(e) => onChange(e.target.value)} {...rest} />
    </label>
  );
}
