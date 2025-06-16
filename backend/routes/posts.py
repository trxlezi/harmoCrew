from flask import Blueprint, request, jsonify
import datetime
from db.database import get_connection
from middleware.auth import token_required

posts_bp = Blueprint('posts', __name__)

@posts_bp.route("/posts", methods=["GET"])
@token_required
def get_posts(current_user_email):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT 
                post_id AS id,
                user_id,
                user_nome AS nome,
                user_email AS email,
                titulo,
                texto,
                audio_url,
                created_at,
                updated_at
            FROM UserPostsView
            ORDER BY created_at DESC
            LIMIT 50
        """)
        posts = cursor.fetchall()
        for post in posts:
            post['profile_pic_url'] = post.get('profile_pic_url') or f"https://i.pravatar.cc/50?u={post['user_id']}"
            post['data'] = post['created_at'].strftime("%Y-%m-%d %H:%M:%S") if post['created_at'] else None
            post['audio_url'] = post.get('audio_url')
            post['titulo'] = post.get('titulo', '')
        return jsonify({"posts": posts})
    except Exception as err:
        return jsonify({"message": "Erro no banco de dados ao buscar posts.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@posts_bp.route("/posts", methods=["POST"])
@token_required
def create_post(current_user_email):
    data = request.json or {}
    titulo = data.get("titulo", "").strip()
    texto = data.get("texto", "").strip()
    raw_audio_url = data.get("audio_url")
    audio_url = raw_audio_url.strip() if isinstance(raw_audio_url, str) else None

    if not titulo or not texto: 
        return jsonify({"message": "Título e texto do post não podem ser vazios."}), 400

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id, nome, profile_pic_url FROM users WHERE email = %s", (current_user_email,))
        user = cursor.fetchone()
        if not user:
            return jsonify({"message": "Usuário não encontrado."}), 404

        cursor.execute(
            "INSERT INTO posts (user_id, titulo, texto, audio_url) VALUES (%s, %s, %s, %s)",
            (user['id'], titulo, texto, audio_url)
        )
        conn.commit()
        post_id = cursor.lastrowid

        created_at_datetime = datetime.datetime.now(datetime.UTC)
        new_post_data = {
            "id": post_id,
            "user_id": user['id'],
            "nome": user['nome'],
            "profile_pic_url": user.get('profile_pic_url') or f"https://i.pravatar.cc/50?u={user['id']}",
            "titulo": titulo,
            "texto": texto,
            "audio_url": audio_url,
            "data": created_at_datetime.strftime("%Y-%m-%d %H:%M:%S") 
        }
        return jsonify({"message": "Post criado com sucesso!", "post": new_post_data}), 201
    except Exception as err:
        return jsonify({"message": "Erro no banco de dados ao criar post.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@posts_bp.route("/user/<int:user_id>/posts", methods=["GET"])
@token_required
def get_user_posts(current_user_email, user_id):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT 
                post_id AS id,
                user_id,
                user_nome AS nome,
                user_email AS email,
                titulo,
                texto,
                audio_url,
                created_at,
                updated_at
            FROM UserPostsView
            WHERE user_id = %s
            ORDER BY created_at DESC
        """, (user_id,))
        posts = cursor.fetchall()
        for post in posts:
            post['profile_pic_url'] = post.get('profile_pic_url') or f"https://i.pravatar.cc/50?u={post['user_id']}"
            post['data'] = post['created_at'].strftime("%Y-%m-%d %H:%M:%S") if post['created_at'] else None
            post['audio_url'] = post.get('audio_url')
            post['titulo'] = post.get('titulo', '')
        return jsonify({"posts": posts})
    except Exception as err:
        return jsonify({"message": "Erro no banco de dados ao buscar posts do usuário.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close() 