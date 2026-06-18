# Integracao Mobile com HarmoCrew API

## Repositorios

- frontend/mobile: `harmoCrew`
- backend/API: `api-harmocrew`

Os repositorios continuam separados. O backend nao foi copiado para o frontend e o frontend nao foi copiado para o backend.

## Como subir backend

Com NGINX e duas instancias da API:

```powershell
cd ..\api-harmocrew
docker compose -f docker-compose.nginx.yml up --build
```

Validar:

```powershell
curl http://localhost:8080/health
```

URLs:

- navegador/desktop: `http://localhost:8080`
- Android Emulator: `http://10.0.2.2:8080`
- celular fisico: `http://IP_DA_MAQUINA:8080`
- Swagger: `http://localhost:8080/swagger-ui.html`
- Swagger alternativo: `http://localhost:8080/swagger-ui/index.html`

## Como rodar mobile integrado

Modo mock, padrao para demonstracao offline:

```powershell
cd mobile
flutter pub get
flutter run --dart-define=USE_MOCKS=true
```

Modo API real no Android Emulator:

```powershell
flutter run --dart-define=USE_MOCKS=false --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Modo API real no desktop/navegador:

```powershell
flutter run --dart-define=USE_MOCKS=false --dart-define=API_BASE_URL=http://localhost:8080
```

Build APK:

```powershell
flutter build apk --debug
```

## Funcionalidades integradas

- Auth:
  - `POST /auth/register`
  - `POST /auth/login`
  - `POST /auth/logout`
  - token JWT em memoria via `ApiSession`
  - envio de `Authorization: Bearer TOKEN`
- Artistas/Talentos:
  - `GET /api/artists`
  - `POST /api/artists`
- Projetos:
  - `GET /api/projects`
- Tarefas:
  - `GET /api/tasks`
  - `GET /api/projects/{projectId}/tasks`
  - `POST /api/projects/{projectId}/tasks`
  - `PATCH /api/tasks/{id}/status`
- Candidaturas:
  - `GET /api/applications`
  - `GET /api/projects/{projectId}/applications`
  - `POST /api/projects/{projectId}/applications`
  - `PATCH /api/applications/{id}/status`

## Funcionalidades ainda mockadas

- Ensaios
- Mensagens
- Decisoes
- Metas semanais
- Responsabilidades
- Detalhes demonstrativos

Essas telas continuam usando `MockCollaborationStore` como fallback academico e modo demonstracao.

## Evidencias recomendadas

- Print de `docker compose -f docker-compose.nginx.yml ps`.
- Print do Swagger.
- Print do app fazendo login com `USE_MOCKS=false`.
- Print de Talentos/Projetos carregando dados da API.
- Print de criacao de talento, tarefa ou candidatura com SnackBar.
- Print de alteracao de status de tarefa ou candidatura.
