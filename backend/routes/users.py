from flask import Blueprint, request
from db.database import get_connection
from middleware.auth import token_required
from routes.shared import error_response, get_user_by_email, serialize_profile, success_response

users_bp = Blueprint("users", __name__)


def _resolve_profile(cursor, current_user_email, view_user_id):
    cursor.execute(
        "SELECT id, nome, email, profile_pic_url, descricao, links_sociais FROM users WHERE id = %s",
        (view_user_id,),
    )
    user = cursor.fetchone()
    if not user:
        return None

    current_user = get_user_by_email(cursor, current_user_email)
    is_following = False
    if current_user:
        cursor.execute(
            "SELECT 1 FROM follows WHERE follower_id = %s AND following_id = %s",
            (current_user["id"], view_user_id),
        )
        is_following = bool(cursor.fetchone())

    return serialize_profile(user, is_following=is_following)


@users_bp.route("/search_users", methods=["GET"])
@users_bp.route("/api/profiles/search", methods=["GET"])
@token_required
def search_users(current_user_email):
    query = request.args.get("query") or request.args.get("q") or ""
    query = query.strip()
    if not query:
        return success_response({"profiles": [], "users": []})

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT id, nome, email, profile_pic_url, descricao, links_sociais
            FROM users
            WHERE (nome LIKE %s OR email LIKE %s) AND email != %s
            ORDER BY nome ASC
            LIMIT 10
            """,
            (f"%{query}%", f"%{query}%", current_user_email),
        )
        profiles = [serialize_profile(user) for user in cursor.fetchall()]
        return success_response({"profiles": profiles, "users": profiles})
    except Exception as err:
        return error_response("Erro ao buscar perfis.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@users_bp.route("/user/<int:view_user_id>", methods=["GET"])
@users_bp.route("/api/profiles/<int:view_user_id>", methods=["GET"])
@token_required
def get_user_by_id(current_user_email, view_user_id):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        profile = _resolve_profile(cursor, current_user_email, view_user_id)
        if not profile:
            return error_response("Usuario nao encontrado.", 404)
        return success_response({"profile": profile, "user": profile})
    except Exception as err:
        return error_response("Erro ao buscar perfil.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@users_bp.route("/api/profiles/me", methods=["GET"])
@token_required
def get_me(current_user_email):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        user = get_user_by_email(cursor, current_user_email)
        if not user:
            return error_response("Usuario nao encontrado.", 404)
        profile = serialize_profile(user, is_following=False)
        return success_response({"profile": profile, "user": profile})
    except Exception as err:
        return error_response("Erro ao buscar o proprio perfil.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@users_bp.route("/follow/<int:user_to_follow_id>", methods=["POST"])
@users_bp.route("/api/profiles/<int:user_to_follow_id>/follow", methods=["POST"])
@token_required
def follow_user(current_user_email, user_to_follow_id):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        current_user = get_user_by_email(cursor, current_user_email)
        if not current_user:
            return error_response("Usuario autenticado nao encontrado.", 404)

        cursor.execute(
            "SELECT id FROM follows WHERE follower_id = %s AND following_id = %s",
            (current_user["id"], user_to_follow_id),
        )
        if cursor.fetchone():
            return error_response("Voce ja segue este perfil.", 400)

        cursor.execute(
            "INSERT INTO follows (follower_id, following_id) VALUES (%s, %s)",
            (current_user["id"], user_to_follow_id),
        )
        conn.commit()
        profile = _resolve_profile(cursor, current_user_email, user_to_follow_id)
        return success_response({"profile": profile, "message": "Perfil seguido com sucesso."})
    except Exception as err:
        return error_response("Erro ao seguir perfil.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@users_bp.route("/unfollow/<int:user_to_unfollow_id>", methods=["POST"])
@users_bp.route("/api/profiles/<int:user_to_unfollow_id>/follow", methods=["DELETE"])
@token_required
def unfollow_user(current_user_email, user_to_unfollow_id):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        current_user = get_user_by_email(cursor, current_user_email)
        if not current_user:
            return error_response("Usuario autenticado nao encontrado.", 404)

        cursor.execute(
            "DELETE FROM follows WHERE follower_id = %s AND following_id = %s",
            (current_user["id"], user_to_unfollow_id),
        )
        conn.commit()
        profile = _resolve_profile(cursor, current_user_email, user_to_unfollow_id)
        return success_response({"profile": profile, "message": "Perfil removido da sua rede."})
    except Exception as err:
        return error_response("Erro ao deixar de seguir perfil.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@users_bp.route("/followers/<int:user_id_profile>", methods=["GET"])
@token_required
def get_followers(current_user_email, user_id_profile):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT u.id, u.nome, u.email, u.profile_pic_url, u.descricao, u.links_sociais
            FROM users u
            INNER JOIN follows f ON u.id = f.follower_id
            WHERE f.following_id = %s
            ORDER BY u.nome ASC
            """,
            (user_id_profile,),
        )
        followers = [serialize_profile(user) for user in cursor.fetchall()]
        return success_response({"followers": followers})
    except Exception as err:
        return error_response("Erro ao buscar seguidores.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@users_bp.route("/following/<int:user_id_profile>", methods=["GET"])
@token_required
def get_following(current_user_email, user_id_profile):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT u.id, u.nome, u.email, u.profile_pic_url, u.descricao, u.links_sociais
            FROM users u
            INNER JOIN follows f ON u.id = f.following_id
            WHERE f.follower_id = %s
            ORDER BY u.nome ASC
            """,
            (user_id_profile,),
        )
        following = [serialize_profile(user) for user in cursor.fetchall()]
        return success_response({"following": following})
    except Exception as err:
        return error_response("Erro ao buscar perfis seguidos.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@users_bp.route("/user/me/descricao", methods=["PUT"])
@users_bp.route("/api/profiles/me/description", methods=["PUT"])
@token_required
def update_description(current_user_email):
    payload = request.json or {}
    new_description = payload.get("descricao", "").strip()

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            "UPDATE users SET descricao = %s WHERE email = %s",
            (new_description, current_user_email),
        )
        conn.commit()
        user = get_user_by_email(cursor, current_user_email)
        profile = serialize_profile(user, is_following=False)
        return success_response({"profile": profile, "message": "Descricao atualizada."})
    except Exception as err:
        return error_response("Erro ao atualizar descricao.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@users_bp.route("/user/me/links", methods=["PUT"])
@users_bp.route("/api/profiles/me/links", methods=["PUT"])
@token_required
def update_links(current_user_email):
    payload = request.json or {}
    links = payload.get("links_sociais")
    if links is None:
        links = payload.get("links", "")
    links = str(links).strip()

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            "UPDATE users SET links_sociais = %s WHERE email = %s",
            (links, current_user_email),
        )
        conn.commit()
        user = get_user_by_email(cursor, current_user_email)
        profile = serialize_profile(user, is_following=False)
        return success_response({"profile": profile, "message": "Links atualizados."})
    except Exception as err:
        return error_response("Erro ao atualizar links.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()
