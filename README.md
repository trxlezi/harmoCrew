# HarmoCrew

HarmoCrew e um projeto academico com tres frentes no mesmo repositorio:

- `mobile/`: app Flutter com dados mockados locais para demonstracao e avaliacao academica
- `backend/`: API Flask para a versao web
- `frontend/`: interface React da plataforma web

O foco principal da entrega academica esta no app Flutter em `mobile/`, com navegacao, formularios, responsividade e componentes Material.

## Estrutura do repositorio

```text
harmoCrew-main/
|-- mobile/      # app Flutter mobile com mocks locais
|-- backend/     # API Flask
|-- frontend/    # interface React
|-- docs/        # documentos e materiais auxiliares
`-- README.md
```

## Como rodar o app Flutter

### Pre-requisitos

- Flutter instalado e disponivel no `PATH`
- Android Studio com Android SDK
- Um emulador Android iniciado ou um celular Android conectado

### Passo a passo

1. Entre na pasta do app:

```powershell
cd mobile
```

2. Instale as dependencias:

```powershell
flutter pub get
```

3. Verifique os dispositivos disponiveis:

```powershell
flutter devices
```

4. Rode o app:

```powershell
flutter run
```

Se houver mais de um device:

```powershell
flutter run -d <device-id>
```

### Validacao academica

Sempre que fizer alteracoes no app Flutter, rode:

```powershell
dart format .
flutter analyze
flutter test
```

## Como rodar backend e frontend web

### Backend Flask

1. Entre em `backend/`
2. Ative sua virtual environment, se estiver usando uma
3. Crie um arquivo `backend/.env` com base em `backend/.env.example`
4. Rode:

```powershell
python app.py
```

### Frontend React

1. Entre em `frontend/`
2. Instale as dependencias:

```powershell
npm install
```

3. Rode:

```powershell
npm start
```

## Observacao

O app mobile usa dados mockados locais e nao depende do backend real para a demonstracao academica.
