import React from 'react';
import { Link } from 'react-router-dom';
import styles from '../styles/Navbar.module.css';

export default function Navbar() {
  return (
    <nav className={styles.navbar}>
      <Link to="/">Harmocrew</Link>
      <Link to="/dj/dashboard">Dashboard DJ</Link>
      <Link to="/artist/dashboard">Dashboard Artista</Link>
      <Link to="/create-project">Novo Projeto</Link>
      <Link to="/">Login</Link>
    </nav>
  );
}
