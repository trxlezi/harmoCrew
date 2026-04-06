import React from "react";
import AppProviders from "./app/providers";
import AppRouter from "./app/router";
import "./index.css";
import "./styles/theme.css";
import "./styles/layout.css";

export default function App() {
  return (
    <AppProviders>
      <AppRouter />
    </AppProviders>
  );
}
