import React, { useState } from "react";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import LoadingState from "../../../components/ui/LoadingState";
import { useAuth } from "../../../context/AuthContext";
import api, { errorMessage } from "../../../services/api";
import useLoader from "../../../utils/useLoader";
import { formatDateTime } from "../../../utils/labels";

export default function ChatTab({ project }) {
  const { user } = useAuth();
  const [text, setText] = useState("");
  const [error, setError] = useState("");
  const { data, loading, reload } = useLoader(() => api.messages.list(project.id), [project.id]);

  async function send(event) {
    event.preventDefault();
    if (!text.trim()) return;
    try {
      await api.messages.send(project.id, user.artistId, text.trim());
      setText("");
      reload();
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  if (loading) return <LoadingState title="Carregando mensagens" />;
  const messages = [...(data || [])].sort((a, b) => new Date(a.sentAt) - new Date(b.sentAt));

  return (
    <SurfaceCard className="conversation-panel">
      <div className="message-list">
        {messages.length === 0 ? <p className="muted">Nenhuma mensagem ainda.</p> : null}
        {messages.map((message) => (
          <div key={message.id} className={`message-bubble${message.senderArtistId === user.artistId ? " message-bubble--self" : ""}`}>
            <strong className="small">{message.senderArtistName}</strong>
            <p>{message.content}</p>
            <span className="muted small">{formatDateTime(message.sentAt)}</span>
          </div>
        ))}
      </div>
      <form className="conversation-form" onSubmit={send}>
        <input value={text} onChange={(e) => setText(e.target.value)} placeholder="Escreva para a banda…" />
        <button type="submit" className="primary-button">Enviar</button>
      </form>
      {error ? <div className="form-error">{error}</div> : null}
    </SurfaceCard>
  );
}
