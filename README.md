# Real-Time Air Quality Data Pipeline

A complete end-to-end data engineering project that monitors air quality in real-time for Kenyan cities (Nairobi and Mombasa), demonstrating modern data pipeline architecture using streaming, change data capture (CDC), and analytics storage.

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [What Problem Does This Solve?](#what-problem-does-this-solve)
3. [Architecture Overview](#architecture-overview)
4. [Technologies Used](#technologies-used)
5. [How the System Works](#how-the-system-works)
6. [Prerequisites](#prerequisites)
7. [Installation & Setup](#installation--setup)
8. [Understanding Each Component](#understanding-each-component)
9. [Monitoring & UI Dashboards](#monitoring--ui-dashboards)
10. [Querying the Data](#querying-the-data)
11. [Project Structure](#project-structure)
12. [Troubleshooting](#troubleshooting)
13. [Future Enhancements](#future-enhancements)
14. [Learning Outcomes](#learning-outcomes)

---

## 🌍 Project Overview

This project builds a **real-time data pipeline** that:
- Collects air quality data (PM2.5, PM10, carbon monoxide, ozone, etc.) for Nairobi and Mombasa
- Streams the data through a message queue (Kafka)
- Stores raw data in MongoDB for flexibility
- Captures changes automatically using Change Data Capture (CDC)
- Stores processed data in Cassandra for fast analytics queries

Think of it like this: Imagine you're monitoring the air quality in your city every hour. This system automatically fetches that information, saves it in multiple places for different purposes, and makes it available for analysis - all happening in real-time without manual intervention.

**🎯 Key Features:**
- ✅ Fully automated data collection every hour
- ✅ Real-time data streaming
- ✅ Automatic change tracking (you know when new data arrives)
- ✅ Multiple storage systems optimized for different use cases
- ✅ Built-in monitoring dashboards
- ✅ Containerized (runs anywhere with Docker)
- ✅ Production-ready error handling and retry logic

---

## 🤔 What Problem Does This Solve?

### The Challenge
Air quality affects millions of people's health daily. To build applications like:
- Public health monitoring systems
- Air quality prediction models
- Environmental impact studies
- Mobile apps showing air quality alerts

You need **reliable, real-time air quality data** that's easy to query and analyze.

### Our Solution
This pipeline automates everything:
1. **Data Collection**: Fetches data from Open-Meteo API hourly
2. **Reliability**: Automatically retries on failures
3. **Scalability**: Can easily add more cities or data sources
4. **Flexibility**: Stores data in multiple formats for different needs
5. **Real-time**: Changes are captured and propagated instantly

---

## 🏗️ Architecture Overview

Our pipeline follows the **Lambda Architecture** pattern, combining real-time and batch processing capabilities.

```
┌─────────────────┐
│   Open-Meteo    │  ← External Air Quality API
│      API        │
└────────┬────────┘
         │ HTTP Request (Every hour)
         ↓
┌─────────────────┐
│    Producer     │  ← Python script fetching data
│   (Ingestion)   │
└────────┬────────┘
         │ Publishes
         ↓
┌─────────────────┐
│  Kafka Broker   │  ← Message Queue (Streaming)
│   (Topic: air_  │
│  quality_data)  │
└────────┬────────┘
         │ Subscribes
         ↓
┌─────────────────┐
│    Consumer     │  ← Reads from Kafka
│ (MongoDB Writer)│
└────────┬────────┘
         │ Inserts
         ↓
┌─────────────────┐
│    MongoDB      │  ← Raw Data Storage (Document DB)
│ (Raw Documents) │
└────────┬────────┘
         │ Monitors Changes
         ↓
┌─────────────────┐
│    Debezium     │  ← Change Data Capture (CDC)
│  CDC Connector  │
└────────┬────────┘
         │ Publishes Changes
         ↓
┌─────────────────┐
│  Kafka Broker   │  ← CDC Events Stream
│ (Topic: mongo_  │
│  cdc.raw_data)  │
└────────┬────────┘
         │ Subscribes
         ↓
┌─────────────────┐
│   Cassandra     │  ← Analytics Consumer
│    Consumer     │
└────────┬────────┘
         │ Inserts
         ↓
┌─────────────────┐
│   Cassandra     │  ← Time-Series Analytics DB
│  (Optimized for │
│   Fast Queries) │
└─────────────────┘
```

**📸 INSERT SCREENSHOT: Architecture diagram (create using draw.io or similar)**

---

## 🛠️ Technologies Used

### Core Components

| Technology | Purpose | Why We Use It |
|------------|---------|---------------|
| **Python 3.10** | Programming Language | Easy to learn, great for data processing |
| **Apache Kafka** | Message Broker | Handles high-volume real-time data streaming |
| **MongoDB** | NoSQL Database | Flexible schema for raw data storage |
| **Cassandra** | Wide-Column Store | Optimized for time-series queries |
| **Debezium** | CDC Platform | Automatically captures database changes |
| **Docker** | Containerization | Ensures consistency across environments |
| **Zookeeper** | Coordination Service | Manages Kafka cluster |

### Python Libraries

- `kafka-python`: Kafka client for producing and consuming messages
- `pymongo`: MongoDB driver for Python
- `cassandra-driver`: Cassandra client
- `requests`: HTTP library for API calls
- `python-dotenv`: Environment variable management

---

## 🔄 How the System Works

Let me break down the data flow in simple terms:

### Step 1: Data Collection (Ingestion)
**Every hour**, our **Producer** script:
1. Wakes up automatically
2. Contacts the Open-Meteo weather API
3. Requests air quality data for Nairobi and Mombasa
4. Receives metrics like:
   - PM2.5 (fine particulate matter)
   - PM10 (coarse particulate matter)
   - Carbon monoxide levels
   - Nitrogen dioxide
   - Sulphur dioxide
   - Ozone levels
   - UV index

**📸 INSERT SCREENSHOT: Producer logs showing successful data fetch**

### Step 2: Message Streaming (Kafka)
The Producer doesn't directly save to a database. Instead, it:
1. Publishes the data to a **Kafka topic** (think of it as a mailbox)
2. This allows multiple consumers to read the same data
3. Provides fault tolerance (messages are kept even if consumers fail)

**Why use Kafka?**
- **Decoupling**: Producer and consumers work independently
- **Scalability**: Easy to add more consumers
- **Reliability**: Messages aren't lost if something crashes

**📸 INSERT SCREENSHOT: Kafka UI showing the air_quality_data topic**

### Step 3: Raw Data Storage (MongoDB)
A **Consumer** service:
1. Reads messages from Kafka
2. Stores each reading in MongoDB
3. MongoDB keeps the data in its original form

**Why MongoDB?**
- Flexible schema (easy to add new fields later)
- Great for raw, unprocessed data
- Fast writes for incoming data

**📸 INSERT SCREENSHOT: MongoDB data sample using MongoDB Compass or mongosh**

### Step 4: Change Data Capture (Debezium)
Here's where it gets interesting! **Debezium** acts like a watchdog:
1. Monitors MongoDB for any changes (inserts, updates, deletes)
2. Whenever data changes, it automatically:
   - Captures what changed
   - Creates a change event
   - Publishes it to another Kafka topic

**Why CDC?**
- No need to modify application code
- Captures every change automatically
- Enables building downstream applications without touching the source

**📸 INSERT SCREENSHOT: Debezium connector status in Kafka Connect UI**

### Step 5: Analytics Storage (Cassandra)
Another **Consumer** service:
1. Reads change events from the CDC Kafka topic
2. Transforms data if needed
3. Stores in Cassandra with optimized schema

**Why Cassandra?**
- Designed for time-series data
- Fast queries for date ranges
- Can handle massive data volumes
- Great for dashboards and analytics

**📸 INSERT SCREENSHOT: Cassandra data queried via cqlsh**

---

## ✅ Prerequisites

Before starting, you need:

1. **Docker & Docker Compose**
   - Docker Desktop (Windows/Mac) or Docker Engine (Linux)
   - Version 20.10 or higher
   - [Download Docker](https://www.docker.com/get-started)

2. **Git** (to clone the repository)
   - [Download Git](https://git-scm.com/downloads)

3. **System Requirements**
   - At least 8GB RAM (16GB recommended)
   - 20GB free disk space
   - Internet connection (for pulling Docker images and API calls)

4. **Basic Command Line Knowledge**
   - Opening a terminal/command prompt
   - Running commands
   - Basic file navigation

**Note:** You don't need to install Python, Kafka, MongoDB, or Cassandra separately - Docker handles everything!

---

## 🚀 Installation & Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/air-quality-pipeline.git
cd air-quality-pipeline
```

### Step 2: Create Environment File

Create a `.env` file in the project root with the following content:

```env
# Kafka Configuration
BOOTSTRAP_SERVERS=kafka:9092
KAFKA_TOPIC=air_quality_data
CDC_TOPIC=mongo_cdc.air_quality_db.air_quality_raw

# MongoDB Configuration
MONGO_URI=mongodb://airflow:airflow123@mongo:27017/air_quality_db?authSource=admin&replicaSet=rs0
MONGO_DB=air_quality_db
MONGO_COLLECTION=air_quality_raw

# Cassandra Configuration
CASSANDRA_HOST=cassandra
CASSANDRA_PORT=9042
CASSANDRA_KEYSPACE=air_quality_analytics

# API Configuration
OPEN_METEO_URL=https://air-quality-api.open-meteo.com/v1/air-quality
FETCH_INTERVAL=3600

# City Coordinates (Nairobi)
NAIROBI_LAT=-1.286389
NAIROBI_LON=36.817223

# City Coordinates (Mombasa)
MOMBASA_LAT=-4.0435
MOMBASA_LON=39.6682
```

### Step 3: Create MongoDB Keyfile

This is required for MongoDB replica set security:

```bash
openssl rand -base64 756 > mongo-keyfile
chmod 400 mongo-keyfile
sudo chown 999:999 mongo-keyfile
```

**On Windows (PowerShell):**
```powershell
# Create a random keyfile
$bytes = New-Object byte[] 756
(New-Object Security.Cryptography.RNGCryptoServiceProvider).GetBytes($bytes)
[Convert]::ToBase64String($bytes) | Out-File -FilePath mongo-keyfile -Encoding ASCII
```

### Step 4: Start All Services

```bash
docker-compose up -d
```

This command:
- Downloads all necessary Docker images (first time only)
- Starts all services in the background
- Takes 2-5 minutes depending on your internet speed

**📸 INSERT SCREENSHOT: docker-compose up output showing all services starting**

### Step 5: Initialize MongoDB Replica Set

Wait for MongoDB to fully start (about 30 seconds), then:

```bash
docker logs mongo-init
```

You should see: `Replica set initialized successfully!`

**📸 INSERT SCREENSHOT: mongo-init logs showing successful initialization**

### Step 6: Initialize Cassandra Schema

```bash
docker exec -i cassandra cqlsh < storage/cassandra_setup.cql
```

This creates the necessary keyspace and tables in Cassandra.

### Step 7: Register Debezium CDC Connector

```bash
curl -X POST http://localhost:8084/connectors \
  -H "Content-Type: application/json" \
  -d @streaming/mongo_connector_config.json
```

Verify it's running:

```bash
curl -s http://localhost:8084/connectors/mongo-air-quality-connector/status | python3 -m json.tool
```

You should see `"state": "RUNNING"`

**📸 INSERT SCREENSHOT: Connector status output**

### Step 8: Verify Everything is Running

```bash
docker ps
```

You should see 10 containers running:
- mongo
- mongo-init (exited - that's normal)
- zookeeper
- kafka
- kafka-ui
- producer
- consumer
- mongo-connector
- cassandra
- cassandra-consumer

**📸 INSERT SCREENSHOT: docker ps output showing all containers**

---

## 🧩 Understanding Each Component

### 1. Producer (Data Ingestion)

**Location:** `ingestion/producer.py`

**What it does:**
- Runs every hour (configurable via `FETCH_INTERVAL`)
- Fetches air quality data from Open-Meteo API
- Publishes to Kafka topic `air_quality_data`

**Key Features:**
- Automatic retry logic (5 attempts)
- Connection pooling to Kafka
- Detailed logging

**Monitor it:**
```bash
docker logs -f producer
```

**Expected log output:**
```
2025-10-16 21:51:42 [INFO] Connected to Kafka broker at kafka:9092
2025-10-16 21:51:47 [INFO] Published data for Nairobi at 2025-10-20T23:00
2025-10-16 21:51:48 [INFO] Published data for Mombasa at 2025-10-20T23:00
2025-10-16 21:51:48 [INFO] waiting for the next cycle...
```

**📸 INSERT SCREENSHOT: Producer logs**

---

### 2. Kafka Broker (Message Queue)

**Purpose:** Acts as a buffer between data producers and consumers

**Key Concepts:**
- **Topics**: Named channels (like `air_quality_data`)
- **Partitions**: Topics split for parallel processing
- **Offset**: Position in the message stream

**Check topics:**
```bash
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list
```

**Output:**
```
air_quality_data
mongo_cdc.air_quality_db.air_quality_raw
connect-configs
connect-offsets
connect-status
```

---

### 3. Consumer (MongoDB Writer)

**Location:** `ingestion/consumer.py`

**What it does:**
- Subscribes to Kafka topic `air_quality_data`
- Reads each message
- Inserts into MongoDB collection `air_quality_raw`

**Monitor it:**
```bash
docker logs -f consumer
```

**Expected output:**
```
2025-10-16 21:57:16 [INFO] Inserted record for Nairobi at 2025-10-20T23:00
2025-10-16 21:57:16 [INFO] Inserted record for Mombasa at 2025-10-20T23:00
```

**📸 INSERT SCREENSHOT: Consumer logs**

---

### 4. MongoDB (Raw Data Store)

**Purpose:** Stores all air quality readings in their original format

**Data Structure:**
```json
{
  "_id": ObjectId("68f14dc6a9f4452c033325d8"),
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

**Query MongoDB:**
```bash
docker exec mongo mongosh -u airflow -p airflow123 --authenticationDatabase admin --quiet \
  --eval "db.getSiblingDB('air_quality_db').air_quality_raw.find().limit(5)"
```

**Count documents:**
```bash
docker exec mongo mongosh -u airflow -p airflow123 --authenticationDatabase admin --quiet \
  --eval "db.getSiblingDB('air_quality_db').air_quality_raw.countDocuments()"
```

**📸 INSERT SCREENSHOT: MongoDB query results**

---

### 5. Debezium CDC Connector

**Purpose:** Captures every change in MongoDB and streams it to Kafka

**How it works:**
1. Monitors MongoDB's oplog (operation log)
2. When a document is inserted/updated/deleted
3. Creates a change event with:
   - `before`: State before change
   - `after`: State after change
   - `op`: Operation type (c=create, u=update, d=delete, r=read)
4. Publishes to CDC topic

**Check connector status:**
```bash
curl -s http://localhost:8084/connectors/mongo-air-quality-connector/status | python3 -m json.tool
```

**List all connectors:**
```bash
curl -s http://localhost:8084/connectors
```

**📸 INSERT SCREENSHOT: Connector status**

---

### 6. Cassandra Consumer

**Location:** `streaming/kafka_consumer.py`

**What it does:**
- Reads CDC events from Kafka
- Parses the change data
- Inserts into Cassandra for analytics

**Monitor it:**
```bash
docker logs -f cassandra-consumer
```

**Expected output:**
```
2025-10-16 21:28:47 [INFO] Connected to Cassandra keyspace: air_quality_analytics
2025-10-16 21:28:47 [INFO] Subscribed to CDC topic: mongo_cdc.air_quality_db.air_quality_raw
2025-10-16 21:28:47 [INFO] Inserted reading for Nairobi at 2025-10-20 23:00:00
2025-10-16 21:28:47 [INFO] Inserted reading for Mombasa at 2025-10-20 23:00:00
```

**📸 INSERT SCREENSHOT: Cassandra consumer logs**

---

### 7. Cassandra (Analytics Store)

**Purpose:** Optimized storage for time-series queries and analytics

**Schema Design:**
```sql
PRIMARY KEY (city, timestamp)
```
- **Partition Key**: `city` (data for each city stored together)
- **Clustering Key**: `timestamp` (sorted by time, newest first)

This design allows fast queries like:
- "Get all readings for Nairobi in the last 24 hours"
- "Show me the trend for PM2.5 in Mombasa this week"

**Query Cassandra:**
```bash
# Count all readings
docker exec cassandra cqlsh -e "SELECT COUNT(*) FROM air_quality_analytics.air_quality_readings;"

# View sample data
docker exec cassandra cqlsh -e "SELECT city, timestamp, pm2_5, pm10, ozone FROM air_quality_analytics.air_quality_readings LIMIT 5;"

# Query specific city
docker exec cassandra cqlsh -e "SELECT timestamp, pm2_5, ozone FROM air_quality_analytics.air_quality_readings WHERE city='Nairobi' LIMIT 10;"
```

**📸 INSERT SCREENSHOT: Cassandra query results**

---

## 📊 Monitoring & UI Dashboards

### 1. Kafka UI (Monitoring Kafka)

**Access:** http://localhost:8083

**What you can do:**
- View all Kafka topics
- See messages in real-time
- Monitor consumer lag
- Check topic configurations
- Browse message content

**How to use:**
1. Open browser and go to `http://localhost:8083`
2. You'll see a dashboard with all topics
3. Click on `air_quality_data` to see messages
4. Click on `mongo_cdc.air_quality_db.air_quality_raw` to see CDC events

**Key Metrics to Monitor:**
- **Messages**: Total messages in each topic
- **Consumer Groups**: Active consumers and their offsets
- **Lag**: How far behind consumers are

**📸 INSERT SCREENSHOT: Kafka UI dashboard**
**📸 INSERT SCREENSHOT: Kafka UI showing air_quality_data topic with messages**
**📸 INSERT SCREENSHOT: Kafka UI showing consumer groups**

**Troubleshooting with Kafka UI:**
- If producer isn't working → Check if `air_quality_data` topic has recent messages
- If consumer isn't working → Check consumer group lag
- If CDC isn't working → Check if CDC topic has messages

---

### 2. Kafka Connect UI (Monitoring Debezium)

**Access:** http://localhost:8084

This is a REST API endpoint. Use it with curl or Postman.

**Check connector status:**
```bash
curl -s http://localhost:8084/connectors/mongo-air-quality-connector/status | python3 -m json.tool
```

**Expected healthy output:**
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

**Other useful endpoints:**

List all connectors:
```bash
curl -s http://localhost:8084/connectors
```

Get connector config:
```bash
curl -s http://localhost:8084/connectors/mongo-air-quality-connector/config | python3 -m json.tool
```

Restart a connector:
```bash
curl -X POST http://localhost:8084/connectors/mongo-air-quality-connector/restart
```

Delete a connector:
```bash
curl -X DELETE http://localhost:8084/connectors/mongo-air-quality-connector
```

**📸 INSERT SCREENSHOT: Connector status JSON output**

---

### 3. MongoDB (Using MongoDB Compass - Optional)

If you want a GUI for MongoDB:

1. Download [MongoDB Compass](https://www.mongodb.com/products/compass)
2. Connect using: `mongodb://airflow:airflow123@localhost:27020/air_quality_db?authSource=admin`
3. Browse the `air_quality_raw` collection

**📸 INSERT SCREENSHOT: MongoDB Compass showing the collection**

---

### 4. Container Health Monitoring

**View all containers:**
```bash
docker ps
```

**Check resource usage:**
```bash
docker stats
```

This shows CPU, memory, and network usage for each container.

**📸 INSERT SCREENSHOT: docker stats output**

**View logs for any service:**
```bash
# Producer
docker logs -f producer

# Consumer
docker logs -f consumer

# Kafka
docker logs -f kafka

# MongoDB
docker logs -f mongo

# Cassandra
docker logs -f cassandra

# Cassandra Consumer
docker logs -f cassandra-consumer
```

---

## 🔍 Querying the Data

### MongoDB Queries

**Basic Queries:**

```bash
# Count total documents
docker exec mongo mongosh -u airflow -p airflow123 --authenticationDatabase admin --quiet \
  --eval "db.getSiblingDB('air_quality_db').air_quality_raw.countDocuments()"

# Find latest reading for Nairobi
docker exec mongo mongosh -u airflow -p airflow123 --authenticationDatabase admin --quiet \
  --eval "db.getSiblingDB('air_quality_db').air_quality_raw.find({city: 'Nairobi'}).sort({_id: -1}).limit(1)"

# Find all readings with high PM2.5 (> 50)
docker exec mongo mongosh -u airflow -p airflow123 --authenticationDatabase admin --quiet \
  --eval "db.getSiblingDB('air_quality_db').air_quality_raw.find({pm2_5: {\$gt: 50}})"

# Get average PM2.5 by city
docker exec mongo mongosh -u airflow -p airflow123 --authenticationDatabase admin --quiet \
  --eval "db.getSiblingDB('air_quality_db').air_quality_raw.aggregate([{'\$group': {_id: '\$city', avgPM25: {'\$avg': '\$pm2_5'}}}])"
```

---

### Cassandra Queries (CQL)

**Basic Queries:**

```bash
# Count all readings
docker exec cassandra cqlsh -e "SELECT COUNT(*) FROM air_quality_analytics.air_quality_readings;"

# Get latest readings for each city
docker exec cassandra cqlsh -e "SELECT city, timestamp, pm2_5, pm10, ozone FROM air_quality_analytics.air_quality_readings PER PARTITION LIMIT 1;"

# Query Nairobi readings
docker exec cassandra cqlsh -e "SELECT timestamp, pm2_5, pm10, carbon_monoxide FROM air_quality_analytics.air_quality_readings WHERE city='Nairobi' LIMIT 20;"

# Query Mombasa readings
docker exec cassandra cqlsh -e "SELECT timestamp, pm2_5, pm10, carbon_monoxide FROM air_quality_analytics.air_quality_readings WHERE city='Mombasa' LIMIT 20;"

# Query specific time range (if you have multiple days of data)
docker exec cassandra cqlsh -e "SELECT * FROM air_quality_analytics.air_quality_readings WHERE city='Nairobi' AND timestamp >= '2025-10-20' AND timestamp < '2025-10-21';"
```

**Advanced Analytics (after collecting data for several days):**

```bash
# Get daily averages (requires daily_air_quality_stats table to be populated)
docker exec cassandra cqlsh -e "SELECT date, avg_pm2_5, avg_pm10 FROM air_quality_analytics.daily_air_quality_stats WHERE city='Nairobi' LIMIT 7;"
```

**📸 INSERT SCREENSHOT: Various query results from both databases**

---

## 📁 Project Structure

```
air-quality-pipeline/
│
├── ingestion/                      # Data ingestion components
│   ├── Dockerfile                  # Dockerfile for producer/consumer
│   ├── producer.py                 # Fetches data from API → Kafka
│   └── consumer.py                 # Kafka → MongoDB writer
│
├── streaming/                      # Streaming components
│   ├── kafka_consumer.py           # CDC → Cassandra consumer
│   └── mongo_connector_config.json # Debezium CDC configuration
│
├── storage/                        # Database initialization
│   ├── mongo_init.js               # MongoDB initialization (empty)
│   ├── cassandra_setup.cql         # Cassandra schema
│   └── init-replica-set.sh         # MongoDB replica set init script
│
├── docker-compose.yml              # Orchestrates all services
├── Dockerfile                      # Base Python image
├── requirements.txt                # Python dependencies
├── .env                            # Environment variables (create this)
├── .gitignore                      # Git ignore file
├── mongo-keyfile                   # MongoDB security key (create this)
└── README.md                       # This file
```

---

## 🐛 Troubleshooting

### Issue 1: Producer Can't Connect to Kafka

**Symptoms:**
```
KafkaConnectionError: 111 ECONNREFUSED
```

**Solutions:**
1. Check Kafka is running: `docker ps | grep kafka`
2. Wait 30 seconds for Kafka to fully start
3. Check `docker-compose.yml` has correct `KAFKA_ADVERTISED_LISTENERS`:
   ```yaml
   KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092,PLAINTEXT_INTERNAL://kafka:9093
   ```
4. Restart producer: `docker-compose restart producer`

---

### Issue 2: Consumer Can't Write to MongoDB

**Symptoms:**
```
No servers available for writes
server_type: RSGhost
```

**Solution:**
MongoDB replica set not initialized. Run:
```bash
docker logs mongo-init
```

If you see errors, manually initialize:
```bash
docker exec mongo mongosh -u airflow -p airflow123 --authenticationDatabase admin --eval "rs.initiate({_id: 'rs0', members: [{_id: 0, host: 'mongo:27017'}]})"
```

---

### Issue 3: Debezium Connector Not Running

**Symptoms:**
```bash
curl http://localhost:8084/connectors
# Returns: []
```

**Solution:**
Register the connector:
```bash
curl -X POST http://localhost:8084/connectors \
  -H "Content-Type: application/json" \
  -d @streaming/mongo_connector_config.json
```

---

### Issue 4: Cassandra Consumer Fails

**Symptoms:**
```
Unrecognized configs: {'value_desrializer'}
```

**Solution:**
Typo in code. Check `streaming/kafka_consumer.py` line 64:
```python
# Wrong:
value_desrializer=lambda x: json.loads(x.decode("utf-8"))

# Correct:
value_deserializer=lambda x: json.loads(x.decode("utf-8"))
```

Fix the typo and rebuild:
```bash
docker-compose up -d --build cassandra-consumer
```

---

### Issue 5: Only 2 Records in Cassandra

**Symptoms:**
Logs show many inserts but `SELECT COUNT(*)` shows only 2 records.

**Explanation:**
This is normal! All readings have the same timestamp (hourly data). Cassandra's primary key is `(city, timestamp)`, so:
- Each city gets only 1 record (the latest)
- Inserts with same PK are UPSERTs (updates)

**Solution:**
Wait 1 hour for new timestamp data, or change `FETCH_INTERVAL` to collect historical data.

---

### Issue 6: Docker Compose Fails to Start

**Symptoms:**
```
ERROR: Couldn't connect to Docker daemon
```

**Solutions:**
1. Start Docker Desktop (Windows/Mac)
2. Or start Docker service (Linux): `sudo systemctl start docker`
3. Check Docker is running: `docker ps`

---

### Issue 7: Permission Denied on mongo-keyfile

**Symptoms:**
```
error: open("mongo-keyfile"): Permission denied
```

**Solution:**
```bash
chmod 400 mongo-keyfile
sudo chown 999:999 mongo-keyfile
```

---

### General Debugging Commands

**Check all container statuses:**
```bash
docker ps -a
```

**View logs for specific service:**
```bash
docker logs <container-name>
```

**Restart specific service:**
```bash
docker-compose restart <service-name>
```

**Rebuild and restart:**
```bash
docker-compose up -d --build <service-name>
```

**Stop everything:**
```bash
docker-compose down
```

**Stop and remove volumes (CAUTION: deletes all data):**
```bash
docker-compose down -v
```

---

## 🚀 Future Enhancements

This project can be extended in many ways:

### 1. Data Visualization
- Add Grafana for real-time dashboards
- Create charts showing:
  - PM2.5 trends over time
  - Comparison between cities
  - Air quality index (AQI) calculations
  - Health recommendations based on levels

### 2. More Cities
Add more Kenyan cities:
```python
CITIES = {
    "Nairobi": {...},
    "Mombasa": {...},
    "Kisumu": {"lat": -0.0917, "lon": 34.7680},
    "Nakuru": {"lat": -0.3031, "lon": 36.0800},
    "Eldoret": {"lat": 0.5143, "lon": 35.2698}
}
```

### 3. Data Processing
- Calculate Air Quality Index (AQI) from raw pollutant values
- Add data quality checks and validation
- Implement data aggregation pipelines
- Create hourly, daily, weekly summaries

### 4. Alerting System
- Send notifications when air quality exceeds thresholds
- Email/SMS alerts for unhealthy air quality
- Integration with Slack or Discord webhooks

### 5. Machine Learning
- Predict future air quality levels
- Anomaly detection for unusual pollution spikes
- Correlation analysis with weather data

### 6. API Development
- Build REST API to serve data
- Create endpoints for:
  - Current air quality by city
  - Historical data queries
  - Statistical summaries
- Add authentication and rate limiting

### 7. Performance Optimization
- Add Kafka partitioning for better parallelism
- Implement data retention policies
- Add caching layer (Redis) for frequent queries
- Optimize Cassandra queries with materialized views

### 8. High Availability
- Add multiple Kafka brokers
- Configure Cassandra cluster (3+ nodes)
- Implement MongoDB sharding
- Add load balancer for API

---

## 🎓 Learning Outcomes

By building and understanding this project, you will learn:

### 1. Data Engineering Fundamentals
- **ETL/ELT Processes**: Extract, Transform, Load patterns
- **Data Pipeline Architecture**: Designing robust data flows
- **Stream Processing**: Real-time vs batch processing
- **Data Modeling**: Schema design for different databases

### 2. Distributed Systems
- **Message Queues**: Kafka for decoupled architecture
- **Pub/Sub Pattern**: Publishers and subscribers
- **Event-Driven Architecture**: Reacting to data changes
- **Horizontal Scaling**: Adding more nodes for capacity

### 3. Database Technologies

**MongoDB (Document Store):**
- Schema-less flexibility
- Document-oriented design
- Replica sets for high availability
- When to use NoSQL

**Cassandra (Wide-Column Store):**
- Time-series data modeling
- Partition key design
- Clustering keys and sorting
- CAP theorem in practice (AP system)
- CQL queries and best practices

### 4. Change Data Capture (CDC)
- Database change tracking
- Event sourcing patterns
- Debezium platform
- Building derived data stores
- Maintaining data consistency across systems

### 5. Containerization & Orchestration
- Docker fundamentals
- Docker Compose for multi-container apps
- Container networking
- Volume management
- Environment configuration
- Container health checks

### 6. DevOps Practices
- Infrastructure as Code (IaC)
- Service dependencies management
- Logging and monitoring
- Debugging distributed systems
- Error handling and retry logic

### 7. API Integration
- REST API consumption
- Rate limiting considerations
- Error handling for external services
- Data parsing and validation

### 8. Python for Data Engineering
- Kafka client (`kafka-python`)
- Database drivers (pymongo, cassandra-driver)
- Asynchronous operations
- Logging best practices
- Environment variable management

### 9. Production Readiness
- **Reliability**: Retry logic, error handling
- **Observability**: Logging, monitoring, metrics
- **Scalability**: Designing for growth
- **Security**: Authentication, keyfile management
- **Documentation**: Writing clear, helpful docs

### 10. Real-World Problem Solving
- Debugging connection issues
- Understanding error messages
- Reading logs effectively
- Performance troubleshooting
- Data consistency challenges

---

## 📚 Additional Resources

### Learning Kafka
- [Kafka Official Documentation](https://kafka.apache.org/documentation/)
- [Confluent Kafka Tutorials](https://kafka-tutorials.confluent.io/)
- [Understanding Kafka Topics and Partitions](https://www.confluent.io/blog/apache-kafka-intro-how-kafka-works/)

### MongoDB
- [MongoDB University](https://university.mongodb.com/) (Free courses)
- [MongoDB Manual](https://docs.mongodb.com/manual/)
- [Replica Sets Explained](https://docs.mongodb.com/manual/replication/)

### Cassandra
- [DataStax Academy](https://academy.datastax.com/) (Free courses)
- [Cassandra Data Modeling](https://cassandra.apache.org/doc/latest/cassandra/data_modeling/)
- [CQL Reference](https://cassandra.apache.org/doc/latest/cassandra/cql/)

### Debezium
- [Debezium Documentation](https://debezium.io/documentation/)
- [CDC Tutorial](https://debezium.io/blog/2020/02/10/event-sourcing-vs-cdc/)

### Docker
- [Docker Getting Started](https://docs.docker.com/get-started/)
- [Docker Compose Tutorial](https://docs.docker.com/compose/gettingstarted/)

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Report Bugs**: Open an issue describing the bug
2. **Suggest Features**: Share your ideas for enhancements
3. **Submit Pull Requests**: Fix bugs or add features
4. **Improve Documentation**: Help make the docs clearer
5. **Share Your Experience**: Write blog posts or tutorials

### Development Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Test thoroughly
5. Commit: `git commit -m 'Add amazing feature'`
6. Push: `git push origin feature/amazing-feature`
7. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👨‍💻 Author

**Your Name**
- GitHub: [@yourusername](https://github.com/yourusername)
- LinkedIn: [Your LinkedIn](https://linkedin.com/in/yourprofile)
- Email: your.email@example.com

---

## 🙏 Acknowledgments

- **Open-Meteo API** for providing free air quality data
- **Apache Kafka** community for excellent documentation
- **Debezium** team for the CDC platform
- All open-source contributors who make projects like this possible

---

## 📸 Screenshots