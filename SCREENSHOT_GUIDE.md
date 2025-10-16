# Screenshot Guide for Air Quality Pipeline Documentation

This guide tells you exactly what screenshots to capture and where to insert them in the README.md file.

---

## 📸 Screenshot Checklist

Use this checklist to track your progress:

- [ ] Architecture Diagram
- [ ] Docker Compose Startup
- [ ] Container Status
- [ ] Producer Logs
- [ ] Kafka UI - Dashboard
- [ ] Kafka UI - Topics
- [ ] Kafka UI - Messages
- [ ] Consumer Logs
- [ ] MongoDB Query Results
- [ ] Mongo Init Logs
- [ ] Debezium Connector Status
- [ ] Cassandra Consumer Logs
- [ ] Cassandra Query Results
- [ ] Docker Stats
- [ ] Kafka UI - Consumer Groups

---

## 🎯 Screenshot Instructions

### Screenshot 1: Architecture Diagram
**Location in README:** Section "Architecture Overview"
**What to capture:** Create a visual diagram using draw.io, Lucidchart, or similar

**Steps:**
1. Go to https://app.diagrams.net/
2. Create a flowchart showing:
   - Open-Meteo API (cloud icon)
   - Producer (box with Python logo)
   - Kafka (box with Kafka logo)
   - Consumer (box)
   - MongoDB (database icon)
   - Debezium CDC (box)
   - Kafka CDC Topic (box)
   - Cassandra Consumer (box)
   - Cassandra (database icon)
3. Add arrows showing data flow
4. Use different colors for each layer (ingestion, streaming, storage)
5. Export as PNG
6. Save as: `screenshots/architecture-diagram.png`

**Insert in README after:**
```markdown
└─────────────────┘
```

---

### Screenshot 2: Docker Compose Startup
**Location in README:** Section "Installation & Setup > Step 4"
**What to capture:** Terminal output when running `docker-compose up -d`

**Steps:**
1. Stop all containers: `docker-compose down`
2. Clear terminal
3. Run: `docker-compose up -d`
4. Take screenshot showing:
   - The command
   - Creating network
   - Creating volumes
   - Pulling/Creating containers
   - Starting containers
5. Save as: `screenshots/docker-compose-up.png`

**Insert in README after:**
```markdown
- Takes 2-5 minutes depending on your internet speed
```

---

### Screenshot 3: Mongo Init Success
**Location in README:** Section "Installation & Setup > Step 5"
**What to capture:** `docker logs mongo-init` output

**Steps:**
1. Run: `docker logs mongo-init`
2. Take screenshot showing:
   - "Waiting for MongoDB to start..."
   - "Initializing MongoDB replica set..."
   - Connection messages
   - "{ ok: 1 }" or success message
   - "MongoDB replica set initialization complete."
3. Save as: `screenshots/mongo-init-success.png`

**Insert in README after:**
```markdown
You should see: `Replica set initialized successfully!`
```

---

### Screenshot 4: Debezium Connector Status
**Location in README:** Section "Installation & Setup > Step 7"
**What to capture:** Connector status JSON output

**Steps:**
1. Run: `curl -s http://localhost:8084/connectors/mongo-air-quality-connector/status | python3 -m json.tool`
2. Take screenshot showing JSON with:
   - "state": "RUNNING"
   - Worker ID
   - Tasks array with state "RUNNING"
3. Save as: `screenshots/debezium-status.png`

**Insert in README after:**
```markdown
You should see `"state": "RUNNING"`
```

---

### Screenshot 5: Docker PS Output
**Location in README:** Section "Installation & Setup > Step 8"
**What to capture:** `docker ps` showing all containers

**Steps:**
1. Run: `docker ps`
2. Take screenshot showing all 10 containers:
   - mongo
   - mongo-init (may show as exited - that's OK)
   - zookeeper
   - kafka
   - kafka-ui
   - producer
   - consumer
   - mongo-connector
   - cassandra
   - cassandra-consumer
3. Make sure STATUS column is visible
4. Save as: `screenshots/docker-ps-all-containers.png`

**Insert in README after:**
```markdown
- cassandra-consumer
```

---

### Screenshot 6: Producer Logs
**Location in README:** Section "Understanding Each Component > 1. Producer"
**What to capture:** `docker logs producer --tail 20`

**Steps:**
1. Run: `docker logs producer --tail 20`
2. Take screenshot showing:
   - "Starting air quality producer..."
   - "Producing to topic 'air_quality_data' every 3600 seconds"
   - "Connected to Kafka broker"
   - "Published data for Nairobi at..."
   - "Published data for Mombasa at..."
   - "waiting for the next cycle..."
3. Save as: `screenshots/producer-logs.png`

**Insert in README after:**
```markdown
2025-10-16 21:51:48 [INFO] waiting for the next cycle...
```

---

### Screenshot 7: Consumer Logs
**Location in README:** Section "Understanding Each Component > 3. Consumer"
**What to capture:** `docker logs consumer --tail 20`

**Steps:**
1. Run: `docker logs consumer --tail 20`
2. Take screenshot showing:
   - "Connected to MongoDB"
   - "Connected to kafka broker"
   - "Inserted record for Nairobi at..."
   - "Inserted record for Mombasa at..."
3. Save as: `screenshots/consumer-logs.png`

**Insert in README after:**
```markdown
2025-10-16 21:57:16 [INFO] Inserted record for Mombasa at 2025-10-20T23:00
```

---

### Screenshot 8: MongoDB Query Results
**Location in README:** Section "Understanding Each Component > 4. MongoDB"
**What to capture:** MongoDB query showing documents

**Steps:**
1. Run: `docker exec mongo mongosh -u airflow -p airflow123 --authenticationDatabase admin --quiet --eval "db.getSiblingDB('air_quality_db').air_quality_raw.find().limit(3)"`
2. Take screenshot showing:
   - Document with _id, time, pm2_5, pm10, etc.
   - Multiple cities (Nairobi, Mombasa)
   - JSON structure clearly visible
3. Save as: `screenshots/mongodb-query.png`

**Insert in README after:**
```markdown
  "city": "Mombasa"
}
```

---

### Screenshot 9: Cassandra Consumer Logs
**Location in README:** Section "Understanding Each Component > 6. Cassandra Consumer"
**What to capture:** `docker logs cassandra-consumer --tail 20`

**Steps:**
1. Run: `docker logs cassandra-consumer --tail 20`
2. Take screenshot showing:
   - "Starting Cassandra Consumer..."
   - "Connected to Cassandra keyspace: air_quality_analytics"
   - "Subscribed to CDC topic"
   - "Inserted reading for Nairobi at..."
   - "Inserted reading for Mombasa at..."
3. Save as: `screenshots/cassandra-consumer-logs.png`

**Insert in README after:**
```markdown
2025-10-16 21:28:47 [INFO] Inserted reading for Mombasa at 2025-10-20 23:00:00
```

---

### Screenshot 10: Cassandra Query Results
**Location in README:** Section "Understanding Each Component > 7. Cassandra"
**What to capture:** Cassandra query showing data

**Steps:**
1. Run: `docker exec cassandra cqlsh -e "SELECT city, timestamp, pm2_5, pm10, ozone FROM air_quality_analytics.air_quality_readings LIMIT 5;"`
2. Take screenshot showing:
   - Table header with column names
   - Rows of data for both cities
   - Clean tabular format
3. Save as: `screenshots/cassandra-query.png`

**Insert in README after:**
```markdown
 Nairobi | 2025-10-20 23:00:00.000000+0000 |     8 |  8.5 |    60
```

---

### Screenshot 11: Kafka UI - Dashboard
**Location in README:** Section "Monitoring & UI Dashboards > 1. Kafka UI"
**What to capture:** Main Kafka UI dashboard

**Steps:**
1. Open browser to http://localhost:8083
2. Take screenshot showing:
   - List of all topics
   - Topic names clearly visible
   - Message counts
   - Clean UI layout
3. Save as: `screenshots/kafka-ui-dashboard.png`

**Insert in README after:**
```markdown
**Key Metrics to Monitor:**
```

---

### Screenshot 12: Kafka UI - Air Quality Topic
**Location in README:** Section "Monitoring & UI Dashboards > 1. Kafka UI"
**What to capture:** Messages in air_quality_data topic

**Steps:**
1. In Kafka UI, click on "air_quality_data" topic
2. Click "Messages" tab
3. Take screenshot showing:
   - Topic name at top
   - List of messages
   - Message content (JSON with city, pm2_5, etc.)
   - Timestamps
4. Save as: `screenshots/kafka-ui-messages.png`

**Insert in README after:**
```markdown
4. Click on `mongo_cdc.air_quality_db.air_quality_raw` to see CDC events
```

---

### Screenshot 13: Kafka UI - Consumer Groups
**Location in README:** Section "Monitoring & UI Dashboards > 1. Kafka UI"
**What to capture:** Consumer groups and their lag

**Steps:**
1. In Kafka UI, click "Consumer Groups" in left menu
2. Take screenshot showing:
   - List of consumer groups
   - Group IDs (air_quality_group, cassandra_consumer_group)
   - State (Stable)
   - Members count
3. Save as: `screenshots/kafka-ui-consumers.png`

**Insert in README after:**
```markdown
- **Lag**: How far behind consumers are
```

---

### Screenshot 14: Debezium Connector Status (API)
**Location in README:** Section "Monitoring & UI Dashboards > 2. Kafka Connect UI"
**What to capture:** Terminal showing connector status JSON

**Steps:**
1. Run: `curl -s http://localhost:8084/connectors/mongo-air-quality-connector/status | python3 -m json.tool`
2. Take screenshot showing formatted JSON
3. Make sure "RUNNING" states are clearly visible
4. Save as: `screenshots/debezium-api-status.png`

**Insert in README after:**
```markdown
    "type": "source"
}
```

---

### Screenshot 15: MongoDB Compass (Optional)
**Location in README:** Section "Monitoring & UI Dashboards > 3. MongoDB"
**What to capture:** MongoDB Compass showing the collection

**If you have MongoDB Compass installed:**
1. Open MongoDB Compass
2. Connect to: `mongodb://airflow:airflow123@localhost:27020/air_quality_db?authSource=admin`
3. Navigate to air_quality_raw collection
4. Take screenshot showing:
   - Collection name in sidebar
   - Documents view
   - Document structure
5. Save as: `screenshots/mongodb-compass.png`

**Insert in README after:**
```markdown
3. Browse the `air_quality_raw` collection
```

---

### Screenshot 16: Docker Stats
**Location in README:** Section "Monitoring & UI Dashboards > 4. Container Health"
**What to capture:** `docker stats` output

**Steps:**
1. Run: `docker stats --no-stream`
2. Take screenshot showing:
   - Container names
   - CPU %
   - Memory usage
   - Network I/O
   - All containers visible
3. Save as: `screenshots/docker-stats.png`

**Insert in README after:**
```markdown
This shows CPU, memory, and network usage for each container.
```

---

### Screenshot 17: Query Results Compilation
**Location in README:** Section "Querying the Data"
**What to capture:** Multiple query results in one image

**Steps:**
1. Run several queries in sequence:
   ```bash
   # MongoDB count
   docker exec mongo mongosh -u airflow -p airflow123 --authenticationDatabase admin --quiet --eval "db.getSiblingDB('air_quality_db').air_quality_raw.countDocuments()"
   
   # Cassandra count
   docker exec cassandra cqlsh -e "SELECT COUNT(*) FROM air_quality_analytics.air_quality_readings;"
   
   # City-specific query
   docker exec cassandra cqlsh -e "SELECT timestamp, pm2_5 FROM air_quality_analytics.air_quality_readings WHERE city='Nairobi' LIMIT 3;"
   ```
2. Take screenshot showing all outputs
3. Save as: `screenshots/query-results-compilation.png`

**Insert in README after:**
```markdown
**📸 INSERT SCREENSHOT: Various query results from both databases**
```

---

## 📁 Screenshot Organization

Create this folder structure:

```
air-quality-pipeline/
├── screenshots/
│   ├── architecture-diagram.png
│   ├── docker-compose-up.png
│   ├── docker-ps-all-containers.png
│   ├── mongo-init-success.png
│   ├── debezium-status.png
│   ├── producer-logs.png
│   ├── consumer-logs.png
│   ├── mongodb-query.png
│   ├── cassandra-consumer-logs.png
│   ├── cassandra-query.png
│   ├── kafka-ui-dashboard.png
│   ├── kafka-ui-messages.png
│   ├── kafka-ui-consumers.png
│   ├── debezium-api-status.png
│   ├── mongodb-compass.png (optional)
│   ├── docker-stats.png
│   └── query-results-compilation.png
```

---

## 🖼️ How to Insert Screenshots in README

After capturing each screenshot, insert it into the README.md using this syntax:

```markdown
![Screenshot Description](screenshots/filename.png)
```

**Example:**
```markdown
**📸 Screenshot: Producer Logs**
![Producer Logs showing successful data publication](screenshots/producer-logs.png)
```

---

## 💡 Screenshot Best Practices

1. **Resolution**: Use at least 1920x1080 for clarity
2. **Cropping**: Crop out unnecessary toolbars/taskbars
3. **Highlighting**: Add red boxes or arrows to highlight important parts (optional)
4. **Dark/Light Mode**: Be consistent - use the same theme throughout
5. **Terminal Width**: Make terminal at least 100 columns wide
6. **Font Size**: Increase terminal font size for readability (14-16pt)
7. **Clean Output**: Clear terminal before taking screenshots of commands
8. **File Format**: Use PNG for best quality
9. **File Size**: Optimize images to keep under 1MB each
10. **Names**: Use descriptive, lowercase, hyphen-separated names

---

## 🛠️ Tools for Screenshots

### Mac
- Built-in: `Cmd + Shift + 4` (select area)
- App: Skitch (for annotations)

### Windows
- Built-in: `Windows + Shift + S` (Snipping Tool)
- App: Greenshot (free, open-source)

### Linux
- GNOME: `Shift + Print Screen`
- KDE: Spectacle
- CLI: `scrot` or `gnome-screenshot`

### For Annotations
- [Snagit](https://www.techsmith.com/screen-capture.html) (paid)
- [Greenshot](https://getgreenshot.org/) (free)
- [Skitch](https://evernote.com/products/skitch) (free)
- Online: [Photopea](https://www.photopea.com/) (free)

---

## ✅ Verification Checklist

Before finalizing documentation:

- [ ] All screenshots are clear and readable
- [ ] File names match the guide
- [ ] Screenshots are placed in correct sections
- [ ] All placeholder text `**📸 INSERT SCREENSHOT:**` is replaced
- [ ] Images load correctly in GitHub/rendered Markdown
- [ ] File sizes are reasonable (< 1MB each)
- [ ] Architecture diagram includes all components
- [ ] Terminal screenshots show complete commands and outputs
- [ ] UI screenshots show relevant information clearly
- [ ] No sensitive information visible (passwords, personal data)

---

## 🎨 Architecture Diagram Details

Your architecture diagram should include:

**Components (boxes):**
1. Open-Meteo API (cloud icon)
2. Producer (Python logo)
3. Kafka Broker (Kafka logo)
4. Consumer (gear icon)
5. MongoDB (leaf icon)
6. Debezium CDC (connector icon)
7. Kafka CDC Topic (Kafka logo)
8. Cassandra Consumer (gear icon)
9. Cassandra (Cassandra logo)

**Connections (arrows):**
- API → Producer (HTTP)
- Producer → Kafka (Publishes)
- Kafka → Consumer (Subscribes)
- Consumer → MongoDB (Inserts)
- MongoDB → Debezium (Monitors)
- Debezium → Kafka CDC (Publishes)
- Kafka CDC → Cassandra Consumer (Subscribes)
- Cassandra Consumer → Cassandra (Inserts)

**Labels:**
- Topic names on Kafka arrows
- Data formats (JSON)
- Operation types (Hourly, Real-time)

**Color Scheme Suggestion:**
- Blue: Data sources (API, databases)
- Green: Processing components (producer, consumers)
- Orange: Streaming (Kafka)
- Purple: CDC/transformation

---

## 📝 Notes

- If you don't have data yet, run the system for a few hours first
- Some screenshots (like Kafka UI) are best taken when messages are flowing
- For the architecture diagram, you can also use:
  - PowerPoint/Google Slides
  - Excalidraw (https://excalidraw.com/)
  - Mermaid diagrams (markdown-based)
- Keep original, unedited versions of all screenshots as backup
- Consider creating a video walkthrough as supplementary material

---

## 🚀 Quick Start Checklist

For a quick screenshot session, do this in order:

1. Start all services: `docker-compose up -d`
2. Wait 2 minutes for initialization
3. Capture docker ps
4. Capture mongo-init logs
5. Register Debezium connector
6. Capture connector status
7. Wait 5 minutes for data to flow
8. Open Kafka UI → capture all three views
9. Capture producer, consumer, cassandra-consumer logs
10. Run queries → capture results
11. Capture docker stats
12. Create architecture diagram last

Total time: ~30 minutes

---

End of Screenshot Guide