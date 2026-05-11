import React, { createContext, useContext, useEffect, useMemo, useState } from "react";
import api, { setAuthToken } from "../services/api";

const AuthContext = createContext(null);

export function useAuth() {
  return useContext(AuthContext);
}

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => localStorage.getItem("harmocrew-token"));
  const [user, setUser] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    setAuthToken(token);
  }, [token]);

  useEffect(() => {
    let isMounted = true;

    async function validateSession() {
      if (!token) {
        if (isMounted) {
          setUser(null);
          setIsLoading(false);
        }
        return;
      }

      try {
        const response = await api.auth.me();
        if (isMounted) {
          setUser(response.data.data.user);
        }
      } catch (error) {
        if (isMounted) {
          localStorage.removeItem("harmocrew-token");
          setToken(null);
          setUser(null);
        }
      } finally {
        if (isMounted) {
          setIsLoading(false);
        }
      }
    }

    validateSession();

    return () => {
      isMounted = false;
    };
  }, [token]);

  const value = useMemo(
    () => ({
      token,
      user,
      isLoading,
      login: (nextToken, nextUser) => {
        localStorage.setItem("harmocrew-token", nextToken);
        setToken(nextToken);
        setUser(nextUser);
      },
      logout: async () => {
        try {
          if (token) {
            await api.auth.logout();
          }
        } finally {
          localStorage.removeItem("harmocrew-token");
          setAuthToken(null);
          setToken(null);
          setUser(null);
        }
      },
      updateUser: (updater) => {
        setUser((currentUser) =>
          typeof updater === "function" ? updater(currentUser) : updater
        );
      },
    }),
    [isLoading, token, user]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
