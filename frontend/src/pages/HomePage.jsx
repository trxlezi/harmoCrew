import React, { useEffect, useState } from "react";
import styles from "../styles/HomePage.module.css";
import { useAuth } from "../context/AuthContext";
import "../styles/global.css";
import "../styles/colors.css";

const HomePage = () => {
  const { token, user, logout } = useAuth();
  const [posts, setPosts] = useState([]);
  const [newPostText, setNewPostText] = useState("");
  const [loading, setLoading] = useState(false);
  const [selectedPost, setSelectedPost] = useState(null);
  const [showNewPostModal, setShowNewPostModal] = useState(false);

  const [searchTerm, setSearchTerm] = useState("");
  const [searchResults, setSearchResults] = useState([]);

  useEffect(() => {
    const fetchPosts = async () => {
      try {
        const res = await fetch("http://localhost:5000/posts", {
          headers: { Authorization: `Bearer ${token}` },
        });
        const data = await res.json();
        if (res.ok) {
          setPosts(data.posts);
        } else {
          alert(data.message || "Erro ao carregar posts.");
          if (res.status === 401) logout();
        }
      } catch (err) {
        alert("Erro de conexão com o servidor.");
      }
    };
    fetchPosts();
  }, [token, logout]);

  useEffect(() => {
    const delayDebounce = setTimeout(() => {
      if (searchTerm.trim()) {
        fetch(`http://localhost:5000/search_users?q=${encodeURIComponent(searchTerm)}`, {
          headers: { Authorization: `Bearer ${token}` },
        })
          .then((res) => res.json())
          .then((data) => setSearchResults(data.users || []))
          .catch(() => setSearchResults([]));
      } else {
        setSearchResults([]);
      }
    }, 500);

    return () => clearTimeout(delayDebounce);
  }, [searchTerm, token]);

  const handleCreatePost = async (e) => {
    e.preventDefault();
    if (!newPostText.trim()) {
      alert("Digite algo para postar!");
      return;
    }

    setLoading(true);
    try {
      const res = await fetch("http://localhost:5000/posts", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ texto: newPostText }),
      });

      const data = await res.json();

      if (res.ok) {
        setPosts([data.post, ...posts]);
        setNewPostText("");
        setShowNewPostModal(false);
      } else {
        alert(data.message || "Erro ao criar post.");
        if (res.status === 401) logout();
      }
    } catch (err) {
      alert("Erro de conexão com o servidor.");
    }
    setLoading(false);
  };

  const handleCandidatar = async (postId) => {
    try {
      const res = await fetch(`http://localhost:5000/candidatar/${postId}`, {
        method: "POST",
        headers: { Authorization: `Bearer ${token}` },
      });
      const data = await res.json();
      alert(data.message || "Candidatura enviada!");
    } catch (err) {
      alert("Erro ao se candidatar.");
    }
    setSelectedPost(null);
  };

  return (
    <div className={styles.wrapper}>
      {/* Sidebar esquerda */}
      <aside className={styles.sidebarLeft}>
        <nav>
          <ul>
            <li><a href="/home">Início</a></li>
            <li>
              <button className={styles.linkButton} onClick={() => setShowNewPostModal(true)}>
                Novo Projeto
              </button>
            </li>
            <li><a href="/candidaturas">Candidaturas</a></li>
            <li><a href="/configuracoes">Configurações</a></li>
          </ul>
        </nav>
      </aside>

      <main className={styles.feed}>
        <h2 className={styles.title}>Timeline Musical</h2>
        {posts.length === 0 ? (
          <p>Nenhum post disponível.</p>
        ) : (
          posts.map((post) => (
            <div
              key={post.id}
              className={styles.postCard}
              onClick={() => setSelectedPost(post)}
            >
              <strong>{post.nome}</strong>
              <p>{post.texto}</p>
              <small>{post.data}</small>
            </div>
          ))
        )}
      </main>

      <aside className={styles.sidebarRight}>
        <input
          className={styles.search}
          type="text"
          placeholder="Buscar artistas..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
        {searchResults.length > 0 && (
          <div className={styles.searchResults}>
            {searchResults.map((u) => (
              <div key={u.id} className={styles.searchResultItem}>
                <strong>{u.nome}</strong>
                <p>{u.email}</p>
              </div>
            ))}
          </div>
        )}
      </aside>

      {selectedPost && (
        <div className={styles.overlay} onClick={() => setSelectedPost(null)}>
          <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
            <h3>{selectedPost.nome}</h3>
            <p>{selectedPost.texto}</p>
            <small>{selectedPost.data}</small>

            {selectedPost.user_id !== user?.id && (
              <button onClick={() => handleCandidatar(selectedPost.id)}>
                Candidatar-se
              </button>
            )}

            <div style={{ marginTop: "1rem", textAlign: "right" }}>
              <button
                className={styles.cancelButton}
                onClick={() => setSelectedPost(null)}
              >
                Fechar
              </button>
            </div>
          </div>
        </div>
      )}

      {showNewPostModal && (
        <div className={styles.overlay} onClick={() => setShowNewPostModal(false)}>
          <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
            <h3>Criar Novo Projeto</h3>
            <form onSubmit={handleCreatePost}>
              <textarea
                placeholder="No que você está trabalhando?"
                value={newPostText}
                onChange={(e) => setNewPostText(e.target.value)}
                rows={4}
                className={styles.textarea}
              />
              <div className={styles.modalActions}>
                <button
                  type="submit"
                  className={styles.publishButton}
                  disabled={loading}
                >
                  {loading ? "Publicando..." : "Publicar"}
                </button>
                <button
                  type="button"
                  className={styles.cancelButton}
                  onClick={() => setShowNewPostModal(false)}
                >
                  Cancelar
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default HomePage;
