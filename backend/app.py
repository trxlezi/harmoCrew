import re
import mysql.connector
from flask import Flask, request, jsonify
from flask_cors import CORS
import jwt
import datetime
from functools import wraps
from werkzeug.security import generate_password_hash, check_password_hash
from db.init_db import init_db
from db.database import get_connection

init_db()

app = Flask(__name__)

CORS(app, 
     resources={r"/*": {
         "origins": ["http://localhost:3000", "http://127.0.0.1:3000"]
     }},
     allow_headers=["Authorization", "Content-Type", "X-Requested-With"],
     methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
     supports_credentials=True,
     expose_headers=["Content-Type", "Authorization"]
)

app.config['SECRET_KEY'] = '4f7d8a9b2c3e1f0a9d7b5e6c8f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a'

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
    return "Backend HarmoCrew está funcionando!"

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
        cursor.execute("UPDATE users SET profile_pic_url = %s WHERE email = %s", (default_profile_pic_url, email))
        conn.commit()
        return jsonify({"message": "Usuário criado com sucesso!"}), 201
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados ao registrar.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

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
        cursor.execute("SELECT id, nome, email, senha, profile_pic_url FROM users WHERE email = %s", (email,))
        user = cursor.fetchone()

        if not user or not check_password_hash(user['senha'], senha):
            return jsonify({"message": "Email ou senha incorretos."}), 401

        expiration_time = datetime.datetime.now(datetime.UTC) + datetime.timedelta(hours=24)
        token = jwt.encode({
            'email': user['email'],
            'id': user['id'], 
            'exp': expiration_time
        }, app.config['SECRET_KEY'], algorithm="HS256")
        
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
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados ao logar.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/profile", methods=["GET"])
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
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados ao buscar perfil.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/posts", methods=["GET"])
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
            post['profile_pic_url'] = f"https://i.pravatar.cc/50?u={post['user_id']}"
            post['data'] = post['created_at'].strftime("%Y-%m-%d %H:%M:%S") if post['created_at'] else None
            post['audio_url'] = post.get('audio_url')
            post['titulo'] = post.get('titulo', '')
        return jsonify({"posts": posts})
    except mysql.connector.Error as err:
        print('Erro MySQL:', err)
        return jsonify({"message": "Erro no banco de dados ao buscar posts.", "error": str(err)}), 500
    except Exception as e:
        import traceback
        print('Erro inesperado em /posts:', e)
        traceback.print_exc()
        return jsonify({"message": "Erro inesperado ao buscar posts.", "error": str(e)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/posts", methods=["POST"])
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
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados ao criar post.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/candidatar/<int:post_id>", methods=["POST"])
@token_required
def candidatar(current_user_email, post_id):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True) 
        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        user = cursor.fetchone()
        if not user:
            return jsonify({"message": "Usuário não encontrado."}), 404
        user_id = user['id']

        cursor.execute("SELECT user_id FROM posts WHERE id = %s", (post_id,))
        post_owner = cursor.fetchone()
        if not post_owner:
            return jsonify({"message": "Post não encontrado."}), 404
        
        if post_owner['user_id'] == user_id:
            return jsonify({"message": "Você não pode se candidatar ao seu próprio post."}), 400

        cursor.execute("SELECT 1 FROM candidaturas WHERE user_id = %s AND post_id = %s", (user_id, post_id))
        if cursor.fetchone():
            return jsonify({"message": "Você já se candidatou a este post."}), 400

        cursor.execute("INSERT INTO candidaturas (user_id, post_id) VALUES (%s, %s)", (user_id, post_id))
        conn.commit()
        return jsonify({"message": "Candidatura enviada com sucesso!"})
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/candidaturas_recebidas_view", methods=["GET"])
@token_required
def candidaturas_recebidas_view(current_user_email):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        user = cursor.fetchone()
        if not user:
            return jsonify({"message": "Usuário não encontrado."}), 404
        user_id = user['id']
        cursor.execute("""
            SELECT * FROM CandidacyDetailsView WHERE owner_id = %s ORDER BY data_candidatura DESC
        """, (user_id,))
        candidaturas = cursor.fetchall()
        return jsonify({"candidaturas": candidaturas})
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/candidaturas/<int:candidatura_id>/<string:acao>", methods=["POST"])
@token_required
def atualizar_candidatura_status(current_user_email, candidatura_id, acao): 
    if acao not in ("aceitar", "rejeitar"):
        return jsonify({"message": "Ação inválida. Use 'aceitar' ou 'rejeitar'."}), 400
    
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        user = cursor.fetchone()
        if not user:
            return jsonify({"message": "Usuário não encontrado."}), 404
        user_id = user['id']

        cursor.execute("""
            SELECT c.id, p.user_id AS dono_post_id
            FROM candidaturas c
            JOIN posts p ON c.post_id = p.id
            WHERE c.id = %s
        """, (candidatura_id,))
        candidatura = cursor.fetchone()

        if not candidatura:
            return jsonify({"message": "Candidatura não encontrada."}), 404

        if candidatura['dono_post_id'] != user_id:
            return jsonify({"message": "Você não tem permissão para alterar esta candidatura."}), 403

        novo_status = "aceito" if acao == "aceitar" else "rejeitado"
        cursor.callproc('UpdateCandidacyStatus', (candidatura_id, novo_status))
        conn.commit()
        return jsonify({"message": f"Candidatura {novo_status} com sucesso."})
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/search_users", methods=["GET"])
@token_required 
def search_users(current_user_email):
    termo = request.args.get("q", "").strip()
    if not termo:
        return jsonify({"users": []})
    
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id, nome, email, profile_pic_url FROM users WHERE nome LIKE %s LIMIT 10", (f"%{termo}%",))
        usuarios = cursor.fetchall()

        for usuario in usuarios:
            usuario['profile_pic_url'] = usuario.get('profile_pic_url') or f'https://i.pravatar.cc/30?u={usuario["id"]}'

        return jsonify({"users": usuarios})
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/user/<int:view_user_id>", methods=["GET"]) 
@token_required
def get_user_by_id(current_user_email, view_user_id): 
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("SELECT id, nome, email, profile_pic_url, descricao, links_sociais FROM users WHERE id = %s", (view_user_id,))
        user_profile = cursor.fetchone()

        if not user_profile:
            return jsonify({"message": "Usuário não encontrado."}), 404

        user_profile['profile_pic_url'] = user_profile.get('profile_pic_url') or f"https://i.pravatar.cc/150?u={user_profile['id']}"

        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        logged_user = cursor.fetchone()
        if not logged_user: 
            return jsonify({"message": "Erro ao identificar usuário logado."}), 500
        logged_user_id = logged_user['id']
        
        is_following = False
        if logged_user_id != view_user_id:
            cursor.execute("SELECT IsFollowing(%s, %s) AS is_following", (logged_user_id, view_user_id))
            is_following = bool(cursor.fetchone()['is_following'])
        
        cursor.execute("SELECT GetUserPostCount(%s) AS post_count", (view_user_id,))
        post_count = cursor.fetchone()['post_count']

        user_profile['is_following'] = is_following
        user_profile['post_count'] = post_count

        return jsonify({"user": user_profile})
    except mysql.connector.Error as err:
        import traceback
        traceback.print_exc()
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/follow/<int:user_to_follow_id>", methods=["POST"]) 
@token_required
def follow_user(current_user_email, user_to_follow_id): 
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True) 
        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        follower = cursor.fetchone()
        if not follower:
            return jsonify({"message": "Usuário seguidor não encontrado."}), 404
        follower_id = follower['id']

        if follower_id == user_to_follow_id:
            return jsonify({"message": "Você não pode seguir a si mesmo."}), 400

        cursor.execute("SELECT 1 FROM users WHERE id = %s", (user_to_follow_id,))
        if not cursor.fetchone():
            return jsonify({"message": "Usuário a ser seguido não encontrado."}), 404
        
        try:
            cursor.execute("INSERT INTO seguidores (seguidor_id, seguido_id) VALUES (%s, %s)", (follower_id, user_to_follow_id))
            conn.commit()
        except mysql.connector.IntegrityError as e:
            if e.errno == 1062: 
                return jsonify({"message": "Você já está seguindo este usuário."}), 409
            else:
                raise e 
        
        return jsonify({"message": "Seguindo usuário com sucesso!"})
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route('/unfollow/<int:user_to_unfollow_id>', methods=['POST']) 
@token_required
def unfollow(current_user_email, user_to_unfollow_id): 
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        current_user = cursor.fetchone()
        if not current_user:
            return jsonify({"message": "Usuário atual não encontrado."}), 404
        current_user_id = current_user['id']

        cursor.execute("DELETE FROM seguidores WHERE seguidor_id = %s AND seguido_id = %s", (current_user_id, user_to_unfollow_id))
        conn.commit()

        if cursor.rowcount == 0:
            return jsonify({"message": "Usuário não era seguido."}), 400

        return jsonify({"message": "Deixou de seguir o usuário com sucesso!"}), 200
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/followers/<int:user_id_profile>", methods=["GET"]) 
@token_required
def get_followers(current_user_email, user_id_profile): 
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT u.id, u.nome, u.email, u.profile_pic_url
            FROM seguidores s
            JOIN users u ON s.seguidor_id = u.id 
            WHERE s.seguido_id = %s
        """, (user_id_profile,))
        followers = cursor.fetchall()

        for follower_user in followers:
            follower_user['profile_pic_url'] = follower_user.get('profile_pic_url') or f'https://i.pravatar.cc/30?u={follower_user["id"]}'

        return jsonify({"followers": followers})
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro ao buscar seguidores.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/following/<int:user_id_profile>", methods=["GET"])
@token_required
def get_user_following_list(current_user_email, user_id_profile):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT u.id, u.nome, u.email, u.profile_pic_url
            FROM seguidores s
            JOIN users u ON s.seguido_id = u.id
            WHERE s.seguidor_id = %s 
        """, (user_id_profile,)) 
        following = cursor.fetchall()

        for followed_user in following:
            followed_user['profile_pic_url'] = followed_user.get('profile_pic_url') or f'https://i.pravatar.cc/30?u={followed_user["id"]}'
        
        return jsonify({"following": following})
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro ao buscar quem o usuário segue.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/user/<int:user_id>/posts", methods=["GET"])
@token_required
def get_user_posts(current_user_email, user_id):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.callproc('GetUserPosts', (user_id,))
        posts = []
        for result in cursor.stored_results():
            posts = result.fetchall()
        for post in posts:
            post['profile_pic_url'] = f"https://i.pravatar.cc/50?u={user_id}"
            post['data'] = post['created_at'].strftime("%Y-%m-%d %H:%M:%S") if post.get('created_at') else None
            post['audio_url'] = post.get('audio_url')
            post['titulo'] = post.get('titulo', '')
        return jsonify({"posts": posts})
    except mysql.connector.Error as err:
        print('Erro MySQL:', err)
        return jsonify({"message": "Erro ao buscar posts do usuário.", "error": str(err)}), 500
    except Exception as e:
        import traceback
        print('Erro inesperado em /user/<id>/posts:', e)
        traceback.print_exc()
        return jsonify({"message": "Erro inesperado ao buscar posts do usuário.", "error": str(e)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/user/<int:user_id>/following", methods=["GET"])
@token_required
def get_user_following(current_user_email, user_id):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT u.id, u.nome, u.email, u.profile_pic_url
            FROM seguidores s
            JOIN users u ON s.seguido_id = u.id
            WHERE s.seguidor_id = %s
        """, (user_id,))
        following = cursor.fetchall()
        for followed_user in following:
            followed_user['profile_pic_url'] = followed_user.get('profile_pic_url') or f'https://i.pravatar.cc/30?u={followed_user["id"]}'
        return jsonify({"following": following})
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro ao buscar quem o usuário segue.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/user/<int:user_id>/followers", methods=["GET"])
@token_required
def get_user_followers(current_user_email, user_id):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT u.id, u.nome, u.email, u.profile_pic_url
            FROM seguidores s
            JOIN users u ON s.seguidor_id = u.id
            WHERE s.seguido_id = %s
        """, (user_id,))
        followers = cursor.fetchall()
        for follower_user in followers:
            follower_user['profile_pic_url'] = follower_user.get('profile_pic_url') or f'https://i.pravatar.cc/30?u={follower_user["id"]}'
        return jsonify({"followers": followers})
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro ao buscar seguidores.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/api/me/following", methods=["GET"])
@token_required
def get_my_following(current_user_email):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        user = cursor.fetchone()
        if not user:
            return jsonify({"message": "Usuário logado não encontrado."}), 404
        current_user_id = user['id']

        cursor.execute("""
            SELECT u.id, u.nome, u.email, u.profile_pic_url 
            FROM seguidores s
            JOIN users u ON s.seguido_id = u.id
            WHERE s.seguidor_id = %s
        """, (current_user_id,))
        following_list = cursor.fetchall()

        for followed_user in following_list:
            followed_user['profile_pic_url'] = followed_user.get('profile_pic_url') or f'https://i.pravatar.cc/30?u={followed_user["id"]}'
        
        return jsonify({"following": following_list})
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/user/me/descricao", methods=["PUT"])
@token_required
def update_my_descricao(current_user_email):
    data = request.json or {}
    descricao = data.get("descricao", "").strip()
    if descricao is None:
        return jsonify({"message": "Descrição é obrigatória."}), 400
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE users SET descricao = %s WHERE email = %s", (descricao, current_user_email))
        conn.commit()
        return jsonify({"message": "Descrição atualizada com sucesso!"})
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro ao atualizar descrição.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/user/me/links", methods=["PUT"])
@token_required
def update_my_links(current_user_email):
    data = request.json or {}
    links_sociais = data.get("links_sociais", "").strip()
    if links_sociais is None:
        return jsonify({"message": "Links sociais são obrigatórios."}), 400
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE users SET links_sociais = %s WHERE email = %s", (links_sociais, current_user_email))
        conn.commit()
        return jsonify({"message": "Links sociais atualizados com sucesso!"})
    except mysql.connector.Error as err:
        return jsonify({"message": "Erro ao atualizar links sociais.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@app.route("/messages", methods=["POST"])
@token_required
def send_message(current_user_email):
    data = request.json or {}
    receiver_id = data.get("receiver_id")
    content = data.get("content", "").strip()

    if not receiver_id or not content:
        return jsonify({"message": "ID do destinatário e conteúdo são obrigatórios."}), 400

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        sender = cursor.fetchone()
        if not sender:
            return jsonify({"message": "Usuário remetente não encontrado."}), 404

        cursor.execute("SELECT id FROM users WHERE id = %s", (receiver_id,))
        if not cursor.fetchone():
            return jsonify({"message": "Usuário destinatário não encontrado."}), 404

        cursor.execute("""
            INSERT INTO messages (sender_id, receiver_id, content)
            VALUES (%s, %s, %s)
        """, (sender['id'], receiver_id, content))
        conn.commit()

        return jsonify({"message": "Mensagem enviada com sucesso!"}), 201

    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route("/messages/<int:receiver_id>", methods=["GET"])
@token_required
def get_conversation(current_user_email, receiver_id):
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        sender = cursor.fetchone()
        if not sender:
            return jsonify({"message": "Usuário não encontrado."}), 404

        cursor.execute("""
            SELECT 
                m.id, m.sender_id, m.receiver_id, m.content, m.timestamp,
                s.nome AS sender_nome, r.nome AS receiver_nome
            FROM messages m
            JOIN users s ON m.sender_id = s.id
            JOIN users r ON m.receiver_id = r.id
            WHERE 
                (m.sender_id = %s AND m.receiver_id = %s)
                OR
                (m.sender_id = %s AND m.receiver_id = %s)
            ORDER BY m.timestamp ASC
        """, (sender['id'], receiver_id, receiver_id, sender['id']))
        
        messages = cursor.fetchall()
        for msg in messages:
            msg['timestamp'] = msg['timestamp'].strftime("%Y-%m-%d %H:%M:%S")

        return jsonify({"messages": messages})

    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route("/messages/contacts", methods=["GET"])
@token_required
def get_chat_contacts(current_user_email):
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        # Pega o ID do usuário atual
        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        user = cursor.fetchone()
        if not user:
            return jsonify({"message": "Usuário não encontrado."}), 404

        user_id = user['id']

        # Retorna apenas os seguidores do usuário logado
        cursor.execute('''
            SELECT u.id, u.nome, u.email
            FROM seguidores s
            JOIN users u ON s.seguidor_id = u.id
            WHERE s.seguido_id = %s
        ''', (user_id,))
        contacts = cursor.fetchall()
        return jsonify({"contacts": contacts})

    except mysql.connector.Error as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000)
