import os
import json
import time
import logging
from datetime import datetime
from kafka import KafkaConsumer
from cassandra.cluster import Cluster
from cassandra.auth import PlainTextAuthProvider
from dotenv import load_dotenv

# Load envronment variables
load_dotenv()

# Configurations
kafka_broker = os.getenv("BOOTSTRAP_SERVERS")
cdc_topic = os.getenv("CDC_TOPIC")
cassandra_host = os.getenv("CASSANDRA_HOST")
cassandra_port = int(os.getenv("CASSANDRA_PORT"))
cassandra_keyspace = os.getenv("CASSANDRA_KEYSPACE")

# logging setup
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("CassandraConsumer")

# Connect to Cassandra cluster with retry logic and returns a session object for executing queries
def connect_cassandra():
    for attempt in range(10):
        try:
            logger.info(
                f"Attempting to connect to Cassandra at {cassandra_host}:{cassandra_port}"
            )
            cluster = Cluster([cassandra_host], port=cassandra_port)
            session = cluster.connect(cassandra_keyspace)
            logger.info(f"Connected to Cassandra keyspace: {cassandra_keyspace}")
            return session
        except Exception as e:
            logger.warning(
                f"Cassandra connection failed (attempt {attempt + 1}/10): {e}"
            )
            time.sleep(10)
    raise Exception("Failed to connect to Cassandra after 10 attempts")

# Connect to Kafka and subscribe to the CDC topic.
# auto_offset_reset='earliest' ensures we process all messages from the beginning.
def connect_kafka():
    for attempt in range(5):
        try:
            consumer = KafkaConsumer(
                cdc_topic,
                bootstrap_servers=[kafka_broker],
                auto_offset_reset='earliest',
                enable_auto_commit=True,
                group_id="cassandra_consumer_group",
                value_deserializer=lambda x: json.loads(x.decode("utf-8")),
            )
            logger.info(f"Connected to Kafka broker at {kafka_broker}")
            logger.info(f"Subscribed to CDC topic: {cdc_topic}")
            return consumer
        except Exception as e:
            logger.warning(f"Kafka connection failed (attempt {attempt + 1}/5): {e}")
            time.sleep(5)
    raise Exception("Failed to connect to Kafka after 5 attempts")

# Parse Debezium CDC meesage
def parse_cdc_message(message):
    try:
        # Extract the 'after' field which contains the new document
        after = message.get("after")
        if not after:
            return None
        
        # The 'after' field is a JSON string, so we need to parse it
        document = json.loads(after)
        return document
    except Exception as e:
        logger.error(f"Error parsing CDC message: {e}")
        return None
    

# Insert air quality reading into Cassandra  
def insert_to_cassandra(session, data):
    try:
        # Parse timestamp from string to datetime
        # Expected format: "2025-10-20T23:00"
        timestamp = datetime.fromisoformat(data.get("timestamp", data.get("time")))

        # Prepare CQL insert statement
        insert_query = """
        INSERT INTO air_quality_readings (
            city, timestamp, pm2_5, pm10, carbon_monoxide,
            nitrogen_dioxide, sulphur_dioxide, ozone, uv_index, inserted_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, toTimestamp(now()))
        """

        # Prepare the statement that Cassandra will optimize
        prepared = session.prepare(insert_query)

        # Execute with data
        session.execute(
            prepared,
            (
                data.get("city"),
                timestamp,
                float(data.get("pm2_5", 0)),
                float(data.get("pm10", 0)),
                float(data.get("carbon_monoxide", 0)),
                float(data.get("nitrogen_dioxide", 0)),
                float(data.get("sulphur_dioxide", 0)),
                float(data.get("ozone", 0)),
                float(data.get("uv_index", 0)),
            ),
        )
        logger.info(f"Inserted reading for {data.get('city')} at {timestamp}")
        return True
    
    except Exception as e:
        logger.error(f"Failed to insert into Cassandra: {e}")
        logger.error(f"Data: {data}")
        return False
    

if __name__ == "__main__":
    logger.info("Starting Cassandra Consumer...")

    # Connect to Cassandra and Kafka
    cassandra_session = connect_cassandra()
    kafka_consumer = connect_kafka()

    logger.info("Processing CDC messages...")

    # Main processing loop
    for message in kafka_consumer:
        try:
            # Get the CDC message value
            cdc_data = message.value

            # Parse the CDC message to extract the document
            document = parse_cdc_message(cdc_data)

            if document:
                # Insert into Cassandra
                insert_to_cassandra(cassandra_session, document)
            else:
                logger.warning("Skipped message: No valid document found")
        
        except Exception as e:
            logger.error(f"Error processing message: {e}")
            # Continue processing the next message instead of crashing
            continue