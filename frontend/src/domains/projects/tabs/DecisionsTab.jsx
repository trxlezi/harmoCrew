import React, { useState } from "react";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import StatusPill from "../../../components/ui/StatusPill";
import EmptyState from "../../../components/ui/EmptyState";
import LoadingState from "../../../components/ui/LoadingState";
import { useAuth } from "../../../context/AuthContext";
import api, { errorMessage, mediaUrl } from "../../../services/api";
import useLoader from "../../../utils/useLoader";
import { FILE_CATEGORY, formatBytes, formatDate, formatDateTime } from "../../../utils/labels";

/*
 * Funcionalidade 2 - Registro de decisoes e versionamento de arquivos.
 * Cada upload vira uma versao (autor, data, hash) com link imutavel; enquetes
 * escolhem a versao oficial, que fica travada; tudo vai para a auditoria.
 */
export default function DecisionsTab({ project }) {
  const [feedback, setFeedback] = useState("");
  const { data, loading, error, reload } = useLoader(async () => {
    const [files, polls, decisions, audit] = await Promise.all([
      api.files.list(project.id),
      api.polls.list(project.id),
      api.decisions.list(project.id),
      api.files.audit(project.id),
    ]);
    return { files, polls, decisions, audit };
  }, [project.id]);

  const act = async (fn, message) => {
    try {
      await fn();
      setFeedback(message);
      reload();
    } catch (err) {
      setFeedback(errorMessage(err));
    }
  };

  if (loading) return <LoadingState title="Carregando arquivos e decisões" />;
  if (error) return <div className="form-error">{error}</div>;

  return (
    <div className="page-stack">
      {feedback ? <div className="inline-feedback">{feedback}</div> : null}
      <UploadForm project={project} onDone={(name) => { setFeedback(`"${name}" enviado como v1.`); reload(); }} />

      <div className="two-columns">
        <section>
          <h2 className="block-title">Arquivos e versões</h2>
          {data.files.length === 0 ? (
            <EmptyState title="Nenhum arquivo" description="Envie guias de áudio, arranjos e PDFs." />
          ) : (
            <div className="card-stack">
              {data.files.map((file) => <FileCard key={file.id} file={file} project={project} act={act} />)}
            </div>
          )}
        </section>

        <section>
          <h2 className="block-title">Enquetes</h2>
          <PollForm files={data.files} project={project} act={act} />
          <div className="card-stack">
            {data.polls.map((poll) => <PollCard key={poll.id} poll={poll} act={act} />)}
          </div>

          <h2 className="block-title">Decisões registradas</h2>
          <DecisionForm project={project} act={act} />
          {data.decisions.length === 0 ? (
            <p className="muted">Registre uma decisão acima ou encerre uma enquete para registrá-la automaticamente.</p>
          ) : (
            <ul className="timeline-list">
              {data.decisions.map((decision) => (
                <li key={decision.id}>
                  <strong>{decision.title}</strong>
                  <span className="muted small"> · {formatDate(decision.decidedAt)} · {decision.decidedByArtistName || "banda"}</span>
                  {decision.status === "CANCELED" ? <> <StatusPill tone="danger">cancelada</StatusPill></> : null}
                  {decision.status === "REVIEWED" ? <> <StatusPill tone="success">revisada</StatusPill></> : null}
                  {decision.description ? <p className="muted small">{decision.description}</p> : null}
                  {decision.impact ? <p className="small">Impacto: {decision.impact}</p> : null}
                  {decision.status === "REGISTERED" ? (
                    <div className="button-row">
                      <button type="button" className="ghost-button" onClick={() => act(() => api.decisions.updateStatus(decision.id, "REVIEWED"), "Decisão marcada como revisada.")}>Marcar revisada</button>
                      <button type="button" className="ghost-button" onClick={() => act(() => api.decisions.updateStatus(decision.id, "CANCELED"), "Decisão cancelada.")}>Cancelar</button>
                    </div>
                  ) : null}
                </li>
              ))}
            </ul>
          )}

          <h2 className="block-title">Log de auditoria</h2>
          <ul className="timeline-list audit">
            {data.audit.slice(0, 15).map((entry) => (
              <li key={entry.id}>
                <span className="muted small">{formatDateTime(entry.createdAt)} · {entry.actorName || "sistema"}</span>
                <p>{entry.details}</p>
              </li>
            ))}
          </ul>
        </section>
      </div>
    </div>
  );
}

function UploadForm({ project, onDone }) {
  const [form, setForm] = useState({ file: null, name: "", category: "AUDIO_GUIDE", description: "" });
  const [error, setError] = useState("");
  const [key, setKey] = useState(0);

  async function submit(event) {
    event.preventDefault();
    if (!form.file) return setError("Escolha um arquivo.");
    try {
      const created = await api.files.create(project.id, form.file, {
        name: form.name, category: form.category, description: form.description,
      });
      setForm({ file: null, name: "", category: "AUDIO_GUIDE", description: "" });
      setKey((k) => k + 1);
      setError("");
      onDone(created.name);
    } catch (err) {
      setError(errorMessage(err, "Falha no upload."));
    }
  }

  return (
    <SurfaceCard>
      <form className="filter-bar" onSubmit={submit}>
        <input key={key} type="file" onChange={(e) => setForm({ ...form, file: e.target.files[0] })} />
        <input placeholder="Nome (ex.: Arranjo Samba)" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
        <select value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })}>
          {Object.entries(FILE_CATEGORY).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
        </select>
        <button type="submit" className="primary-button">Enviar arquivo</button>
      </form>
      {error ? <div className="form-error">{error}</div> : null}
    </SurfaceCard>
  );
}

function FileCard({ file, act }) {
  const [expanded, setExpanded] = useState(false);
  const [note, setNote] = useState("");
  const [upload, setUpload] = useState(null);
  const current = file.currentVersion;

  return (
    <SurfaceCard>
      <div className="row-between">
        <div>
          <strong>{file.name}</strong>
          <p className="muted small">{FILE_CATEGORY[file.category]} · {file.versions.length} versão(ões)</p>
        </div>
        {file.locked ? <StatusPill tone="success">🔒 Oficial: v{file.lockedVersionNumber}</StatusPill> : <StatusPill tone="neutral">Em revisão</StatusPill>}
      </div>
      {current ? (
        <p className="small">
          Vigente: <a href={mediaUrl(current.url)} target="_blank" rel="noreferrer">v{current.versionNumber} — {current.originalFilename}</a>
          <span className="muted"> · {current.uploadedByName} · {formatDateTime(current.uploadedAt)}</span>
        </p>
      ) : null}

      {file.locked ? (
        <button type="button" className="ghost-button" onClick={() => {
          const reason = window.prompt("Motivo para destravar a versão decidida:");
          if (reason) act(() => api.files.unlock(file.id, reason), "Arquivo destravado (registrado na auditoria).");
        }}>Destravar</button>
      ) : (
        <form className="filter-bar" onSubmit={(e) => {
          e.preventDefault();
          if (upload) act(() => api.files.uploadVersion(file.id, upload, note), `Nova versão de "${file.name}" enviada. A banda foi notificada.`);
        }}>
          <input type="file" onChange={(e) => setUpload(e.target.files[0])} />
          <input placeholder="O que mudou?" value={note} onChange={(e) => setNote(e.target.value)} />
          <button type="submit" className="secondary-button">Nova versão</button>
        </form>
      )}

      <button type="button" className="link-button" onClick={() => setExpanded((v) => !v)}>
        {expanded ? "Ocultar histórico" : "Ver todas as versões"}
      </button>
      {expanded ? (
        <table className="data-table">
          <thead><tr><th>Versão</th><th>Autor</th><th>Data</th><th>Nota</th><th>SHA-256</th></tr></thead>
          <tbody>
            {file.versions.map((version) => (
              <tr key={version.id} className={version.decided ? "row-decided" : ""}>
                <td><a href={mediaUrl(version.url)} target="_blank" rel="noreferrer">v{version.versionNumber}</a> <span className="muted small">{formatBytes(version.sizeBytes)}</span></td>
                <td>{version.uploadedByName || "—"}</td>
                <td>{formatDateTime(version.uploadedAt)}</td>
                <td>{version.note || "—"}</td>
                <td><code title={version.sha256}>{version.sha256.slice(0, 10)}…</code></td>
              </tr>
            ))}
          </tbody>
        </table>
      ) : null}
    </SurfaceCard>
  );
}

function PollForm({ files, project, act }) {
  const [fileId, setFileId] = useState("");
  const [question, setQuestion] = useState("");
  const candidates = files.filter((file) => !file.locked && file.versions.length > 1);

  return (
    <SurfaceCard>
      <form className="stack-sm" onSubmit={(e) => {
        e.preventDefault();
        const file = files.find((f) => String(f.id) === fileId);
        if (!file) return;
        act(() => api.polls.create(project.id, {
          question: question || `Qual versão de "${file.name}" usamos?`,
          options: file.versions.map((v) => ({ label: `v${v.versionNumber}${v.note ? ` — ${v.note}` : ""}`, fileVersionId: v.id })),
        }), "Enquete aberta. Os membros foram notificados.");
        setQuestion("");
      }}>
        <span className="muted small">Abrir enquete para decidir a versão oficial (arquivos com 2+ versões)</span>
        <select value={fileId} onChange={(e) => setFileId(e.target.value)}>
          <option value="">Escolha o arquivo…</option>
          {candidates.map((file) => <option key={file.id} value={file.id}>{file.name} ({file.versions.length} versões)</option>)}
        </select>
        <input placeholder="Pergunta (opcional)" value={question} onChange={(e) => setQuestion(e.target.value)} />
        <button type="submit" className="secondary-button" disabled={!fileId}>Abrir enquete</button>
      </form>
    </SurfaceCard>
  );
}

function PollCard({ poll, act }) {
  const open = poll.status === "OPEN";
  const total = poll.options.reduce((sum, option) => sum + option.voters.length, 0) || 1;
  return (
    <SurfaceCard>
      <div className="row-between">
        <strong>{poll.question}</strong>
        <StatusPill tone={open ? "accent" : "success"}>{open ? "Aberta" : "Encerrada"}</StatusPill>
      </div>
      {poll.options.map((option) => (
        <div key={option.id} className={`poll-option${poll.winningOptionId === option.id ? " winner" : ""}`}>
          <div className="row-between">
            <span>{option.label}</span>
            <span className="muted small">{option.voters.length} voto(s)</span>
          </div>
          <div className="bar"><div className="bar-fill" style={{ width: `${(option.voters.length / total) * 100}%` }} /></div>
          {option.voters.length ? <p className="muted small">{option.voters.join(", ")}</p> : null}
          {open ? (
            <button type="button" className="ghost-button" onClick={() => act(() => api.polls.vote(poll.id, option.id), "Voto registrado.")}>Votar</button>
          ) : null}
        </div>
      ))}
      {open ? (
        <button type="button" className="primary-button" onClick={() => act(() => api.polls.close(poll.id), "Enquete encerrada: decisão registrada e versão travada.")}>
          Encerrar e decidir
        </button>
      ) : null}
    </SurfaceCard>
  );
}

function DecisionForm({ project, act }) {
  const { user } = useAuth();
  const empty = { title: "", description: "", impact: "", decidedByArtistId: String(user.artistId) };
  const [form, setForm] = useState(empty);
  const [open, setOpen] = useState(false);
  if (!open) {
    return <button type="button" className="secondary-button" onClick={() => setOpen(true)}>Registrar decisão</button>;
  }
  return (
    <SurfaceCard>
      <form className="stack-sm" onSubmit={(e) => {
        e.preventDefault();
        act(() => api.decisions.create(project.id, {
          ...form,
          decidedByArtistId: Number(form.decidedByArtistId),
          decidedAt: new Date().toISOString().slice(0, 10),
        }), `Decisão "${form.title}" registrada.`);
        setForm(empty);
        setOpen(false);
      }}>
        <input required placeholder="O que foi decidido? (ex.: Tom da música em Ré)" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
        <textarea rows={2} placeholder="Contexto / justificativa" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
        <input placeholder="Impacto (ex.: refazer guia de voz)" value={form.impact} onChange={(e) => setForm({ ...form, impact: e.target.value })} />
        <select value={form.decidedByArtistId} onChange={(e) => setForm({ ...form, decidedByArtistId: e.target.value })}>
          {project.artists.map((a) => <option key={a.id} value={a.id}>Decidido por {a.stageName}</option>)}
        </select>
        <div className="button-row">
          <button type="submit" className="primary-button">Salvar decisão</button>
          <button type="button" className="ghost-button" onClick={() => setOpen(false)}>Cancelar</button>
        </div>
      </form>
    </SurfaceCard>
  );
}
