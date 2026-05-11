import React, { useEffect, useState } from "react";
import EmptyState from "../../../components/ui/EmptyState";
import LoadingState from "../../../components/ui/LoadingState";
import SectionHeader from "../../../components/ui/SectionHeader";
import SurfaceCard from "../../../components/ui/SurfaceCard";
import { useAuth } from "../../../context/AuthContext";
import api from "../../../services/api";
import ProfileHero from "../components/ProfileHero";

export default function ProfilePage() {
  const { updateUser } = useAuth();
  const [profile, setProfile] = useState(null);
  const [projects, setProjects] = useState([]);
  const [descriptionDraft, setDescriptionDraft] = useState("");
  const [linksDraft, setLinksDraft] = useState("");
  const [photoDraft, setPhotoDraft] = useState("");
  const [status, setStatus] = useState("loading");
  const [feedbackMessage, setFeedbackMessage] = useState("");

  useEffect(() => {
    async function loadProfile() {
      setStatus("loading");
      const [profileResponse, projectsResponse] = await Promise.all([
        api.profiles.me(),
        api.profiles.projects("me"),
      ]);

      const nextProfile = profileResponse.data.data.profile;
      setProfile(nextProfile);
      setDescriptionDraft(nextProfile.descricao || "");
      setLinksDraft(nextProfile.links_sociais || "");
      setPhotoDraft(nextProfile.profile_pic_url || "");
      setProjects(projectsResponse.data.data.projects || []);
      setStatus("ready");
    }

    loadProfile().catch((error) => {
      setProjects([]);
      setStatus("error");
      setFeedbackMessage(
        error?.response?.data?.error?.message ||
          "Nao foi possivel carregar seu perfil."
      );
    });
  }, []);

  async function handleSaveDescription() {
    try {
      const response = await api.profiles.updateDescription(descriptionDraft);
      setProfile(response.data.data.profile);
      updateUser((current) => ({ ...current, ...response.data.data.profile }));
      setFeedbackMessage("Descricao atualizada com sucesso.");
    } catch (error) {
      setFeedbackMessage(
        error?.response?.data?.error?.message ||
          "Nao foi possivel salvar a descricao."
      );
    }
  }

  async function handleSaveLinks() {
    try {
      const response = await api.profiles.updateLinks(linksDraft);
      setProfile(response.data.data.profile);
      updateUser((current) => ({ ...current, ...response.data.data.profile }));
      setFeedbackMessage("Links atualizados com sucesso.");
    } catch (error) {
      setFeedbackMessage(
        error?.response?.data?.error?.message ||
          "Nao foi possivel atualizar os links."
      );
    }
  }

  async function handleSavePhoto() {
    try {
      const response = await api.profiles.updatePhoto(photoDraft);
      setProfile(response.data.data.profile);
      updateUser((current) => ({ ...current, ...response.data.data.profile }));
      setFeedbackMessage("Foto de perfil atualizada com sucesso.");
    } catch (error) {
      setFeedbackMessage(
        error?.response?.data?.error?.message ||
          "Nao foi possivel atualizar a foto de perfil."
      );
    }
  }

  if (status === "loading") {
    return (
      <LoadingState
        title="Carregando seu perfil"
        description="Buscando sua apresentacao, links e publicacoes recentes."
      />
    );
  }

  if (!profile) {
    return (
      <EmptyState
        title="Perfil indisponivel"
        description={feedbackMessage || "Ainda nao foi possivel carregar suas informacoes."}
      />
    );
  }

  return (
    <div className="page-stack">
      <SectionHeader
        eyebrow="Perfil"
        title="Sua identidade profissional"
        subtitle="Apresente claramente quem voce e, o que busca e como outras pessoas podem colaborar."
      />

      {feedbackMessage ? <div className="inline-feedback">{feedbackMessage}</div> : null}

      <ProfileHero profile={profile} isCurrentUser isFollowing={false} onFollowToggle={() => {}} />

      <div className="page-grid">
        <section className="content-column">
          <SurfaceCard>
            <SectionHeader
              eyebrow="Descricao"
              title="Posicionamento artistico"
              subtitle="Defina seu momento criativo, estilo e tipo de parceria procurada."
            />
            <textarea
              rows={6}
              value={descriptionDraft}
              onChange={(event) => setDescriptionDraft(event.target.value)}
            />
            <button type="button" className="primary-button" onClick={handleSaveDescription}>
              Salvar descricao
            </button>
          </SurfaceCard>

          <SurfaceCard>
            <SectionHeader
              eyebrow="Projetos"
              title="Publicacoes no ecossistema"
              subtitle="Suas oportunidades recentes aparecem aqui como portfolio vivo."
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
                title="Sem publicacoes ainda"
                description="Crie uma oportunidade no hub explorar para comecar seu portfolio."
              />
            )}
          </SurfaceCard>
        </section>

        <aside className="sidebar-column">
          <SurfaceCard>
            <SectionHeader
              eyebrow="Foto"
              title="Imagem de perfil"
              subtitle="Use uma URL publica de imagem para atualizar sua apresentacao."
            />
            <label className="field">
              <span>URL da imagem</span>
              <input
                type="url"
                value={photoDraft}
                onChange={(event) => setPhotoDraft(event.target.value)}
                placeholder="https://..."
              />
            </label>
            <button type="button" className="secondary-button" onClick={handleSavePhoto}>
              Atualizar foto
            </button>
          </SurfaceCard>

          <SurfaceCard>
            <SectionHeader
              eyebrow="Links"
              title="Presenca digital"
              subtitle="Organize seus canais principais em um unico campo."
            />
            <textarea
              rows={6}
              value={linksDraft}
              onChange={(event) => setLinksDraft(event.target.value)}
              placeholder="Spotify, Instagram, SoundCloud, portfolio..."
            />
            <button type="button" className="secondary-button" onClick={handleSaveLinks}>
              Atualizar links
            </button>
          </SurfaceCard>
        </aside>
      </div>
    </div>
  );
}
