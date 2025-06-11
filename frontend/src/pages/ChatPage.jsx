import React, { useEffect, useState, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import { getChatContacts, getConversation, sendMessage } from '../services/api';

const ChatPage = () => {
  const { user, token } = useAuth();
  const [contacts, setContacts] = useState([]);
  const [selectedContact, setSelectedContact] = useState(null);
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [loadingMessages, setLoadingMessages] = useState(false);
  const messagesEndRef = useRef(null);

  useEffect(() => {
    if (token) {
      getChatContacts(token)
        .then(res => setContacts(res.data.contacts))
        .catch(() => setContacts([]));
    }
  }, [token]);

  useEffect(() => {
    if (selectedContact && token) {
      setLoadingMessages(true);
      getConversation(token, selectedContact.id)
        .then(res => setMessages(res.data.messages))
        .catch(() => setMessages([]))
        .finally(() => setLoadingMessages(false));
    }
  }, [selectedContact, token]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = async (e) => {
    e.preventDefault();
    if (!newMessage.trim() || !selectedContact) return;
    try {
      await sendMessage(token, selectedContact.id, newMessage);
      setNewMessage('');
      // Refresh messages
      getConversation(token, selectedContact.id)
        .then(res => setMessages(res.data.messages));
    } catch (err) {
      alert('Erro ao enviar mensagem');
    }
  };

  return (
    <div style={{ display: 'flex', height: '80vh', border: '1px solid #ccc', borderRadius: 8, overflow: 'hidden' }}>
      {/* Contacts */}
      <div style={{ width: 250, borderRight: '1px solid #eee', background: '#fafafa', overflowY: 'auto' }}>
        <h3 style={{ padding: 16, margin: 0, borderBottom: '1px solid #eee' }}>Contatos</h3>
        {contacts.length === 0 && <div style={{ padding: 16 }}>Nenhum contato</div>}
        {contacts.map(contact => (
          <div
            key={contact.id}
            onClick={() => setSelectedContact(contact)}
            style={{
              padding: 16,
              cursor: 'pointer',
              background: selectedContact?.id === contact.id ? '#e0e7ff' : 'transparent',
              borderBottom: '1px solid #eee',
              fontWeight: selectedContact?.id === contact.id ? 'bold' : 'normal',
            }}
          >
            <div>{contact.nome}</div>
            <div style={{ fontSize: 12, color: '#888' }}>{contact.email}</div>
          </div>
        ))}
      </div>
      {/* Chat */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: 16, borderBottom: '1px solid #eee', background: '#f3f4f6', minHeight: 60 }}>
          {selectedContact ? (
            <>
              <strong>{selectedContact.nome}</strong>
              <div style={{ fontSize: 12, color: '#888' }}>{selectedContact.email}</div>
            </>
          ) : (
            <span>Selecione um contato para conversar</span>
          )}
        </div>
        <div style={{ flex: 1, overflowY: 'auto', padding: 16, background: '#fff' }}>
          {loadingMessages ? (
            <div>Carregando mensagens...</div>
          ) : (
            messages.length === 0 ? (
              <div style={{ color: '#888' }}>Nenhuma mensagem</div>
            ) : (
              messages.map(msg => (
                <div
                  key={msg.id}
                  style={{
                    marginBottom: 12,
                    textAlign: msg.sender_id === user.id ? 'right' : 'left',
                  }}
                >
                  <div
                    style={{
                      display: 'inline-block',
                      background: msg.sender_id === user.id ? '#6366f1' : '#e5e7eb',
                      color: msg.sender_id === user.id ? '#fff' : '#222',
                      borderRadius: 16,
                      padding: '8px 16px',
                      maxWidth: '70%',
                    }}
                  >
                    {msg.content}
                  </div>
                  <div style={{ fontSize: 10, color: '#888', marginTop: 2 }}>
                    {msg.timestamp}
                  </div>
                </div>
              ))
            )
          )}
          <div ref={messagesEndRef} />
        </div>
        {/* Input */}
        {selectedContact && (
          <form onSubmit={handleSend} style={{ display: 'flex', borderTop: '1px solid #eee', padding: 12, background: '#fafafa' }}>
            <input
              type="text"
              value={newMessage}
              onChange={e => setNewMessage(e.target.value)}
              placeholder="Digite sua mensagem..."
              style={{ flex: 1, border: '1px solid #ccc', borderRadius: 16, padding: '8px 12px', marginRight: 8 }}
            />
            <button type="submit" style={{ background: '#6366f1', color: '#fff', border: 'none', borderRadius: 16, padding: '8px 20px', fontWeight: 'bold' }}>
              Enviar
            </button>
          </form>
        )}
      </div>
    </div>
  );
};

export default ChatPage; 