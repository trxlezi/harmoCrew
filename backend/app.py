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

app.config['SECRET_KEY'] = 'sua_chave_super_secreta_aqui'

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

    conn = None
    cursor = None
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
        if cursor:
            cursor.close()
        if conn:
            conn.close()


@app.route("/login", methods=["POST"])
def login():
    data = request.json or {}
    email = data.get("email", "").strip()
    senha = data.get("senha", "")

    if not email or not senha:
        return jsonify({"message": "Email e senha são obrigatórios."}), 400

    conn = None
    cursor = None
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
        if cursor:
            cursor.close()
        if conn:
            conn.close()


@app.route("/profile", methods=["GET"])
@token_required
def profile(current_user_email):
    conn = None
    cursor = None
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
        if cursor:
            cursor.close()
        if conn:
            conn.close()


if __name__ == "__main__":
    app.run(debug=True)
