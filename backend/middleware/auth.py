from functools import wraps
from flask import request, jsonify
import jwt
from config.config import SECRET_KEY

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
            data = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
            current_user_email = data['email']
        except jwt.ExpiredSignatureError:
            return jsonify({"message": "Token expirado!"}), 401
        except jwt.InvalidTokenError:
            return jsonify({"message": "Token inválido!"}), 401
        except Exception as e:
            return jsonify({"message": "Erro ao validar token.", "error": str(e)}), 401

        return f(current_user_email, *args, **kwargs)
    return decorated 