from flask import Flask
from flask_cors import CORS
from db.init_db import init_db
from config.config import CORS_CONFIG
from routes.auth import auth_bp
from routes.posts import posts_bp
from routes.users import users_bp
from routes.messages import messages_bp
from routes.candidatures import candidatures_bp

# Initialize database
init_db()

# Create Flask app
app = Flask(__name__)

# Configure CORS
CORS(app, **CORS_CONFIG)

# Register blueprints
app.register_blueprint(auth_bp)
app.register_blueprint(posts_bp)
app.register_blueprint(users_bp)
app.register_blueprint(messages_bp)
app.register_blueprint(candidatures_bp)

@app.route("/")
def home():
    return "Backend HarmoCrew está funcionando!"

if __name__ == "__main__":
    app.run(debug=True)
