# Resumo tecnico do projeto HarmoCrew para Claude

## Visao geral

HarmoCrew e uma plataforma academica de colaboracao musical. A ideia central e
ajudar musicos e artistas a encontrar colaboradores, organizar projetos
musicais, controlar tarefas, candidaturas, ensaios, decisoes, mensagens e metas
semanais.

O produto esta dividido em dois repositorios independentes:

- `api-harmocrew`: backend/API REST da disciplina Desenvolvimento Web Back-end.
- `harmoCrew`: repositorio do mobile/frontend, com app Flutter em `mobile/`,
  usado na disciplina Desenvolvimento para Dispositivos Moveis.

A integracao entre eles e feita por HTTP/JSON. O app Flutter nao possui backend
proprio; ele consome a API Spring Boot.

## Backend: api-harmocrew

Repositorio:

- `https://github.com/trxlezi/api-harmocrew`

Papel academico:

- entrega de Web Back-end.

Tecnologias:

- Java 21
- Maven Wrapper
- Spring Boot 4.0.6
- Spring WebMVC
- Spring Data JPA
- Hibernate
- Spring Security
- JWT
- BCrypt
- PostgreSQL
- H2 em testes
- Swagger/OpenAPI
- Docker
- NGINX
- JMeter

Estrutura principal:

- `controllers`
- `entities`
- `services`
- `repositories`
- `dtos`
- `dtos/mapper`
- `security`
- `config`
- `exceptions`
- `enums`

Controllers:

- `AuthController`
- `HealthController`
- `ArtistController`
- `MusicalProjectController`
- `TaskController`
- `ApplicationController`
- `RehearsalController`
- `WeeklyGoalController`
- `DecisionRecordController`
- `CollaborationMessageController`

Entidades:

- `User`
- `Artist`
- `MusicalProject`
- `Task`
- `Application`
- `Rehearsal`
- `WeeklyGoal`
- `DecisionRecord`
- `CollaborationMessage`

Relacionamentos principais:

- `User` 1:1 `Artist`
- `MusicalProject` 1:N `Task`
- `MusicalProject` N:N `Artist`
- `Artist` 1:N `Application`
- `MusicalProject` 1:N `Application`
- `MusicalProject` 1:N `Rehearsal`
- `MusicalProject` 1:N `CollaborationMessage`
- `MusicalProject` 1:N `DecisionRecord`
- `MusicalProject` 1:N `WeeklyGoal`
- `Artist` 1:N `WeeklyGoal`
- `Artist` 1:N `DecisionRecord`
- `Artist` 1:N `CollaborationMessage`

Autenticacao e seguranca:

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/logout`
- aliases em `/api/auth`
- senhas com BCrypt
- JWT Bearer Token
- rotas protegidas com `Authorization: Bearer <token>`
- Swagger/OpenAPI com esquema Bearer
- logout com blacklist em memoria

Observacao importante:

- Em ambiente com NGINX e duas instancias, a blacklist de logout fica em memoria
  e nao e compartilhada entre `api-1` e `api-2`.

Endpoints principais:

- `GET /health`
- `/api/artists`
- `/api/projects`
- `/api/tasks`
- `/api/applications`
- `/api/rehearsals`
- `/api/weekly-goals`
- `/api/decisions`
- `/api/messages`

CRUDs:

- CRUD completo: `Artist`, `MusicalProject`, `Task`, `Rehearsal`,
  `WeeklyGoal`, `DecisionRecord`.
- Operacoes parciais: `Application`, `CollaborationMessage`, `User` via auth.

Swagger:

- `http://localhost:8080/swagger-ui.html`
- `http://localhost:8080/swagger-ui/index.html`
- `http://localhost:8080/v3/api-docs`

Docker:

- `docker-compose.yml`: PostgreSQL + 1 instancia da API.
- `docker-compose.nginx.yml`: PostgreSQL + `api-1` + `api-2` + NGINX.
- `nginx/nginx.conf`: upstream `harmocrew_api`, algoritmo `least_conn`,
  servidores `api-1:8080` e `api-2:8080`.

Testes automatizados:

- comando: `./mvnw clean test`
- resultado documentado: 10 testes, 0 falhas, 0 erros, 0 ignorados.

Testes funcionais:

- arquivo: `docs/functional-tests.http`
- cobre health, register, login, logout, Bearer Token, Artist, MusicalProject,
  Task e Application.

JMeter:

- arquivo de plano: `docs/performance/harmocrew-performance-test.jmx`
- resumo: `docs/performance/performance-results-summary.md`
- dashboards HTML:
  - `docs/performance/report-sem-nginx/index.html`
  - `docs/performance/report-com-nginx/index.html`

Resultados sem NGINX:

- 1000 requisicoes
- 0 erros
- taxa de erro 0%
- media 3,27 ms
- mediana 3 ms
- P90 5 ms
- P95 6 ms
- P99 10 ms
- throughput 34,06 req/s

Resultados com NGINX:

- 1000 requisicoes
- 0 erros
- taxa de erro 0%
- media 52,57 ms
- mediana 19 ms
- P90 72 ms
- P95 115 ms
- P99 511 ms
- throughput 34,72 req/s

Conclusao dos testes de performance:

- ambos os cenarios tiveram 0% de erro;
- sem NGINX teve menor latencia;
- com NGINX validou balanceamento entre duas instancias com throughput
  semelhante.

## Frontend/mobile: harmoCrew/mobile

Repositorio:

- `https://github.com/trxlezi/harmoCrew`

Papel academico:

- entrega de Desenvolvimento para Dispositivos Moveis.

Tecnologias:

- Flutter
- Dart SDK `^3.11.4`
- Material Components
- tema escuro
- rotas nomeadas
- pacote `http: ^1.6.0`
- `flutter_test`
- `flutter_lints`

Estrutura principal:

- `mobile/lib/app`
- `mobile/lib/app/widgets`
- `mobile/lib/core/api`
- `mobile/lib/core/theme`
- `mobile/lib/features/auth`
- `mobile/lib/features/home`
- `mobile/lib/features/projects`
- `mobile/lib/features/members`
- `mobile/lib/features/collaboration`
- `mobile/lib/features/profile`
- `mobile/lib/features/details`
- `mobile/test`

Arquivos centrais:

- `api_client.dart`: centraliza GET, POST, PUT, PATCH e DELETE.
- `api_config.dart`: define `API_BASE_URL`.
- `api_session.dart`: guarda token JWT em memoria.
- `auth_store.dart`: controla usuario autenticado no app.
- `collaboration_store.dart`: estado compartilhado e sincronizacao com a API.

Services de API:

- `AuthApiService`
- `ArtistApiService`
- `ProjectApiService`
- `TaskApiService`
- `ApplicationApiService`
- `RehearsalApiService`
- `MessageApiService`
- `DecisionApiService`
- `WeeklyGoalApiService`

Telas:

- Login
- Cadastro
- Home/Painel
- Perfil
- Projetos
- Talentos
- Formulario de integrante/artista
- Detalhe de artista
- Candidaturas
- Tarefas
- Kanban
- Ensaios
- Mensagens
- Decisoes
- Metas semanais
- Responsabilidades
- Detalhes demonstrativos
- Colaboracao

## Integracao mobile/API

Configuracao:

- `API_BASE_URL` define a URL do backend.
- Android Emulator: `http://10.0.2.2:8080`
- Desktop/navegador: `http://localhost:8080`

Fluxo de autenticacao:

1. Tela de login/cadastro chama `AuthStore`.
2. `AuthStore` chama `AuthApiService`.
3. `AuthApiService` usa `ApiClient`.
4. Backend responde com token JWT.
5. `ApiSession` salva o token em memoria.
6. Chamadas seguintes enviam `Authorization: Bearer <token>`.

Fluxo de dados:

1. Tela Flutter chama `CollaborationStore`.
2. `CollaborationStore` chama services de dominio.
3. Services usam `ApiClient`.
4. Backend retorna JSON.
5. Store atualiza listas em memoria.
6. UI atualiza telas, loading, erros e estados vazios.

Funcionalidades conectadas:

- Login, cadastro e logout.
- Talentos/artistas.
- Projetos.
- Tarefas.
- Candidaturas.
- Ensaios.
- Mensagens.
- Decisoes.
- Metas semanais.
- Kanban.
- Painel, perfil e detalhes usando dados sincronizados da API.

Operacoes de rede:

- GET: listagens.
- POST: cadastro/login/criacao de recursos.
- PUT: atualizacoes completas em recursos suportados pelo backend.
- PATCH: atualizacao de status.
- DELETE: exclusao de metas no mobile e recursos no backend.

Estado atual importante:

- O modo mock/offline foi removido do runtime do mobile.
- O app depende do backend `api-harmocrew` em execucao.
- Fixtures ou dados artificiais devem ficar restritos a testes automatizados.

Testes mobile:

- `mobile/test/smoke_test.dart`
- valida inicializacao na tela de login.
- comandos documentados:
  - `flutter analyze`
  - `flutter test`
- resultado documentado: sucesso.

## Evidencias recomendadas para a apresentacao

Backend:

- GitHub do `api-harmocrew`.
- Swagger aberto.
- Terminal com `docker compose -f docker-compose.nginx.yml ps`.
- `curl http://localhost:8080/health`.
- Logs do NGINX recebendo chamadas do app.
- `docs/functional-tests.http`.
- `docs/final-compliance-check.md`.
- JMeter sem NGINX.
- JMeter com NGINX.
- `docs/performance/performance-results-summary.md`.

Mobile:

- GitHub do `harmoCrew`.
- App Flutter na tela de login.
- App Flutter apos cadastro/login.
- Tela de talentos ou projetos carregando dados da API.
- Tela de tarefas/Kanban.
- Tela de candidaturas, ensaios, mensagens, decisoes ou metas.
- Terminal com `flutter analyze`.
- Terminal com `flutter test`.

## Comandos uteis

Backend:

```powershell
cd "C:\Users\d-_-b\Documents\ambos harmocrews\api-harmocrew"
.\mvnw clean test
docker compose -f docker-compose.nginx.yml up --build
curl http://localhost:8080/health
```

Mobile Android Emulator:

```powershell
cd "C:\Users\d-_-b\Documents\ambos harmocrews\harmoCrew\mobile"
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Mobile desktop/navegador:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

Build APK:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Logs:

```powershell
docker compose -f docker-compose.nginx.yml logs -f
docker compose -f docker-compose.nginx.yml logs -f nginx
docker compose -f docker-compose.nginx.yml logs -f api-1 api-2
```

## Pendencias e observacoes

- A apresentacao deve evitar afirmar que existe modo mock/offline no mobile,
  pois ele foi removido do runtime.
- A apresentacao deve explicar que backend e mobile pertencem ao mesmo produto,
  mas sao entregas separadas de disciplinas diferentes.
- Para demonstrar o app, o backend precisa estar rodando.
- Rotas protegidas retornam `401` se chamadas sem token JWT.
- O app deve fazer login/cadastro antes de consumir dados protegidos.
- A blacklist de logout e em memoria e nao e compartilhada entre multiplas
  instancias da API atras do NGINX.
