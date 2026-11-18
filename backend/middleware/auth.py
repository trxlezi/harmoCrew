from functools import wraps
from flask import request
import jwt
from config.config import SECRET_KEY
from routes.shared import error_response


def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get("Authorization")
        if not auth_header:
            return error_response("Token e obrigatorio.", 401)

        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != "bearer":
            return error_response("Cabecalho de autorizacao invalido.", 401)

        token = parts[1]
        try:
            data = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
            current_user_email = data["email"]
        except jwt.ExpiredSignatureError:
            return error_response("Token expirado.", 401)
        except jwt.InvalidTokenError:
            return error_response("Token invalido.", 401)
        except Exception as error:
            return error_response("Erro ao validar token.", 401, str(error))

        return f(current_user_email, *args, **kwargs)

    return decorated
