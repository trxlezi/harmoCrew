import React from "react";
import SectionHeader from "../../../components/ui/SectionHeader";
import LoadingState from "../../../components/ui/LoadingState";
import api from "../../../services/api";
import useLoader from "../../../utils/useLoader";
import DashboardView from "../components/DashboardView";

// Dashboard do coletivo: metricas somadas de todos os projetos do usuario.
export default function DashboardPage() {
  const { data, loading, error } = useLoader(() => api.insights.collective(), []);
  return (
    <div className="page-stack">
      <SectionHeader
        eyebrow="Painel"
        title="Performance do seu coletivo"
        subtitle="Conclusão, pontualidade, assiduidade e andamento de todos os projetos em que você participa."
      />
      {loading ? <LoadingState title="Calculando métricas" /> : null}
      {error ? <div className="form-error">{error}</div> : null}
      {data ? <DashboardView data={data} showProjects /> : null}
    </div>
  );
}
