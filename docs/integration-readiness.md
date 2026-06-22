# Prontidao de Integracao - HarmoCrew

Data da verificacao: 2026-06-21

## Estado atual

O backend `api-harmocrew` expoe os endpoints REST necessarios para o app
Flutter. O mobile em `harmoCrew/mobile` consome esses endpoints diretamente.

## Mobile

O app usa:

- `ApiClient` para chamadas HTTP.
- `ApiSession` para token JWT em memoria.
- `AuthStore` para autenticacao.
- `CollaborationStore` para sincronizar artistas, projetos, tarefas,
  candidaturas, ensaios, mensagens, decisoes e metas semanais.

## Validacao local

```powershell
flutter analyze
flutter test
```

Resultado: sucesso.

## Execucao

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Para desktop/navegador:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```
