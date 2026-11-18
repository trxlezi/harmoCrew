import React, { useEffect, useState } from "react";
import EmptyState from "../../../components/ui/EmptyState";
import LoadingState from "../../../components/ui/LoadingState";
import SectionHeader from "../../../components/ui/SectionHeader";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import api from "../../../services/api";
import FeedCard from "../components/FeedCard";
import PostComposer from "../components/PostComposer";
import { capitalizeName } from "../../../utils/formatters";

function formatFeedItem(item) {
  return {
    ...item,
    created_label: new Date(item.created_at || item.data || Date.now()).toLocaleDateString(
      "pt-BR"
    ),
  };
}

export default function ExplorePage() {
  const [feed, setFeed] = useState({
    highlights: [],
    posts: [],
    opportunities: [],
    suggested_profiles: [],
  });
  const [status, setStatus] = useState("loading");
  const [feedbackMessage, setFeedbackMessage] = useState("");

  async function loadFeed() {
    setStatus("loading");
    setFeedbackMessage("");
    try {
      const response = await api.feed.getHomeFeed();
      setFeed(response.data.data);
      setStatus("ready");
    } catch (error) {
      setFeedbackMessage(
        error?.response?.data?.error?.message ||
          "O backend ainda nao respondeu com o novo feed."
      );
      setStatus("error");
    }
  }

  useEffect(() => {
    loadFeed();
  }, []);

  async function handleCreateOpportunity(payload) {
    try {
      setFeedbackMessage("");
      await api.opportunities.create(payload);
      await loadFeed();
      setFeedbackMessage("Oportunidade publicada com sucesso.");
    } catch (error) {
      setFeedbackMessage(
        error?.response?.data?.error?.message ||
          "Nao foi possivel publicar a oportunidade."
      );
    }
  }

  async function handleApply(opportunityId) {
    try {
      setFeedbackMessage("");
      await api.opportunities.apply(opportunityId);
      await loadFeed();
      setFeedbackMessage("Candidatura enviada com sucesso.");
    } catch (error) {
      setFeedbackMessage(
        error?.response?.data?.error?.message ||
          "Nao foi possivel enviar a candidatura."
      );
    }
  }

  return (
    <div className="page-stack">
      <SectionHeader
        eyebrow="Explorar"
        title="Descubra talentos e projetos"
        subtitle="Um hub para acompanhar comunidade, vagas musicais e novas colaboracoes em ritmo profissional."
      />

      <div className="hero-grid">
        <SurfaceCard className="hero-panel hero-panel--feature">
          <span className="section-eyebrow">Curadoria</span>
          <h2>Uma visao equilibrada entre comunidade e recrutamento.</h2>
          <p>
            A nova home mistura oportunidades abertas, atividade recente e
            perfis sugeridos para acelerar conexoes que realmente avancam
            projetos.
          </p>
        </SurfaceCard>
        <PostComposer onSubmit={handleCreateOpportunity} />
      </div>

      {feedbackMessage ? (
        <SurfaceCard className="feedback-card">
          <p>{feedbackMessage}</p>
        </SurfaceCard>
      ) : null}

      <div className="page-grid">
        <section className="content-column">
          <div className="section-block">
            <SectionHeader
              eyebrow="Feed"
              title="Projetos em destaque"
              subtitle="Chamadas recentes de artistas e produtores em busca da proxima colaboracao."
            />

            {status === "loading" ? (
              <LoadingState
                title="Montando seu hub"
                description="Estamos reunindo oportunidades, perfis e publicacoes recentes."
              />
            ) : null}

            {status === "error" ? (
              <EmptyState
                title="Nao foi possivel carregar o feed"
                description={feedbackMessage || "Tente novamente quando o backend estiver disponivel."}
                action={
                  <button type="button" className="secondary-button" onClick={loadFeed}>
                    Tentar novamente
                  </button>
                }
              />
            ) : null}

            {status === "ready" && feed.posts.length === 0 ? (
              <EmptyState
                title="Ainda nao ha projetos publicados"
                description="Seu primeiro anuncio pode abrir a proxima parceria certa."
              />
            ) : null}

            <div className="card-stack">
              {feed.posts.map((post) => (
                <FeedCard key={post.id} item={formatFeedItem(post)} onApply={handleApply} />
              ))}
            </div>
          </div>
        </section>

        <aside className="sidebar-column">
          <SurfaceCard>
            <SectionHeader
              eyebrow="Oportunidades"
              title="Chamadas abertas"
              subtitle="Uma amostra rapida das oportunidades em andamento."
            />
            <div className="mini-list">
              {feed.opportunities.slice(0, 4).map((opportunity) => (
                <button
                  key={opportunity.id}
                  type="button"
                  className="list-row-button"
                  onClick={() => handleApply(opportunity.id)}
                >
                  <strong>{opportunity.titulo}</strong>
                  <span>{opportunity.nome}</span>
                </button>
              ))}
            </div>
          </SurfaceCard>

          <SurfaceCard>
            <SectionHeader
              eyebrow="Perfis sugeridos"
              title="Talentos para acompanhar"
              subtitle="Perfis com atividade recente e fit com o ecossistema."
            />
            <div className="mini-list">
              {feed.suggested_profiles.map((profile) => (
                <a key={profile.id} className="list-row-button" href={`/perfil/${profile.id}`}>
                  <strong>{capitalizeName(profile.nome)}</strong>
                  <span>{profile.headline || profile.email}</span>
                </a>
              ))}
            </div>
          </SurfaceCard>
        </aside>
      </div>
    </div>
  );
}
