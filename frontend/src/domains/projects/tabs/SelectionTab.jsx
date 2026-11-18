import React, { useState } from "react";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import StatusPill from "../../../components/ui/StatusPill";
import EmptyState from "../../../components/ui/EmptyState";
import LoadingState from "../../../components/ui/LoadingState";
import api, { errorMessage, mediaUrl } from "../../../services/api";
import useLoader from "../../../utils/useLoader";
import { APPLICATION_STATUS, CRITERIA } from "../../../utils/labels";

/*
 * Funcionalidade 1 - Correspondencia algoritmica de musicos.
 * Ranking por compatibilidade (estilo, instrumentos, influencias, cidade),
 * filtros, audio do perfil e gestao de candidaturas com status/feedback.
 */
export default function SelectionTab({ project, onMembersChanged }) {
  const [filters, setFilters] = useState({ style: "", instrument: "", city: "", minScore: "", appliedOnly: true });
  const [applied, setApplied] = useState(filters);
  const [feedback, setFeedback] = useState("");

  const { data, loading, error, reload } = useLoader(async () => {
    const params = {};
    ["style", "instrument", "city", "minScore"].forEach((key) => {
      if (applied[key]) params[key] = applied[key];
    });
    const [matches, applications] = await Promise.all([
      api.matching.matches(project.id, { ...params, appliedOnly: applied.appliedOnly }),
      api.matching.ranked(project.id, params),
    ]);
    return { matches, applications };
  }, [project.id, applied]);

  async function decide(application, status) {
    let note = "";
    if (status === "APPROVED") note = "Bem-vindo(a) à banda!";
    if (status === "REJECTED") {
      const answer = window.prompt("Feedback para o candidato (opcional):");
      if (answer === null) return; // cancelou: nao recusa
      note = answer;
    }
    try {
      await api.applications.updateStatus(application.id, { status, evaluationNote: note });
      setFeedback(`Candidatura de ${application.artistName}: ${APPLICATION_STATUS[status][0].toLowerCase()}. O candidato foi notificado.`);
      reload();
      if (status === "APPROVED") onMembersChanged();
    } catch (err) {
      setFeedback(errorMessage(err));
    }
  }

  return (
    <div className="page-stack">
      <SurfaceCard>
        <form
          className="filter-bar"
          onSubmit={(event) => {
            event.preventDefault();
            setApplied(filters);
          }}
        >
          <input placeholder="Estilo" value={filters.style} onChange={(e) => setFilters({ ...filters, style: e.target.value })} />
          <input placeholder="Instrumento" value={filters.instrument} onChange={(e) => setFilters({ ...filters, instrument: e.target.value })} />
          <input placeholder="Cidade" value={filters.city} onChange={(e) => setFilters({ ...filters, city: e.target.value })} />
          <input placeholder="Nota mín." type="number" min="0" max="100" value={filters.minScore} onChange={(e) => setFilters({ ...filters, minScore: e.target.value })} />
          <label className="toggle">
            <input type="checkbox" checked={filters.appliedOnly} onChange={(e) => setFilters({ ...filters, appliedOnly: e.target.checked })} />
            Só candidatos da vaga
          </label>
          <button type="submit" className="primary-button">Filtrar</button>
        </form>
      </SurfaceCard>

      {feedback ? <div className="inline-feedback">{feedback}</div> : null}
      {loading ? <LoadingState title="Calculando compatibilidade" /> : null}
      {error ? <div className="form-error">{error}</div> : null}

      {data ? (
        <div className="two-columns">
          <section>
            <h2 className="block-title">Ranking de compatibilidade</h2>
            {data.matches.length === 0 ? (
              <EmptyState title="Ninguém encontrado" description={applied.appliedOnly ? "Ainda não há candidatos para esta vaga (ou nenhum passa nos filtros)." : "Nenhum músico passa nos filtros."} />
            ) : (
              <div className="card-stack">
                {data.matches.map((match) => <MatchCard key={match.artistId} match={match} />)}
              </div>
            )}
          </section>

          <section>
            <h2 className="block-title">Candidaturas ({data.applications.length})</h2>
            {data.applications.length === 0 ? (
              <EmptyState title="Sem candidaturas" description="Divulgue a vaga para receber candidatos." />
            ) : (
              <div className="card-stack">
                {data.applications.map((application) => {
                  const [label, tone] = APPLICATION_STATUS[application.status];
                  const open = !["APPROVED", "REJECTED"].includes(application.status);
                  return (
                    <SurfaceCard key={application.id}>
                      <div className="row-between">
                        <strong>{application.artistName}</strong>
                        <StatusPill tone={tone}>{label}</StatusPill>
                      </div>
                      <p className="muted small">
                        {application.specialty} · {application.availability} · compatibilidade <b>{application.matchScore ?? 0}%</b>
                      </p>
                      <p>{application.message}</p>
                      {application.artistAudioUrl ? <audio controls src={mediaUrl(application.artistAudioUrl)} className="audio" /> : null}
                      {application.evaluationNote ? <p className="muted small">Feedback: {application.evaluationNote}</p> : null}
                      {open ? (
                        <div className="button-row">
                          {application.status === "PENDING" ? (
                            <button type="button" className="ghost-button" onClick={() => decide(application, "UNDER_REVIEW")}>Analisar</button>
                          ) : null}
                          {application.status !== "SHORTLISTED" ? (
                            <button type="button" className="ghost-button" onClick={() => decide(application, "SHORTLISTED")}>Pré-selecionar</button>
                          ) : null}
                          <button type="button" className="primary-button" onClick={() => decide(application, "APPROVED")}>Aprovar</button>
                          <button type="button" className="secondary-button" onClick={() => decide(application, "REJECTED")}>Recusar</button>
                        </div>
                      ) : null}
                    </SurfaceCard>
                  );
                })}
              </div>
            )}
          </section>
        </div>
      ) : null}
    </div>
  );
}

function MatchCard({ match }) {
  const tone = match.score >= 70 ? "success" : match.score >= 40 ? "warning" : "neutral";
  return (
    <SurfaceCard>
      <div className="row-between">
        <div>
          <strong>{match.stageName}</strong>
          <p className="muted small">{match.mainSpecialty} · {match.city || "cidade não informada"}</p>
        </div>
        <div className="score-badge" data-tone={tone}>{match.score}</div>
      </div>
      <div className="criteria">
        {match.breakdown.filter((c) => c.applied).map((criterion) => (
          <div key={criterion.criterion} className="criterion">
            <span>{CRITERIA[criterion.criterion]} <em>peso {criterion.weight}</em></span>
            <div className="bar"><div className="bar-fill" style={{ width: `${criterion.score}%` }} /></div>
          </div>
        ))}
      </div>
      <div className="chip-row">
        {[...match.musicalStyles, ...match.instruments].map((tag) => <span key={tag} className="chip">{tag}</span>)}
        {match.matchedInfluences.map((tag) => <span key={tag} className="chip chip--member">♪ {tag}</span>)}
      </div>
      {match.audioUrl ? <audio controls src={mediaUrl(match.audioUrl)} className="audio" /> : <p className="muted small">Sem áudio no perfil</p>}
      {match.applicationStatus ? (
        <p className="muted small">Candidatura: {APPLICATION_STATUS[match.applicationStatus][0]}</p>
      ) : null}
    </SurfaceCard>
  );
}
