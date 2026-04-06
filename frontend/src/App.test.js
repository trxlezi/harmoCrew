import { render, screen } from "@testing-library/react";
import LoadingState from "./components/ui/LoadingState";

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
