import React, { useEffect, useState } from "react";
import SectionHeader from "../../../components/ui/SectionHeader";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import LoadingState from "../../../components/ui/LoadingState";
import { useAuth } from "../../../context/AuthContext";
import api, { errorMessage, mediaUrl } from "../../../services/api";
import { splitList } from "../../../utils/labels";
import { Field } from "../../projects/pages/ProjectsPage";

/*
 * Perfil musical usado pelo matching: estilos, instrumentos, influencias,
 * cidade e audio de apresentacao.
 */
export default function ProfilePage() {
  const { user, updateUser } = useAuth();
  const [artist, setArtist] = useState(null);
  const [form, setForm] = useState(null);
  const [feedback, setFeedback] = useState("");

  useEffect(() => {
    api.artists.get(user.artistId).then((data) => {
      setArtist(data);
      setForm({
        stageName: data.stageName,
        mainSpecialty: data.mainSpecialty,
        availability: data.availability,
        city: data.city || "",
        bio: data.bio || "",
        musicalStyles: data.musicalStyles.join(", "),
        instruments: data.instruments.join(", "),
        influences: data.influences.join(", "),
      });
    });
  }, [user.artistId]);

  if (!form) return <LoadingState title="Carregando perfil" />;

  async function save(event) {
    event.preventDefault();
    try {
      const saved = await api.artists.update(user.artistId, {
        ...form,
        musicalStyles: splitList(form.musicalStyles),
        instruments: splitList(form.instruments),
        influences: splitList(form.influences),
        audioUrl: artist.audioUrl ? artist.audioUrl.split("?")[0] : null,
      });
      setArtist(saved);
      updateUser({ name: saved.stageName });
      setFeedback("Perfil salvo. Ele já conta no ranking de compatibilidade.");
    } catch (err) {
      setFeedback(errorMessage(err, "Não foi possível salvar."));
    }
  }

  async function uploadAudio(file) {
    if (!file) return;
    try {
      setArtist(await api.artists.uploadAudio(user.artistId, file));
      setFeedback("Áudio de apresentação atualizado.");
    } catch (err) {
      setFeedback(errorMessage(err, "Falha no upload do áudio."));
    }
  }

  const set = (key) => (value) => setForm({ ...form, [key]: value });

  return (
    <div className="page-stack">
      <SectionHeader eyebrow="Perfil musical" title={artist.stageName} subtitle="Quanto mais completo, melhor o seu matching com as vagas." />
      {feedback ? <div className="inline-feedback">{feedback}</div> : null}
      <div className="two-columns">
        <SurfaceCard>
          <form className="form-grid" onSubmit={save}>
            <Field label="Nome artístico" value={form.stageName} onChange={set("stageName")} required />
            <Field label="Especialidade principal" value={form.mainSpecialty} onChange={set("mainSpecialty")} required />
            <Field label="Cidade" value={form.city} onChange={set("city")} />
            <Field label="Disponibilidade" value={form.availability} onChange={set("availability")} required />
            <Field label="Estilos (vírgula)" value={form.musicalStyles} onChange={set("musicalStyles")} placeholder="MPB, Samba Rock" />
            <Field label="Instrumentos (vírgula)" value={form.instruments} onChange={set("instruments")} placeholder="Baixo, Violão" />
            <label className="field form-grid-wide">
              <span>Influências (vírgula)</span>
              <input value={form.influences} onChange={(e) => set("influences")(e.target.value)} placeholder="Jorge Ben, Tim Maia" />
            </label>
            <label className="field form-grid-wide">
              <span>Bio</span>
              <textarea rows={3} value={form.bio} onChange={(e) => set("bio")(e.target.value)} />
            </label>
            <button type="submit" className="primary-button">Salvar perfil</button>
          </form>
        </SurfaceCard>
        <SurfaceCard>
          <h3>Áudio de apresentação</h3>
          <p className="muted small">Os recrutadores ouvem este áudio no ranking de candidatos.</p>
          {artist.audioUrl ? (
            <>
              <audio controls src={mediaUrl(artist.audioUrl)} className="audio" />
              <p className="muted small">{artist.audioFilename}</p>
            </>
          ) : <p className="muted">Nenhum áudio enviado.</p>}
          <input type="file" accept="audio/*" onChange={(e) => uploadAudio(e.target.files[0])} />
        </SurfaceCard>
      </div>
    </div>
  );
}
