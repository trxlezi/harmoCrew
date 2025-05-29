import re
import mysql.connector
from flask import Flask, request, jsonify
from flask_cors import CORS
import jwt
import datetime
from functools import wraps
from werkzeug.security import generate_password_hash, check_password_hash

from db.database import get_connection

app = Flask(__name__)
CORS(app)

app.config['SECRET_KEY'] = '4f7d8a9b2c3e1f0a9d7b5e6c8f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a'

EMAIL_REGEX = re.compile(r"[^@]+@[^@]+\.[^@]+")


def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({"message": "Token é obrigatório!"}), 401

        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != "bearer":
            return jsonify({"message": "Cabeçalho de autorização inválido!"}), 401

        token = parts[1]

        try:
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
            current_user_email = data['email']
        except jwt.ExpiredSignatureError:
            return jsonify({"message": "Token expirado!"}), 401
        except jwt.InvalidTokenError:
            return jsonify({"message": "Token inválido!"}), 401
        except Exception as e:
            return jsonify({"message": "Erro ao validar token.", "error": str(e)}), 401

        return f(current_user_email, *args, **kwargs)

    return decorated


@app.route("/")
def home():
    return "Backend está funcionando!"


@app.route("/register", methods=["POST"])
def register():
    data = request.json or {}
    nome = data.get("nome", "").strip()
    email = data.get("email", "").strip()
    senha = data.get("senha", "")

    if not nome or not email or not senha:
        return jsonify({"message": "Nome, email e senha são obrigatórios."}), 400

    if not EMAIL_REGEX.match(email):
        return jsonify({"message": "Formato de email inválido."}), 400

    hashed_password = generate_password_hash(senha, method='pbkdf2:sha256')

    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT 1 FROM users WHERE email = %s", (email,))
        if cursor.fetchone():
            return jsonify({"message": "Usuário já existe com este email."}), 409

        cursor.execute("INSERT INTO users (nome, email, senha) VALUES (%s, %s, %s)",
                       (nome, email, hashed_password))
        conn.commit()

        return jsonify({"message": "Usuário criado com sucesso!"}), 201

    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()


@app.route("/login", methods=["POST"])
def login():
    data = request.json or {}
    email = data.get("email", "").strip()
    senha = data.get("senha", "")

    if not email or not senha:
        return jsonify({"message": "Email e senha são obrigatórios."}), 400

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
        user = cursor.fetchone()

        if not user or not check_password_hash(user['senha'], senha):
            return jsonify({"message": "Email ou senha incorretos."}), 401

        token = jwt.encode({
            'email': user['email'],
            'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
        }, app.config['SECRET_KEY'], algorithm="HS256")

        return jsonify({
            "token": token,
            "user": {
                "id": user['id'],
                "nome": user['nome'],
                "email": user['email']
            }
        })

    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()


@app.route("/profile", methods=["GET"])
@token_required
def profile(current_user_email):
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id, nome, email FROM users WHERE email = %s", (current_user_email,))
        user = cursor.fetchone()

        if not user:
            return jsonify({"message": "Usuário não encontrado."}), 404

        return jsonify({"user": user})

    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()


@app.route("/posts", methods=["GET"])
@token_required
def get_posts(current_user_email):
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT p.id, u.nome, p.texto, p.created_at, p.user_id
            FROM posts p
            JOIN users u ON p.user_id = u.id
            ORDER BY p.created_at DESC
            LIMIT 50
        """)
        posts = cursor.fetchall()

        for post in posts:
            post['data'] = post.pop('created_at').strftime("%Y-%m-%d %H:%M:%S")

        return jsonify({"posts": posts})

    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()



@app.route("/posts", methods=["POST"])
@token_required
def create_post(current_user_email):
    data = request.json or {}
    texto = data.get("texto", "").strip()

    if not texto:
        return jsonify({"message": "O texto do post não pode ser vazio."}), 400

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        user = cursor.fetchone()
        if not user:
            return jsonify({"message": "Usuário não encontrado."}), 404

        cursor.execute(
            "INSERT INTO posts (user_id, texto) VALUES (%s, %s)",
            (user['id'], texto)
        )
        conn.commit()

        post_id = cursor.lastrowid

        cursor.execute("""
            SELECT p.id, u.nome, p.texto, p.created_at
            FROM posts p
            JOIN users u ON p.user_id = u.id
            WHERE p.id = %s
        """, (post_id,))
        post = cursor.fetchone()
        post['data'] = post.pop('created_at').strftime("%Y-%m-%d %H:%M:%S")

        return jsonify({"message": "Post criado com sucesso!", "post": post}), 201

    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route("/candidatar/<int:post_id>", methods=["POST"])
@token_required
def candidatar(current_user_email, post_id):
    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        user = cursor.fetchone()
        if not user:
            return jsonify({"message": "Usuário não encontrado."}), 404

        user_id = user[0]

        cursor.execute("SELECT 1 FROM candidaturas WHERE user_id = %s AND post_id = %s", (user_id, post_id))
        if cursor.fetchone():
            return jsonify({"message": "Você já se candidatou a este post."}), 400

        cursor.execute("INSERT INTO candidaturas (user_id, post_id) VALUES (%s, %s)", (user_id, post_id))
        conn.commit()

        return jsonify({"message": "Candidatura enviada com sucesso!"})

    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route("/candidaturas", methods=["GET"])
@token_required
def listar_candidaturas(current_user_email):
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        autor = cursor.fetchone()
        if not autor:
            return jsonify({"message": "Usuário não encontrado."}), 404

        autor_id = autor['id']

        cursor.execute("""
            SELECT c.id, c.data, u.nome AS nome_artista, p.texto AS post_texto
            FROM candidaturas c
            JOIN users u ON c.user_id = u.id
            JOIN posts p ON c.post_id = p.id
            WHERE p.user_id = %s
            ORDER BY c.data DESC
        """, (autor_id,))
        candidaturas = cursor.fetchall()

        return jsonify({"candidaturas": candidaturas})

    except mysql.connector.Error as err:
        return jsonify({"message": "Erro ao buscar candidaturas.", "error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route("/candidaturas/<int:candidatura_id>/<string:acao>", methods=["POST"])
@token_required
def acao_candidatura(current_user_email, candidatura_id, acao):
    if acao not in ["aceitar", "rejeitar"]:
        return jsonify({"message": "Ação inválida."}), 400

    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("UPDATE candidaturas SET status = %s WHERE id = %s", (acao, candidatura_id))
        conn.commit()

        return jsonify({"message": f"Candidatura {acao} com sucesso!"})
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro ao atualizar candidatura.", "error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route("/search_users", methods=["GET"])
@token_required
def search_users(current_user_email):
    termo = request.args.get("q", "").strip()

    if not termo:
        return jsonify({"users": []})

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT id, nome, email FROM users WHERE nome LIKE %s LIMIT 10", (f"%{termo}%",))
        usuarios = cursor.fetchall()

        return jsonify({"users": usuarios})
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    app.run(debug=True)
