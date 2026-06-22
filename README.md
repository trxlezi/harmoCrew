# HarmoCrew

Projeto academico para demonstrar uma plataforma de colaboracao musical.

## Estrutura

```text
mobile/   app Flutter usado na apresentacao
backend/  API Flask da versao web
frontend/ interface React da versao web
docs/     materiais auxiliares
```

## App mobile

O foco da apresentacao esta no app Flutter em `mobile/`. Ele consome a API real
do projeto, portanto o backend precisa estar em execucao.

Para executar:

```powershell
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```
