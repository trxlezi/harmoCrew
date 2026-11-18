import React from "react";

export default function LoadingState({ title = "Carregando...", description }) {
  return (
    <div className="loading-state" role="status" aria-live="polite">
      <div className="loading-spinner" />
      <div>
        <h3>{title}</h3>
        {description ? <p>{description}</p> : null}
      </div>
    </div>
  );
}
