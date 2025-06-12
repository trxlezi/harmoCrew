# HarmoCrew

HarmoCrew é uma plataforma web colaborativa para músicos, beatmakers e artistas, permitindo criar perfis, compartilhar projetos, seguir outros usuários, candidatar-se a colaborações e interagir via chat.

---

## Sumário

- [Funcionalidades](#funcionalidades)
- [Tecnologias Utilizadas](#tecnologias-utilizadas)
- [Como rodar o projeto](#como-rodar-o-projeto)
  - [Backend](#backend)
  - [Frontend](#frontend)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Principais Rotas da API](#principais-rotas-da-api)
- [Scripts de Banco de Dados](#scripts-de-banco-de-dados)
- [Licença](#licença)

---

## Funcionalidades

- Cadastro e login de usuários com autenticação JWT
- Perfis de usuário com foto, descrição e links sociais
- Criação, listagem e candidatura em projetos (posts)
- Sistema de seguidores/seguindo
- Busca de usuários
- Chat entre usuários
- Log de auditoria e triggers no banco de dados

---

## Tecnologias Utilizadas

### Backend
- Python 3
- Flask
- Flask-CORS
- Flask-MySQLdb
- MySQL Connector
- PyJWT
- MySQL

### Frontend
- React
- React Router DOM
- Axios

---

## Como rodar o projeto

### Pré-requisitos

- Python 3.x
- Node.js e npm
- MySQL Server

### Backend

1. **Instale as dependências:**
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

2. **Configure o banco de dados:**
   - Edite o arquivo `backend/db/init_db.py` se necessário (usuário, senha, host).
   - O banco será criado automaticamente ao rodar o backend.

3. **Rode o backend:**
   ```bash
   python app.py
   ```
   O backend estará disponível em `http://localhost:5000`.

### Frontend

1. **Instale as dependências:**
   ```bash
   cd frontend
   npm install
   ```

2. **Rode o frontend:**
   ```bash
   npm start
   ```
   O frontend estará disponível em `http://localhost:3000`.

---

## Estrutura do Projeto
```
harmoCrew/
│
├── backend/
│ ├── app.py # API Flask principal
│ ├── requirements.txt # Dependências Python
│ └── db/
│ ├── init_db.py # Script de inicialização do banco
│ ├── create_users_table.sql
│ └── database.py
│
├── frontend/
│ ├── package.json # Dependências React
│ ├── src/
│ │ ├── pages/ # Páginas principais (Home, Login, Perfil, etc)
│ │ ├── components/ # Componentes reutilizáveis (Navbar, Chat, etc)
│ │ ├── context/ # Contextos de autenticação
│ │ └── styles/ # Estilos CSS
│ └── public/
│
└── README.md
```
---

## Principais Rotas da API

- `POST   /register` — Cadastro de usuário
- `POST   /login` — Login e obtenção de token JWT
- `GET    /profile` — Dados do usuário logado
- `GET    /posts` — Listar posts
- `POST   /posts` — Criar post
- `POST   /candidatar/<post_id>` — Candidatar-se a um post
- `GET    /user/<id>` — Perfil público de um usuário
- `POST   /follow/<id>` — Seguir usuário
- `POST   /unfollow/<id>` — Deixar de seguir usuário
- `GET    /user/<id>/posts` — Listar posts de um usuário
- `GET    /user/<id>/followers` — Listar seguidores
- `GET    /user/<id>/following` — Listar quem o usuário segue
- `PUT    /user/me/descricao` — Atualizar descrição do perfil
- `PUT    /user/me/links` — Atualizar links sociais
- `POST   /messages` — Enviar mensagem
- `GET    /messages/<receiver_id>` — Buscar conversa com usuário

---

## Scripts de Banco de Dados

- O banco é inicializado automaticamente pelo script `backend/db/init_db.py` ao rodar o backend.
- Inclui criação de tabelas, views, procedures, funções e triggers para auditoria.

---

## Licença

Este projeto é apenas para fins educacionais e de demonstração.

---
