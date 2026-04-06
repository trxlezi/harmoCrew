import React, { useEffect, useState } from "react";
import EmptyState from "../../../components/ui/EmptyState";
import LoadingState from "../../../components/ui/LoadingState";
import SectionHeader from "../../../components/ui/SectionHeader";
import api from "../../../services/api";
import OpportunityCard from "../components/OpportunityCard";

export default function OpportunitiesPage() {
  const [opportunities, setOpportunities] = useState([]);
  const [status, setStatus] = useState("loading");
  const [feedbackMessage, setFeedbackMessage] = useState("");

  async function loadOpportunities() {
    setStatus("loading");
    setFeedbackMessage("");
    try {
      const response = await api.opportunities.list();
      setOpportunities(response.data.data.opportunities || []);
      setStatus("ready");
    } catch (error) {
      setFeedbackMessage(
        error?.response?.data?.error?.message ||
          "Nao foi possivel obter a lista de oportunidades."
      );
      setStatus("error");
    }
  }

  useEffect(() => {
    loadOpportunities();
  }, []);

  async function handleApply(opportunityId) {
    try {
      setFeedbackMessage("");
      await api.opportunities.apply(opportunityId);
      await loadOpportunities();
      setFeedbackMessage("Candidatura registrada com sucesso.");
    } catch (error) {
      setFeedbackMessage(
        error?.response?.data?.error?.message ||
          "Nao foi possivel registrar sua candidatura."
      );
    }
  }

  return (
    <div className="page-stack">
      <SectionHeader
        eyebrow="Oportunidades"
        title="Pipeline musical em andamento"
        subtitle="Acompanhe oportunidades abertas com linguagem mais clara, tom profissional e acoes diretas."
      />

      {feedbackMessage ? <div className="inline-feedback">{feedbackMessage}</div> : null}

      {status === "loading" ? (
        <LoadingState
          title="Buscando oportunidades"
          description="Estamos organizando as chamadas abertas mais recentes."
        />
      ) : null}

      {status === "error" ? (
        <EmptyState
          title="Falha ao carregar oportunidades"
          description={feedbackMessage || "Revise a API ou tente novamente em instantes."}
          action={
            <button type="button" className="secondary-button" onClick={loadOpportunities}>
              Recarregar
            </button>
          }
        />
      ) : null}

      {status === "ready" && opportunities.length === 0 ? (
        <EmptyState
          title="Nenhuma oportunidade encontrada"
          description="Publique sua primeira chamada ou volte mais tarde para descobrir novas vagas."
        />
      ) : null}

      <div className="card-stack">
        {opportunities.map((opportunity) => (
          <OpportunityCard
            key={opportunity.id}
            opportunity={{
              ...opportunity,
              created_label: new Date(
                opportunity.created_at || opportunity.data || Date.now()
              ).toLocaleDateString("pt-BR"),
            }}
            onApply={handleApply}
          />
        ))}
      </div>
    </div>
  );
}
