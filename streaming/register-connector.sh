#!/bin/sh

# ============================================
# Debezium Connector Auto-Registration Script
# ============================================
# This script automatically registers the MongoDB CDC connector
# Compatible with Alpine Linux / minimal images

echo "================================================"
echo "Debezium Connector Registration Script"
echo "================================================"
echo ""

# Configuration
CONNECT_HOST="localhost"
CONNECT_PORT="8084"
CONNECTOR_NAME="mongo-air-quality-connector"
CONFIG_FILE="streaming/mongo_connector_config.json"
MAX_RETRIES=10
RETRY_DELAY=5

# Function to check if Kafka Connect is ready
check_connect_ready() {
    curl -s -o /dev/null -w "%{http_code}" http://${CONNECT_HOST}:${CONNECT_PORT}/connectors
}

# Function to check if connector exists
check_connector_exists() {
    curl -s http://${CONNECT_HOST}:${CONNECT_PORT}/connectors | grep -q "${CONNECTOR_NAME}"
}

# Wait for Kafka Connect to be ready
echo "Waiting for Kafka Connect to be ready..."
attempt=0
while [ $attempt -lt $MAX_RETRIES ]; do
    http_code=$(check_connect_ready)
    if [ "$http_code" = "200" ]; then
        echo "✓ Kafka Connect is ready!"
        break
    fi

    attempt=$((attempt + 1))
    if [ $attempt -eq $MAX_RETRIES ]; then
        echo "✗ Kafka Connect is not responding after ${MAX_RETRIES} attempts"
        echo "Please check if mongo-connector container is running"
        exit 1
    fi

    echo "  Attempt $attempt/$MAX_RETRIES - Kafka Connect not ready (HTTP $http_code). Retrying in ${RETRY_DELAY}s..."
    sleep $RETRY_DELAY
done

echo ""

# Check if connector already exists
echo "Checking if connector already exists..."
if check_connector_exists; then
    echo "⚠ Connector '${CONNECTOR_NAME}' already exists"
    echo "✓ No action needed"
    exit 0
fi

echo "→ Connector does not exist. Creating new connector..."
echo ""

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "✗ Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Register the connector
echo "Registering connector from: $CONFIG_FILE"
response=$(curl -s -X POST http://${CONNECT_HOST}:${CONNECT_PORT}/connectors \
    -H "Content-Type: application/json" \
    -d @${CONFIG_FILE})

# Check if registration was successful
if echo "$response" | grep -q "\"name\":\"${CONNECTOR_NAME}\""; then
    echo "✓ Connector registered successfully!"
    echo ""
    echo "Waiting for connector to initialize..."
    sleep 5
    echo ""
    echo "================================================"
    echo "SUCCESS: CDC Connector Registered!"
    echo "================================================"
    echo ""
    echo "The Debezium CDC connector is now active."
    echo "It will automatically capture changes from MongoDB."
    exit 0
else
    echo "✗ Failed to register connector"
    echo ""
    echo "Response from Kafka Connect:"
    echo "$response"
    echo ""
    exit 1
fi
