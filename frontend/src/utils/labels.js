// Rotulos em portugues para os enums da API.
export const STAGES = [
  ["COMPOSITION", "Composição"],
  ["ARRANGEMENT", "Arranjo"],
  ["RECORDING", "Gravação"],
  ["MIXING", "Mixagem"],
  ["RELEASE", "Lançamento"],
];
export const stageLabel = (s) => (STAGES.find(([k]) => k === s) || [s, "Sem etapa"])[1];

export const TASK_STATUS = [
  ["TODO", "A fazer"],
  ["IN_PROGRESS", "Em andamento"],
  ["DONE", "Concluída"],
];
export const taskStatusLabel = (s) => (TASK_STATUS.find(([k]) => k === s) || [s, s])[1];

export const PRIORITY = { LOW: "Baixa", MEDIUM: "Média", HIGH: "Alta" };

export const APPLICATION_STATUS = {
  PENDING: ["Pendente", "neutral"],
  UNDER_REVIEW: ["Em análise", "accent"],
  SHORTLISTED: ["Pré-selecionado", "warning"],
  APPROVED: ["Aprovado", "success"],
  REJECTED: ["Recusado", "danger"],
};

export const FILE_CATEGORY = {
  AUDIO_GUIDE: "Guia de áudio",
  ARRANGEMENT: "Arranjo",
  SHEET_PDF: "Partitura (PDF)",
  LYRICS: "Letra",
  SETLIST: "Setlist",
  OTHER: "Outro",
};

export const CRITERIA = {
  STYLE: "Estilo",
  INSTRUMENTS: "Instrumentos",
  INFLUENCES: "Influências",
  LOCATION: "Localização",
};

export function formatDate(value) {
  if (!value) return "—";
  const date = new Date(value.length === 10 ? `${value}T12:00:00` : value);
  return date.toLocaleDateString("pt-BR");
}

export function formatDateTime(value) {
  if (!value) return "—";
  return new Date(value).toLocaleString("pt-BR", { dateStyle: "short", timeStyle: "short" });
}

export function formatBytes(bytes) {
  if (bytes == null) return "";
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}

export const splitList = (text) =>
  text
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
