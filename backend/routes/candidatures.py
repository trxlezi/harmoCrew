from flask import Blueprint, request, jsonify
from db.database import get_connection
from middleware.auth import token_required

candidatures_bp = Blueprint('candidatures', __name__)

@candidatures_bp.route("/candidatar/<int:post_id>", methods=["POST"])
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
    except Exception as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@candidatures_bp.route("/candidaturas_recebidas_view", methods=["GET"])
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
    except Exception as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@candidatures_bp.route("/candidaturas/<int:candidatura_id>/<string:acao>", methods=["POST"])
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
    except Exception as err:
        return jsonify({"message": "Erro no banco de dados.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close() 