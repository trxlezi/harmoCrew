from flask import Blueprint, request
from db.database import get_connection
from middleware.auth import token_required
from routes.shared import error_response, get_user_by_email, serialize_post, success_response

posts_bp = Blueprint("posts", __name__)


def _query_posts(cursor, where_clause="", params=()):
    cursor.execute(
        f"""
        SELECT
            post_id AS id,
            user_id,
            user_nome AS nome,
            user_email AS email,
            titulo,
            texto,
            audio_url,
            profile_pic_url,
            created_at,
            updated_at
        FROM UserPostsView
        {where_clause}
        ORDER BY created_at DESC
        """,
        params,
    )
    return [serialize_post(post, "Oportunidade") for post in cursor.fetchall()]


@posts_bp.route("/posts", methods=["GET"])
@posts_bp.route("/api/opportunities", methods=["GET"])
@token_required
def get_posts(current_user_email):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        opportunities = _query_posts(cursor)
        return success_response({"posts": opportunities, "opportunities": opportunities})
    except Exception as err:
        return error_response("Erro ao buscar oportunidades.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@posts_bp.route("/posts", methods=["POST"])
@posts_bp.route("/api/opportunities", methods=["POST"])
@token_required
def create_post(current_user_email):
    data = request.json or {}
    titulo = data.get("titulo", "").strip()
    texto = data.get("texto", "").strip()
    audio_url = (data.get("audio_url") or "").strip() or None

    if not titulo or not texto:
        return error_response("Titulo e descricao sao obrigatorios.", 400)

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        user = get_user_by_email(cursor, current_user_email)
        if not user:
            return error_response("Usuario autenticado nao encontrado.", 404)

        cursor.execute(
            "INSERT INTO posts (user_id, titulo, texto, audio_url) VALUES (%s, %s, %s, %s)",
            (user["id"], titulo, texto, audio_url),
        )
        conn.commit()
        post_id = cursor.lastrowid
        cursor.execute(
            """
            SELECT
                p.id,
                p.user_id,
                u.nome,
                u.email,
                u.profile_pic_url,
                p.titulo,
                p.texto,
                p.audio_url,
                p.created_at,
                p.updated_at
            FROM posts p
            JOIN users u ON u.id = p.user_id
            WHERE p.id = %s
            """,
            (post_id,),
        )
        post = serialize_post(cursor.fetchone(), "Oportunidade")
        return success_response({"post": post, "opportunity": post}, status=201)
    except Exception as err:
        return error_response("Erro ao criar oportunidade.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@posts_bp.route("/user/<int:user_id>/posts", methods=["GET"])
@posts_bp.route("/api/profiles/<profile_ref>/projects", methods=["GET"])
@token_required
def get_user_posts(current_user_email, user_id=None, profile_ref=None):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        target_user_id = user_id
        if profile_ref is not None:
            if profile_ref == "me":
                current_user = get_user_by_email(cursor, current_user_email)
                if not current_user:
                    return error_response("Usuario autenticado nao encontrado.", 404)
                target_user_id = current_user["id"]
            else:
                target_user_id = int(profile_ref)

        projects = _query_posts(cursor, "WHERE user_id = %s", (target_user_id,))
        return success_response({"posts": projects, "projects": projects})
    except ValueError:
        return error_response("Identificador de perfil invalido.", 400)
    except Exception as err:
        return error_response("Erro ao buscar projetos do perfil.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()
