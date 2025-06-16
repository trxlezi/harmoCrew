from flask import Blueprint, request, jsonify
from db.database import get_connection
from middleware.auth import token_required

messages_bp = Blueprint('messages', __name__)

@messages_bp.route("/messages", methods=["POST"])
@token_required
def send_message(current_user_email):
    data = request.json or {}
    receiver_id = data.get("receiver_id")
    message_text = data.get("message", "").strip()

    if not receiver_id or not message_text:
        return jsonify({"message": "ID do destinatário e mensagem são obrigatórios."}), 400

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()

        # Get sender's ID
        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        sender = cursor.fetchone()
        if not sender:
            return jsonify({"message": "Usuário não encontrado."}), 404

        # Insert message
        cursor.execute("""
            INSERT INTO messages (sender_id, receiver_id, content)
            VALUES (%s, %s, %s)
        """, (sender[0], receiver_id, message_text))
        conn.commit()

        return jsonify({"message": "Mensagem enviada com sucesso!"}), 201
    except Exception as err:
        return jsonify({"message": "Erro ao enviar mensagem.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@messages_bp.route("/messages/<int:receiver_id>", methods=["GET"])
@token_required
def get_conversation(current_user_email, receiver_id):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        # Get current user's ID
        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        current_user = cursor.fetchone()
        if not current_user:
            return jsonify({"message": "Usuário não encontrado."}), 404

        # Get messages between users
        cursor.execute("""
            SELECT 
                m.id,
                m.sender_id,
                m.receiver_id,
                m.content,
                m.timestamp,
                s.nome as sender_nome,
                r.nome as receiver_nome
            FROM messages m
            JOIN users s ON m.sender_id = s.id
            JOIN users r ON m.receiver_id = r.id
            WHERE (m.sender_id = %s AND m.receiver_id = %s)
               OR (m.sender_id = %s AND m.receiver_id = %s)
            ORDER BY m.timestamp ASC
        """, (current_user['id'], receiver_id, receiver_id, current_user['id']))
        messages = cursor.fetchall()

        # Format messages
        for message in messages:
            message['timestamp'] = message['timestamp'].strftime("%Y-%m-%d %H:%M:%S")
            message['is_sender'] = message['sender_id'] == current_user['id']

        return jsonify({"messages": messages})
    except Exception as err:
        return jsonify({"message": "Erro ao buscar mensagens.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

@messages_bp.route("/messages/contacts", methods=["GET"])
@token_required
def get_chat_contacts(current_user_email):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        # Get current user's ID
        cursor.execute("SELECT id FROM users WHERE email = %s", (current_user_email,))
        current_user = cursor.fetchone()
        if not current_user:
            return jsonify({"message": "Usuário não encontrado."}), 404

        # Get all users who have exchanged messages with current user
        cursor.execute("""
            SELECT DISTINCT
                u.id,
                u.nome,
                u.email,
                u.profile_pic_url,
                (
                    SELECT content
                    FROM messages
                    WHERE (sender_id = %s AND receiver_id = u.id)
                       OR (sender_id = u.id AND receiver_id = %s)
                    ORDER BY timestamp DESC
                    LIMIT 1
                ) as last_message,
                (
                    SELECT timestamp
                    FROM messages
                    WHERE (sender_id = %s AND receiver_id = u.id)
                       OR (sender_id = u.id AND receiver_id = %s)
                    ORDER BY timestamp DESC
                    LIMIT 1
                ) as last_message_time
            FROM users u
            INNER JOIN messages m ON (m.sender_id = u.id OR m.receiver_id = u.id)
            WHERE (m.sender_id = %s OR m.receiver_id = %s)
            AND u.id != %s
            ORDER BY last_message_time DESC
        """, (current_user['id'], current_user['id'], current_user['id'], current_user['id'], 
              current_user['id'], current_user['id'], current_user['id']))
        
        contacts = cursor.fetchall()
        for contact in contacts:
            contact['profile_pic_url'] = contact.get('profile_pic_url') or f"https://i.pravatar.cc/150?u={contact['id']}"
            if contact['last_message_time']:
                contact['last_message_time'] = contact['last_message_time'].strftime("%Y-%m-%d %H:%M:%S")

        return jsonify({"contacts": contacts})
    except Exception as err:
        return jsonify({"message": "Erro ao buscar contatos.", "error": str(err)}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close() 