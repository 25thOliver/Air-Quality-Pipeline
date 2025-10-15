import os
import json
import time
import logging
from kafka import KafkaConsumer
from pymongo import MongoClient
from dotenv import load_dotenv
from kafka.errors import NoBrokersAvailable

# Load environment variables
load_dotenv()

kafka_broker = os.getenv("BOOTSTRAP_SERVERS", "kafka:9092")
topic = os.getenv("KAFKA_TOPIC")
mongo_uri = os.getenv("MONGO_URI")
db_name = os.getenv("MONGO_DB")
collection_name = os.getenv("MONGO_COLLECTION")

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("AirQualityConsumer")


# Connect to MongoDB with retries
def connect_mongo():
    for attempt in range(5):
        try:
            client = MongoClient(mongo_uri)
            db = client[db_name]
            collection = db[collection_name]
            logger.info("Connected to MongoDB at %s", mongo_uri)
            return collection
        except Exception as e:
            logger.warning("MongoDB connection failed (%d/5): %s", attempt + 1, e)
            time.sleep(5)
    raise Exception("Failed to connect to MongoDB after multiple attempts")


 # Connect to Kafka and subscribe to the topic   
def create_consumer():
    for attempt in range(5):
        try:
            consumer = KafkaConsumer(
                topic,
                bootstrap_servers=[kafka_broker],
                auto_offset_reset="earliest",
                enable_auto_commit=True,
                group_id="air_quality_group",
                value_deserializer=lambda x: json.loads(x.decode("utf-8"))
            )
            logger.info("Connected to kafka broker at %s", kafka_broker)
            return consumer
        except NoBrokersAvailable:
            logger.warning("Kafka broker not available, retrying (%d/5)...", attempt + 1)
            time.sleep(5)
    raise Exception("Failed to connect to Kafka after multiple attempts")


if __name__ == "__main__":
    logger.info("Starting Air Quality Consumer...")
    collection = connect_mongo()
    consumer = create_consumer()

    for message in consumer:
        try:
            data = message.value
            collection.insert_one(data)
            logger.info("Inserted record for %s at %s", data["city"], data["timestamp"])
        except Exception as e:
            logger.error("Failed to insert record: %s", e)
