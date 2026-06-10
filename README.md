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

O foco da apresentacao esta no app Flutter em `mobile/`. Ele usa dados locais
mockados para demonstrar os fluxos colaborativos sem depender de servidor.

Para executar:

```powershell
cd mobile
flutter pub get
flutter run
```

## Dados

No app mobile, os dados criados durante o uso ficam apenas em memoria. Ao
reiniciar, o aplicativo volta para os dados iniciais.
