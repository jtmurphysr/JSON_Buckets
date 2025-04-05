# JSON Buckets Server

A simple, secure JSON storage service with API key authentication, similar to npoint.io. This service allows users to store and retrieve JSON data through a RESTful API.

## Features

- 🔒 API Key Authentication
- 🚦 Rate Limiting
- 📦 JSON Storage
- 🔄 CRUD Operations
- 🛡️ Security Best Practices
- 📊 Database Indexing
- 🔍 Error Handling

## Prerequisites

- Python 3.8+
- MySQL 5.7+
- Nginx
- Systemd (for service management)

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/yourusername/json-buckets.git
cd json-buckets
```

2. Create and activate a virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

5. Initialize the database:
```bash
mysql -u root < db_init.sql
```

6. Run the application:
```bash
python app.py
```

## Production Deployment

For production deployment, use the provided setup script:

```bash
sudo ./setup.sh
```

This will:
- Install all required dependencies
- Set up the MySQL database
- Configure Nginx
- Create a systemd service
- Set up proper permissions

## Docker Deployment

### Quick Start with Docker

1. Clone the repository:
```bash
git clone https://github.com/yourusername/json-buckets.git
cd json-buckets
```

2. Configure environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration if needed
```

3. Build and start the containers:
```bash
docker-compose up -d
```

4. Create a user and get an API key:
```bash
chmod +x docker-admin.sh
./docker-admin.sh add-user myusername
```

5. Access the API at http://localhost:5000

### Docker Management Commands

- **Start the service**:
  ```bash
  docker-compose up -d
  ```

- **Stop the service**:
  ```bash
  docker-compose down
  ```

- **View logs**:
  ```bash
  docker-compose logs -f app
  ```

- **Add a new user**:
  ```bash
  ./docker-admin.sh add-user username
  ```

- **List all users**:
  ```bash
  ./docker-admin.sh list-users
  ```

- **Reset a user's API key**:
  ```bash
  ./docker-admin.sh reset-key username
  ```

### Container Security

- The default credentials in .env.example should be changed for production
- Persistent database data is stored in a Docker volume
- Container networking is isolated with custom bridge network

## API Documentation

### Authentication

All API requests require an API key in the Authorization header:
```
Authorization: Bearer your-api-key
```

### Endpoints

#### Create Bucket
```http
POST /bucket
Content-Type: application/json

{
    "your": "json data"
}
```

Response:
```json
{
    "bucket_id": "generated-uuid",
    "url": "/bucket/generated-uuid"
}
```

#### List Buckets
```http
GET /buckets
```

Response:
```json
[
    {
        "id": "bucket-uuid",
        "created_at": "timestamp",
        "updated_at": "timestamp"
    }
]
```

#### View Bucket
```http
GET /bucket/<bucket_id>
```

Response:
```json
{
    "your": "json data"
}
```

#### Update Bucket
```http
PUT /bucket/<bucket_id>
Content-Type: application/json

{
    "updated": "json data"
}
```

Response:
```json
{
    "message": "updated",
    "bucket_id": "bucket-uuid"
}
```

#### Delete Bucket
```http
DELETE /bucket/<bucket_id>
```

Response:
```json
{
    "message": "deleted",
    "bucket_id": "bucket-uuid"
}
```

### Rate Limits

- Global: 200 requests per day, 50 per hour
- Bucket creation/update/delete: 10 per minute
- Bucket viewing/listing: 30 per minute

### Error Responses

```json
{
    "error": "Error Type",
    "message": "Detailed error message"
}
```

Common status codes:
- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized (No API key)
- 403: Forbidden (Invalid API key)
- 404: Not Found
- 429: Rate Limit Exceeded
- 500: Internal Server Error

## Security Considerations

1. API Keys
   - Store API keys securely
   - Rotate keys periodically
   - Use HTTPS in production

2. Rate Limiting
   - Prevents abuse
   - Configurable limits
   - IP-based tracking

3. Database
   - Proper indexing
   - Foreign key constraints
   - Prepared statements

4. Environment Variables
   - Sensitive data stored in .env
   - Production credentials should be changed
   - File permissions set to 640

## Development

### Running Tests
```bash
python -m pytest
```

### Code Style
```bash
flake8 .
```

## License

MIT License - see LICENSE file for details

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Support

For support, please open an issue in the GitHub repository.

