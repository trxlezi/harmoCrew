from flask import jsonify


def success_response(data=None, meta=None, status=200):
    return jsonify({
        "success": True,
        "data": data or {},
        "meta": meta,
        "error": None,
    }), status


def error_response(message, status=400, details=None):
    return jsonify({
        "success": False,
        "data": None,
        "meta": None,
        "error": {
            "message": message,
            "details": details,
        },
    }), status


def get_user_by_email(cursor, email):
    cursor.execute(
        "SELECT id, nome, email, profile_pic_url, descricao, links_sociais FROM users WHERE email = %s",
        (email,),
    )
    return cursor.fetchone()


def ensure_profile_photo(profile):
    if not profile:
        return profile
    profile["profile_pic_url"] = profile.get("profile_pic_url") or f"https://i.pravatar.cc/150?u={profile['id']}"
    return profile


def serialize_profile(profile, is_following=False):
    if not profile:
        return None

    profile = ensure_profile_photo(dict(profile))
    return {
        "id": profile["id"],
        "nome": profile["nome"],
        "email": profile["email"],
        "profile_pic_url": profile["profile_pic_url"],
        "descricao": profile.get("descricao") or "",
        "links_sociais": profile.get("links_sociais") or "",
        "headline": profile.get("descricao") or profile["email"],
        "is_following": bool(is_following),
    }


def serialize_post(post, type_label="Projeto"):
    post_dict = dict(post)
    post_dict["profile_pic_url"] = post_dict.get("profile_pic_url") or f"https://i.pravatar.cc/50?u={post_dict['user_id']}"
    post_dict["type_label"] = type_label
    return post_dict
