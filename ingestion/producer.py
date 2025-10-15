import os
import json
import time
import logging
import requests
from dotenv import load_dotenv
from kafka import KafkaProducer
from kafka.errors import NoBrokersAvailable

# Load environment variables
load_dotenv()

broker = os.environ.get("BOOTSTRAP_SERVERS", "kafka:9092")
topic = os.environ.get("KAFKA_TOPIC")
api_url = os.environ.get("OPEN_METEO_URL")
interval = int(os.environ.get("FETCH_INTERVAL", 3600))

# City coordinates
CITIES = {
    "Nairobi": {
        "lat": float(os.getenv("NAIROBI_LAT", -1.286389)),
        "lon": float(os.getenv("NAIROBI_LON", 36.817223)),
    },
    "Mombasa": {
        "lat": float(os.getenv("MOMBASA_LAT", -4.0435)),
        "lon": float(os.getenv("MOMBASA_LON", 39.6682)),
    },
}

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger("AirQualityProducer")

# Kafka producer setup with retry
def create_producer():
    for attempt in range(5):
        try:
            producer = KafkaProducer(
                bootstrap_servers=[broker],
                value_serializer=lambda v: json.dumps(v).encode("utf-8"),
                linger_ms=1000,
            )
            logger.info("Connected to Kafka broker at %s", broker)
            return producer
        except NoBrokersAvailable:
            logger.warning("Kafka broker not available, retrying (%d/5)...", attempt + 1)
            time.sleep(5)
    raise Exception("Failed to connect to Kafka after multiple attempts")

# Fetch current air quality data for a given city
def fetch_air_quality(city, lat, lon):
    params = {
        "latitude": lat,
        "longitude": lon,
        "hourly": "pm2_5,pm10,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,uv_index"
    }
    try:
        response = requests.get(api_url, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()

        latest = {k: v[-1] for k, v in data["hourly"].items()}
        latest["timestamp"] = data["hourly"]["time"][-1]
        latest["city"] = city
        return latest
    except Exception as e:
        print(f"Error fetching data for {city}: {e}")
        return None
    
# Send air quality data to Kafka topic
def publish_to_kafka(data):
    if data:
        try:
            producer.send(topic, value=data)
            producer.flush()
            logger.info("Published data for %s at %s", data["city"], data["timestamp"])
        except Exception as e:
            logger.error("Failed to publish data for %s: %s", data.get("city"), e)

if __name__ == "__main__":
    logger.info("Starting air quality producer...")
    logger.info("Producing to topic '%s' every %d seconds", topic, interval)

    producer = create_producer()

    while True:
        for city, coords in CITIES.items():
            record = fetch_air_quality(city, coords['lat'], coords['lon'])
            publish_to_kafka(record)

        logger.info("waiting for the next cycle...\n")
        time.sleep(interval)