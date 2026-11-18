import React from "react";
import { Link, NavLink, Navigate, Route, Routes, useParams } from "react-router-dom";
import LoadingState from "../../../components/ui/LoadingState";
import StatusPill from "../../../components/ui/StatusPill";
import { useAuth } from "../../../context/AuthContext";
import api from "../../../services/api";
import useLoader from "../../../utils/useLoader";
import { formatDate } from "../../../utils/labels";
import SelectionTab from "../tabs/SelectionTab";
import DecisionsTab from "../tabs/DecisionsTab";
import WorkflowTab from "../tabs/WorkflowTab";
import DashboardTab from "../tabs/DashboardTab";
import ChatTab from "../tabs/ChatTab";
import RoutineTab from "../tabs/RoutineTab";
import ProjectSettings from "../components/ProjectSettings";

export const STATUS_LABEL = { PLANNING: "Planejamento", ACTIVE: "Ativo", PAUSED: "Pausado", FINISHED: "Finalizado" };

const TABS = [
  ["selecao", "Seleção de músicos"],
  ["decisoes", "Decisões e arquivos"],
  ["workflow", "Tarefas e timeline"],
  ["rotina", "Ensaios e metas"],
  ["dashboard", "Dashboard"],
  ["chat", "Mensagens"],
  ["config", "Configurações"],
];

export default function ProjectPage() {
  const { id } = useParams();
  const { user } = useAuth();
  const { data: project, loading, error, reload } = useLoader(() => api.projects.get(id), [id]);

  if (loading) return <LoadingState title="Carregando projeto" />;
  if (error) return <div className="form-error">{error}</div>;

  const member = project.artists.some((artist) => artist.id === user.artistId) || user.role === "ADMIN";

  return (
    <div className="page-stack">
      <div className="project-header surface-card">
        <div>
          <Link to="/projetos" className="muted small">← Projetos</Link>
          <h1 className="section-title">{project.title}</h1>
          <p className="muted">
            {STATUS_LABEL[project.status]} · {project.musicalStyle || "Estilo livre"} · {project.location || "Remoto"} · início {formatDate(project.startDate)}
          </p>
          <div className="chip-row">
            {project.artists.map((artist) => (
              <span key={artist.id} className="chip chip--member">{artist.stageName}</span>
            ))}
          </div>
        </div>
        <StatusPill tone={member ? "success" : "neutral"}>{member ? "Você é membro" : "Visitante"}</StatusPill>
      </div>

      {!member ? (
        <div className="locked-card surface-card">
          <h3>Área restrita aos membros</h3>
          <p className="muted">
            Arquivos, decisões, tarefas, candidatos e métricas deste projeto só aparecem para quem faz parte da banda.
            Candidate-se na página de projetos para participar.
          </p>
        </div>
      ) : (
        <>
          <nav className="tabs" aria-label="Seções do projeto">
            {TABS.map(([path, label]) => (
              <NavLink key={path} to={`/projetos/${project.id}/${path}`} className={({ isActive }) => `tab${isActive ? " active" : ""}`}>
                {label}
              </NavLink>
            ))}
          </nav>
          <Routes>
            <Route index element={<Navigate to="selecao" replace />} />
            <Route path="selecao" element={<SelectionTab project={project} onMembersChanged={reload} />} />
            <Route path="decisoes" element={<DecisionsTab project={project} />} />
            <Route path="workflow" element={<WorkflowTab project={project} />} />
            <Route path="rotina" element={<RoutineTab project={project} />} />
            <Route path="dashboard" element={<DashboardTab project={project} />} />
            <Route path="chat" element={<ChatTab project={project} />} />
            <Route path="config" element={<ProjectSettings project={project} onSaved={reload} />} />
          </Routes>
        </>
      )}
    </div>
  );
}
