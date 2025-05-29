import React, { useEffect, useState } from "react";
import { useAuth } from "../context/AuthContext";
import "../styles/global.css";
import "../styles/colors.css";

const CandidatePage = () => {
  const { token } = useAuth();
  const [candidaturas, setCandidaturas] = useState([]);

  useEffect(() => {
    const fetchCandidaturas = async () => {
      const res = await fetch("http://localhost:5000/candidaturas", {
        headers: { Authorization: `Bearer ${token}` },
      });
      const data = await res.json();
      if (res.ok) setCandidaturas(data.candidaturas);
    };
    fetchCandidaturas();
  }, [token]);

  const handleAcao = async (candidaturaId, acao) => {
    const res = await fetch(`http://localhost:5000/candidaturas/${candidaturaId}/${acao}`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}` },
    });
    const data = await res.json();
    alert(data.message);
  };

  return (
    <div style={{ padding: "2rem", color: "white" }}>
      <h2>Candidaturas Recebidas</h2>
      {candidaturas.length === 0 ? (
        <p>Nenhuma candidatura recebida.</p>
      ) : (
        candidaturas.map((c) => (
          <div key={c.id} style={{ background: "#222", padding: "1rem", marginBottom: "1rem", borderRadius: "8px" }}>
            <p><strong>Post:</strong> {c.post_texto}</p>
            <p><strong>Artista:</strong> {c.nome_artista}</p>
            <button onClick={() => handleAcao(c.id, "aceitar")}>Aceitar</button>
            <button onClick={() => handleAcao(c.id, "rejeitar")}>Rejeitar</button>
          </div>
        ))
      )}
    </div>
  );
};

export default CandidatePage;
