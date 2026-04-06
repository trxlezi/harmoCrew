import React from "react";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import StatusPill from "../../../components/ui/StatusPill";
import { capitalizeName } from "../../../utils/formatters";

export default function OpportunityCard({ opportunity, onApply }) {
  return (
    <SurfaceCard className="opportunity-card">
      <div className="opportunity-card-top">
        <div>
          <StatusPill tone={opportunity.status_tone || "success"}>
            {opportunity.status_label || "Aberta"}
          </StatusPill>
          <h3>{opportunity.titulo}</h3>
        </div>
          <span>{capitalizeName(opportunity.nome)}</span>
        </div>
      <p>{opportunity.texto}</p>
      <div className="feed-card-footer">
        <span>{opportunity.created_label}</span>
        <button type="button" className="secondary-button" onClick={() => onApply(opportunity.id)}>
          Quero participar
        </button>
      </div>
    </SurfaceCard>
  );
}
