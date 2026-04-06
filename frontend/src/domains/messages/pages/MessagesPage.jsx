import React, { useEffect, useState } from "react";
import EmptyState from "../../../components/ui/EmptyState";
import LoadingState from "../../../components/ui/LoadingState";
import SectionHeader from "../../../components/ui/SectionHeader";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import api from "../../../services/api";
import { capitalizeName } from "../../../utils/formatters";
import ConversationPanel from "../components/ConversationPanel";

export default function MessagesPage() {
  const [contacts, setContacts] = useState([]);
  const [activeContactId, setActiveContactId] = useState(null);
  const [messages, setMessages] = useState([]);
  const [contactsStatus, setContactsStatus] = useState("loading");
  const [conversationStatus, setConversationStatus] = useState("idle");
  const [feedbackMessage, setFeedbackMessage] = useState("");

  async function loadContacts() {
    setContactsStatus("loading");
    setFeedbackMessage("");
    try {
      const response = await api.messages.contacts();
      const nextContacts = response.data.data.contacts || [];
      setContacts(nextContacts);
      if (nextContacts.length > 0) {
        setActiveContactId(nextContacts[0].id);
      }
      setContactsStatus("ready");
    } catch (error) {
      setContacts([]);
      setContactsStatus("error");
      setFeedbackMessage(
        error?.response?.data?.error?.message ||
          "Nao foi possivel carregar seus contatos."
      );
    }
  }

  useEffect(() => {
    loadContacts();
  }, []);

  async function loadConversation(contactId) {
    if (!contactId) {
      return;
    }

    setConversationStatus("loading");
    try {
      const response = await api.messages.conversation(contactId);
      setMessages(response.data.data.messages || []);
      setConversationStatus("ready");
    } catch (error) {
      setMessages([]);
      setConversationStatus("error");
      setFeedbackMessage(
        error?.response?.data?.error?.message ||
          "Nao foi possivel carregar a conversa selecionada."
      );
    }
  }

  useEffect(() => {
    loadConversation(activeContactId);
  }, [activeContactId]);

  async function handleSendMessage(content) {
    try {
      await api.messages.send(activeContactId, content);
      await loadConversation(activeContactId);
    } catch (error) {
      setFeedbackMessage(
        error?.response?.data?.error?.message ||
          "Nao foi possivel enviar a mensagem."
      );
    }
  }

  const activeContact = contacts.find((contact) => contact.id === activeContactId) || null;

  return (
    <div className="page-stack">
      <SectionHeader
        eyebrow="Mensagens"
        title="Converse com quem move seus projetos"
        subtitle="Um painel mais limpo para acompanhar contatos relevantes, ultimas trocas e proximos passos."
      />

      <div className="messages-layout">
        <SurfaceCard className="messages-sidebar">
          {contactsStatus === "loading" ? (
            <LoadingState
              title="Carregando contatos"
              description="Buscando as pessoas com quem voce ja pode conversar."
            />
          ) : null}

          {contactsStatus === "error" ? (
            <EmptyState
              title="Sua caixa de entrada nao abriu"
              description={feedbackMessage}
              action={
                <button type="button" className="secondary-button" onClick={loadContacts}>
                  Tentar novamente
                </button>
              }
            />
          ) : null}

          {contactsStatus === "ready" && contacts.length === 0 ? (
            <EmptyState
              title="Sem contatos disponiveis"
              description="As conversas aparecem quando houver conexao mutua na plataforma."
            />
          ) : null}

          {contactsStatus === "ready"
            ? contacts.map((contact) => (
                <button
                  key={contact.id}
                  type="button"
                  className={`contact-row ${contact.id === activeContactId ? "contact-row--active" : ""}`}
                  onClick={() => setActiveContactId(contact.id)}
                >
                  <strong>{capitalizeName(contact.nome)}</strong>
                  <span>{contact.last_message || "Inicie a conversa"}</span>
                </button>
              ))
            : null}
        </SurfaceCard>

        <SurfaceCard className="messages-main">
          {conversationStatus === "loading" ? (
            <LoadingState
              title="Abrindo conversa"
              description="Recuperando o historico desta conexao."
            />
          ) : (
            <ConversationPanel
              activeContact={activeContact}
              messages={messages}
              onSendMessage={handleSendMessage}
            />
          )}
        </SurfaceCard>
      </div>
    </div>
  );
}
