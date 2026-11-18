import React from "react";
import LoadingState from "../../../components/ui/LoadingState";
import api from "../../../services/api";
import useLoader from "../../../utils/useLoader";
import DashboardView from "../../dashboard/components/DashboardView";

// Funcionalidade 4 - dashboard do projeto.
export default function DashboardTab({ project }) {
  const { data, loading, error } = useLoader(() => api.insights.dashboard(project.id), [project.id]);
  if (loading) return <LoadingState title="Calculando métricas" />;
  if (error) return <div className="form-error">{error}</div>;
  return <DashboardView data={data} />;
}
