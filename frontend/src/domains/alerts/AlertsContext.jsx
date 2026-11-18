import React, { createContext, useContext, useEffect, useState } from "react";
import { useAuth } from "../../context/AuthContext";
import { subscribeAlerts } from "../../services/api";

const AlertsContext = createContext({ unread: 0, latest: null, version: 0 });
export const useAlerts = () => useContext(AlertsContext);

/*
 * Mantem a conexao SSE de alertas aberta enquanto o usuario esta logado.
 * "ready" traz o contador de nao lidas; "notification" chega em tempo real.
 */
export function AlertsProvider({ children }) {
  const { token } = useAuth();
  const [state, setState] = useState({ unread: 0, latest: null, version: 0 });

  useEffect(() => {
    if (!token) return undefined;
    return subscribeAlerts((name, payload) => {
      if (name === "ready") {
        const unread = typeof payload === "number" ? payload : payload?.unread ?? 0;
        setState((s) => ({ ...s, unread }));
      }
      if (name === "notification") {
        setState((s) => ({ unread: s.unread + 1, latest: payload, version: s.version + 1 }));
      }
    });
  }, [token]);

  useEffect(() => {
    if (!state.latest) return undefined;
    const timer = setTimeout(() => setState((s) => ({ ...s, latest: null })), 6000);
    return () => clearTimeout(timer);
  }, [state.latest]);

  const value = {
    ...state,
    setUnread: (unread) => setState((s) => ({ ...s, unread })),
  };

  return (
    <AlertsContext.Provider value={value}>
      {children}
      {state.latest ? (
        <div className="toast" role="status">
          <strong>🔔 {state.latest.title}</strong>
          <span>{state.latest.body}</span>
        </div>
      ) : null}
    </AlertsContext.Provider>
  );
}
