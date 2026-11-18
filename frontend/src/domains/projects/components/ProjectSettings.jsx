import React, { useState } from "react";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import api, { errorMessage } from "../../../services/api";
import { splitList } from "../../../utils/labels";
import { Field } from "../pages/ProjectsPage";

const STATUSES = [["PLANNING", "Planejamento"], ["ACTIVE", "Ativo"], ["PAUSED", "Pausado"], ["FINISHED", "Finalizado"]];

// Editar dados da vaga/projeto e o status (planejamento, ativo, pausado, finalizado).
export default function ProjectSettings({ project, onSaved }) {
  const [form, setForm] = useState({
    title: project.title,
    description: project.description || "",
    musicalStyle: project.musicalStyle || "",
    location: project.location || "",
    startDate: project.startDate,
    status: project.status,
    needs: (project.needs || []).join(", "),
    desiredInfluences: (project.desiredInfluences || []).join(", "),
  });
  const [feedback, setFeedback] = useState("");
  const set = (key) => (value) => setForm({ ...form, [key]: value });

  async function save(event) {
    event.preventDefault();
    try {
      await api.projects.update(project.id, {
        ...form,
        needs: splitList(form.needs),
        desiredInfluences: splitList(form.desiredInfluences),
      });
      setFeedback("Projeto atualizado. O ranking de compatibilidade já usa os novos requisitos.");
      onSaved();
    } catch (err) {
      setFeedback(errorMessage(err, "Não foi possível salvar."));
    }
  }

  return (
    <div className="page-stack">
      {feedback ? <div className="inline-feedback">{feedback}</div> : null}
      <div className="two-columns">
        <SurfaceCard>
          <form className="form-grid" onSubmit={save}>
            <Field label="Título" value={form.title} onChange={set("title")} required />
            <label className="field">
              <span>Status</span>
              <select className="select" value={form.status} onChange={(e) => set("status")(e.target.value)}>
                {STATUSES.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
              </select>
            </label>
            <Field label="Estilo musical" value={form.musicalStyle} onChange={set("musicalStyle")} />
            <Field label="Cidade" value={form.location} onChange={set("location")} />
            <Field label="Início" type="date" value={form.startDate} onChange={set("startDate")} required />
            <Field label="Instrumentos procurados (vírgula)" value={form.needs} onChange={set("needs")} />
            <label className="field form-grid-wide">
              <span>Influências desejadas (vírgula)</span>
              <input value={form.desiredInfluences} onChange={(e) => set("desiredInfluences")(e.target.value)} />
            </label>
            <label className="field form-grid-wide">
              <span>Descrição</span>
              <textarea rows={3} value={form.description} onChange={(e) => set("description")(e.target.value)} />
            </label>
            <button type="submit" className="primary-button">Salvar projeto</button>
          </form>
        </SurfaceCard>
        <SurfaceCard>
          <h3>Integrantes ({project.artists.length})</h3>
          <ul className="mini-list-clean">
            {project.artists.map((artist) => (
              <li key={artist.id}>
                <strong>{artist.stageName}</strong>
                <span className="muted small"> · {artist.mainSpecialty}{artist.city ? ` · ${artist.city}` : ""}</span>
              </li>
            ))}
          </ul>
          <p className="muted small">
            Para adicionar alguém, aprove a candidatura na aba Seleção ou convide pela página Músicos.
          </p>
        </SurfaceCard>
      </div>
    </div>
  );
}
