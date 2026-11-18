import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../../../context/AuthContext";
import api, { errorMessage } from "../../../services/api";

export default function LoginPage() {
  const navigate = useNavigate();
  const { login } = useAuth();
  const [formData, setFormData] = useState({ email: "", password: "" });
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event) {
    event.preventDefault();
    setError("");
    setIsSubmitting(true);

    try {
      login(await api.auth.login(formData));
      navigate("/projetos");
    } catch (requestError) {
      setError(requestError?.response?.status === 401 ? "Email ou senha invalidos." : errorMessage(requestError, "Nao foi possivel entrar agora."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <section className="auth-shell">
      <div className="auth-hero">
        <span className="hero-kicker">HarmoCrew</span>
        <h1>Comunidade e oportunidades para musicos em um unico lugar.</h1>
        <p>
          Descubra talentos, publique projetos, acompanhe candidaturas e
          mantenha conversas com quem faz sentido para a sua jornada musical.
        </p>
        <div className="hero-pills">
          <span>Matching de musicos</span>
          <span>Versoes e decisoes</span>
          <span>Workflow e metricas</span>
        </div>
      </div>

      <form className="auth-card" onSubmit={handleSubmit}>
        <div className="auth-card-copy">
          <span className="section-eyebrow">Entrar</span>
          <h2>Volte para o seu ecossistema criativo</h2>
        </div>

        <label className="field">
          <span>Email</span>
          <input
            type="email"
            value={formData.email}
            onChange={(event) =>
              setFormData((current) => ({ ...current, email: event.target.value }))
            }
            placeholder="voce@harmocrew.com"
          />
        </label>

        <label className="field">
          <span>Senha</span>
          <input
            type="password"
            value={formData.password}
            onChange={(event) =>
              setFormData((current) => ({ ...current, password: event.target.value }))
            }
            placeholder="Sua senha"
          />
        </label>

        {error ? <div className="form-error">{error}</div> : null}

        <button type="submit" className="primary-button" disabled={isSubmitting}>
          {isSubmitting ? "Entrando..." : "Entrar na plataforma"}
        </button>

        <p className="auth-footnote">
          Ainda nao tem conta? <Link to="/register">Criar cadastro</Link>
        </p>
      </form>
    </section>
  );
}
