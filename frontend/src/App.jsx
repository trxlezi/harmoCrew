import './App.css';
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';

import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import DashboardDJ from './pages/DashboardDJ';
import DashboardArtist from './pages/DashboardArtist';
import ProjectDetails from './pages/ProjectDetails';
import CreateProject from './pages/CreateProject';
import HomePage from './pages/HomePage';

import { AuthProvider } from './context/AuthContext';
import PrivateRoute from './components/PrivateRoute';
import Layout from './components/Layout';

function App() {
  return (
    <Router>
      <AuthProvider>
        <Layout>
          <Routes>
-            <Route path="/" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />

-            <Route path="/home" element={<PrivateRoute><HomePage /></PrivateRoute>} />
            <Route path="/dj/dashboard" element={<PrivateRoute><DashboardDJ /></PrivateRoute>} />
            <Route path="/artist/dashboard" element={<PrivateRoute><DashboardArtist /></PrivateRoute>} />
            <Route path="/projects/:id" element={<PrivateRoute><ProjectDetails /></PrivateRoute>} />
            <Route path="/create-project" element={<PrivateRoute><CreateProject /></PrivateRoute>} />
          </Routes>
        </Layout>
      </AuthProvider>
    </Router>
  );
}

export default App;
