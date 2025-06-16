from flask import Blueprint, request, jsonify
from db.database import get_connection
from middleware.auth import token_required

users_bp = Blueprint('users', __name__)

@users_bp.route("/search_users", methods=["GET"])
@token_required
def search_users(current_user_email):
    query = request.args.get('query') or request.args.get('q') or ''
    query = query.strip()
    if not query:
        return jsonify({"users": []})

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT id, nome, email, profile_pic_url
            FROM users
            WHERE (nome LIKE %s OR email LIKE %s)
            AND email != %s
            LIMIT 10
        """, (f'%{query}%', f'%{query}%', current_user_email))
        users = cursor.fetchall()
        for user in users:
            user['profile_pic_url'] = user.get('profile_pic_url') or f"https://i.pravatar.cc/150?u={user['id']}"
        return jsonify({"users": users})
    except Exception as err:
        return jsonify({"message": "Erro ao buscar usuários.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@users_bp.route("/user/<int:view_user_id>", methods=["GET"])
@token_required
def get_user_by_id(current_user_email, view_user_id):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Get user info
        cursor.execute("""
            SELECT id, nome, email, profile_pic_url, descricao, links_sociais
            FROM users
            WHERE id = %s
        """, (view_user_id,))
        user = cursor.fetchone()
        
        if not user:
            return jsonify({"message": "Usuário não encontrado.", "user": None}), 404

        # Get following status
        cursor.execute("""
            SELECT 1 FROM follows
            WHERE follower_id = (SELECT id FROM users WHERE email = %s)
            AND following_id = %s
        """, (current_user_email, view_user_id))
        is_following = bool(cursor.fetchone())

        user['profile_pic_url'] = user.get('profile_pic_url') or f"https://i.pravatar.cc/150?u={user['id']}"
        user['is_following'] = is_following
        user['links'] = user.get('links_sociais')
        if 'links_sociais' not in user:
            user['links_sociais'] = ''
        if 'descricao' not in user:
            user['descricao'] = ''

        return jsonify({"user": user})
    except Exception as err:
        print('Erro em /user/<id>:', err)
        return jsonify({"message": "Erro ao buscar usuário.", "error": str(err), "user": None}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@users_bp.route("/follow/<int:user_to_follow_id>", methods=["POST"])
@token_required
def follow_user(current_user_email, user_to_follow_id):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()

        # Get current user's ID
        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        current_user = cursor.fetchone()
        if not current_user:
            return jsonify({"message": "Usuário não encontrado."}), 404

        # Check if already following
        cursor.execute("""
            SELECT 1 FROM follows
            WHERE follower_id = %s AND following_id = %s
        """, (current_user[0], user_to_follow_id))
        if cursor.fetchone():
            return jsonify({"message": "Você já está seguindo este usuário."}), 400

        # Add follow relationship
        cursor.execute("""
            INSERT INTO follows (follower_id, following_id)
            VALUES (%s, %s)
        """, (current_user[0], user_to_follow_id))
        conn.commit()

        return jsonify({"message": "Usuário seguido com sucesso!"}), 200
    except Exception as err:
        return jsonify({"message": "Erro ao seguir usuário.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@users_bp.route('/unfollow/<int:user_to_unfollow_id>', methods=['POST'])
@token_required
def unfollow(current_user_email, user_to_unfollow_id):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()

        # Get current user's ID
        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        current_user = cursor.fetchone()
        if not current_user:
            return jsonify({"message": "Usuário não encontrado."}), 404

        # Remove follow relationship
        cursor.execute("""
            DELETE FROM follows
            WHERE follower_id = %s AND following_id = %s
        """, (current_user[0], user_to_unfollow_id))
        conn.commit()

        return jsonify({"message": "Deixou de seguir o usuário com sucesso!"}), 200
    except Exception as err:
        return jsonify({"message": "Erro ao deixar de seguir usuário.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@users_bp.route("/followers/<int:user_id_profile>", methods=["GET"])
@token_required
def get_followers(current_user_email, user_id_profile):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT u.id, u.nome, u.email, u.profile_pic_url
            FROM users u
            INNER JOIN follows f ON u.id = f.follower_id
            WHERE f.following_id = %s
        """, (user_id_profile,))
        followers = cursor.fetchall()
        for follower in followers:
            follower['profile_pic_url'] = follower.get('profile_pic_url') or f"https://i.pravatar.cc/150?u={follower['id']}"
        return jsonify({"followers": followers or []})
    except Exception as err:
        print('Erro em /followers/<id>:', err)
        return jsonify({"message": "Erro ao buscar seguidores.", "error": str(err), "followers": []}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@users_bp.route("/following/<int:user_id_profile>", methods=["GET"])
@token_required
def get_user_following_list(current_user_email, user_id_profile):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT u.id, u.nome, u.email, u.profile_pic_url
            FROM users u
            INNER JOIN follows f ON u.id = f.following_id
            WHERE f.follower_id = %s
        """, (user_id_profile,))
        following = cursor.fetchall()
        for user in following:
            user['profile_pic_url'] = user.get('profile_pic_url') or f"https://i.pravatar.cc/150?u={user['id']}"
        return jsonify({"following": following or []})
    except Exception as err:
        print('Erro em /following/<id>:', err)
        return jsonify({"message": "Erro ao buscar usuários seguidos.", "error": str(err), "following": []}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@users_bp.route("/user/me/descricao", methods=["PUT"])
@token_required
def update_my_descricao(current_user_email):
    data = request.json or {}
    nova_descricao = data.get("descricao", "").strip()

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE users
            SET descricao = %s
            WHERE email = %s
        """, (nova_descricao, current_user_email))
        conn.commit()
        return jsonify({"message": "Descrição atualizada com sucesso!"}), 200
    except Exception as err:
        return jsonify({"message": "Erro ao atualizar descrição.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@users_bp.route("/user/me/links", methods=["PUT"])
@token_required
def update_my_links(current_user_email):
    data = request.json or {}
    novos_links = data.get("links", "").strip()

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE users
            SET links = %s
            WHERE email = %s
        """, (novos_links, current_user_email))
        conn.commit()
        return jsonify({"message": "Links atualizados com sucesso!"}), 200
    except Exception as err:
        return jsonify({"message": "Erro ao atualizar links.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close() 