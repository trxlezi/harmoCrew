# Integracao Mobile com HarmoCrew API

## Repositorios

- mobile/frontend: `harmoCrew`
- backend/API: `api-harmocrew`

Os repositorios continuam separados. O app Flutter consome a API real do
backend e depende do servidor em execucao.

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

## Como rodar mobile

Android Emulator:

```powershell
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Desktop/navegador:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

Build APK:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

## Funcionalidades conectadas

- Auth: cadastro, login, logout e token JWT.
- Artistas/Talentos: listagem e cadastro.
- Projetos: listagem.
- Tarefas: listagem, criacao e status.
- Candidaturas: listagem, criacao e status.
- Ensaios: listagem, criacao e status.
- Mensagens: listagem e envio.
- Decisoes: listagem, criacao e status.
- Metas semanais: listagem, criacao, edicao, status e exclusao.
- Kanban, painel, perfil, talentos e detalhes usam a mesma store sincronizada
  com a API.

## Observacoes

- `API_BASE_URL` e a unica configuracao de endpoint do mobile.
- Fixtures ou dados artificiais devem ficar restritos a testes automatizados.
