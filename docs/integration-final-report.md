# Relatorio Final de Integracao - HarmoCrew

Data: 2026-06-17

## Backend validado

Sim.

Resultados:

- `git status --short --branch`: `## main...origin/main`
- `.\mvnw clean test`: sucesso, 10 testes, 0 falhas, 0 erros, 0 ignorados
- Docker ativo: sim
- `docker compose -f docker-compose.nginx.yml up --build -d`: sucesso
- `docker compose -f docker-compose.nginx.yml ps`: `api-1`, `api-2`, `postgres` e `nginx` Up; Postgres healthy
- `GET http://localhost:8080/health`: retornou `status: UP`
- `http://localhost:8080/swagger-ui.html`: HTTP 200
- `http://localhost:8080/v3/api-docs`: HTTP 200

## Mobile validado

Sim.

Resultados antes da integracao:

- `flutter pub get`: sucesso
- `flutter analyze`: sucesso
- `flutter build apk --debug`: sucesso
- `flutter test`: falhava porque a pasta `test/` nao existia

Correcao aplicada:

- Adicionado `flutter_test` em `dev_dependencies`
- Criado `mobile/test/smoke_test.dart`

## Integracao implementada

Sim.

Modo padrao:

- `USE_MOCKS=true`, mantendo demonstracao offline.

Modo API:

- `USE_MOCKS=false`
- `API_BASE_URL` configuravel por `dart-define`

## Endpoints usados

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/logout`
- `GET /api/artists`
- `POST /api/artists`
- `GET /api/projects`
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
- Candidaturas
- Kanban, indiretamente pelo mesmo store de tarefas

## Telas ainda mockadas

- Ensaios
- Mensagens
- Decisoes
- Metas semanais
- Responsabilidades
- Detalhes demonstrativos

## Arquivos alterados

No `harmoCrew`:

- `docs/api-integration-plan.md`
- `docs/integration-final-report.md`
- `docs/integration-readiness.md`
- `docs/mobile-api-integration.md`
- `mobile/pubspec.yaml`
- `mobile/pubspec.lock`
- `mobile/test/smoke_test.dart`
- `mobile/lib/core/api/api_client.dart`
- `mobile/lib/core/api/api_config.dart`
- `mobile/lib/core/api/api_exception.dart`
- `mobile/lib/core/api/api_session.dart`
- `mobile/lib/app/widgets/app_scaffold.dart`
- `mobile/lib/features/auth/data/auth_api_service.dart`
- `mobile/lib/features/auth/data/mock_auth_store.dart`
- `mobile/lib/features/auth/domain/auth_user.dart`
- `mobile/lib/features/auth/presentation/login_screen.dart`
- `mobile/lib/features/auth/presentation/register_screen.dart`
- `mobile/lib/features/members/data/artist_api_service.dart`
- `mobile/lib/features/members/presentation/talents_screen.dart`
- `mobile/lib/features/projects/data/project_api_service.dart`
- `mobile/lib/features/projects/presentation/projects_screen.dart`
- `mobile/lib/features/collaboration/data/application_api_service.dart`
- `mobile/lib/features/collaboration/data/task_api_service.dart`
- `mobile/lib/features/collaboration/screens/applications_screen.dart`
- `mobile/lib/features/collaboration/screens/tasks_screen.dart`
- `mobile/lib/features/collaboration/stores/mock_collaboration_store.dart`

No `api-harmocrew`:

- Nenhum arquivo alterado.

## Comandos de execucao

Backend:

```powershell
cd ..\api-harmocrew
.\mvnw clean test
docker compose -f docker-compose.nginx.yml up --build
curl http://localhost:8080/health
```

Mobile:

```powershell
cd ..\harmoCrew\mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter run --dart-define=USE_MOCKS=false --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

## Pendencias

- Teste manual completo em emulador/celular fisico ainda deve ser registrado com prints.
- Candidatura via API exige `artistId` numerico. O app usa o primeiro artista carregado da API como fallback quando o login nao retorna `artistId`.
- Ensaios, mensagens, decisoes, metas semanais e responsabilidades continuam mockados.

## O que commitar

No `harmoCrew`:

- Documentacao de integracao.
- Camada API Flutter.
- Services de auth, artistas, projetos, tarefas e candidaturas.
- Ajustes das telas integradas.
- Teste smoke e dependencias `http`/`flutter_test`.

No `api-harmocrew`:

- Nada, pois o backend nao foi alterado.

## O que nao commitar

- Arquivos de build gerados.
- Mudancas automaticas de migrador Flutter em arquivos Android/desktop, se aparecerem apenas como artefatos de ferramenta sem decisao do grupo.
- Containers, volumes ou logs locais de Docker.
