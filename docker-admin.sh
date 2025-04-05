#!/bin/bash
# docker-admin.sh - Utility script for JSON Buckets admin tasks in Docker

set -e

# Function to add a new user to the database
add_user() {
    if [ -z "$1" ]; then
        echo "Error: Please provide a username"
        echo "Usage: $0 add-user <username>"
        exit 1
    fi
    
    USERNAME=$1
    
    # Generate API key
    API_KEY=$(docker-compose exec app python -c "import secrets; print(secrets.token_urlsafe(32))")
    
    # Add user to database
    docker-compose exec db mysql -u root -p$MYSQL_ROOT_PASSWORD jsonbuckets -e "INSERT INTO users (username, api_key) VALUES ('$USERNAME', '$API_KEY');"
    
    echo "User added successfully:"
    echo "Username: $USERNAME"
    echo "API Key: $API_KEY"
}

# Function to list all users
list_users() {
    docker-compose exec db mysql -u root -p$MYSQL_ROOT_PASSWORD jsonbuckets -e "SELECT id, username, api_key, created_at FROM users;"
}

# Function to reset a user's API key
reset_api_key() {
    if [ -z "$1" ]; then
        echo "Error: Please provide a username"
        echo "Usage: $0 reset-key <username>"
        exit 1
    fi
    
    USERNAME=$1
    
    # Generate new API key
    API_KEY=$(docker-compose exec app python -c "import secrets; print(secrets.token_urlsafe(32))")
    
    # Update API key in database
    docker-compose exec db mysql -u root -p$MYSQL_ROOT_PASSWORD jsonbuckets -e "UPDATE users SET api_key = '$API_KEY' WHERE username = '$USERNAME';"
    
    echo "API key reset successfully for user '$USERNAME':"
    echo "New API Key: $API_KEY"
}

# Main script
case "$1" in
    add-user)
        add_user "$2"
        ;;
    list-users)
        list_users
        ;;
    reset-key)
        reset_api_key "$2"
        ;;
    *)
        echo "JSON Buckets Admin Utility"
        echo "Usage: $0 [command]"
        echo ""
        echo "Available commands:"
        echo "  add-user <username>  - Add a new user"
        echo "  list-users           - List all users"
        echo "  reset-key <username> - Reset API key for a user"
        ;;
esac 