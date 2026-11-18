import axios from "axios";

const client = axios.create({
  baseURL: "http://localhost:5000/api",
});

export function setAuthToken(token) {
  if (token) {
    client.defaults.headers.common.Authorization = `Bearer ${token}`;
    return;
  }

  delete client.defaults.headers.common.Authorization;
}

const api = {
  auth: {
    login: (payload) => client.post("/login", payload),
    register: (payload) => client.post("/register", payload),
    me: () => client.get("/profile"),
    logout: () => client.post("/logout"),
  },
  feed: {
    getHomeFeed: () => client.get("/feed"),
  },
  opportunities: {
    list: () => client.get("/opportunities"),
    create: (payload) => client.post("/opportunities", payload),
    apply: (opportunityId) => client.post(`/opportunities/${opportunityId}/apply`),
  },
  dashboard: {
    summary: () => client.get("/dashboard/summary"),
  },
  candidacies: {
    received: () => client.get("/candidacies/received"),
    accept: (candidacyId) => client.post(`/candidacies/${candidacyId}/aceitar`),
    reject: (candidacyId) => client.post(`/candidacies/${candidacyId}/rejeitar`),
  },
  messages: {
    contacts: () => client.get("/messages/contacts"),
    conversation: (profileId) => client.get(`/messages/conversations/${profileId}`),
    send: (profileId, message) =>
      client.post("/messages", { receiver_id: profileId, message }),
  },
  profiles: {
    me: () => client.get("/profiles/me"),
    search: (query) => client.get(`/profiles/search?q=${encodeURIComponent(query)}`),
    byId: (profileId) => client.get(`/profiles/${profileId}`),
    projects: (profileId) => client.get(`/profiles/${profileId}/projects`),
    updateDescription: (description) =>
      client.put("/profiles/me/description", { descricao: description }),
    updateLinks: (links) =>
      client.put("/profiles/me/links", { links_sociais: links }),
    updatePhoto: (profilePicUrl) =>
      client.put("/profiles/me/photo", { profile_pic_url: profilePicUrl }),
    follow: (profileId) => client.post(`/profiles/${profileId}/follow`),
    unfollow: (profileId) => client.delete(`/profiles/${profileId}/follow`),
  },
};

export default api;
