# Prompt para Claude criar PowerPoint do HarmoCrew

Copie e cole o prompt abaixo no Claude.

---

Voce e um especialista em apresentacoes academicas, design de slides e comunicacao tecnica. Crie o conteudo completo de uma apresentacao em PowerPoint para o projeto abaixo.

# Titulo da apresentacao

HarmoCrew: Plataforma de Colaboracao Musical

# Objetivo da apresentacao

Mostrar o produto completo HarmoCrew, considerando backend e mobile como partes integradas de uma mesma solucao:

- app mobile Flutter;
- API REST Spring Boot;
- integracao mobile/API por HTTP;
- autenticacao JWT;
- CRUDs e operacoes de dominio;
- banco relacional PostgreSQL com ORM;
- Docker e NGINX;
- testes funcionais;
- testes de performance com JMeter;
- recursos e telas do app mobile.

# Publico

Apresentacao academica para duas disciplinas:

- Desenvolvimento Web Back-end;
- Desenvolvimento para Dispositivos Moveis.

Explique claramente que o produto e o mesmo, mas as entregas academicas estao separadas em dois repositorios:

- `api-harmocrew`: entrega da disciplina de Web Back-end.
- `harmoCrew/mobile`: entrega da disciplina de Desenvolvimento Mobile.

# Duracao

Monte uma apresentacao para uma fala de 15 a 20 minutos, dividida entre 4 integrantes.

# Quantidade de slides

Crie entre 12 e 15 slides. A sugestao ideal e 15 slides.

# Estilo visual

Use um visual moderno, academico e limpo:

- tema escuro ou azul/roxo, combinando tecnologia e musica;
- tipografia grande e legivel;
- poucos textos por slide;
- icones de musica, API, banco de dados, mobile, seguranca, Docker, NGINX e nuvem;
- tabelas pequenas;
- diagramas simples;
- destaque de evidencias tecnicas;
- espacos reservados para prints reais do projeto quando fizer sentido;
- cada slide deve parecer pronto para virar PowerPoint, com layout sugerido.

# Estrutura obrigatoria dos slides

## Slide 1 - Capa

Conteudo:

- HarmoCrew
- Plataforma de Colaboracao Musical
- Disciplinas envolvidas:
  - Desenvolvimento Web Back-end
  - Desenvolvimento para Dispositivos Moveis
- Integrantes e prontuarios:
  - Rafael Yukio Shiraishi - BP3052591
  - Gabriel Trolezi Caetano - BP3051862
  - Kaian Muniz de Souza - BP3051901
  - Joao Vitor Santos - BP3051552

Visual: capa com fundo escuro, elemento musical discreto, icone de mobile e API.

## Slide 2 - Problema e motivacao

Conteudo:

- Dificuldade de musicos encontrarem colaboradores.
- Projetos musicais precisam de organizacao.
- Necessidade de controlar tarefas, candidaturas, ensaios, decisoes, mensagens e metas.
- Falta de uma visao centralizada para colaboracao musical.

Visual: mapa simples de dores ou cards com icones.

## Slide 3 - Visao geral da solucao

Conteudo:

- App Flutter para acesso mobile.
- API REST Spring Boot como nucleo da aplicacao.
- PostgreSQL como banco relacional.
- Docker e NGINX para execucao e balanceamento.
- Integracao via HTTP/JSON com token JWT.

Visual: diagrama simples:

Flutter App -> API REST Spring Boot -> PostgreSQL

## Slide 4 - Separacao das entregas

Conteudo:

- Backend/API em repositorio independente: `api-harmocrew`.
- Mobile/frontend em repositorio independente: `harmoCrew`.
- Mesmo produto, duas entregas academicas.
- A integracao acontece por API REST.
- O mobile nao tem backend proprio; ele consome o backend Spring Boot.

Visual: dois blocos lado a lado com uma seta HTTP/API entre eles.

## Slide 5 - Arquitetura geral

Conteudo:

- Mobile Flutter chama endpoints REST.
- `ApiClient` centraliza GET, POST, PUT, PATCH e DELETE.
- `ApiSession` guarda token JWT em memoria.
- Backend Spring Boot valida Bearer Token.
- PostgreSQL armazena usuarios, artistas, projetos e colaboracoes.
- NGINX recebe em `localhost:8080` e balanceia para `api-1` e `api-2`.
- Observacao importante: o modo mock/offline foi removido do mobile; o app depende da API real em execucao.

Visual: diagrama:

Flutter App -> ApiClient -> NGINX :8080 -> api-1/api-2 Spring Boot -> PostgreSQL

## Slide 6 - Backend: tecnologias e requisitos atendidos

Conteudo:

- Java 21.
- Spring Boot 4.0.6.
- Spring WebMVC.
- Spring Data JPA / Hibernate.
- PostgreSQL.
- H2 em testes.
- Spring Security.
- JWT Bearer Token.
- BCrypt.
- Swagger/OpenAPI.
- Docker.
- NGINX.
- JMeter.
- Maven Wrapper.

Visual: grade de tecnologias com icones.

## Slide 7 - Backend: entidades e relacionamentos

Mostrar entidades:

- User
- Artist
- MusicalProject
- Task
- Application
- Rehearsal
- WeeklyGoal
- DecisionRecord
- CollaborationMessage

Destacar relacionamentos:

- User 1:1 Artist.
- MusicalProject 1:N Task.
- MusicalProject N:N Artist.
- Artist 1:N Application.
- MusicalProject 1:N Application.
- MusicalProject 1:N Rehearsal.
- MusicalProject 1:N CollaborationMessage.
- MusicalProject 1:N DecisionRecord.
- MusicalProject 1:N WeeklyGoal.

Visual: diagrama ER simplificado, sem excesso de campos.

## Slide 8 - Backend: API REST e autenticacao

Conteudo:

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/logout`
- JWT Bearer Token.
- Rotas protegidas com Spring Security.
- CRUD completo de Artist.
- CRUD completo de MusicalProject.
- CRUD completo de Task, Rehearsal, WeeklyGoal e DecisionRecord.
- Operacoes de Application e CollaborationMessage.
- Swagger como documentacao interativa.

Visual: fluxo auth:

Login/Register -> Token JWT -> Authorization: Bearer token -> rotas protegidas

## Slide 9 - Backend: Docker, NGINX e testes funcionais

Conteudo:

- `docker-compose.yml`: PostgreSQL + 1 instancia da API.
- `docker-compose.nginx.yml`: PostgreSQL + `api-1` + `api-2` + NGINX.
- `nginx/nginx.conf` usa upstream `harmocrew_api` com `least_conn`.
- PostgreSQL com healthcheck.
- Testes automatizados: `./mvnw clean test`.
- Resultado documentado: 10 testes, 0 falhas, 0 erros, 0 ignorados.
- Testes funcionais documentados em `docs/functional-tests.http`.

Visual: pipeline pequeno: Docker -> API -> NGINX -> testes.

Reservar espaco para prints:

- `docker compose -f docker-compose.nginx.yml ps`
- `curl http://localhost:8080/health`
- Swagger
- arquivo `docs/functional-tests.http`

## Slide 10 - Backend: JMeter e resultados

Use os dados reais:

Sem NGINX:

- 1000 requisicoes.
- 0 erros.
- media 3,27 ms.
- mediana 3 ms.
- P90 5 ms.
- P95 6 ms.
- throughput 34,06 req/s.

Com NGINX:

- 1000 requisicoes.
- 0 erros.
- media 52,57 ms.
- mediana 19 ms.
- P90 72 ms.
- P95 115 ms.
- throughput 34,72 req/s.

Conclusao:

- Ambos os cenarios tiveram 0% de erro.
- Sem NGINX teve menor latencia.
- Com NGINX validou o balanceamento entre duas instancias com throughput semelhante.

Visual: tabela comparativa pequena + destaque "0% erro".

Reservar espaco para prints:

- dashboard JMeter sem NGINX;
- dashboard JMeter com NGINX;
- `docs/performance/performance-results-summary.md`.

## Slide 11 - Mobile: tecnologias e estrutura

Conteudo:

- Flutter.
- Dart SDK `^3.11.4`.
- Material Components.
- Tema escuro.
- Navegacao por rotas nomeadas.
- Pacote `http` para rede.
- `ApiClient` para operacoes GET, POST, PUT, PATCH e DELETE.
- `AuthStore` para autenticacao.
- `CollaborationStore` para estado compartilhado e sincronizacao com a API.
- Services por dominio: auth, artists, projects, tasks, applications, rehearsals, messages, decisions e weekly goals.
- Teste smoke em `mobile/test/smoke_test.dart`.

Visual: estrutura de pastas simplificada:

`app/`, `core/api/`, `features/auth/`, `features/collaboration/`, `features/members/`, `features/projects/`.

## Slide 12 - Mobile: telas e funcionalidades

Mostrar principais telas:

- Login.
- Cadastro.
- Painel.
- Projetos.
- Perfil.
- Talentos.
- Detalhe de artista.
- Cadastro de integrante/artista.
- Candidaturas.
- Tarefas.
- Kanban.
- Ensaios.
- Mensagens.
- Decisoes.
- Metas semanais.
- Responsabilidades.

Visual: mosaico com prints do app ou cards com icones.

Reservar espaco para prints:

- app Flutter login;
- app Flutter listando dados da API;
- Kanban/tarefas;
- tela de talentos ou projetos.

## Slide 13 - Mobile: integracao com API

Conteudo:

- `API_BASE_URL` configura a URL do backend.
- Android Emulator usa `http://10.0.2.2:8080`.
- Desktop/navegador usa `http://localhost:8080`.
- Login/cadastro chamam `/auth/login` e `/auth/register`.
- Token JWT e salvo em `ApiSession`.
- `ApiClient` adiciona `Authorization: Bearer <token>` nas rotas protegidas.
- `CollaborationStore.syncAll()` sincroniza artistas, projetos, tarefas, candidaturas, ensaios, mensagens, decisoes e metas.
- Telas tratam loading, erro, estado vazio e feedback com SnackBar.
- O app atual nao possui modo mock/offline em runtime; ele depende da API real.

Operacoes de rede atendidas:

- GET: listar artistas, projetos, tarefas, candidaturas, ensaios, mensagens, decisoes e metas.
- POST: cadastrar usuario, login, criar artista, tarefa, candidatura, ensaio, mensagem, decisao e meta.
- PUT: atualizar metas semanais e recursos com CRUD completo no backend.
- PATCH: alterar status de tarefas, candidaturas, ensaios, decisoes e metas.
- DELETE: excluir metas semanais no app e entidades no backend.

Visual: fluxo:

Tela Flutter -> Store -> Service -> ApiClient -> Endpoint Spring Boot -> JSON -> Store -> UI

## Slide 14 - Demonstracao sugerida

Mostrar uma sequencia curta:

1. Subir backend com Docker/NGINX.
2. Ver Swagger.
3. Validar `/health`.
4. Abrir app Flutter no emulador Android.
5. Cadastrar usuario.
6. Login.
7. Listar talentos/projetos.
8. Criar tarefa.
9. Alterar status no Kanban.
10. Criar candidatura.
11. Criar ensaio, mensagem, decisao ou meta.
12. Logout.

Visual: linha do tempo da demonstracao, com prints pequenos.

Reservar espaco para prints:

- terminal Docker;
- Swagger;
- app login;
- lista carregada da API;
- Kanban/tarefas.

## Slide 15 - Conclusao e criterios atendidos

Conteudo:

- Backend atende REST, CRUD, ORM, PostgreSQL, JWT, BCrypt, Docker, NGINX, JMeter e testes funcionais.
- Mobile atende navegacao, formularios, tema, gerenciamento de estado com stores, chamadas HTTP e integracao com API.
- Dois repositorios separados, mas um unico produto integrado.
- Evidencias documentadas em README, Swagger, `functional-tests.http`, relatorios JMeter e testes automatizados.
- Projeto pronto para apresentacao academica.

Visual: checklist final com duas colunas: Back-end e Mobile.

# Divisao entre integrantes

Sugira esta divisao:

Integrante 1:

- Introducao, problema, dominio e visao geral.
- Slides 1 a 4.

Integrante 2:

- Backend, entidades, relacionamentos e API REST.
- Slides 5 a 8.

Integrante 3:

- Docker, NGINX, testes, JMeter e resultados.
- Slides 9 e 10.

Integrante 4:

- Mobile, integracao, demonstracao e conclusao.
- Slides 11 a 15.

# Notas do apresentador

Para cada slide, gere obrigatoriamente:

- titulo;
- bullets do slide;
- sugestao visual/layout;
- fala sugerida em linguagem natural;
- quem apresenta;
- tempo estimado.

# Prints e evidencias que devem ser indicados

Indique exatamente em quais slides colocar prints de:

- GitHub dos dois repositorios;
- Swagger;
- terminal com `docker compose -f docker-compose.nginx.yml ps`;
- `curl http://localhost:8080/health`;
- JMeter sem NGINX;
- JMeter com NGINX;
- app Flutter login;
- app Flutter listando dados da API;
- Kanban/tarefas;
- relatorio de conformidade;
- logs do NGINX recebendo chamadas do app, se houver.

# Saida final desejada

Entregue em formato util para montar o PowerPoint:

1. Conteudo slide por slide.
2. Roteiro de fala por slide.
3. Design sugerido.
4. Lista de imagens/prints necessarios.
5. Versao resumida para copiar no PowerPoint.
6. Versao com notas do apresentador.
7. Sugestao de tempo total por integrante.

# Dados reais do projeto para usar na apresentacao

## Repositorios

- Backend/API REST: `api-harmocrew`
  - GitHub: `https://github.com/trxlezi/api-harmocrew`
  - Disciplina: Desenvolvimento Web Back-end
- Frontend/mobile: `harmoCrew`
  - GitHub: `https://github.com/trxlezi/harmoCrew`
  - Disciplina: Desenvolvimento para Dispositivos Moveis
  - App principal: `harmoCrew/mobile`

## Integrantes

- Rafael Yukio Shiraishi - BP3052591
- Gabriel Trolezi Caetano - BP3051862
- Kaian Muniz de Souza - BP3051901
- Joao Vitor Santos - BP3051552

## Backend - tecnologias

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
- H2 para testes
- Swagger/OpenAPI
- Docker
- NGINX
- JMeter

## Backend - estrutura

Pacotes principais:

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

Controllers principais:

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

Security:

- `SecurityConfig`
- `JwtAuthenticationFilter`
- `JwtService`
- `TokenBlacklistService`
- `OpenApiConfig` com Bearer Auth

## Backend - entidades

- `User`
- `Artist`
- `MusicalProject`
- `Task`
- `Application`
- `Rehearsal`
- `WeeklyGoal`
- `DecisionRecord`
- `CollaborationMessage`

## Backend - relacionamentos

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

## Backend - endpoints principais

Auth:

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/logout`
- aliases em `/api/auth/register`, `/api/auth/login`, `/api/auth/logout`

Health:

- `GET /health`

Artists:

- `GET /api/artists`
- `GET /api/artists/{id}`
- `POST /api/artists`
- `PUT /api/artists/{id}`
- `DELETE /api/artists/{id}`

Projects:

- `GET /api/projects`
- `GET /api/projects/summaries`
- `GET /api/projects/{id}`
- `POST /api/projects`
- `PUT /api/projects/{id}`
- `POST /api/projects/{projectId}/artists/{artistId}`
- `DELETE /api/projects/{id}`

Tasks:

- `GET /api/tasks`
- `GET /api/projects/{projectId}/tasks`
- `POST /api/projects/{projectId}/tasks`
- `PUT /api/tasks/{id}`
- `PATCH /api/tasks/{id}/status`
- `DELETE /api/tasks/{id}`

Applications:

- `GET /api/applications`
- `GET /api/projects/{projectId}/applications`
- `POST /api/projects/{projectId}/applications`
- `PATCH /api/applications/{id}/status`
- `DELETE /api/applications/{id}`

Rehearsals:

- `GET /api/rehearsals`
- `GET /api/projects/{projectId}/rehearsals`
- `POST /api/projects/{projectId}/rehearsals`
- `PUT /api/rehearsals/{id}`
- `PATCH /api/rehearsals/{id}/status`
- `DELETE /api/rehearsals/{id}`

Weekly Goals:

- `GET /api/weekly-goals`
- `GET /api/projects/{projectId}/weekly-goals`
- `POST /api/projects/{projectId}/weekly-goals`
- `PUT /api/weekly-goals/{id}`
- `PATCH /api/weekly-goals/{id}/status`
- `DELETE /api/weekly-goals/{id}`

Decisions:

- `GET /api/decisions`
- `GET /api/projects/{projectId}/decisions`
- `POST /api/projects/{projectId}/decisions`
- `PUT /api/decisions/{id}`
- `PATCH /api/decisions/{id}/status`
- `DELETE /api/decisions/{id}`

Messages:

- `GET /api/messages`
- `GET /api/projects/{projectId}/messages`
- `POST /api/projects/{projectId}/messages`
- `DELETE /api/messages/{id}`

## Backend - Docker e NGINX

Arquivos:

- `Dockerfile`
- `docker-compose.yml`
- `docker-compose.nginx.yml`
- `nginx/nginx.conf`

`docker-compose.yml`:

- PostgreSQL 16 Alpine
- 1 instancia da API
- porta `8080:8080`
- banco `harmocrew`
- usuario `harmocrew`
- senha `harmocrew`

`docker-compose.nginx.yml`:

- PostgreSQL
- `api-1`
- `api-2`
- `nginx`
- NGINX exposto em `localhost:8080`

`nginx/nginx.conf`:

- upstream `harmocrew_api`
- algoritmo `least_conn`
- servidores `api-1:8080` e `api-2:8080`

Observacao:

- Logout usa blacklist de token em memoria; em ambiente com duas instancias essa blacklist nao e compartilhada entre `api-1` e `api-2`.

## Backend - testes e evidencias

Testes automatizados:

- comando: `./mvnw clean test`
- resultado documentado: 10 testes, 0 falhas, 0 erros, 0 ignorados.

Testes funcionais:

- arquivo: `docs/functional-tests.http`
- cobre health, register, login, logout, Bearer Token, Artist, MusicalProject, Task e Application.

Swagger:

- `http://localhost:8080/swagger-ui.html`
- `http://localhost:8080/swagger-ui/index.html`
- `http://localhost:8080/v3/api-docs`

## Backend - JMeter

Arquivo principal:

- `docs/performance/performance-results-summary.md`

Arquivos de evidencia:

- `docs/performance/harmocrew-performance-test.jmx`
- `docs/performance/results-sem-nginx.jtl`
- `docs/performance/results-com-nginx.jtl`
- `docs/performance/report-sem-nginx/index.html`
- `docs/performance/report-com-nginx/index.html`

Resultados sem NGINX:

- 1000 requisicoes
- 1000 sucessos
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
- 1000 sucessos
- 0 erros
- taxa de erro 0%
- media 52,57 ms
- mediana 19 ms
- P90 72 ms
- P95 115 ms
- P99 511 ms
- throughput 34,72 req/s

Conclusao JMeter:

- Os dois cenarios ficaram estaveis com 0% de erro.
- Sem NGINX teve menor latencia.
- Com NGINX mostrou balanceamento funcionando com throughput semelhante.

## Mobile - tecnologias

- Flutter
- Dart SDK `^3.11.4`
- Material Components
- Tema escuro
- Rotas nomeadas
- `http: ^1.6.0`
- `flutter_test`
- `flutter_lints`

## Mobile - estrutura

Pastas principais:

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

Arquivos de API:

- `mobile/lib/core/api/api_client.dart`
- `mobile/lib/core/api/api_config.dart`
- `mobile/lib/core/api/api_exception.dart`
- `mobile/lib/core/api/api_session.dart`

Stores:

- `AuthStore`
- `CollaborationStore`

Services:

- `AuthApiService`
- `ArtistApiService`
- `ProjectApiService`
- `TaskApiService`
- `ApplicationApiService`
- `RehearsalApiService`
- `MessageApiService`
- `DecisionApiService`
- `WeeklyGoalApiService`

## Mobile - telas

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

## Mobile - integracao real

O app consome a API real do `api-harmocrew`.

Configuracao:

- `API_BASE_URL` define a URL do backend.
- Android Emulator: `http://10.0.2.2:8080`
- Desktop/navegador: `http://localhost:8080`

O app nao possui modo mock/offline em runtime.

Fluxo:

- `AuthApiService` chama `/auth/register`, `/auth/login` e `/auth/logout`.
- `ApiSession` guarda token JWT em memoria.
- `ApiClient` envia `Authorization: Bearer <token>` nas chamadas protegidas.
- `CollaborationStore.syncAll()` busca artists, projects, tasks, applications, rehearsals, messages, decisions e weekly goals.
- Telas chamam stores/services e atualizam UI com loading, erro, estado vazio e SnackBar.

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

## Mobile - testes

Arquivo:

- `mobile/test/smoke_test.dart`

Teste:

- inicializa o app na tela de login;
- valida textos `Entrar` e `Email`.

Validacao documentada:

- `flutter analyze`: sucesso.
- `flutter test`: sucesso.

## Comandos uteis

Backend:

```powershell
cd ..\api-harmocrew
.\mvnw clean test
docker compose -f docker-compose.nginx.yml up --build
curl http://localhost:8080/health
```

Mobile Android Emulator:

```powershell
cd ..\harmoCrew\mobile
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

## Observacoes importantes para a apresentacao

- O backend e o mobile estao em repositorios separados.
- O mobile nao inclui backend; ele consome a API REST.
- Rotas protegidas retornam `401` quando chamadas sem token JWT.
- O app deve fazer login/cadastro antes de carregar dados protegidos.
- O modo mock/offline foi removido do runtime do mobile.
- A apresentacao deve enfatizar que o produto e integrado, mas as entregas academicas sao separadas por disciplina.

Agora gere a apresentacao completa com os slides, roteiro, notas e sugestoes visuais.
