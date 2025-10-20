#!/bin/bash

# ============================================
# Air Quality Pipeline - Health Check Script
# ============================================
# Comprehensive health check for all services
# Run this after: docker-compose up -d
#
# Usage: ./health-check.sh
# ============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Symbols
CHECK="✓"
CROSS="✗"
WARN="⚠"
INFO="ℹ"

# Counters
PASSED=0
FAILED=0
WARNINGS=0

echo ""
echo "================================================"
echo "   Air Quality Pipeline - Health Check"
echo "================================================"
echo ""

# Function to print status
print_status() {
    local status=$1
    local message=$2
    local details=$3

    if [ "$status" = "pass" ]; then
        echo -e "${GREEN}${CHECK}${NC} ${message}"
        [ -n "$details" ] && echo -e "  ${BLUE}${INFO}${NC} ${details}"
        ((PASSED++))
    elif [ "$status" = "fail" ]; then
        echo -e "${RED}${CROSS}${NC} ${message}"
        [ -n "$details" ] && echo -e "  ${YELLOW}${WARN}${NC} ${details}"
        ((FAILED++))
    elif [ "$status" = "warn" ]; then
        echo -e "${YELLOW}${WARN}${NC} ${message}"
        [ -n "$details" ] && echo -e "  ${INFO} ${details}"
        ((WARNINGS++))
    fi
}

# Function to print section header
print_section() {
    echo ""
    echo -e "${BOLD}$1${NC}"
    echo "----------------------------------------"
}

# ============================================
# 1. Container Status Check
# ============================================
print_section "1. Container Status"

EXPECTED_CONTAINERS=("mongo" "zookeeper" "kafka" "kafka-ui" "producer" "consumer" "mongo-connector" "cassandra" "cassandra-consumer")
RUNNING_COUNT=0

for container in "${EXPECTED_CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        status=$(docker ps --filter "name=^${container}$" --format '{{.Status}}')
        if echo "$status" | grep -q "Up"; then
            print_status "pass" "Container: $container" "Status: $status"
            ((RUNNING_COUNT++))
        else
            print_status "fail" "Container: $container" "Status: $status"
        fi
    else
        print_status "fail" "Container: $container" "Not found or not running"
    fi
done

# Check mongo-init (should be exited with code 0)
if docker ps -a --filter "name=^mongo-init$" --format '{{.Status}}' | grep -q "Exited (0)"; then
    print_status "pass" "Container: mongo-init" "Exited successfully (expected)"
else
    print_status "warn" "Container: mongo-init" "Not exited successfully (check logs)"
fi

# ============================================
# 2. MongoDB Health
# ============================================
print_section "2. MongoDB Health"

# Check replica set status
RS_STATUS=$(docker exec mongo mongosh -u airflow -p airflow123 --authenticationDatabase admin --quiet --eval "rs.status().ok" 2>/dev/null)
if [ "$RS_STATUS" = "1" ]; then
    print_status "pass" "MongoDB Replica Set" "Initialized and running"
else
    print_status "fail" "MongoDB Replica Set" "Not initialized - run: bash storage/init-replica-set.sh"
fi

# Check document count
DOC_COUNT=$(docker exec mongo mongosh -u airflow -p airflow123 --authenticationDatabase admin --quiet --eval "db.getSiblingDB('air_quality_db').air_quality_raw.countDocuments()" 2>/dev/null)
if [ -n "$DOC_COUNT" ] && [ "$DOC_COUNT" -gt 0 ]; then
    print_status "pass" "MongoDB Data" "$DOC_COUNT documents in air_quality_raw collection"
elif [ "$DOC_COUNT" = "0" ]; then
    print_status "warn" "MongoDB Data" "No documents yet (waiting for producer to run)"
else
    print_status "fail" "MongoDB Data" "Cannot query collection"
fi

# ============================================
# 3. Kafka Health
# ============================================
print_section "3. Kafka Health"

# Check if Kafka is accepting connections
if docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092 >/dev/null 2>&1; then
    print_status "pass" "Kafka Broker" "Accepting connections on port 9092"
else
    print_status "fail" "Kafka Broker" "Not responding"
fi

# Check main topic
TOPIC_OFFSET=$(docker exec kafka kafka-run-class kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic air_quality_data 2>/dev/null | awk -F: '{print $3}')
if [ -n "$TOPIC_OFFSET" ]; then
    if [ "$TOPIC_OFFSET" -gt 0 ]; then
        print_status "pass" "Kafka Topic: air_quality_data" "$TOPIC_OFFSET messages"
    else
        print_status "warn" "Kafka Topic: air_quality_data" "No messages yet (waiting for producer)"
    fi
else
    print_status "fail" "Kafka Topic: air_quality_data" "Topic not found or inaccessible"
fi

# ============================================
# 4. Producer Health
# ============================================
print_section "4. Producer Health"

PRODUCER_LOGS=$(docker logs producer --tail 20 2>&1)

if echo "$PRODUCER_LOGS" | grep -q "Connected to Kafka broker"; then
    print_status "pass" "Producer Connection" "Connected to Kafka"
else
    print_status "fail" "Producer Connection" "Not connected to Kafka"
fi

if echo "$PRODUCER_LOGS" | grep -q "Published data for"; then
    LAST_PUBLISH=$(echo "$PRODUCER_LOGS" | grep "Published data for" | tail -1 | awk '{print $6, $7, $8}')
    print_status "pass" "Producer Activity" "Last publish: $LAST_PUBLISH"
elif echo "$PRODUCER_LOGS" | grep -q "waiting for the next cycle"; then
    print_status "warn" "Producer Activity" "Waiting for next cycle (hourly schedule)"
else
    print_status "warn" "Producer Activity" "No publishing activity detected yet"
fi

# ============================================
# 5. Consumer Health
# ============================================
print_section "5. Consumer Health"

CONSUMER_LOGS=$(docker logs consumer --tail 20 2>&1)

if echo "$CONSUMER_LOGS" | grep -q "Connected to MongoDB"; then
    print_status "pass" "Consumer → MongoDB Connection" "Connected"
else
    print_status "fail" "Consumer → MongoDB Connection" "Not connected"
fi

if echo "$CONSUMER_LOGS" | grep -q "Connected to kafka broker"; then
    print_status "pass" "Consumer → Kafka Connection" "Connected"
else
    print_status "fail" "Consumer → Kafka Connection" "Not connected"
fi

if echo "$CONSUMER_LOGS" | grep -q "Inserted record for"; then
    LAST_INSERT=$(echo "$CONSUMER_LOGS" | grep "Inserted record for" | tail -1 | awk '{print $7, $8, $9}')
    print_status "pass" "Consumer Activity" "Last insert: $LAST_INSERT"
else
    print_status "warn" "Consumer Activity" "No insert activity detected yet"
fi

# ============================================
# 6. Debezium CDC Health
# ============================================
print_section "6. Debezium CDC (Change Data Capture)"

# Check if connector exists
CONNECTOR_LIST=$(curl -s http://localhost:8084/connectors 2>/dev/null)
if echo "$CONNECTOR_LIST" | grep -q "mongo-air-quality-connector"; then
    print_status "pass" "Debezium Connector" "Registered"

    # Check connector status
    CONNECTOR_STATUS=$(curl -s http://localhost:8084/connectors/mongo-air-quality-connector/status 2>/dev/null)
    CONN_STATE=$(echo "$CONNECTOR_STATUS" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('connector', {}).get('state', 'UNKNOWN'))" 2>/dev/null)
    TASK_STATE=$(echo "$CONNECTOR_STATUS" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('tasks', [{}])[0].get('state', 'UNKNOWN'))" 2>/dev/null)

    if [ "$CONN_STATE" = "RUNNING" ] && [ "$TASK_STATE" = "RUNNING" ]; then
        print_status "pass" "Debezium Status" "Connector: RUNNING, Task: RUNNING"
    else
        print_status "fail" "Debezium Status" "Connector: $CONN_STATE, Task: $TASK_STATE"
    fi
else
    print_status "fail" "Debezium Connector" "Not registered - run: ./streaming/register-connector.sh"
fi

# Check CDC topic
CDC_OFFSET=$(docker exec kafka kafka-run-class kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic mongo_cdc.air_quality_db.air_quality_raw 2>/dev/null | awk -F: '{print $3}')
if [ -n "$CDC_OFFSET" ]; then
    if [ "$CDC_OFFSET" -gt 0 ]; then
        print_status "pass" "CDC Kafka Topic" "$CDC_OFFSET change events captured"
    else
        print_status "warn" "CDC Kafka Topic" "No CDC events yet"
    fi
else
    print_status "warn" "CDC Kafka Topic" "Topic not created yet"
fi

# ============================================
# 7. Cassandra Health
# ============================================
print_section "7. Cassandra Health"

# Check if Cassandra is accepting connections
if docker exec cassandra cqlsh -e "DESCRIBE KEYSPACES;" >/dev/null 2>&1; then
    print_status "pass" "Cassandra Connection" "Accepting CQL connections"
else
    print_status "fail" "Cassandra Connection" "Not responding to CQL commands"
fi

# Check keyspace exists
if docker exec cassandra cqlsh -e "DESCRIBE KEYSPACE air_quality_analytics;" >/dev/null 2>&1; then
    print_status "pass" "Cassandra Keyspace" "air_quality_analytics exists"
else
    print_status "fail" "Cassandra Keyspace" "air_quality_analytics not found - run: docker exec -i cassandra cqlsh < storage/cassandra_setup.cql"
fi

# Check data count
CASS_COUNT=$(docker exec cassandra cqlsh -e "SELECT COUNT(*) FROM air_quality_analytics.air_quality_readings;" 2>/dev/null | grep -A2 "count" | tail -1 | xargs)
if [ -n "$CASS_COUNT" ] && [ "$CASS_COUNT" -gt 0 ]; then
    print_status "pass" "Cassandra Data" "$CASS_COUNT readings stored"
elif [ "$CASS_COUNT" = "0" ]; then
    print_status "warn" "Cassandra Data" "No data yet (waiting for CDC events)"
else
    print_status "warn" "Cassandra Data" "Cannot query data"
fi

# ============================================
# 8. Cassandra Consumer Health
# ============================================
print_section "8. Cassandra Consumer Health"

CASS_CONSUMER_LOGS=$(docker logs cassandra-consumer --tail 20 2>&1)

if echo "$CASS_CONSUMER_LOGS" | grep -q "Connected to Cassandra keyspace"; then
    print_status "pass" "Cassandra Consumer → Cassandra" "Connected to keyspace"
else
    print_status "fail" "Cassandra Consumer → Cassandra" "Not connected"
fi

if echo "$CASS_CONSUMER_LOGS" | grep -q "Subscribed to CDC topic"; then
    print_status "pass" "Cassandra Consumer → Kafka" "Subscribed to CDC topic"
else
    print_status "fail" "Cassandra Consumer → Kafka" "Not subscribed"
fi

if echo "$CASS_CONSUMER_LOGS" | grep -q "Inserted reading for"; then
    LAST_CASS_INSERT=$(echo "$CASS_CONSUMER_LOGS" | grep "Inserted reading for" | tail -1 | awk '{print $7, $8, $9}')
    print_status "pass" "Cassandra Consumer Activity" "Last insert: $LAST_CASS_INSERT"
elif echo "$CASS_CONSUMER_LOGS" | grep -q "Processing CDC messages"; then
    print_status "warn" "Cassandra Consumer Activity" "Waiting for CDC messages"
else
    print_status "warn" "Cassandra Consumer Activity" "No activity detected"
fi

# ============================================
# 9. Monitoring UIs
# ============================================
print_section "9. Monitoring Interfaces"

# Check Kafka UI
if curl -s http://localhost:8083 >/dev/null 2>&1; then
    print_status "pass" "Kafka UI" "http://localhost:8083"
else
    print_status "fail" "Kafka UI" "Not accessible at http://localhost:8083"
fi

# Check Kafka Connect API
if curl -s http://localhost:8084/connectors >/dev/null 2>&1; then
    print_status "pass" "Kafka Connect API" "http://localhost:8084"
else
    print_status "fail" "Kafka Connect API" "Not accessible at http://localhost:8084"
fi

# ============================================
# Summary
# ============================================
echo ""
echo "================================================"
echo "   Health Check Summary"
echo "================================================"
echo ""

TOTAL=$((PASSED + FAILED + WARNINGS))

echo -e "${GREEN}Passed:${NC}   $PASSED"
echo -e "${RED}Failed:${NC}   $FAILED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "${BOLD}Total:${NC}    $TOTAL"
echo ""

# Overall status
if [ $FAILED -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ ALL SYSTEMS OPERATIONAL${NC}"
    echo ""
    echo "Your pipeline is running perfectly! 🎉"
    echo ""
    echo "Quick access:"
    echo "  • Kafka UI:    http://localhost:8083"
    echo "  • MongoDB:     docker exec mongo mongosh -u airflow -p airflow123 --authenticationDatabase admin"
    echo "  • Cassandra:   docker exec cassandra cqlsh"
    exit 0
elif [ $FAILED -eq 0 ]; then
    echo -e "${YELLOW}${BOLD}⚠ SYSTEM OPERATIONAL WITH WARNINGS${NC}"
    echo ""
    echo "Pipeline is running but some components may need attention."
    echo "Review warnings above and wait for data to flow (hourly schedule)."
    exit 0
else
    echo -e "${RED}${BOLD}✗ SYSTEM HAS FAILURES${NC}"
    echo ""
    echo "Some components are not working correctly. Please review the failures above."
    echo ""
    echo "Common fixes:"
    echo "  • MongoDB replica set: bash storage/init-replica-set.sh"
    echo "  • Register CDC:        ./streaming/register-connector.sh"
    echo "  • Initialize Cassandra: docker exec -i cassandra cqlsh < storage/cassandra_setup.cql"
    echo "  • View logs:           docker logs <container-name>"
    echo ""
    exit 1
fi
