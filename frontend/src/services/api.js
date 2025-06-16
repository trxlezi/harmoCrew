import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:5000',
});

// Envia uma mensagem
export const sendMessage = (token, receiver_id, message) =>
  api.post(
    '/messages',
    { receiver_id, message },
    { headers: { Authorization: `Bearer ${token}` } }
  );

// Busca a conversa entre o usuário logado e outro usuário
export const getConversation = (token, receiver_id) =>
  api.get(`/messages/${receiver_id}`, {
    headers: { Authorization: `Bearer ${token}` },
  });

// Busca os contatos do chat
export const getChatContacts = (token) =>
  api.get('/messages/contacts', {
    headers: { Authorization: `Bearer ${token}` },
  });

export default api;
