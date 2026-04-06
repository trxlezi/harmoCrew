import React from "react";
import { Outlet, useLocation } from "react-router-dom";
import Navbar from "./Navbar";

const AUTH_ROUTES = new Set(["/login", "/register", "/"]);

export default function Layout() {
  const location = useLocation();
  const hideNavbar = AUTH_ROUTES.has(location.pathname);

  return (
    <div className="app-shell">
      <div className="app-background" />
      {!hideNavbar ? <Navbar /> : null}
      <main className="app-content">
        <Outlet />
      </main>
    </div>
  );
}
