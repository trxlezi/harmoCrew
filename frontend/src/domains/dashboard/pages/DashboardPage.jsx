import React, { useEffect, useState } from "react";
import EmptyState from "../../../components/ui/EmptyState";
import LoadingState from "../../../components/ui/LoadingState";
import SectionHeader from "../../../components/ui/SectionHeader";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import api from "../../../services/api";
import { capitalizeName } from "../../../utils/formatters";
import SummaryCard from "../components/SummaryCard";

export default function DashboardPage() {
  const [summary, setSummary] = useState(null);
  const [status, setStatus] = useState("loading");
  const [feedbackMessage, setFeedbackMessage] = useState("");

  async function loadSummary() {
    setStatus("loading");
    try {
      const response = await api.dashboard.summary();
      setSummary(response.data.data);
      setStatus("ready");
      setFeedbackMessage("");
    } catch (error) {
      setSummary({ totals: {}, recent_candidacies: [], received_candidacies: [], recent_messages: [] });
      setStatus("error");
      setFeedbackMessage(
        error?.response?.data?.error?.message ||
          "O resumo do painel nao foi carregado."
      );
    }
  }

  useEffect(() => {
    loadSummary();
  }, []);

  async function handleCandidacyAction(candidacyId, action) {
    try {
      if (action === "aceitar") {
        await api.candidacies.accept(candidacyId);
      } else {
        await api.candidacies.reject(candidacyId);
      }
      await loadSummary();
      setFeedbackMessage(
        action === "aceitar"
          ? "Candidatura aceita com sucesso."
          : "Candidatura rejeitada com sucesso."
      );
    } catch (error) {
      setFeedbackMessage(
        error?.response?.data?.error?.message ||
          "Nao foi possivel atualizar a candidatura."
      );
    }
  }

  return (
    <div className="page-stack">
      <SectionHeader
        eyebrow="Painel"
        title="Visao de negocio para a sua atividade musical"
        subtitle="Acompanhe candidaturas, oportunidades abertas e conversas recentes sem se perder no fluxo."
      />

      {status === "loading" ? (
        <LoadingState
          title="Montando seu painel"
          description="Estamos consolidando candidaturas, mensagens e oportunidades."
        />
      ) : null}

      {status === "error" ? (
        <EmptyState
          title="Nao foi possivel abrir o painel"
          description={feedbackMessage}
          action={
            <button type="button" className="secondary-button" onClick={loadSummary}>
              Recarregar painel
            </button>
          }
        />
      ) : null}

      {feedbackMessage && status !== "error" ? (
        <div className="inline-feedback">{feedbackMessage}</div>
      ) : null}

      <div className="summary-grid">
        <SummaryCard
          label="Candidaturas recebidas"
          value={summary?.totals?.received ?? 0}
          detail="Interacoes de talentos interessados nos seus projetos."
        />
        <SummaryCard
          label="Candidaturas enviadas"
          value={summary?.totals?.sent ?? 0}
          detail="Projetos aos quais voce decidiu se conectar."
        />
        <SummaryCard
          label="Oportunidades abertas"
          value={summary?.totals?.open_opportunities ?? 0}
          detail="Projetos ativos aguardando novas colaboracoes."
        />
      </div>

      <SurfaceCard>
        <SectionHeader
          eyebrow="Atividade recente"
          title="O que pede sua atencao agora"
          subtitle="Uma leitura rapida das ultimas candidaturas e mensagens."
        />

        {summary?.recent_candidacies?.length ? (
          <div className="mini-list">
            {summary.recent_candidacies.map((entry) => (
              <div key={entry.id || entry.candidatura_id} className="list-row-button list-row-button--static">
                <strong>{entry.title || entry.post_titulo || "Candidatura"}</strong>
                <span>{entry.status || entry.status_candidatura}</span>
              </div>
            ))}
          </div>
        ) : (
          <EmptyState
            title="Sem movimentacoes recentes"
            description="Quando novas candidaturas chegarem, elas aparecerao aqui."
          />
        )}
      </SurfaceCard>

      <SurfaceCard>
        <SectionHeader
          eyebrow="Curadoria"
          title="Candidaturas recebidas"
          subtitle="Aqui voce aprova ou rejeita quem se inscreveu nos seus projetos."
        />

        {summary?.received_candidacies?.length ? (
          <div className="card-stack">
            {summary.received_candidacies.map((entry) => (
              <div key={entry.candidatura_id} className="approval-card">
                <div className="approval-copy">
                  <strong>{capitalizeName(entry.candidato_nome)}</strong>
                  <span>{entry.post_titulo}</span>
                  <small>{entry.data_candidatura}</small>
                </div>
                <div className="approval-actions">
                  <span className={`status-pill status-pill--${entry.status_candidatura === "pendente" ? "warning" : entry.status_candidatura === "aceito" ? "success" : "danger"}`}>
                    {entry.status_candidatura}
                  </span>
                  <button
                    type="button"
                    className="secondary-button"
                    onClick={() => handleCandidacyAction(entry.candidatura_id, "aceitar")}
                    disabled={entry.status_candidatura === "aceito"}
                  >
                    Aceitar
                  </button>
                  <button
                    type="button"
                    className="ghost-button"
                    onClick={() => handleCandidacyAction(entry.candidatura_id, "rejeitar")}
                    disabled={entry.status_candidatura === "rejeitado"}
                  >
                    Rejeitar
                  </button>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <EmptyState
            title="Nenhuma candidatura recebida"
            description="Quando alguem se inscrever em um projeto seu, a aprovacao aparece aqui."
          />
        )}
      </SurfaceCard>
    </div>
  );
}
