FROM python:3.10-slim

WORKDIR /app

# Install dependencies including mysql-client for wait-for-db script
RUN apt-get update && apt-get install -y default-mysql-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set environment variables
ENV FLASK_APP=app.py
ENV PYTHONUNBUFFERED=1

# Expose port
EXPOSE 5000

# Make wait-for-db script executable
RUN chmod +x wait-for-db.sh

# Run gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "wsgi:app"] 