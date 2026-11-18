import React from "react";
import { Navigate, Route, Routes } from "react-router-dom";
import Layout from "../components/Layout";
import PrivateRoute from "../components/PrivateRoute";
import LoginPage from "../domains/auth/pages/LoginPage";
import RegisterPage from "../domains/auth/pages/RegisterPage";
import ExplorePage from "../domains/explore/pages/ExplorePage";
import OpportunitiesPage from "../domains/opportunities/pages/OpportunitiesPage";
import MessagesPage from "../domains/messages/pages/MessagesPage";
import DashboardPage from "../domains/dashboard/pages/DashboardPage";
import ProfilePage from "../domains/profile/pages/ProfilePage";
import PublicProfilePage from "../domains/profile/pages/PublicProfilePage";

export default function AppRouter() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route path="/" element={<Navigate to="/login" replace />} />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        <Route
          path="/explorar"
          element={
            <PrivateRoute>
              <ExplorePage />
            </PrivateRoute>
          }
        />
        <Route
          path="/oportunidades"
          element={
            <PrivateRoute>
              <OpportunitiesPage />
            </PrivateRoute>
          }
        />
        <Route
          path="/mensagens"
          element={
            <PrivateRoute>
              <MessagesPage />
            </PrivateRoute>
          }
        />
        <Route
          path="/painel"
          element={
            <PrivateRoute>
              <DashboardPage />
            </PrivateRoute>
          }
        />
        <Route
          path="/perfil"
          element={
            <PrivateRoute>
              <ProfilePage />
            </PrivateRoute>
          }
        />
        <Route
          path="/perfil/:id"
          element={
            <PrivateRoute>
              <PublicProfilePage />
            </PrivateRoute>
          }
        />
      </Route>
    </Routes>
  );
}
