# Real-Time Air Quality Data Pipeline

A complete end-to-end data engineering project that monitors air quality in real-time for Kenyan cities (Nairobi and Mombasa), demonstrating modern data pipeline architecture using streaming, change data capture (CDC), and analytics storage.

---

## Table of Contents

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

## Project Overview

This project builds a **real-time data pipeline** that:
- Collects air quality data (PM2.5, PM10, carbon monoxide, ozone, etc.) for Nairobi and Mombasa
- Streams the data through a message queue (Kafka)
- Stores raw data in MongoDB for flexibility
- Captures changes automatically using Change Data Capture (CDC)
- Stores processed data in Cassandra for fast analytics queries

Think of it like this: Imagine you're monitoring the air quality in your city every hour. This system automatically fetches that information, saves it in multiple places for different purposes, and makes it available for analysis - all happening in real-time without manual intervention.

** Key Features:**
- Fully automated data collection every hour
- Real-time data streaming
- Automatic change tracking (you know when new data arrives)
- Multiple storage systems optimized for different use cases
- Built-in monitoring dashboards
- Containerized (runs anywhere with Docker)
- Production-ready error handling and retry logic

---

## What Problem Does This Solve?

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

## Architecture Overview

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

## Technologies Used

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

## How the System Works

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
![Producer logs showing succesful data fetch](images/producer_logs.png)
*Producer logs showing successful data fetch*

### Step 2: Message Streaming (Kafka)
The Producer doesn't directly save to a database. Instead, it:
1. Publishes the data to a **Kafka topic** (think of it as a mailbox)
2. This allows multiple consumers to read the same data
3. Provides fault tolerance (messages are kept even if consumers fail)

**Why use Kafka?**
- **Decoupling**: Producer and consumers work independently
- **Scalability**: Easy to add more consumers
- **Reliability**: Messages aren't lost if something crashes
![Kafka UI showing the air_quality_data](images/kafka_ui_msgs.png)
*Kafka UI showing the air_quality_data topic*

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
![Cassandra data queried via cqlsh](images/cassandra_query.png)
*Cassandra data queried via cqlsh*

---

## Prerequisites

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

## Installation & Setup

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


### Step 4: Start All Services

```bash
docker-compose up -d
```

This command:
- Downloads all necessary Docker images (first time only)
- Starts all services in the background
- Takes 2-5 minutes depending on your internet speed
![docker-compose up output showing all services starting](images/docker_compose_up.png)
*docker-compose up output showing all services starting*

### Step 5: Initialize MongoDB Replica Set

Wait for MongoDB to fully start (about 30 seconds), then:

```bash
docker logs mongo-init
```

You should see: `Replica set initialized successfully!`
![MongoDB Initialization](images/mongo_init_success.png)
*mongo-init logs showing successful initialization*

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
![Docker ps](images/docker_ps.png)
*docker ps output showing all containers*

---

## Understanding Each Component

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
![Producer logs](images/producer_logs.png)
*Producer logs*

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
![Consumer logs](images/consumer_logs.png)
*Consumer logs*

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
![MongoDB query results](images/mongodb_query.png)
*MongoDB query results*

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
![Cassandra consumer logs]()
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
![Cassandra query results](images/query_results.png)
*Cassandra query results*

---

## Monitoring & UI Dashboards

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
![Kafka UI dashboard](images/kafka_ui.png)
![Messages](images/kafka_ui_msgs.png)
![Consumers](images/kafka_ui_consumers.png)

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



---

### Issue 5: Only 2 Records in Cassandra

**Symptoms:**
Logs show many inserts but `SELECT COUNT(*)` shows only 2 records.

*
```


## Future Enhancements

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

---
## Contributing

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

## Author

**Your Name**
- GitHub: [@25thOliver](https://github.com/25thOliver)
- LinkedIn: [LinkedIn](https://www.linkedin.com/in/samwel-oliver/)
- Email: oliversamwel33@gmail.com

---

## Acknowledgments

- **Open-Meteo API** for providing free air quality data
- **Apache Kafka** community for excellent documentation
- **Debezium** team for the CDC platform
- All open-source contributors who make projects like this possible