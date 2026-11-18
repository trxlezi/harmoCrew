import { useCallback, useEffect, useState } from "react";
import { errorMessage } from "../services/api";

// Carrega dados assincronos com estados de loading/erro e funcao de recarga.
export default function useLoader(loader, deps = []) {
  const [state, setState] = useState({ data: null, loading: true, error: "" });

  // eslint-disable-next-line react-hooks/exhaustive-deps
  const run = useCallback(loader, deps);

  const reload = useCallback(async () => {
    try {
      const data = await run();
      setState({ data, loading: false, error: "" });
    } catch (error) {
      setState({ data: null, loading: false, error: errorMessage(error, "Falha ao carregar.") });
    }
  }, [run]);

  useEffect(() => {
    setState((current) => ({ ...current, loading: true }));
    reload();
  }, [reload]);

  return { ...state, reload };
}
