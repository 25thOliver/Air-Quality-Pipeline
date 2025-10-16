#!/bin/bash

echo "Waiting for MongoDB to start..."
sleep 10

echo "Initializing MongoDB replica set..."

mongosh --host mongo:27017 -u airflow -p airflow123 --authenticationDatabase admin --eval '
rs.initiate({
    "_id": "rs0",
    "members": [
        {
            "_id": 0,
            "host": "mongo:27017"
        }
    ]
})
'

echo "MongoDB replica set initialization complete."
