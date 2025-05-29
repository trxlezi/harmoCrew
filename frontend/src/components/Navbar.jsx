// src/components/Navbar.jsx
import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import styles from '../styles/Navbar.module.css';
import "../styles/global.css";
import "../styles/colors.css";

export default function Navbar() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <nav className={styles.navbar}>
      <Link to="/home" className={styles.logo}>Harmocrew</Link>

      {user ? (
        <div className={styles.navRight}>
          <Link to="/profile" className={styles.buttonLike}>
            {user.nome}
          </Link>
          <button onClick={handleLogout} className={styles.buttonLike}>
            Logout
          </button>
        </div>
      ) : (
        <Link to="/login" className={styles.buttonLike}>Login</Link>
      )}
    </nav>
  );
}
