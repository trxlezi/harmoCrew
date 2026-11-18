import React, { createContext, useContext, useMemo, useState } from "react";
import api, { setAuthToken } from "../services/api";

const AuthContext = createContext(null);
const STORAGE_KEY = "harmocrew-session";

export function useAuth() {
  return useContext(AuthContext);
}

function readSession() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch (error) {
    return null;
  }
}

/*
 * Sessao vinda da API Spring: { token, userId, artistId, name, email, role }.
 * O token e aplicado no cliente antes da primeira renderizacao.
 */
const initial = readSession();
setAuthToken(initial?.token ?? null);

export function AuthProvider({ children }) {
  const [session, setSession] = useState(initial);

  const value = useMemo(
    () => ({
      token: session?.token ?? null,
      user: session,
      isLoading: false,
      login: (auth) => {
        setAuthToken(auth.token);
        try {
          localStorage.setItem(STORAGE_KEY, JSON.stringify(auth));
        } catch (error) {
          // sem storage: sessao vale so nesta aba
        }
        setSession(auth);
      },
      logout: async () => {
        try {
          if (session?.token) await api.auth.logout();
        } catch (error) {
          // token ja invalido
        } finally {
          try {
            localStorage.removeItem(STORAGE_KEY);
          } catch (error) {
            // ignora
          }
          setAuthToken(null);
          setSession(null);
        }
      },
      updateUser: (patch) => setSession((current) => ({ ...current, ...patch })),
    }),
    [session]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
