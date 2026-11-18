import React, { useState } from "react";

export default function PostComposer({ onSubmit }) {
  const [formData, setFormData] = useState({
    titulo: "",
    texto: "",
    audio_url: "",
  });

  async function handleSubmit(event) {
    event.preventDefault();
    if (!formData.titulo.trim() || !formData.texto.trim()) {
      return;
    }

    await onSubmit({
      titulo: formData.titulo.trim(),
      texto: formData.texto.trim(),
      audio_url: formData.audio_url.trim(),
    });

    setFormData({ titulo: "", texto: "", audio_url: "" });
  }

  return (
    <form className="composer-card" onSubmit={handleSubmit}>
      <label className="field">
        <span>Titulo do projeto</span>
        <input
          type="text"
          value={formData.titulo}
          onChange={(event) =>
            setFormData((current) => ({ ...current, titulo: event.target.value }))
          }
          placeholder="Ex: Procuro vocalista para single indie pop"
        />
      </label>
      <label className="field">
        <span>Descricao</span>
        <textarea
          value={formData.texto}
          onChange={(event) =>
            setFormData((current) => ({ ...current, texto: event.target.value }))
          }
          placeholder="Explique o som, o momento do projeto e o perfil procurado."
          rows={4}
        />
      </label>
      <label className="field">
        <span>Link de audio</span>
        <input
          type="url"
          value={formData.audio_url}
          onChange={(event) =>
            setFormData((current) => ({ ...current, audio_url: event.target.value }))
          }
          placeholder="https://..."
        />
      </label>
      <button type="submit" className="primary-button">
        Publicar oportunidade
      </button>
    </form>
  );
}
