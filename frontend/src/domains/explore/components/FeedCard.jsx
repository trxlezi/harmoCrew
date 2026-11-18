import React from "react";
import { Link } from "react-router-dom";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import StatusPill from "../../../components/ui/StatusPill";
import { capitalizeName } from "../../../utils/formatters";

export default function FeedCard({ item, onApply }) {
  return (
    <SurfaceCard className="feed-card">
      <div className="feed-card-top">
        <div>
          <StatusPill tone="accent">{item.type_label || "Projeto"}</StatusPill>
          <h3>{item.titulo}</h3>
        </div>
          <Link to={`/perfil/${item.user_id}`}>{capitalizeName(item.nome)}</Link>
        </div>
      <p>{item.texto}</p>
      {item.audio_url ? (
        <audio controls className="audio-player" src={item.audio_url}>
          Seu navegador nao suporta audio.
        </audio>
      ) : null}
      <div className="feed-card-footer">
        <span>{item.created_label}</span>
        {onApply ? (
          <button type="button" className="secondary-button" onClick={() => onApply(item.id)}>
            Candidatar-se
          </button>
        ) : null}
      </div>
    </SurfaceCard>
  );
}
