import React from "react";
import { NavLink, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { useAlerts } from "../domains/alerts/AlertsContext";

const NAV_ITEMS = [
  { to: "/projetos", label: "Projetos" },
  { to: "/responsabilidades", label: "Minha agenda" },
  { to: "/musicos", label: "Músicos" },
  { to: "/painel", label: "Painel" },
  { to: "/perfil", label: "Perfil" },
];

export default function Navbar() {
  const navigate = useNavigate();
  const { user, logout } = useAuth();
  const { unread } = useAlerts();

  return (
    <header className="topbar">
      <button type="button" className="brand-mark" onClick={() => navigate("/projetos")}>
        HarmoCrew
      </button>

      <nav className="topbar-nav" aria-label="Navegacao principal">
        {NAV_ITEMS.map((item) => (
          <NavLink key={item.to} to={item.to} className={({ isActive }) => `topbar-link${isActive ? " active" : ""}`}>
            {item.label}
          </NavLink>
        ))}
      </nav>

      <div className="topbar-user">
        <NavLink to="/alertas" className={({ isActive }) => `topbar-link bell${isActive ? " active" : ""}`} aria-label={`Alertas (${unread} não lidos)`}>
          🔔{unread > 0 ? <span className="badge">{unread}</span> : null}
        </NavLink>
        <div className="topbar-avatar">{user?.name?.slice(0, 1).toUpperCase() ?? "H"}</div>
        <div className="topbar-user-copy">
          <strong>{user?.name || "HarmoCrew"}</strong>
          <span>{user?.email}</span>
        </div>
        <button
          type="button"
          className="ghost-button"
          onClick={async () => {
            await logout();
            navigate("/login");
          }}
        >
          Sair
        </button>
      </div>
    </header>
  );
}
