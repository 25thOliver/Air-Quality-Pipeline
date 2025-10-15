# Base image
FROM python:3.10-slim

# Set workdir
WORKDIR /app

# Copy dependencies
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY . .

# Default command (override in docker-compose)
CMD ["python3"]
