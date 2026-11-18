import React from "react";
import { Navigate, Route, Routes } from "react-router-dom";
import Layout from "../components/Layout";
import PrivateRoute from "../components/PrivateRoute";
import LoginPage from "../domains/auth/pages/LoginPage";
import RegisterPage from "../domains/auth/pages/RegisterPage";
import ProjectsPage from "../domains/projects/pages/ProjectsPage";
import ProjectPage from "../domains/projects/pages/ProjectPage";
import MusiciansPage from "../domains/musicians/MusiciansPage";
import DashboardPage from "../domains/dashboard/pages/DashboardPage";
import AlertsPage from "../domains/alerts/AlertsPage";
import ResponsibilitiesPage from "../domains/responsibilities/ResponsibilitiesPage";
import ProfilePage from "../domains/profile/pages/ProfilePage";

const PRIVATE = [
  ["/projetos", <ProjectsPage />],
  ["/projetos/:id/*", <ProjectPage />],
  ["/musicos", <MusiciansPage />],
  ["/painel", <DashboardPage />],
  ["/alertas", <AlertsPage />],
  ["/responsabilidades", <ResponsibilitiesPage />],
  ["/perfil", <ProfilePage />],
];

export default function AppRouter() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route path="/" element={<Navigate to="/projetos" replace />} />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        {PRIVATE.map(([path, element]) => (
          <Route key={path} path={path} element={<PrivateRoute>{element}</PrivateRoute>} />
        ))}
        <Route path="*" element={<Navigate to="/projetos" replace />} />
      </Route>
    </Routes>
  );
}
