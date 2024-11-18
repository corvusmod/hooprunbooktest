#!/bin/bash

# Constants
SERVICE_NAME="postgres_database_jump_sidecar"
DATABASE="postgres"
USER="postgres"
PASSWORD="postgres"
HOST="pstest" #This is manager hostname
PORT=9051

# Function to get the number of replicas for a Docker service
get_service_replicas() {
    docker service ps "$SERVICE_NAME" --filter "desired-state=running" |grep $SERVICE_NAME | wc -l 2>/dev/null
}

# Function to scale a Docker service
scale_service() {
    local replicas=$1
    docker service scale "$SERVICE_NAME=$replicas" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Scaled service $SERVICE_NAME to $replicas replicas."
    else
        echo "Failed to scale service $SERVICE_NAME to $replicas replicas."
        exit 1
    fi
}

# Function to connect to the database
connect_to_database() {
    echo "Connecting using: -h $HOST -p $PORT -U $USER -d $DATABASE and password $PASSWORD"
    PGPASSWORD=$PASSWORD psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DATABASE" -c "SELECT version();" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Connected to the database successfully."
    else
        echo "Failed to connect to the database."
        ret_code=$?
        printf 'Error in execing gosu, %d\n' $ret_code
        exit 1
    fi
}

# Main logic
echo "Checking replicas for service $SERVICE_NAME..."
replicas=$(get_service_replicas)

if [ $? -ne 0 ]; then
    echo "Service $SERVICE_NAME does not exist or an error occurred."
    exit 1
fi

if [ "$replicas" -ne 1 ]; then
    echo "Service $SERVICE_NAME is not scaled to 1. Scaling it to 1..."
    scale_service 1
else
    echo "Service $SERVICE_NAME is already scaled to 1."
fi

echo "Connecting to the database..."
connect_to_database

echo "Scaling service $SERVICE_NAME back to 0..."
scale_service 0
