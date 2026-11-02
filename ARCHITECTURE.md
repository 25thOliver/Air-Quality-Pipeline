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
    P["ingestion/producer.py\nFetches last 24h, selects most recent\ncomplete reading per city"]
    K1["Kafka topic: air_quality_data\n1 partition, RF=1, auto-created"]
    C1["ingestion/consumer.py\nWrites raw JSON to MongoDB"]
    MDB["MongoDB: air_quality_db.air_quality_raw\nRaw document store, Replica Set rs0"]
    DBZ["Debezium MongoDB Connector\nTails MongoDB oplog via change streams"]
    K2["Kafka topic:\nmongo_cdc.air_quality_db.air_quality_raw"]
    CC["streaming/kafka_consumer.py\nParses CDC envelope, writes to Cassandra"]
    CASS["Cassandra: air_quality_analytics\nTime-series analytics store"]

    API -->|"HTTPS GET every 3600s"| P
    P -->|"JSON message"| K1
    K1 -->|"consumer group: air_quality_group"| C1
    C1 -->|"insert_one"| MDB
    MDB --> DBZ
    DBZ --> K2
    K2 -->|"consumer group: cassandra_consumer_group"| CC
    CC -->|"INSERT"| CASS
