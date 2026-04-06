from flask import Flask
from flask_cors import CORS
from db.init_db import init_db
from config.config import CORS_CONFIG
from routes.auth import auth_bp
from routes.posts import posts_bp
from routes.users import users_bp
from routes.messages import messages_bp
from routes.candidatures import candidatures_bp
from routes.feed import feed_bp
from routes.dashboard import dashboard_bp

init_db()

app = Flask(__name__)
CORS(app, **CORS_CONFIG)

app.register_blueprint(auth_bp)
app.register_blueprint(posts_bp)
app.register_blueprint(users_bp)
app.register_blueprint(messages_bp)
app.register_blueprint(candidatures_bp)
app.register_blueprint(feed_bp)
app.register_blueprint(dashboard_bp)


@app.route("/")
def home():
    return "Backend HarmoCrew esta funcionando!"


if __name__ == "__main__":
    app.run(debug=True)
