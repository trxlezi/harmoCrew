import re

# Flask app configuration
SECRET_KEY = '4f7d8a9b2c3e1f0a9d7b5e6c8f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a'

# CORS configuration
CORS_CONFIG = {
    'resources': {r"/*": {
        "origins": ["http://localhost:3000", "http://127.0.0.1:3000"]
    }},
    'allow_headers': ["Authorization", "Content-Type", "X-Requested-With"],
    'methods': ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    'supports_credentials': True,
    'expose_headers': ["Content-Type", "Authorization"]
}

# Validation patterns
EMAIL_REGEX = re.compile(r"[^@]+@[^@]+\.[^@]+") 