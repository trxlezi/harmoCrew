import React, { useEffect } from "react";
import { Link } from "react-router-dom";
import SectionHeader from "../../components/ui/SectionHeader";
import SurfaceCard from "../../components/ui/SurfaceCard";
import EmptyState from "../../components/ui/EmptyState";
import LoadingState from "../../components/ui/LoadingState";
import api from "../../services/api";
import useLoader from "../../utils/useLoader";
import { formatDateTime } from "../../utils/labels";
import { useAlerts } from "./AlertsContext";

const ICONS = {
  TASK_ASSIGNED: "📌",
  TASK_STATUS_CHANGED: "🔄",
  TASK_OVERDUE: "⏰",
  APPLICATION_STATUS_CHANGED: "📨",
  POLL_OPENED: "🗳️",
  POLL_CLOSED: "✅",
  FILE_VERSION_UPLOADED: "📁",
};

export default function AlertsPage() {
  const { version, setUnread } = useAlerts();
  const { data, loading, reload } = useLoader(() => api.notifications.list(), []);

  // Recarrega quando chega alerta novo pelo SSE.
  useEffect(() => {
    if (version) reload();
  }, [version, reload]);

  async function readAll() {
    await api.notifications.markAllRead();
    setUnread(0);
    reload();
  }

  async function readOne(notification) {
    if (notification.read) return;
    await api.notifications.markRead(notification.id);
    reload();
  }

  return (
    <div className="page-stack">
      <SectionHeader
        eyebrow="Alertas em tempo real"
        title="Prazos, mudanças e decisões"
        subtitle="Avisos de tarefas atribuídas, mudanças de status, atrasos, enquetes, novas versões e candidaturas."
        action={<button type="button" className="secondary-button" onClick={readAll}>Marcar todos como lidos</button>}
      />
      {loading ? <LoadingState /> : null}
      {data && data.length === 0 ? <EmptyState title="Nenhum alerta" description="Tudo em dia por aqui." /> : null}
      <div className="card-stack">
        {(data || []).map((n) => (
          <SurfaceCard key={n.id} className={`alert-card${n.read ? "" : " unread"}`}>
            <div className="row-between" onClick={() => readOne(n)} role="button" tabIndex={0} onKeyDown={() => readOne(n)}>
              <div>
                <strong>{ICONS[n.type] || "🔔"} {n.title}</strong>
                <p className="muted">{n.body}</p>
              </div>
              <div className="align-right">
                <span className="muted small">{formatDateTime(n.createdAt)}</span>
                {n.projectId ? <div><Link className="small" to={`/projetos/${n.projectId}`}>Abrir projeto</Link></div> : null}
              </div>
            </div>
          </SurfaceCard>
        ))}
      </div>
    </div>
  );
}
