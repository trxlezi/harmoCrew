import datetime
import jwt
import re
from flask import Blueprint, request
from werkzeug.security import check_password_hash, generate_password_hash
from config.config import EMAIL_REGEX, SECRET_KEY
from db.database import get_connection
from middleware.auth import token_required
from routes.shared import error_response, get_user_by_email, success_response

auth_bp = Blueprint("auth", __name__)

PASSWORD_REGEX = re.compile(r"^(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$")


def _serialize_auth_user(user):
    profile_pic_url = user.get("profile_pic_url") or f"https://i.pravatar.cc/150?u={user['id']}"
    return {
        "id": user["id"],
        "nome": user["nome"],
        "email": user["email"],
        "profile_pic_url": profile_pic_url,
        "descricao": user.get("descricao") or "",
        "links_sociais": user.get("links_sociais") or "",
    }


@auth_bp.route("/register", methods=["POST"])
@auth_bp.route("/api/register", methods=["POST"])
def register():
    data = request.json or {}
    nome = data.get("nome", "").strip()
    email = data.get("email", "").strip()
    senha = data.get("senha", "")

    if not nome or not email or not senha:
      return error_response("Nome, email e senha sao obrigatorios.", 400)

    if not EMAIL_REGEX.match(email):
      return error_response("Formato de email invalido.", 400)

    if not PASSWORD_REGEX.match(senha):
      return error_response(
          "A senha deve ter pelo menos 8 caracteres, 1 letra maiuscula, 1 numero e 1 simbolo.",
          400,
      )

    conn = None
    cursor = None
    try:
      conn = get_connection()
      cursor = conn.cursor(dictionary=True)
      cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
      if cursor.fetchone():
          return error_response("Ja existe um usuario com este email.", 409)

      hashed_password = generate_password_hash(senha, method="pbkdf2:sha256")
      cursor.execute(
          "INSERT INTO users (nome, email, senha, profile_pic_url) VALUES (%s, %s, %s, %s)",
          (nome, email, hashed_password, f"https://i.pravatar.cc/150?u={email}"),
      )
      conn.commit()
      return success_response({"message": "Cadastro realizado com sucesso."}, status=201)
    except Exception as err:
      return error_response("Erro ao registrar usuario.", 500, str(err))
    finally:
      if cursor:
          cursor.close()
      if conn and conn.is_connected():
          conn.close()


@auth_bp.route("/login", methods=["POST"])
@auth_bp.route("/api/login", methods=["POST"])
def login():
    data = request.json or {}
    email = data.get("email", "").strip()
    senha = data.get("senha", "")

    if not email or not senha:
        return error_response("Email e senha sao obrigatorios.", 400)

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            "SELECT id, nome, email, senha, profile_pic_url, descricao, links_sociais FROM users WHERE email = %s",
            (email,),
        )
        user = cursor.fetchone()

        if not user or not check_password_hash(user["senha"], senha):
            return error_response("Email ou senha incorretos.", 401)

        cursor.execute("UPDATE users SET last_login = NOW() WHERE id = %s", (user["id"],))
        conn.commit()

        expiration_time = datetime.datetime.now(datetime.UTC) + datetime.timedelta(hours=24)
        token = jwt.encode(
            {"email": user["email"], "id": user["id"], "exp": expiration_time},
            SECRET_KEY,
            algorithm="HS256",
        )

        return success_response({
            "token": token,
            "user": _serialize_auth_user(user),
        })
    except Exception as err:
        return error_response("Erro ao autenticar usuario.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@auth_bp.route("/profile", methods=["GET"])
@auth_bp.route("/api/profile", methods=["GET"])
@token_required
def profile(current_user_email):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        user = get_user_by_email(cursor, current_user_email)
        if not user:
            return error_response("Usuario nao encontrado.", 404)

        return success_response({"user": _serialize_auth_user(user)})
    except Exception as err:
        return error_response("Erro ao buscar perfil autenticado.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@auth_bp.route("/logout", methods=["POST"])
@auth_bp.route("/api/logout", methods=["POST"])
@token_required
def logout(current_user_email):
    return success_response({"message": "Logout realizado com sucesso."})
