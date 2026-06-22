# HarmoCrew Mobile

Aplicativo Flutter usado para apresentar os fluxos principais do HarmoCrew.

O app consome a API real do projeto. O backend precisa estar em execucao.

## Como executar

Suba o backend antes de abrir o app:

```powershell
cd ..\..\api-harmocrew
docker compose -f docker-compose.nginx.yml up --build
```

Depois rode o mobile:

```powershell
cd ..\harmoCrew\mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Para desktop/navegador, use:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

## Validacao

```powershell
flutter analyze
flutter test
```
