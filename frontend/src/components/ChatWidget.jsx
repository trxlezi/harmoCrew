import React, { useState, useEffect, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import { getChatContacts, getConversation, sendMessage } from '../services/api';

const widgetStyle = {
  position: 'fixed',
  bottom: 32,
  right: 32,
  zIndex: 1000,
  minWidth: 320,
  maxWidth: 370,
  boxShadow: '0 8px 32px rgba(0,0,0,0.25)',
  borderRadius: 18,
  background: 'rgba(30,32,60,0.98)',
  fontFamily: 'inherit',
  transition: 'transform 0.2s cubic-bezier(.4,2,.6,1), box-shadow 0.2s',
  animation: 'chatOpen 0.3s cubic-bezier(.4,2,.6,1)',
};

const headerStyle = {
  background: 'linear-gradient(90deg, #6366f1 0%, #a349d1 100%)',
  color: '#fff',
  padding: '14px 20px',
  borderTopLeftRadius: 18,
  borderTopRightRadius: 18,
  cursor: 'pointer',
  fontWeight: 'bold',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'space-between',
  fontSize: 18,
  letterSpacing: 0.5,
  boxShadow: '0 2px 8px rgba(99,102,241,0.08)',
};

const contactListStyle = {
  maxHeight: 220,
  overflowY: 'auto',
  borderBottom: '1px solid #2a2a2e',
  background: 'rgba(40,42,70,0.98)',
};

const chatWindowStyle = {
  display: 'flex',
  flexDirection: 'column',
  height: 380,
  maxHeight: '60vh',
};

const inputStyle = {
  flex: 1,
  border: 'none',
  borderRadius: 16,
  padding: '10px 14px',
  marginRight: 8,
  background: '#23233a',
  color: '#fff',
  fontSize: 15,
  outline: 'none',
  boxShadow: '0 1px 4px rgba(99,102,241,0.08)',
  transition: 'box-shadow 0.2s',
};

const sendButtonStyle = {
  background: 'linear-gradient(90deg, #6366f1 0%, #a349d1 100%)',
  color: '#fff',
  border: 'none',
  borderRadius: 16,
  padding: '10px 18px',
  fontWeight: 'bold',
  fontSize: 15,
  cursor: 'pointer',
  boxShadow: '0 2px 8px rgba(99,102,241,0.10)',
  transition: 'background 0.2s',
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
        <div style={{...headerStyle, borderRadius: 24, minWidth: 60, minHeight: 60, justifyContent: 'center', cursor: 'pointer', fontSize: 28, padding: 0}} onClick={() => setOpen(true)}>
          <span role="img" aria-label="chat">💬</span>
        </div>
      )}
      {open && (
        <div style={{border: '1px solid #23233a', borderRadius: 18, background: 'rgba(30,32,60,0.98)'}}>
          <div style={headerStyle} onClick={() => setOpen(false)}>
            <span>Chat</span>
            <span style={{cursor: 'pointer', fontSize: 22, marginLeft: 8, fontWeight: 400}}>&#10005;</span>
          </div>
          {!selectedContact ? (
            <div style={contactListStyle}>
              {contacts.length === 0 && <div style={{padding: 16, color: '#aaa'}}>Nenhum seguidor para conversar.</div>}
              {contacts.map(contact => (
                <div
                  key={contact.id}
                  onClick={() => setSelectedContact(contact)}
                  style={{
                    padding: 14,
                    cursor: 'pointer',
                    borderBottom: '1px solid #23233a',
                    background: 'transparent',
                    fontWeight: 500,
                    display: 'flex',
                    alignItems: 'center',
                    transition: 'background 0.15s',
                  }}
                  onMouseOver={e => e.currentTarget.style.background = '#23233a'}
                  onMouseOut={e => e.currentTarget.style.background = 'transparent'}
                >
                  <span style={{marginRight: 10, background: '#6366f1', borderRadius: '50%', width: 32, height: 32, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700, color: '#fff', fontSize: 18}}>
                    {contact.nome[0]}
                  </span>
                  <span>{contact.nome}</span>
                </div>
              ))}
            </div>
          ) : (
            <div style={chatWindowStyle}>
              <div style={{padding: 12, borderBottom: '1px solid #23233a', background: 'rgba(40,42,70,0.98)', fontWeight: 600, fontSize: 16, display: 'flex', alignItems: 'center'}}>
                <span style={{cursor: 'pointer', marginRight: 8, fontSize: 18}} onClick={() => setSelectedContact(null)}>&larr;</span>
                {selectedContact.nome}
              </div>
              <div style={{flex: 1, overflowY: 'auto', padding: 12, background: 'rgba(30,32,60,0.98)'}}>
                {loadingMessages ? (
                  <div style={{color: '#aaa'}}>Carregando mensagens...</div>
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
                            background: msg.sender_id === user.id ? 'linear-gradient(90deg, #6366f1 0%, #a349d1 100%)' : '#23233a',
                            color: msg.sender_id === user.id ? '#fff' : '#eee',
                            borderRadius: 16,
                            padding: '8px 16px',
                            maxWidth: '70%',
                            fontSize: 15,
                            boxShadow: msg.sender_id === user.id ? '0 2px 8px rgba(99,102,241,0.10)' : 'none',
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
              <form onSubmit={handleSend} style={{ display: 'flex', borderTop: '1px solid #23233a', padding: 10, background: 'rgba(40,42,70,0.98)' }}>
                <input
                  type="text"
                  value={newMessage}
                  onChange={e => setNewMessage(e.target.value)}
                  placeholder="Digite sua mensagem..."
                  style={inputStyle}
                />
                <button type="submit" style={sendButtonStyle}>
                  Enviar
                </button>
              </form>
            </div>
          )}
        </div>
      )}
      <style>{`
        @keyframes chatOpen {
          from { transform: scale(0.85) translateY(40px); opacity: 0; }
          to { transform: scale(1) translateY(0); opacity: 1; }
        }
      `}</style>
    </div>
  );
};

export default ChatWidget; 