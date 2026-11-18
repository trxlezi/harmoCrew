import React, { useMemo, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import api from "../../../services/api";

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default function RegisterPage() {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    nome: "",
    email: "",
    senha: "",
    confirmSenha: "",
  });
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const passwordChecks = useMemo(
    () => [
      { label: "8 caracteres", valid: formData.senha.length >= 8 },
      { label: "1 letra maiuscula", valid: /[A-Z]/.test(formData.senha) },
      { label: "1 numero", valid: /\d/.test(formData.senha) },
      { label: "1 simbolo", valid: /[^A-Za-z0-9]/.test(formData.senha) },
    ],
    [formData.senha]
  );

  async function handleSubmit(event) {
    event.preventDefault();

    if (!EMAIL_REGEX.test(formData.email)) {
      setError("Informe um email valido.");
      return;
    }

    if (formData.senha !== formData.confirmSenha) {
      setError("As senhas precisam coincidir.");
      return;
    }

    setError("");
    setIsSubmitting(true);

    try {
      await api.auth.register({
        nome: formData.nome,
        email: formData.email,
        senha: formData.senha,
      });
      navigate("/login");
    } catch (requestError) {
      setError(
        requestError?.response?.data?.error?.message ||
          "Nao foi possivel criar sua conta."
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <section className="auth-shell auth-shell--register">
      <div className="auth-hero">
        <span className="hero-kicker">Perfil profissional + comunidade</span>
        <h1>Monte sua presenca artistica e encontre projetos certos.</h1>
        <p>
          O novo HarmoCrew organiza sua trajetoria musical em torno de
          descoberta, oportunidades e relacionamento profissional.
        </p>
      </div>

      <form className="auth-card" onSubmit={handleSubmit}>
        <div className="auth-card-copy">
          <span className="section-eyebrow">Criar conta</span>
          <h2>Entre com uma identidade pronta para colaborar</h2>
        </div>

        <label className="field">
          <span>Nome artistico ou completo</span>
          <input
            type="text"
            value={formData.nome}
            onChange={(event) =>
              setFormData((current) => ({ ...current, nome: event.target.value }))
            }
            placeholder="Seu nome"
          />
        </label>

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
            value={formData.senha}
            onChange={(event) =>
              setFormData((current) => ({ ...current, senha: event.target.value }))
            }
            placeholder="Crie uma senha forte"
          />
        </label>

        <label className="field">
          <span>Confirmar senha</span>
          <input
            type="password"
            value={formData.confirmSenha}
            onChange={(event) =>
              setFormData((current) => ({
                ...current,
                confirmSenha: event.target.value,
              }))
            }
            placeholder="Repita a senha"
          />
        </label>

        <div className="password-grid">
          {passwordChecks.map((check) => (
            <span
              key={check.label}
              className={`status-pill status-pill--${check.valid ? "success" : "neutral"}`}
            >
              {check.label}
            </span>
          ))}
        </div>

        {error ? <div className="form-error">{error}</div> : null}

        <button type="submit" className="primary-button" disabled={isSubmitting}>
          {isSubmitting ? "Criando..." : "Criar conta"}
        </button>

        <p className="auth-footnote">
          Ja tem cadastro? <Link to="/login">Entrar</Link>
        </p>
      </form>
    </section>
  );
}
