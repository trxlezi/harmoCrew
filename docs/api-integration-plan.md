# Plano de Integracao Mobile com API REST - HarmoCrew

## Repositorios envolvidos

- Frontend/mobile: `harmoCrew`
- Backend/API REST: `api-harmocrew`

O backend continua independente como entrega da disciplina de Back-end. O mobile continua independente como entrega da disciplina Mobile. A integracao acontece apenas no app Flutter, consumindo a API REST por HTTP.

## URLs base

- Android Emulator: `http://10.0.2.2:8080`
- Navegador/desktop: `http://localhost:8080`
- Celular fisico: `http://IP_DA_MAQUINA:8080`

Configuracao por `dart-define`:

```powershell
flutter run --dart-define=USE_MOCKS=false --dart-define=API_BASE_URL=http://10.0.2.2:8080
flutter run --dart-define=USE_MOCKS=true
```

`USE_MOCKS=true` mantem o modo demonstracao local. `USE_MOCKS=false` ativa consumo real da API.

## Endpoints usados

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/logout`
- `GET /api/artists`
- `POST /api/artists`
- `GET /api/projects`
- `GET /api/projects/{id}`
- `POST /api/projects`
- `GET /api/tasks`
- `GET /api/projects/{projectId}/tasks`
- `POST /api/projects/{projectId}/tasks`
- `PATCH /api/tasks/{id}/status`
- `GET /api/applications`
- `GET /api/projects/{projectId}/applications`
- `POST /api/projects/{projectId}/applications`
- `PATCH /api/applications/{id}/status`

## Telas integradas

- Login
- Cadastro
- Talentos
- Projetos
- Tarefas
- Kanban indiretamente pelo mesmo store de tarefas
- Candidaturas

## Telas que continuam mockadas

- Ensaios
- Metas semanais
- Decisoes
- Mensagens
- Responsabilidades
- Detalhes demonstrativos

Essas telas continuam usando `MockCollaborationStore` como fallback academico.

## Estrategia fallback mock/API

- O app usa mocks por padrao para preservar a apresentacao offline.
- Ao iniciar com `USE_MOCKS=false`, repositories e services chamam a API real.
- Se uma chamada de listagem falhar, a tela exibe SnackBar e mantem os dados locais ja existentes.
- Criacoes e mudancas de status usam API no modo integrado; se falharem, a tela avisa sem quebrar a navegacao.

## Token JWT

- O token retornado por login/cadastro fica em memoria no `ApiSession`.
- O `ApiClient` envia `Authorization: Bearer TOKEN` nas chamadas protegidas.
- Logout chama `/auth/logout` quando ha token e depois limpa a sessao local.

## Como testar

Backend:

```powershell
cd ..\api-harmocrew
docker compose -f docker-compose.nginx.yml up --build
curl http://localhost:8080/health
```

Mobile:

```powershell
cd ..\harmoCrew\mobile
flutter pub get
flutter run --dart-define=USE_MOCKS=false --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Fluxo manual:

- cadastrar usuario;
- fazer login;
- abrir Talentos e Projetos;
- criar talento;
- criar tarefa;
- alterar status no Kanban/Tarefas;
- criar candidatura;
- alterar status da candidatura;
- fazer logout.
