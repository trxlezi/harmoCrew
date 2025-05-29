import React from "react";
import { useLocation } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import Navbar from "./Navbar";
import "../styles/global.css";
import "../styles/colors.css";

export default function Layout({ children }) {
  const location = useLocation();
  const hideNavbarOnPaths = ['/', '/register'];
  const { user, logout } = useAuth();

  const shouldHideNavbar = hideNavbarOnPaths.includes(location.pathname);

  return (
    <>
      {!shouldHideNavbar && <Navbar user={user} logout={logout} />}
      {children}
    </>
  );
}
