import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import EmptyState from "../../../components/ui/EmptyState";
import LoadingState from "../../../components/ui/LoadingState";
import SectionHeader from "../../../components/ui/SectionHeader";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import api from "../../../services/api";
import ProfileHero from "../components/ProfileHero";

export default function PublicProfilePage() {
  const { id } = useParams();
  const [profile, setProfile] = useState(null);
  const [projects, setProjects] = useState([]);
  const [status, setStatus] = useState("loading");
  const [feedbackMessage, setFeedbackMessage] = useState("");

  useEffect(() => {
    async function loadProfile() {
      setStatus("loading");
      const [profileResponse, projectsResponse] = await Promise.all([
        api.profiles.byId(id),
        api.profiles.projects(id),
      ]);
      setProfile(profileResponse.data.data.profile);
      setProjects(projectsResponse.data.data.projects || []);
      setStatus("ready");
    }

    loadProfile().catch((error) => {
      setProfile(null);
      setProjects([]);
      setStatus("error");
      setFeedbackMessage(
        error?.response?.data?.error?.message ||
          "Nao foi possivel carregar este perfil."
      );
    });
  }, [id]);

  async function handleFollowToggle() {
    if (!profile) {
      return;
    }

    const action = profile.is_following ? api.profiles.unfollow : api.profiles.follow;
    const response = await action(profile.id);
    setProfile(response.data.data.profile);
  }

  if (status === "loading") {
    return (
      <LoadingState
        title="Carregando perfil publico"
        description="Buscando portfolio e sinais de alinhamento deste talento."
      />
    );
  }

  if (!profile) {
    return (
      <EmptyState
        title="Perfil nao encontrado"
        description={feedbackMessage || "Esse talento pode ter sido removido ou ainda nao esta disponivel."}
      />
    );
  }

  return (
    <div className="page-stack">
      <SectionHeader
        eyebrow="Perfil publico"
        title="Conheca melhor este talento"
        subtitle="Veja portfolio, descricao e sinais de alinhamento antes de iniciar uma conversa."
      />
      <ProfileHero
        profile={profile}
        isCurrentUser={false}
        isFollowing={profile.is_following}
        onFollowToggle={handleFollowToggle}
      />

      <SurfaceCard>
        <SectionHeader
          eyebrow="Projetos recentes"
          title="Publicacoes visiveis deste perfil"
          subtitle="Uma leitura rapida do repertorio recente."
        />
        {projects.length ? (
          <div className="card-stack">
            {projects.map((project) => (
              <div key={project.id} className="list-row-button list-row-button--static">
                <strong>{project.titulo}</strong>
                <span>{project.texto}</span>
              </div>
            ))}
          </div>
        ) : (
          <EmptyState
            title="Sem projetos publicados"
            description="Quando este perfil publicar uma oportunidade, ela aparecera aqui."
          />
        )}
      </SurfaceCard>
    </div>
  );
}
