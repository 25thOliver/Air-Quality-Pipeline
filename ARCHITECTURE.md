# Architecture

## System Overview

This pipeline collects real-time air quality measurements for Nairobi and Mombasa from the
[Open-Meteo Air Quality API](https://open-meteo.com/en/docs/air-quality-api) and routes
them through a streaming architecture into two storage layers optimised for different access
patterns.

## Data Flow

```mermaid
flowchart TD
    API["Open-Meteo Air Quality API\n(free, no authentication)"]
    P["ingestion/producer.py\nFetches last 24 h, selects most\nrecent complete reading per city"]
    K1["Kafka topic: air_quality_data\n1 partition · RF 1 · auto-created"]
    C1["ingestion/consumer.py\nWrites raw JSON to MongoDB"]
    MDB["MongoDB: air_quality_db.air_quality_raw\nRaw document store · Replica Set rs0"]
    DBZ["Debezium MongoDB Connector\nTails MongoDB oplog via change streams"]
    K2["Kafka topic: mongo_cdc.air_quality_db.air_quality_raw\nCDC change events"]
    CC["streaming/kafka_consumer.py\nParses CDC envelope · writes to Cassandra"]
    CASS["Cassandra: air_quality_analytics\nTime-series analytics store"]

    API -->|"HTTPS GET every 3 600 s"| P
    P -->|"JSON message"| K1
    K1 -->|"consumer group: air_quality_group"| C1
    C1 -->|"insert_one"| MDB
    MDB --> DBZ
    DBZ --> K2
    K2 -->|"consumer group: cassandra_consumer_group"| CC
    CC -->|"INSERT"| CASS


---

### 5. Code Explanation

A few things worth understanding as you write this:

- **The Mermaid diagram** reflects what the code *actually does*, not what you wish it did. The "Known Limitations" section is intentional — it is honest, and it signals to anyone reading the repo that you are aware of the issues and have a plan. This is a mark of engineering maturity.
- **The data model section** shows the shape of data at each stage. This is important because the CDC envelope wraps the original document in a Debezium envelope — something that trips up many engineers.
- **Technology Choices** is the start of architectural reasoning. A hiring manager reading this knows you can explain *why* you used Kafka, not just *that* you used it.

---

### 6. Verification

After creating the file:

```bash
# Confirm file exists
ls -la ARCHITECTURE.md

# Confirm the Mermaid block is syntactically recognisable
grep -c "mermaid" ARCHITECTURE.md
# Expected: 1

# Preview it on GitHub by pushing to your repo
# GitHub will render the Mermaid diagram automatically
