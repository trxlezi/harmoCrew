import React from "react";
import SurfaceCard from "../../../components/ui/SurfaceCard";

export default function SummaryCard({ label, value, detail }) {
  return (
    <SurfaceCard className="summary-card">
      <span className="summary-label">{label}</span>
      <strong className="summary-value">{value}</strong>
      <p className="summary-detail">{detail}</p>
    </SurfaceCard>
  );
}
