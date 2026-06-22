# Plano de Integracao API Mobile

Status: concluido.

## Decisao atual

O app Flutter consome diretamente a API `api-harmocrew`. O modo de demonstracao
offline foi removido do runtime.

## Configuracao

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Para desktop/navegador:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

## Cobertura

- Auth
- Artistas
- Projetos
- Tarefas
- Candidaturas
- Ensaios
- Mensagens
- Decisoes
- Metas semanais
- Kanban e painel via store sincronizada com a API
