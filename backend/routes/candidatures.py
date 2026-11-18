from flask import Blueprint
from db.database import get_connection
from middleware.auth import token_required
from routes.shared import error_response, get_user_by_email, success_response

candidatures_bp = Blueprint("candidatures", __name__)


@candidatures_bp.route("/candidatar/<int:post_id>", methods=["POST"])
@candidatures_bp.route("/api/opportunities/<int:post_id>/apply", methods=["POST"])
@token_required
def candidatar(current_user_email, post_id):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        user = get_user_by_email(cursor, current_user_email)
        if not user:
            return error_response("Usuario autenticado nao encontrado.", 404)

        cursor.execute("SELECT id, user_id, titulo FROM posts WHERE id = %s", (post_id,))
        post = cursor.fetchone()
        if not post:
            return error_response("Oportunidade nao encontrada.", 404)
        if post["user_id"] == user["id"]:
            return error_response("Voce nao pode se candidatar ao proprio projeto.", 400)

        cursor.execute(
            "SELECT id FROM candidaturas WHERE user_id = %s AND post_id = %s",
            (user["id"], post_id),
        )
        if cursor.fetchone():
            return error_response("Voce ja se candidatou a esta oportunidade.", 400)

        cursor.execute(
            "INSERT INTO candidaturas (user_id, post_id) VALUES (%s, %s)",
            (user["id"], post_id),
        )
        conn.commit()
        return success_response({
            "message": "Candidatura enviada com sucesso.",
            "candidacy": {"post_id": post_id, "status": "pendente"},
        })
    except Exception as err:
        return error_response("Erro ao registrar candidatura.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@candidatures_bp.route("/candidaturas_recebidas_view", methods=["GET"])
@candidatures_bp.route("/api/candidacies/received", methods=["GET"])
@token_required
def candidaturas_recebidas_view(current_user_email):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        user = get_user_by_email(cursor, current_user_email)
        if not user:
            return error_response("Usuario autenticado nao encontrado.", 404)

        cursor.execute(
            """
            SELECT *
            FROM CandidacyDetailsView
            WHERE owner_id = %s
            ORDER BY data_candidatura DESC
            """,
            (user["id"],),
        )
        candidaturas = cursor.fetchall()
        return success_response({"candidaturas": candidaturas, "received_candidacies": candidaturas})
    except Exception as err:
        return error_response("Erro ao buscar candidaturas recebidas.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@candidatures_bp.route("/candidaturas/<int:candidatura_id>/<string:acao>", methods=["POST"])
@candidatures_bp.route("/api/candidacies/<int:candidatura_id>/<string:acao>", methods=["POST"])
@token_required
def atualizar_candidatura_status(current_user_email, candidatura_id, acao):
    if acao not in ("aceitar", "rejeitar"):
        return error_response("Acao invalida. Use aceitar ou rejeitar.", 400)

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        user = get_user_by_email(cursor, current_user_email)
        if not user:
            return error_response("Usuario autenticado nao encontrado.", 404)

        cursor.execute(
            """
            SELECT c.id, p.user_id AS dono_post_id
            FROM candidaturas c
            JOIN posts p ON p.id = c.post_id
            WHERE c.id = %s
            """,
            (candidatura_id,),
        )
        candidatura = cursor.fetchone()
        if not candidatura:
            return error_response("Candidatura nao encontrada.", 404)
        if candidatura["dono_post_id"] != user["id"]:
            return error_response("Voce nao pode alterar esta candidatura.", 403)

        novo_status = "aceito" if acao == "aceitar" else "rejeitado"
        cursor.execute(
            "UPDATE candidaturas SET status = %s WHERE id = %s",
            (novo_status, candidatura_id),
        )
        conn.commit()
        cursor.execute(
            """
            SELECT
                c.id AS candidatura_id,
                c.status AS status_candidatura,
                p.titulo AS post_titulo,
                u.nome AS candidato_nome
            FROM candidaturas c
            JOIN posts p ON p.id = c.post_id
            JOIN users u ON u.id = c.user_id
            WHERE c.id = %s
            """,
            (candidatura_id,),
        )
        updated_candidacy = cursor.fetchone()
        return success_response({
            "message": f"Candidatura {novo_status} com sucesso.",
            "candidacy": updated_candidacy,
        })
    except Exception as err:
        return error_response("Erro ao atualizar candidatura.", 500, str(err))
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()
