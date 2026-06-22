# Relatorio Final de Integracao - HarmoCrew

Data: 2026-06-21

## Resultado

O mobile Flutter em `harmoCrew/mobile` foi ajustado para operar conectado ao
backend `api-harmocrew`.

## Validacao

- `flutter analyze`: sucesso.
- `flutter test`: sucesso.

## Configuracao

- `API_BASE_URL` define a URL do backend.
- O app nao possui modo de demonstracao offline em runtime.

## Backend

Subir com:

```powershell
cd ..\api-harmocrew
docker compose -f docker-compose.nginx.yml up --build
```

## Mobile

Android Emulator:

```powershell
cd ..\harmoCrew\mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Desktop/navegador:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

## Funcionalidades conectadas

- Login, cadastro e logout.
- Talentos/artistas.
- Projetos.
- Tarefas.
- Candidaturas.
- Ensaios.
- Mensagens.
- Decisoes.
- Metas semanais.
- Kanban, painel, perfil e detalhes usando dados sincronizados da API.
