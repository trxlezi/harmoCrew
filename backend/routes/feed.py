from flask import Blueprint
from db.database import get_connection
from middleware.auth import token_required
from routes.shared import error_response, get_user_by_email, serialize_post, serialize_profile, success_response

feed_bp = Blueprint("feed", __name__)


@feed_bp.route("/api/feed", methods=["GET"])
@token_required
def get_feed(current_user_email):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        current_user = get_user_by_email(cursor, current_user_email)
        if not current_user:
            return error_response("Usuario autenticado nao encontrado.", 404)

        cursor.execute(
            """
            SELECT
                post_id AS id,
                user_id,
                user_nome AS nome,
                user_email AS email,
                profile_pic_url,
                titulo,
                texto,
                audio_url,
                created_at,
                updated_at
            FROM UserPostsView
            ORDER BY created_at DESC
            LIMIT 8
            """
        )
        posts = [serialize_post(post, "Oportunidade") for post in cursor.fetchall()]

        cursor.execute(
            """
            SELECT id, nome, email, profile_pic_url, descricao, links_sociais
            FROM users
            WHERE id != %s
            ORDER BY last_login DESC, nome ASC
            LIMIT 5
            """,
            (current_user["id"],),
        )
        profiles = [serialize_profile(profile) for profile in cursor.fetchall()]

        highlights = [
            {
                "label": "Projetos ativos",
                "value": len(posts),
            },
            {
                "label": "Perfis sugeridos",
                "value": len(profiles),
            },
        ]

        return success_response({
            "highlights": highlights,
            "posts": posts,
            "opportunities": posts[:4],
            "suggested_profiles": profiles,
        })
    except Exception as err:
        return error_response("Erro ao montar feed inicial.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()
