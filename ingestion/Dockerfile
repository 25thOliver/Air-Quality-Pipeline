# Base image
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the ingestion folder
COPY ingestion ./ingestion

# Copy environment variables
COPY .env .

# Command to run the producer
CMD ["python", "ingestion/producer.py"]
