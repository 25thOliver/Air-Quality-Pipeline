# Monitoring UI Guide - Air Quality Pipeline

Complete guide to using the monitoring interfaces and UIs available in this project.

---

## 📊 Available Interfaces

This project includes two main monitoring interfaces:

1. **Kafka UI** - Visual interface for Kafka (Port 8083)
2. **Kafka Connect REST API** - API for Debezium monitoring (Port 8084)

---

## 🎛️ Kafka UI (Port 8083)

### Accessing Kafka UI

Open your web browser and navigate to:
```
http://localhost:8083
```

### Dashboard Overview

When you first open Kafka UI, you'll see:

**Left Sidebar:**
- **Brokers** - Kafka broker information
- **Topics** - All Kafka topics
- **Consumers** - Consumer groups
- **Schema Registry** - Schema management (if configured)
- **Connect** - Kafka Connect clusters

**Main Panel:**
- Cluster overview
- Topic count
- Broker status
- Version information

---

## 📂 Working with Topics

### Viewing All Topics

1. Click **"Topics"** in the left sidebar
2. You'll see a list of all topics:
   - `air_quality_data` - Main data stream
   - `mongo_cdc.air_quality_db.air_quality_raw` - CDC events
   - `connect-configs` - Kafka Connect configuration
   - `connect-offsets` - Consumer offsets
   - `connect-status` - Connector status
   - `__consumer_offsets` - Internal Kafka topic

### Topic Details

Click on any topic (e.g., `air_quality_data`) to see:

**Overview Tab:**
- Number of partitions
- Replication factor
- Total messages
- Size on disk
- Configuration settings

**Messages Tab:**
- Live message stream
- Message key and value
- Timestamp
- Partition and offset
- Headers (if any)

**Consumers Tab:**
- Which consumer groups are reading this topic
- Consumer lag
- Current offset

**Settings Tab:**
- Topic configuration
- Retention policies
- Cleanup policies

---

## 📨 Viewing Messages

### View Messages in air_quality_data Topic

1. Click **"Topics"** → **"air_quality_data"**
2. Click **"Messages"** tab
3. You'll see messages like:

```json
{
  "time": "2025-10-20T23:00",
  "pm2_5": 8.9,
  "pm10": 12.7,
  "carbon_monoxide": 115.0,
  "nitrogen_dioxide": 3.0,
  "sulphur_dioxide": 2.1,
  "ozone": 50.0,
  "uv_index": 0.0,
  "timestamp": "2025-10-20T23:00",
  "city": "Mombasa"
}
```

**Filtering Options:**
- **Offset**: Jump to specific message number
- **Timestamp**: Show messages from specific time
- **Partition**: View specific partition only
- **Smart filter**: Search within message content

### View CDC Messages

1. Click **"Topics"** → **"mongo_cdc.air_quality_db.air_quality_raw"**
2. Click **"Messages"** tab
3. You'll see CDC event structure:

```json
{
  "before": null,
  "after": "{...full document...}",
  "source": {
    "version": "2.6.2.Final",
    "connector": "mongodb",
    "name": "mongo_cdc",
    "db": "air_quality_db",
    "collection": "air_quality_raw"
  },
  "op": "r",
  "ts_ms": 1760645145381
}
```

**Understanding CDC Fields:**
- `before`: Document state before change (null for inserts)
- `after`: Document state after change
- `op`: Operation type:
  - `r` = Read (initial snapshot)
  - `c` = Create (insert)
  - `u` = Update
  - `d` = Delete
- `source`: Metadata about where change came from
- `ts_ms`: Timestamp in milliseconds

---

## 👥 Monitoring Consumers

### View Consumer Groups

1. Click **"Consumers"** in left sidebar
2. You'll see consumer groups:
   - `air_quality_group` - MongoDB writer consumer
   - `cassandra_consumer_group` - Cassandra writer consumer

### Consumer Group Details

Click on a consumer group to see:

**Topics:**
- Which topics this group subscribes to
- Partition assignment
- Current offset
- Log end offset
- **Lag** (most important metric!)

**Members:**
- Consumer IDs
- Host information
- Partition assignment
- Status

**Understanding Lag:**
- **Lag = 0**: Consumer is caught up ✅
- **Lag > 0**: Consumer is behind ⚠️
- **Increasing lag**: Consumer can't keep up 🚨

**Example:**
```
Topic: air_quality_data
Partition: 0
Current Offset: 150
Log End Offset: 150
Lag: 0  ← Perfect!
```

If lag shows:
```
Current Offset: 100
Log End Offset: 150
Lag: 50  ← Consumer is 50 messages behind!
```

---

## 🔍 Searching and Filtering

### Search Messages

In the Messages tab:

1. **By Content:**
   - Click "Smart filter"
   - Enter search term (e.g., "Nairobi")
   - Click "Submit"

2. **By Offset:**
   - Enter offset number in "Seek to offset" field
   - Click "Submit"

3. **By Timestamp:**
   - Select "Seek to timestamp"
   - Choose date and time
   - Click "Submit"

### Filtering Tips

**Find messages for specific city:**
```
Smart filter: "city": "Nairobi"
```

**Find high pollution events:**
```
Smart filter: "pm2_5": .*[5-9][0-9].*
```
(This regex finds PM2.5 values 50 or higher)

**Find recent messages:**
- Use timestamp filter
- Set to last hour/day

---

## 📈 Monitoring Topic Health

### Key Metrics to Watch

**In Topic Overview:**

1. **Message Count**
   - Should increase steadily
   - For `air_quality_data`: +2 messages per hour (2 cities)

2. **Size on Disk**
   - Shows storage used
   - Monitor if approaching disk limits

3. **Under-Replicated Partitions**
   - Should always be 0
   - If > 0: Replication issue! 🚨

**In Consumer Details:**

1. **Consumer Lag**
   - Should be 0 or very small
   - Increasing = Problem

2. **Messages Per Second**
   - Shows consumption rate
   - Should match production rate

---

## 🔧 Common Tasks in Kafka UI

### Task 1: Verify Data is Flowing

**Steps:**
1. Go to Topics → `air_quality_data`
2. Check "Messages" count - should increase hourly
3. Click Messages tab
4. Verify recent timestamps
5. Check both cities appear

**Expected:** New messages every hour with fresh timestamps

---

### Task 2: Check Consumer Health

**Steps:**
1. Go to Consumers
2. Click on `air_quality_group`
3. Check Topics tab
4. Verify Lag = 0
5. Check Members tab shows 1 member

**Expected:** Lag should be 0, member should be "RUNNING"

---

### Task 3: Verify CDC is Working

**Steps:**
1. Go to Topics → `mongo_cdc.air_quality_db.air_quality_raw`
2. Check message count increases when MongoDB gets new data
3. View messages - should see CDC event structure
4. Verify `op` field shows operations

**Expected:** CDC topic should have same or more messages than source topic

---

### Task 4: Debugging No Data

**If you see no messages:**

1. **Check Producer:**
   ```bash
   docker logs producer --tail 50
   ```
   Look for "Published data for..."

2. **Check Topic Exists:**
   - Kafka UI → Topics
   - Verify `air_quality_data` is listed

3. **Check Kafka Broker:**
   - Kafka UI → Brokers
   - Should show 1 broker, status UP

4. **Check Consumer:**
   ```bash
   docker logs consumer --tail 50
   ```
   Look for "Inserted record for..."

---

## 🔌 Kafka Connect REST API (Port 8084)

### What is This?

The Kafka Connect REST API is used to manage Debezium connectors. It doesn't have a web UI - you interact with it using `curl` or tools like Postman.

### Base URL
```
http://localhost:8084
```

---

## 📡 Common API Endpoints

### 1. List All Connectors

**Request:**
```bash
curl -s http://localhost:8084/connectors
```

**Expected Response:**
```json
["mongo-air-quality-connector"]
```

**What it means:**
- Shows all registered connectors
- Should have at least `mongo-air-quality-connector`

---

### 2. Get Connector Status

**Request:**
```bash
curl -s http://localhost:8084/connectors/mongo-air-quality-connector/status | python3 -m json.tool
```

**Expected Response:**
```json
{
    "name": "mongo-air-quality-connector",
    "connector": {
        "state": "RUNNING",
        "worker_id": "172.21.0.7:8083"
    },
    "tasks": [
        {
            "id": 0,
            "state": "RUNNING",
            "worker_id": "172.21.0.7:8083"
        }
    ],
    "type": "source"
}
```

**Understanding the Response:**

- `connector.state`: Should be "RUNNING" ✅
- `tasks[].state`: All tasks should be "RUNNING" ✅
- `type: "source"`: This is a source connector (reads from DB)

**Possible States:**
- `RUNNING` ✅ - Working correctly
- `PAUSED` ⏸️ - Temporarily stopped
- `FAILED` ❌ - Error occurred
- `UNASSIGNED` 🔄 - Not started yet

---

### 3. Get Connector Configuration

**Request:**
```bash
curl -s http://localhost:8084/connectors/mongo-air-quality-connector/config | python3 -m json.tool
```

**Response shows:**
- MongoDB connection string
- Database and collection to monitor
- Topic prefix
- Converter settings

---

### 4. Restart a Connector

**When to use:** If connector shows FAILED status

**Request:**
```bash
curl -X POST http://localhost:8084/connectors/mongo-air-quality-connector/restart
```

**Expected Response:**
```
(Empty response with HTTP 204)
```

Then check status again to verify it's RUNNING.

---

### 5. Pause a Connector

**When to use:** To temporarily stop CDC without deleting

**Request:**
```bash
curl -X PUT http://localhost:8084/connectors/mongo-air-quality-connector/pause
```

**Resume it:**
```bash
curl -X PUT http://localhost:8084/connectors/mongo-air-quality-connector/resume
```

---

### 6. Delete a Connector

**When to use:** To completely remove the connector

**Warning:** This stops CDC and removes configuration!

**Request:**
```bash
curl -X DELETE http://localhost:8084/connectors/mongo-air-quality-connector
```

**To recreate:**
```bash
curl -X POST http://localhost:8084/connectors \
  -H "Content-Type: application/json" \
  -d @streaming/mongo_connector_config.json
```

---

### 7. List Available Connector Plugins

**Request:**
```bash
curl -s http://localhost:8084/connector-plugins | python3 -m json.tool
```

**Shows:**
- Available connector types
- Versions
- Classes

You should see `MongoDbConnector` in the list.

---

## 🚨 Troubleshooting with UIs

### Problem: Producer Not Sending Data

**Kafka UI Checks:**
1. Topics → `air_quality_data` → Messages
2. Check if message count increases
3. Check timestamp of latest message

**If no new messages:**
```bash
# Check producer logs
docker logs producer --tail 50

# Check if producer container is running
docker ps | grep producer
```

---

### Problem: Consumer Not Reading

**Kafka UI Checks:**
1. Consumers → `air_quality_group`
2. Check if consumer appears in Members
3. Check if Lag is increasing

**If lag is increasing:**
```bash
# Check consumer logs
docker logs consumer --tail 50

# Check MongoDB connection
docker exec mongo mongosh -u airflow -p airflow123 --authenticationDatabase admin --eval "rs.status()"
```

---

### Problem: CDC Not Capturing Changes

**Kafka UI Checks:**
1. Topics → `mongo_cdc.air_quality_db.air_quality_raw`
2. Check message count

**API Checks:**
```bash
# Check connector status
curl -s http://localhost:8084/connectors/mongo-air-quality-connector/status | python3 -m json.tool
```

**If connector is FAILED:**
```bash
# Restart it
curl -X POST http://localhost:8084/connectors/mongo-air-quality-connector/restart

# Check logs
docker logs mongo-connector --tail 100
```

---

### Problem: High Consumer Lag

**Kafka UI Shows:**
- Lag > 100 messages
- Lag continuously increasing

**Possible Causes:**
1. **Consumer is slow**
   - Check consumer logs for errors
   - Database might be slow

2. **Consumer is down**
   - Check: `docker ps | grep consumer`
   - Restart: `docker-compose restart consumer`

3. **Too much data**
   - Normal if just started (catching up)
   - Concerning if happening regularly

---

## 📊 Metrics to Monitor Daily

### Critical Metrics (Check these every day)

**Kafka UI:**
1. **Topic Message Counts**
   - `air_quality_data`: Should increase by ~48 per day (2 cities × 24 hours)
   - `mongo_cdc...`: Should match or exceed air_quality_data

2. **Consumer Lag**
   - Both consumer groups: Lag should be 0
   - Alert if lag > 10

3. **Broker Status**
   - Should show UP
   - Check disk usage

**API:**
4. **Connector Status**
   - Should be RUNNING
   - No task failures

### Warning Signs 🚨

**Red Flags:**
- ❌ Broker shows DOWN
- ❌ Consumer lag > 100 and increasing
- ❌ Connector state = FAILED
- ❌ No new messages in 2+ hours
- ❌ Under-replicated partitions > 0

**Yellow Flags:**
- ⚠️ Consumer lag between 10-100
- ⚠️ Disk usage > 80%
- ⚠️ One task FAILED but connector RUNNING
- ⚠️ Slow message processing

---

## 🎯 Best Practices

### 1. Regular Health Checks

**Morning Routine (5 minutes):**
1. Open Kafka UI
2. Check Topics → Message counts increased overnight
3. Check Consumers → All lags = 0
4. Run API status check
5. Spot check: View few recent messages

### 2. Before Making Changes

**Always check current state first:**
```bash
# Save current connector config
curl -s http://localhost:8084/connectors/mongo-air-quality-connector/config > backup-config.json

# Check current status
curl -s http://localhost:8084/connectors/mongo-air-quality-connector/status
```

### 3. After Deployments

**Verify everything still works:**
1. Wait 5 minutes
2. Check Kafka UI - new messages?
3. Check consumer lag - still 0?
4. Check connector status - still RUNNING?

### 4. Data Validation

**Spot check data quality:**
1. Kafka UI → Messages → View latest message
2. Verify:
   - ✅ Has all expected fields
   - ✅ Values are reasonable (PM2.5 not 9999999)
   - ✅ Timestamp is recent
   - ✅ City name is correct

---

## 🔒 Security Notes

### Production Considerations

**Current Setup (Development):**
- ❌ No authentication on Kafka UI
- ❌ No SSL/TLS
- ❌ Open ports (8083, 8084)

**For Production:**
- ✅ Add authentication to Kafka UI
- ✅ Use SSL/TLS for all connections
- ✅ Restrict port access via firewall
- ✅ Use secrets management for passwords
- ✅ Enable Kafka SASL authentication

**Current Access:**
Anyone on your network can access:
- `http://localhost:8083` - Full Kafka control
- `http://localhost:8084` - Connector management

**Securing in Production:**
```yaml
# Add to docker-compose.yml
kafka-ui:
  environment:
    - AUTH_TYPE=LOGIN_FORM
    - AUTH_USER=admin
    - AUTH_PASSWORD=${UI_PASSWORD}
```

---

## 📚 Additional Resources

### Kafka UI Documentation
- GitHub: https://github.com/provectus/kafka-ui
- Features: https://docs.kafka-ui.provectus.io/features

### Kafka Connect REST API
- Official Docs: https://docs.confluent.io/platform/current/connect/references/restapi.html
- Debezium API: https://debezium.io/documentation/reference/stable/operations/debezium-server.html

### Monitoring Tools
- **Prometheus + Grafana**: Advanced metrics
- **Kafka Manager**: Alternative Kafka UI
- **Cruise Control**: Kafka cluster management

---

## ✅ Quick Reference Commands

```bash
# Kafka UI
Open: http://localhost:8083

# List connectors
curl -s http://localhost:8084/connectors

# Connector status
curl -s http://localhost:8084/connectors/mongo-air-quality-connector/status | python3 -m json.tool

# Restart connector
curl -X POST http://localhost:8084/connectors/mongo-air-quality-connector/restart

# View connector config
curl -s http://localhost:8084/connectors/mongo-air-quality-connector/config | python3 -m json.tool

# Delete connector
curl -X DELETE http://localhost:8084/connectors/mongo-air-quality-connector

# Register connector
curl -X POST http://localhost:8084/connectors -H "Content-Type: application/json" -d @streaming/mongo_connector_config.json

# Check all container logs
docker-compose logs -f

# Check specific service
docker logs -f <service-name>
```

---

End of UI Guide