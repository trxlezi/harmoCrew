import { render, screen } from "@testing-library/react";
import LoadingState from "./components/ui/LoadingState";
import ProfileHero from "./domains/profile/components/ProfileHero";

test("renders the redesign loading state copy", () => {
  render(
    <LoadingState
      title="Carregando harmocrew"
      description="Preparando o ecossistema musical."
    />
  );

  expect(screen.getByText(/carregando harmocrew/i)).toBeInTheDocument();
  expect(screen.getByText(/preparando o ecossistema musical/i)).toBeInTheDocument();
});

test("renders profile photo when a profile image URL exists", () => {
  const { container } = render(
    <ProfileHero
      profile={{
        nome: "Ana Silva",
        descricao: "Vocalista",
        profile_pic_url: "https://example.com/profile.jpg",
      }}
      isCurrentUser
      isFollowing={false}
      onFollowToggle={() => {}}
    />
  );

  expect(container.querySelector(".profile-avatar img")).toHaveAttribute(
    "src",
    "https://example.com/profile.jpg"
  );
});
