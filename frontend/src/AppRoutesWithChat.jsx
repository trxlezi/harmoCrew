import React from 'react';
import { Routes, Route, useLocation } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import HomePage from './pages/HomePage';
import ProfilePage from './pages/ProfilePage';
import { AuthProvider } from './context/AuthContext';
import PrivateRoute from './components/PrivateRoute';
import Layout from './components/Layout';
import CandidaturasPage from "./pages/CandidaturasPage";
import UserProfile from './components/UserProfile';
import ChatWidget from './components/ChatWidget';

function AppRoutesWithChat() {
  const location = useLocation();
  return (
    <AuthProvider>
      <Layout>
        <Routes>
          <Route path="/" element={<LoginPage />} />
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route path="/home" element={<PrivateRoute><HomePage /></PrivateRoute>} />
          <Route path="/profile" element={<PrivateRoute><ProfilePage /></PrivateRoute>} />
          <Route path="/candidaturas" element={<PrivateRoute><CandidaturasPage /></PrivateRoute>} />
          <Route path="/usuario/:id" element={<PrivateRoute><UserProfile /></PrivateRoute>} />
        </Routes>
        {location.pathname === '/home' && <ChatWidget />}
      </Layout>
    </AuthProvider>
  );
}

export default AppRoutesWithChat; 