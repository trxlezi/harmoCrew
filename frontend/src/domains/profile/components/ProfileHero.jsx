import React from "react";
import StatusPill from "../../../components/ui/StatusPill";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import { capitalizeName } from "../../../utils/formatters";

export default function ProfileHero({
  profile,
  isCurrentUser,
  isFollowing,
  onFollowToggle,
}) {
  return (
    <SurfaceCard className="profile-hero">
      <div className="profile-hero-main">
        <div className="profile-avatar">
          {profile.profile_pic_url ? (
            <img src={profile.profile_pic_url} alt="" />
          ) : (
            profile.nome?.slice(0, 1).toUpperCase() ?? "H"
          )}
        </div>
        <div className="profile-copy">
          <StatusPill tone="accent">
            {isCurrentUser ? "Seu perfil" : "Talento da comunidade"}
          </StatusPill>
          <h1>{capitalizeName(profile.nome)}</h1>
          <p>{profile.descricao || "Perfil em construcao. Atualize sua proposta artistica para destacar melhor sua identidade."}</p>
        </div>
      </div>

      {!isCurrentUser ? (
        <button type="button" className="secondary-button" onClick={onFollowToggle}>
          {isFollowing ? "Deixar de seguir" : "Seguir perfil"}
        </button>
      ) : null}
    </SurfaceCard>
  );
}
