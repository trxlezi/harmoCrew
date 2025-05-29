import React, { useEffect, useState } from 'react';
import styles from '../styles/ProfilePage.module.css';
import { useAuth } from '../context/AuthContext';
import "../styles/global.css";
import "../styles/colors.css";

export default function ProfilePage() {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState('projetos');
  const [projects, setProjects] = useState([]);
  const [amigos, setAmigos] = useState([]);

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) return;

    fetch('http://localhost:5000/posts', {
      headers: {
        Authorization: `Bearer ${token}`
      }
    })
      .then(res => res.json())
      .then(data => {
        if (data.posts) {
          const userProjects = data.posts.filter(post => post.user_id === user.id);
          setProjects(userProjects);
        }
      });


    setAmigos([
        { id: 1, nome: "Lucas", foto: "https://i.pravatar.cc/150?u=lucas" },
        { id: 2, nome: "Ana", foto: "https://i.pravatar.cc/150?u=ana" }
      ]);
  }, [user]);

  return (
    <div className={styles.container}>
      <div className={styles.profileSidebar}>
      <img
  className={styles.userPhoto}
  src={`https://i.pravatar.cc/150?u=${user.id}`}
  alt="Foto de perfil"
/>
        <h2>{user.nome}</h2>
        <button className={styles.followButton}>Seguir</button>
        <p className={styles.description}>
          Este é um exemplo de descrição do usuário. Você pode atualizar sua bio mais tarde.
        </p>
      </div>

      <div className={styles.profileContent}>
        <div className={styles.tabs}>
          <button
            className={activeTab === 'projetos' ? styles.activeTab : ''}
            onClick={() => setActiveTab('projetos')}
          >
            Projetos
          </button>
          <button
            className={activeTab === 'amigos' ? styles.activeTab : ''}
            onClick={() => setActiveTab('amigos')}
          >
            Amigos
          </button>
        </div>

        {activeTab === 'projetos' && (
          <div className={styles.projects}>
            {projects.length === 0 ? (
              <p>Você ainda não criou nenhum projeto.</p>
            ) : (
              projects.map(post => (
                <div key={post.id} className={styles.projectCard}>
                  <p>{post.texto}</p>
                  <span>{post.data}</span>
                </div>
              ))
            )}
          </div>
        )}

        {activeTab === 'amigos' && (
          <div className={styles.friends}>
            {amigos.map(amigo => (
              <div key={amigo.id} className={styles.friendCard}>
                <img src={amigo.foto} alt="Amigo" />
                <span>{amigo.nome}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
