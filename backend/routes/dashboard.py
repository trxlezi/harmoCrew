from flask import Blueprint
from db.database import get_connection
from middleware.auth import token_required
from routes.shared import error_response, get_user_by_email, success_response

dashboard_bp = Blueprint("dashboard", __name__)


@dashboard_bp.route("/api/dashboard/summary", methods=["GET"])
@token_required
def get_dashboard_summary(current_user_email):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        current_user = get_user_by_email(cursor, current_user_email)
        if not current_user:
            return error_response("Usuario autenticado nao encontrado.", 404)

        cursor.execute(
            "SELECT COUNT(*) AS total FROM posts WHERE user_id = %s",
            (current_user["id"],),
        )
        own_opportunities = cursor.fetchone()["total"]

        cursor.execute(
            "SELECT COUNT(*) AS total FROM candidaturas WHERE user_id = %s",
            (current_user["id"],),
        )
        sent = cursor.fetchone()["total"]

        cursor.execute(
            """
            SELECT COUNT(*) AS total
            FROM candidaturas c
            JOIN posts p ON p.id = c.post_id
            WHERE p.user_id = %s
            """,
            (current_user["id"],),
        )
        received = cursor.fetchone()["total"]

        cursor.execute(
            """
            SELECT
                c.id AS candidatura_id,
                c.status AS status_candidatura,
                p.titulo AS post_titulo,
                u.nome AS candidato_nome,
                DATE_FORMAT(c.data, '%d/%m %H:%i') AS data_candidatura
            FROM candidaturas c
            JOIN posts p ON p.id = c.post_id
            JOIN users u ON u.id = c.user_id
            WHERE c.user_id = %s OR p.user_id = %s
            ORDER BY c.data DESC
            LIMIT 5
            """,
            (current_user["id"], current_user["id"]),
        )
        candidacies = cursor.fetchall()

        cursor.execute(
            """
            SELECT
                c.id AS candidatura_id,
                c.status AS status_candidatura,
                DATE_FORMAT(c.data, '%d/%m %H:%i') AS data_candidatura,
                u.id AS candidato_id,
                u.nome AS candidato_nome,
                u.email AS candidato_email,
                p.id AS post_id,
                p.titulo AS post_titulo
            FROM candidaturas c
            JOIN posts p ON p.id = c.post_id
            JOIN users u ON u.id = c.user_id
            WHERE p.user_id = %s
            ORDER BY c.data DESC
            LIMIT 12
            """,
            (current_user["id"],),
        )
        received_candidacies = cursor.fetchall()

        cursor.execute(
            """
            SELECT
                m.id,
                m.content,
                DATE_FORMAT(m.timestamp, '%d/%m %H:%i') AS timestamp
            FROM messages m
            WHERE m.sender_id = %s OR m.receiver_id = %s
            ORDER BY m.timestamp DESC
            LIMIT 5
            """,
            (current_user["id"], current_user["id"]),
        )
        recent_messages = cursor.fetchall()

        return success_response({
            "totals": {
                "received": received,
                "sent": sent,
                "open_opportunities": own_opportunities,
            },
            "recent_candidacies": candidacies,
            "received_candidacies": received_candidacies,
            "recent_messages": recent_messages,
        })
    except Exception as err:
        return error_response("Erro ao montar resumo do painel.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()
