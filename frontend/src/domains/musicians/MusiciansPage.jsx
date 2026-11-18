import React, { useState } from "react";
import SectionHeader from "../../components/ui/SectionHeader";
import SurfaceCard from "../../components/ui/SurfaceCard";
import LoadingState from "../../components/ui/LoadingState";
import EmptyState from "../../components/ui/EmptyState";
import api, { errorMessage, mediaUrl } from "../../services/api";
import { useAuth } from "../../context/AuthContext";
import useLoader from "../../utils/useLoader";

// Busca de musicos por estilo, instrumento e cidade (com audio de apresentacao).
export default function MusiciansPage() {
  const [filters, setFilters] = useState({ style: "", instrument: "", city: "" });
  const [applied, setApplied] = useState({});
  const { user } = useAuth();
  const [feedback, setFeedback] = useState("");
  const { data, loading, reload } = useLoader(async () => {
    const [artists, projects] = await Promise.all([api.artists.list(applied), api.projects.list()]);
    const mine = projects.filter((p) => p.artists.some((a) => a.id === user.artistId));
    return { artists, mine };
  }, [applied, user.artistId]);

  return (
    <div className="page-stack">
      <SectionHeader eyebrow="Músicos" title="Encontre talentos" subtitle="Filtre por estilo, instrumento e cidade e ouça o áudio de apresentação." />
      <SurfaceCard>
        <form className="filter-bar" onSubmit={(e) => {
          e.preventDefault();
          setApplied(Object.fromEntries(Object.entries(filters).filter(([, v]) => v)));
        }}>
          <input placeholder="Estilo" value={filters.style} onChange={(e) => setFilters({ ...filters, style: e.target.value })} />
          <input placeholder="Instrumento" value={filters.instrument} onChange={(e) => setFilters({ ...filters, instrument: e.target.value })} />
          <input placeholder="Cidade" value={filters.city} onChange={(e) => setFilters({ ...filters, city: e.target.value })} />
          <button type="submit" className="primary-button">Buscar</button>
        </form>
      </SurfaceCard>
      {feedback ? <div className="inline-feedback">{feedback}</div> : null}
      {loading ? <LoadingState /> : null}
      {data && data.artists.length === 0 ? <EmptyState title="Ninguém encontrado" description="Tente outros filtros." /> : null}
      <div className="card-grid">
        {(data?.artists || []).map((artist) => (
          <SurfaceCard key={artist.id}>
            <strong>{artist.stageName}</strong>
            <p className="muted small">{artist.mainSpecialty} · {artist.city || "cidade não informada"} · {artist.availability}</p>
            {artist.bio ? <p>{artist.bio}</p> : null}
            <div className="chip-row">
              {[...artist.musicalStyles, ...artist.instruments].map((tag) => <span key={tag} className="chip">{tag}</span>)}
            </div>
            {artist.influences.length ? <p className="muted small">Influências: {artist.influences.join(", ")}</p> : null}
            {artist.audioUrl ? <audio controls src={mediaUrl(artist.audioUrl)} className="audio" /> : null}
            {artist.id !== user.artistId ? (
              <Invite artist={artist} projects={data.mine} onDone={(msg) => { setFeedback(msg); reload(); }} />
            ) : <p className="muted small">Este é você.</p>}
          </SurfaceCard>
        ))}
      </div>
    </div>
  );
}

// Convidar o musico para um dos meus projetos (adiciona como integrante).
function Invite({ artist, projects, onDone }) {
  const options = projects.filter((p) => !p.artists.some((a) => a.id === artist.id));
  const [projectId, setProjectId] = useState("");
  if (options.length === 0) return null;
  return (
    <div className="filter-bar invite">
      <select value={projectId} onChange={(e) => setProjectId(e.target.value)}>
        <option value="">Convidar para projeto…</option>
        {options.map((p) => <option key={p.id} value={p.id}>{p.title}</option>)}
      </select>
      <button
        type="button"
        className="secondary-button"
        disabled={!projectId}
        onClick={async () => {
          try {
            await api.projects.addArtist(projectId, artist.id);
            onDone(`${artist.stageName} agora faz parte de "${options.find((p) => String(p.id) === projectId).title}".`);
          } catch (err) {
            onDone(errorMessage(err, "Não foi possível convidar."));
          }
        }}
      >
        Convidar
      </button>
    </div>
  );
}
