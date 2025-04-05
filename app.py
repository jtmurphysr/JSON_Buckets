from flask import Flask, request, jsonify, abort
from flask_mysqldb import MySQL
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from werkzeug.security import generate_password_hash, check_password_hash
import uuid, json, os
from functools import wraps
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)

# --- Config (from environment variables) ---
app.config['MYSQL_HOST'] = os.getenv('MYSQL_HOST', 'localhost')
app.config['MYSQL_USER'] = os.getenv('MYSQL_USER', 'bucketuser')
app.config['MYSQL_PASSWORD'] = os.getenv('MYSQL_PASSWORD', 'bucketpass')
app.config['MYSQL_DB'] = os.getenv('MYSQL_DB', 'jsonbuckets')

mysql = MySQL(app)

# Initialize rate limiter
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)

# --- API Key Auth Decorator ---
def require_api_key(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        key = request.headers.get('Authorization', '').replace('Bearer ', '')
        if not key:
            abort(401)
        cur = mysql.connection.cursor()
        cur.execute("SELECT id, api_key FROM users WHERE api_key = %s", (key,))
        user = cur.fetchone()
        if not user:
            abort(403)
        request.user_id = user[0]
        return f(*args, **kwargs)
    return decorated

# --- Error Handlers ---
@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Not found", "message": "The requested resource was not found"}), 404

@app.errorhandler(403)
def forbidden(error):
    return jsonify({"error": "Forbidden", "message": "Invalid API key"}), 403

@app.errorhandler(401)
def unauthorized(error):
    return jsonify({"error": "Unauthorized", "message": "No API key provided"}), 401

@app.errorhandler(429)
def ratelimit_handler(e):
    return jsonify({"error": "Rate limit exceeded", "message": str(e.description)}), 429

# --- Create Bucket ---
@app.route('/bucket', methods=['POST'])
@require_api_key
@limiter.limit("10 per minute")
def create_bucket():
    try:
        content = request.get_json()
        if not content:
            return jsonify({"error": "Bad Request", "message": "No JSON content provided"}), 400
            
        bucket_id = uuid.uuid4().hex
        cur = mysql.connection.cursor()
        cur.execute("INSERT INTO buckets (id, user_id, content) VALUES (%s, %s, %s)",
                    (bucket_id, request.user_id, json.dumps(content)))
        mysql.connection.commit()
        return jsonify({"bucket_id": bucket_id, "url": f"/bucket/{bucket_id}"}), 201
    except Exception as e:
        mysql.connection.rollback()
        return jsonify({"error": "Internal Server Error", "message": str(e)}), 500

# --- List User's Buckets ---
@app.route('/buckets', methods=['GET'])
@require_api_key
@limiter.limit("30 per minute")
def list_buckets():
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT id, created_at, updated_at FROM buckets WHERE user_id = %s", (request.user_id,))
        buckets = [{"id": row[0], "created_at": row[1], "updated_at": row[2]} for row in cur.fetchall()]
        return jsonify(buckets)
    except Exception as e:
        return jsonify({"error": "Internal Server Error", "message": str(e)}), 500

# --- View Bucket ---
@app.route('/bucket/<bucket_id>', methods=['GET'])
@require_api_key
@limiter.limit("30 per minute")
def view_bucket(bucket_id):
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT content FROM buckets WHERE id = %s AND user_id = %s",
                    (bucket_id, request.user_id))
        result = cur.fetchone()
        if not result:
            abort(404)
        return jsonify(json.loads(result[0]))
    except Exception as e:
        return jsonify({"error": "Internal Server Error", "message": str(e)}), 500

# --- Update Bucket ---
@app.route('/bucket/<bucket_id>', methods=['PUT'])
@require_api_key
@limiter.limit("10 per minute")
def update_bucket(bucket_id):
    try:
        content = request.get_json()
        if not content:
            return jsonify({"error": "Bad Request", "message": "No JSON content provided"}), 400
            
        cur = mysql.connection.cursor()
        cur.execute("UPDATE buckets SET content = %s WHERE id = %s AND user_id = %s",
                    (json.dumps(content), bucket_id, request.user_id))
        mysql.connection.commit()
        if cur.rowcount == 0:
            abort(404)
        return jsonify({"message": "updated", "bucket_id": bucket_id})
    except Exception as e:
        mysql.connection.rollback()
        return jsonify({"error": "Internal Server Error", "message": str(e)}), 500

# --- Delete Bucket ---
@app.route('/bucket/<bucket_id>', methods=['DELETE'])
@require_api_key
@limiter.limit("10 per minute")
def delete_bucket(bucket_id):
    try:
        cur = mysql.connection.cursor()
        cur.execute("DELETE FROM buckets WHERE id = %s AND user_id = %s", (bucket_id, request.user_id))
        mysql.connection.commit()
        if cur.rowcount == 0:
            abort(404)
        return jsonify({"message": "deleted", "bucket_id": bucket_id})
    except Exception as e:
        mysql.connection.rollback()
        return jsonify({"error": "Internal Server Error", "message": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=os.getenv('FLASK_DEBUG', '0') == '1')

