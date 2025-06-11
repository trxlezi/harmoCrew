import React, { useState, useEffect, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import { getChatContacts, getConversation, sendMessage } from '../services/api';

const widgetStyle = {
  position: 'fixed',
  bottom: 24,
  right: 24,
  zIndex: 1000,
  minWidth: 320,
  maxWidth: 360,
  boxShadow: '0 2px 16px rgba(0,0,0,0.18)',
  borderRadius: 12,
  background: '#fff',
  fontFamily: 'inherit',
};

const headerStyle = {
  background: '#6366f1',
  color: '#fff',
  padding: '12px 16px',
  borderTopLeftRadius: 12,
  borderTopRightRadius: 12,
  cursor: 'pointer',
  fontWeight: 'bold',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'space-between',
};

const contactListStyle = {
  maxHeight: 220,
  overflowY: 'auto',
  borderBottom: '1px solid #eee',
};

const chatWindowStyle = {
  display: 'flex',
  flexDirection: 'column',
  height: 380,
  maxHeight: '60vh',
};

const ChatWidget = () => {
  const { user, token } = useAuth();
  const [open, setOpen] = useState(false);
  const [contacts, setContacts] = useState([]);
  const [selectedContact, setSelectedContact] = useState(null);
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [loadingMessages, setLoadingMessages] = useState(false);
  const messagesEndRef = useRef(null);

  useEffect(() => {
    if (token && open) {
      getChatContacts(token)
        .then(res => setContacts(res.data.contacts))
        .catch(() => setContacts([]));
    }
  }, [token, open]);

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
      getConversation(token, selectedContact.id)
        .then(res => setMessages(res.data.messages));
    } catch (err) {
      alert('Erro ao enviar mensagem');
    }
  };

  if (!user) return null;

  return (
    <div style={widgetStyle}>
      {!open && (
        <div style={{...headerStyle, borderRadius: 24, minWidth: 60, minHeight: 60, justifyContent: 'center', cursor: 'pointer'}} onClick={() => setOpen(true)}>
          <span role="img" aria-label="chat" style={{fontSize: 28}}>💬</span>
        </div>
      )}
      {open && (
        <div style={{border: '1px solid #eee', borderRadius: 12, background: '#fff'}}>
          <div style={headerStyle} onClick={() => setOpen(false)}>
            <span>Chat</span>
            <span style={{cursor: 'pointer', fontSize: 20, marginLeft: 8}}>&#10005;</span>
          </div>
          {!selectedContact ? (
            <div style={contactListStyle}>
              {contacts.length === 0 && <div style={{padding: 16, color: '#888'}}>Nenhum seguidor para conversar.</div>}
              {contacts.map(contact => (
                <div
                  key={contact.id}
                  onClick={() => setSelectedContact(contact)}
                  style={{
                    padding: 14,
                    cursor: 'pointer',
                    borderBottom: '1px solid #f3f4f6',
                    background: '#fff',
                    fontWeight: 500,
                    display: 'flex',
                    alignItems: 'center',
                  }}
                >
                  <span style={{marginRight: 10, background: '#e0e7ff', borderRadius: '50%', width: 32, height: 32, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700}}>
                    {contact.nome[0]}
                  </span>
                  <span>{contact.nome}</span>
                </div>
              ))}
            </div>
          ) : (
            <div style={chatWindowStyle}>
              <div style={{padding: 12, borderBottom: '1px solid #eee', background: '#f3f4f6', fontWeight: 600}}>
                <span style={{cursor: 'pointer', marginRight: 8}} onClick={() => setSelectedContact(null)}>&larr;</span>
                {selectedContact.nome}
              </div>
              <div style={{flex: 1, overflowY: 'auto', padding: 12, background: '#fff'}}>
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
                          marginBottom: 10,
                          textAlign: msg.sender_id === user.id ? 'right' : 'left',
                        }}
                      >
                        <div
                          style={{
                            display: 'inline-block',
                            background: msg.sender_id === user.id ? '#6366f1' : '#e5e7eb',
                            color: msg.sender_id === user.id ? '#fff' : '#222',
                            borderRadius: 16,
                            padding: '7px 14px',
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
              <form onSubmit={handleSend} style={{ display: 'flex', borderTop: '1px solid #eee', padding: 10, background: '#fafafa' }}>
                <input
                  type="text"
                  value={newMessage}
                  onChange={e => setNewMessage(e.target.value)}
                  placeholder="Digite sua mensagem..."
                  style={{ flex: 1, border: '1px solid #ccc', borderRadius: 16, padding: '8px 12px', marginRight: 8 }}
                />
                <button type="submit" style={{ background: '#6366f1', color: '#fff', border: 'none', borderRadius: 16, padding: '8px 16px', fontWeight: 'bold' }}>
                  Enviar
                </button>
              </form>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default ChatWidget; 