from flask import Blueprint, request, jsonify
import jwt
import datetime
from werkzeug.security import generate_password_hash, check_password_hash
from db.database import get_connection
from config.config import SECRET_KEY, EMAIL_REGEX
from middleware.auth import token_required

auth_bp = Blueprint('auth', __name__)

@auth_bp.route("/register", methods=["POST"])
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
    default_profile_pic_url = f"https://i.pravatar.cc/150?u={email}" 

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT 1 FROM users WHERE email = %s", (email,))
        if cursor.fetchone():
            return jsonify({"message": "Usuário já existe com este email."}), 409

        cursor.callproc('CreateNewUser', (nome, email, hashed_password))
        conn.commit()
        cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
        user_id = cursor.fetchone()[0]
        default_profile_pic_url = f"https://i.pravatar.cc/150?u={user_id}"
        cursor.execute("UPDATE users SET profile_pic_url = %s WHERE id = %s", (default_profile_pic_url, user_id))
        conn.commit()
        return jsonify({"message": "Usuário criado com sucesso!"}), 201
    except Exception as err:
        return jsonify({"message": "Erro no banco de dados ao registrar.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@auth_bp.route("/login", methods=["POST"])
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
        cursor.execute("SELECT id, nome, email, senha, profile_pic_url FROM users WHERE email = %s", (email,))
        user = cursor.fetchone()

        if not user or not check_password_hash(user['senha'], senha):
            return jsonify({"message": "Email ou senha incorretos."}), 401

        expiration_time = datetime.datetime.now(datetime.UTC) + datetime.timedelta(hours=24)
        token = jwt.encode({
            'email': user['email'],
            'id': user['id'], 
            'exp': expiration_time
        }, SECRET_KEY, algorithm="HS256")
        
        profile_pic_url = user.get('profile_pic_url') or f"https://i.pravatar.cc/150?u={user['id']}"

        return jsonify({
            "token": token,
            "user": {
                "id": user['id'],
                "nome": user['nome'],
                "email": user['email'],
                "profile_pic_url": profile_pic_url
            }
        })
    except Exception as err:
        return jsonify({"message": "Erro no banco de dados ao logar.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@auth_bp.route("/profile", methods=["GET"])
@token_required
def profile(current_user_email):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id, nome, email, profile_pic_url FROM users WHERE email = %s", (current_user_email,))
        user = cursor.fetchone()

        if not user:
            return jsonify({"message": "Usuário não encontrado."}), 404
        
        user['profile_pic_url'] = user.get('profile_pic_url') or f"https://i.pravatar.cc/150?u={user['id']}"

        return jsonify({"user": user})
    except Exception as err:
        return jsonify({"message": "Erro no banco de dados ao buscar perfil.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close() 