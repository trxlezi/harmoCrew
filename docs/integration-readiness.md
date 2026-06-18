# Diagnostico de Prontidao para Integracao - HarmoCrew

Data da verificacao: 2026-06-17

## Backend api-harmocrew

### Status do Git

- Repositorio: `api-harmocrew`
- Branch atual: `main`
- Status: `## main...origin/main`
- Alteracoes locais antes da integracao: nenhuma alteracao local indicada por `git status --short --branch`.

### Resultado dos testes

Comando executado:

```powershell
.\mvnw clean test
```

Resultado:

- Build: sucesso
- Testes: 10
- Falhas: 0
- Erros: 0
- Ignorados: 0

Observacoes do ambiente:

- Maven compilou com alvo Java 21.
- O ambiente local usou Java 25.0.3.
- Houve warnings de Lombok/Unsafe, Mockito/ByteBuddy e SpringDoc, sem quebrar os testes.

### Endpoints disponiveis

Endpoints de autenticacao confirmados em documentacao e controllers:

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/logout`
- aliases em `/api/auth/register`, `/api/auth/login` e `/api/auth/logout`

Endpoints REST principais confirmados:

- `GET /health`
- CRUD de artistas em `/api/artists`
- CRUD de projetos em `/api/projects`
- tarefas em `/api/tasks` e `/api/projects/{projectId}/tasks`
- candidaturas em `/api/applications` e `/api/projects/{projectId}/applications`
- ensaios em `/api/rehearsals` e `/api/projects/{projectId}/rehearsals`
- metas semanais em `/api/weekly-goals` e `/api/projects/{projectId}/weekly-goals`
- decisoes em `/api/decisions` e `/api/projects/{projectId}/decisions`
- mensagens em `/api/messages` e `/api/projects/{projectId}/messages`

### Swagger disponivel

Swagger/OpenAPI esta configurado no backend:

- `http://localhost:8080/swagger-ui.html`
- `http://localhost:8080/swagger-ui/index.html`
- `http://localhost:8080/v3/api-docs`

Evidencias locais:

- dependencia `springdoc-openapi-starter-webmvc-ui` no `pom.xml`;
- `OpenApiConfig` com esquema Bearer;
- `springdoc.swagger-ui.path=/swagger-ui.html` em `application.properties`;
- liberacao de Swagger em `SecurityConfig`.

### Docker/NGINX disponivel

Arquivos encontrados:

- `Dockerfile`
- `docker-compose.yml`
- `docker-compose.nginx.yml`
- `nginx/nginx.conf`

JMeter encontrado:

- `docs/performance/harmocrew-performance-test.jmx`
- `docs/performance/performance-results-summary.md`
- resultados `.jtl` e dashboards HTML em `docs/performance/`

Validacao local tentada:

```powershell
docker compose -f docker-compose.nginx.yml up --build -d
```

Resultado:

- Docker CLI instalado: `Docker version 29.5.3`
- Docker Compose instalado: `Docker Compose version v5.1.4`
- O daemon do Docker Desktop nao estava ativo.
- Erro observado: falha ao conectar em `npipe:////./pipe/dockerDesktopLinuxEngine`.

Por isso, nesta verificacao nao foi possivel validar ao vivo:

- `docker compose -f docker-compose.nginx.yml up --build`
- `curl http://localhost:8080/health`
- Swagger em uma API rodando localmente.

### Observacoes

- A documentacao do backend esta consistente e completa para API REST, JWT, Swagger, Docker, NGINX, JMeter e testes funcionais.
- Os testes automatizados do backend passaram.
- A validacao Docker/NGINX depende de abrir/iniciar o Docker Desktop.
- O logout usa blacklist de token em memoria; com NGINX e duas instancias, essa blacklist nao e compartilhada entre instancias. A limitacao ja esta documentada no README.

### Esta pronto para integracao?

**Nao totalmente nesta maquina, ainda.**

O codigo do backend e os testes indicam prontidao, mas a validacao exigida com Docker/NGINX e `GET /health` nao foi concluida porque o daemon Docker nao estava rodando.

## Frontend harmoCrew/mobile

### Status do Git

- Repositorio: `harmoCrew`
- Branch atual: `main`
- Status inicial: `## main...origin/main`
- Alteracoes locais iniciais: nenhuma alteracao local indicada antes dos comandos Flutter.
- Durante `flutter build apk --debug`, Flutter gerou alteracoes automaticas em arquivos Android/desktop. Essas alteracoes de verificacao foram restauradas para nao misturar artefatos automaticos com a integracao.

### Resultado de flutter analyze

Comando executado:

```powershell
flutter analyze
```

Resultado:

- Sucesso.
- `No issues found!`

### Resultado de flutter test

Comando executado:

```powershell
flutter test
```

Resultado:

- Falha.
- Motivo: `Test directory "test" not found.`

Nao houve falha de teste funcional existente; o projeto simplesmente nao possui pasta `test/`.

### Resultado de flutter build apk --debug

Comando executado:

```powershell
flutter build apk --debug
```

Resultado:

- Sucesso.
- APK gerado em `build\app\outputs\flutter-apk\app-debug.apk`.

Observacao:

- Flutter exibiu aviso de migracao futura do Kotlin Gradle Plugin para Built-in Kotlin.

### Telas existentes

Telas principais encontradas no app Flutter:

- Login
- Cadastro
- Home/Painel inicial
- Perfil
- Projetos
- Talentos
- Formulario de integrante
- Detalhe de artista
- Detalhes demonstrativos
- Colaboracao
- Candidaturas
- Tarefas
- Kanban
- Ensaios
- Mensagens
- Decisoes
- Metas semanais
- Responsabilidades

### Arquitetura atual

Estrutura observada:

- `mobile/lib/app`
- `mobile/lib/app/widgets`
- `mobile/lib/core/theme`
- `mobile/lib/features/auth`
- `mobile/lib/features/home`
- `mobile/lib/features/projects`
- `mobile/lib/features/members`
- `mobile/lib/features/collaboration`
- `mobile/lib/features/details`

Padroes atuais:

- `MaterialApp` com rotas nomeadas.
- Telas em `presentation` ou `screens`.
- Modelos em `domain` e `models`.
- Dados locais em `data/mock_*`.
- Estado compartilhado simples via singletons, principalmente `MockAuthStore` e `MockCollaborationStore`.
- Nao ha Provider, Riverpod, Bloc, Dio ou pacote `http` configurado atualmente.

### Dados mockados existentes

O app ainda usa dados mockados como modo principal:

- `MockAuthStore` para login/cadastro/logout.
- `MockMembers` para integrantes.
- `MockProjects` para projetos.
- `MockCollaborationStore` e `MockCollaborationData` para artistas, projetos, candidaturas, tarefas, ensaios, mensagens, decisoes e metas semanais.

Os READMEs do repositorio e do mobile tambem afirmam que o app usa dados locais em memoria para demonstracao.

### Esta pronto para integracao?

**Nao totalmente ainda.**

O app compila, analisa sem problemas e gera APK, mas `flutter test` falha por ausencia da pasta `test/`. Alem disso, a integracao real ainda nao deve comecar enquanto a validacao ao vivo do backend com Docker/NGINX estiver pendente.

## Decisao

A integracao **nao deve comecar nesta etapa**.

Pendencias antes de alterar codigo do Flutter:

- Iniciar Docker Desktop e validar o backend com:

```powershell
cd ..\api-harmocrew
docker compose -f docker-compose.nginx.yml up --build
curl http://localhost:8080/health
```

- Confirmar Swagger ao vivo em:

```text
http://localhost:8080/swagger-ui.html
```

ou

```text
http://localhost:8080/swagger-ui/index.html
```

- Adicionar pelo menos um teste Flutter minimo ou alinhar que `flutter test` sem pasta `test/` sera aceito como pendencia documentada da entrega mobile.

Depois dessas pendencias, a integracao pode ser planejada no arquivo `docs/api-integration-plan.md`, priorizando mudancas no Flutter e preservando os mocks como fallback ou modo demonstracao.

## Revalidacao em 2026-06-17

As pendencias acima foram tratadas em nova rodada de verificacao:

- Docker Desktop estava ativo.
- `docker compose -f docker-compose.nginx.yml up --build -d` subiu `api-1`, `api-2`, `postgres` e `nginx`.
- `docker compose -f docker-compose.nginx.yml ps` mostrou `api-1` e `api-2` Up, `postgres` Up/healthy e `nginx` Up.
- `GET http://localhost:8080/health` retornou `status: UP`.
- Swagger/API docs responderam HTTP 200 em `http://localhost:8080/swagger-ui.html` e `http://localhost:8080/v3/api-docs`.
- Foi criado `mobile/test/smoke_test.dart`.
- Foi adicionado `flutter_test` ao `mobile/pubspec.yaml`.
- `flutter test` passou.

Decisao atualizada:

**Backend e mobile ficaram prontos para a integracao.** A integracao foi planejada em `docs/api-integration-plan.md`, implementada no Flutter e documentada em `docs/mobile-api-integration.md` e `docs/integration-final-report.md`.
