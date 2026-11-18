import React from "react";
import { BrowserRouter } from "react-router-dom";
import { AuthProvider } from "../context/AuthContext";
import { AlertsProvider } from "../domains/alerts/AlertsContext";

export default function AppProviders({ children }) {
  return (
    <BrowserRouter>
      <AuthProvider>
        <AlertsProvider>{children}</AlertsProvider>
      </AuthProvider>
    </BrowserRouter>
  );
}
