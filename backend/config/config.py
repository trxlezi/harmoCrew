import re
from config.settings import HARMOCREW_SECRET_KEY

# Flask app configuration
SECRET_KEY = HARMOCREW_SECRET_KEY

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
