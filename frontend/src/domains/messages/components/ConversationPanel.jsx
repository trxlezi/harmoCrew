import React, { useState } from "react";
import { capitalizeName } from "../../../utils/formatters";

export default function ConversationPanel({
  activeContact,
  messages,
  onSendMessage,
}) {
  const [draft, setDraft] = useState("");

  async function handleSubmit(event) {
    event.preventDefault();
    if (!draft.trim() || !activeContact) {
      return;
    }

    await onSendMessage(draft.trim());
    setDraft("");
  }

  if (!activeContact) {
    return (
      <div className="conversation-empty">
        <h3>Escolha uma conversa</h3>
        <p>Selecione um contato para acompanhar o historico e enviar uma nova mensagem.</p>
      </div>
    );
  }

  return (
    <div className="conversation-panel">
      <div className="conversation-header">
        <strong>{capitalizeName(activeContact.nome)}</strong>
        <span>{activeContact.email}</span>
      </div>

      <div className="message-list">
        {messages.map((message) => (
          <div
            key={message.id}
            className={`message-bubble ${message.is_sender ? "message-bubble--self" : ""}`}
          >
            <p>{message.content}</p>
            <span>{message.timestamp}</span>
          </div>
        ))}
      </div>

      <form className="conversation-form" onSubmit={handleSubmit}>
        <input
          type="text"
          value={draft}
          onChange={(event) => setDraft(event.target.value)}
          placeholder="Escreva uma mensagem"
        />
        <button type="submit" className="primary-button">
          Enviar
        </button>
      </form>
    </div>
  );
}
