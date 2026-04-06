from flask import Blueprint, request
from db.database import get_connection
from middleware.auth import token_required
from routes.shared import error_response, get_user_by_email, success_response

messages_bp = Blueprint("messages", __name__)


@messages_bp.route("/messages", methods=["POST"])
@messages_bp.route("/api/messages", methods=["POST"])
@token_required
def send_message(current_user_email):
    data = request.json or {}
    receiver_id = data.get("receiver_id")
    message_text = data.get("message", "").strip()

    if not receiver_id or not message_text:
        return error_response("Destinatario e mensagem sao obrigatorios.", 400)

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        sender = get_user_by_email(cursor, current_user_email)
        if not sender:
            return error_response("Usuario autenticado nao encontrado.", 404)

        cursor.execute(
            "INSERT INTO messages (sender_id, receiver_id, content) VALUES (%s, %s, %s)",
            (sender["id"], receiver_id, message_text),
        )
        conn.commit()
        return success_response({"message": "Mensagem enviada com sucesso."}, status=201)
    except Exception as err:
        return error_response("Erro ao enviar mensagem.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@messages_bp.route("/messages/<int:receiver_id>", methods=["GET"])
@messages_bp.route("/api/messages/conversations/<int:receiver_id>", methods=["GET"])
@token_required
def get_conversation(current_user_email, receiver_id):
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
                m.id,
                m.sender_id,
                m.receiver_id,
                m.content,
                DATE_FORMAT(m.timestamp, '%d/%m %H:%i') AS timestamp
            FROM messages m
            WHERE (m.sender_id = %s AND m.receiver_id = %s)
               OR (m.sender_id = %s AND m.receiver_id = %s)
            ORDER BY m.timestamp ASC
            """,
            (current_user["id"], receiver_id, receiver_id, current_user["id"]),
        )
        messages = cursor.fetchall()
        for message in messages:
            message["is_sender"] = message["sender_id"] == current_user["id"]

        return success_response({"messages": messages})
    except Exception as err:
        return error_response("Erro ao buscar conversa.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@messages_bp.route("/messages/contacts", methods=["GET"])
@messages_bp.route("/api/messages/contacts", methods=["GET"])
@token_required
def get_chat_contacts(current_user_email):
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
                ) AS last_message,
                (
                    SELECT DATE_FORMAT(timestamp, '%d/%m %H:%i')
                    FROM messages
                    WHERE (sender_id = %s AND receiver_id = u.id)
                       OR (sender_id = u.id AND receiver_id = %s)
                    ORDER BY timestamp DESC
                    LIMIT 1
                ) AS last_message_time
            FROM users u
            INNER JOIN follows f1 ON f1.following_id = u.id
            INNER JOIN follows f2 ON f2.follower_id = u.id
            WHERE f1.follower_id = %s
              AND f2.following_id = %s
              AND u.id != %s
            ORDER BY last_message_time DESC, u.nome ASC
            """,
            (
                current_user["id"],
                current_user["id"],
                current_user["id"],
                current_user["id"],
                current_user["id"],
                current_user["id"],
                current_user["id"],
            ),
        )
        contacts = cursor.fetchall()
        for contact in contacts:
            contact["profile_pic_url"] = contact.get("profile_pic_url") or f"https://i.pravatar.cc/150?u={contact['id']}"

        return success_response({"contacts": contacts})
    except Exception as err:
        return error_response("Erro ao buscar contatos do chat.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()
