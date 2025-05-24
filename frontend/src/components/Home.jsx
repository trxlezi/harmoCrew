import { useEffect, useState } from "react";
import styles from "../styles/Home.module.css";

const Home = ({ token, onLogout }) => {
  const [user, setUser] = useState(null);

  useEffect(() => {
    const fetchProfile = async () => {
      const res = await fetch("http://localhost:5000/profile", {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
      const data = await res.json();
      if (res.ok) {
        setUser(data.user);
      } else {
        alert(data.message || "Erro ao carregar perfil.");
        if (res.status === 401) {
          onLogout();
        }
      }
    };

    fetchProfile();
  }, [token, onLogout]);

  if (!user) return <p>Carregando perfil...</p>;

  return (
    <div className={styles.container}>
      <h1>Bem-vindo, {user.nome}!</h1>
      <p>Email: {user.email}</p>
      <button onClick={onLogout} className={styles.logoutButton}>
        Sair
      </button>
    </div>
  );
};

export default Home;
