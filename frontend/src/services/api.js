import axios from "axios";

/*
 * Cliente da API Spring (api-harmocrew). Mesmo backend usado pelo app mobile.
 * Configure REACT_APP_API_URL (padrao http://localhost:8080).
 */
export const API_URL = (process.env.REACT_APP_API_URL || "http://localhost:8080").replace(/\/$/, "");

const client = axios.create({ baseURL: `${API_URL}/api` });

let currentToken = null;

export function setAuthToken(token) {
  currentToken = token;
  if (token) {
    client.defaults.headers.common.Authorization = `Bearer ${token}`;
    return;
  }
  delete client.defaults.headers.common.Authorization;
}

// Links /media/... ja vem assinados pela API; so falta o host.
export function mediaUrl(path) {
  if (!path) return null;
  return path.startsWith("http") ? path : `${API_URL}${path}`;
}

export function errorMessage(error, fallback = "Algo deu errado.") {
  const status = error?.response?.status;
  if (status === 403) {
    return error.response.data?.message || "Acesso restrito aos membros do projeto.";
  }
  return error?.response?.data?.message || fallback;
}

const data = (promise) => promise.then((response) => response.data);

function upload(path, file, fields = {}) {
  const form = new FormData();
  form.append("file", file);
  Object.entries(fields).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== "") form.append(key, value);
  });
  return data(client.post(path, form));
}

/*
 * Stream SSE de alertas. EventSource nao envia header Authorization, entao
 * usamos fetch com leitura incremental do corpo.
 */
export function subscribeAlerts(onEvent) {
  const controller = new AbortController();
  (async () => {
    while (!controller.signal.aborted) {
      try {
        const response = await fetch(`${API_URL}/api/notifications/stream`, {
          headers: { Authorization: `Bearer ${currentToken}` },
          signal: controller.signal,
        });
        const reader = response.body.getReader();
        const decoder = new TextDecoder();
        let buffer = "";
        for (;;) {
          const { value, done } = await reader.read();
          if (done) break;
          buffer += decoder.decode(value, { stream: true });
          const chunks = buffer.split(/\r?\n\r?\n/);
          buffer = chunks.pop();
          chunks.forEach((chunk) => {
            let name = "message";
            let payload = "";
            chunk.split(/\r?\n/).forEach((line) => {
              if (line.startsWith("event:")) name = line.slice(6).trim();
              if (line.startsWith("data:")) payload += line.slice(5).trim();
            });
            try {
              onEvent(name, payload ? JSON.parse(payload) : null);
            } catch (e) {
              onEvent(name, payload);
            }
          });
        }
      } catch (error) {
        if (controller.signal.aborted) return;
      }
      await new Promise((resolve) => setTimeout(resolve, 3000));
    }
  })();
  return () => controller.abort();
}

const api = {
  auth: {
    login: (payload) => data(client.post("/auth/login", payload)),
    register: (payload) => data(client.post("/auth/register", payload)),
    logout: () => client.post("/auth/logout"),
  },
  artists: {
    list: (params) => data(client.get("/artists", { params })),
    get: (id) => data(client.get(`/artists/${id}`)),
    update: (id, payload) => data(client.put(`/artists/${id}`, payload)),
    uploadAudio: (id, file) => upload(`/artists/${id}/audio`, file),
  },
  projects: {
    list: () => data(client.get("/projects")),
    get: (id) => data(client.get(`/projects/${id}`)),
    create: (payload) => data(client.post("/projects", payload)),
    update: (id, payload) => data(client.put(`/projects/${id}`, payload)),
    addArtist: (id, artistId) => data(client.post(`/projects/${id}/artists/${artistId}`)),
  },
  applications: {
    mine: (artistId) => data(client.get("/applications", { params: { artistId } })),
    create: (projectId, payload) => data(client.post(`/projects/${projectId}/applications`, payload)),
    updateStatus: (id, payload) => data(client.patch(`/applications/${id}/status`, payload)),
  },
  matching: {
    matches: (projectId, params) => data(client.get(`/projects/${projectId}/matches`, { params })),
    ranked: (projectId, params) => data(client.get(`/projects/${projectId}/applications/ranked`, { params })),
  },
  files: {
    list: (projectId) => data(client.get(`/projects/${projectId}/files`)),
    create: (projectId, file, fields) => upload(`/projects/${projectId}/files`, file, fields),
    uploadVersion: (fileId, file, note) => upload(`/files/${fileId}/versions`, file, { note }),
    unlock: (fileId, reason) => data(client.post(`/files/${fileId}/unlock`, { reason })),
    history: (fileId) => data(client.get(`/files/${fileId}/history`)),
    audit: (projectId) => data(client.get(`/projects/${projectId}/audit-logs`)),
  },
  polls: {
    list: (projectId) => data(client.get(`/projects/${projectId}/polls`)),
    create: (projectId, payload) => data(client.post(`/projects/${projectId}/polls`, payload)),
    vote: (pollId, optionId) => data(client.post(`/polls/${pollId}/votes`, { optionId })),
    close: (pollId) => data(client.post(`/polls/${pollId}/close`, {})),
  },
  decisions: {
    list: (projectId) => data(client.get(`/projects/${projectId}/decisions`)),
    create: (projectId, payload) => data(client.post(`/projects/${projectId}/decisions`, payload)),
    updateStatus: (id, status) => data(client.patch(`/decisions/${id}/status`, { status })),
  },
  rehearsals: {
    list: (projectId) => data(client.get(`/projects/${projectId}/rehearsals`)),
    mine: () => data(client.get("/rehearsals")),
    create: (projectId, payload) => data(client.post(`/projects/${projectId}/rehearsals`, payload)),
    updateStatus: (id, status) => data(client.patch(`/rehearsals/${id}/status`, { status })),
    attendance: (id, attendedArtistIds) => data(client.patch(`/rehearsals/${id}/attendance`, { attendedArtistIds })),
    remove: (id) => client.delete(`/rehearsals/${id}`),
  },
  goals: {
    list: (projectId) => data(client.get(`/projects/${projectId}/weekly-goals`)),
    mine: (ownerArtistId) => data(client.get("/weekly-goals", { params: { ownerArtistId } })),
    create: (projectId, payload) => data(client.post(`/projects/${projectId}/weekly-goals`, payload)),
    update: (id, payload) => data(client.put(`/weekly-goals/${id}`, payload)),
    updateStatus: (id, status) => data(client.patch(`/weekly-goals/${id}/status`, { status })),
    remove: (id) => client.delete(`/weekly-goals/${id}`),
  },
  tasks: {
    list: (projectId) => data(client.get(`/projects/${projectId}/tasks`)),
    mine: () => data(client.get("/tasks")),
    remove: (id) => client.delete(`/tasks/${id}`),
    create: (projectId, payload) => data(client.post(`/projects/${projectId}/tasks`, payload)),
    updateStatus: (id, status) => data(client.patch(`/tasks/${id}/status`, { status })),
  },
  insights: {
    timeline: (projectId) => data(client.get(`/projects/${projectId}/timeline`)),
    dashboard: (projectId) => data(client.get(`/projects/${projectId}/dashboard`)),
    collective: () => data(client.get("/dashboard")),
  },
  messages: {
    list: (projectId) => data(client.get(`/projects/${projectId}/messages`)),
    send: (projectId, senderArtistId, content) =>
      data(client.post(`/projects/${projectId}/messages`, { senderArtistId, content, type: "MESSAGE" })),
  },
  notifications: {
    list: (unreadOnly = false) => data(client.get("/notifications", { params: { unreadOnly } })),
    markRead: (id) => data(client.patch(`/notifications/${id}/read`)),
    markAllRead: () => client.patch("/notifications/read-all"),
  },
};

export default api;
