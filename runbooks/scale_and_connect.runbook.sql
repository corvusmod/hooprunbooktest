import os
import subprocess
import psycopg2
from psycopg2 import sql

# Constants
SERVICE_NAME = "postgres_database_jump_sidecar"
DATABASE = "postgres"
USER = "postgres"
PASSWORD = "postgres"
HOST = "localhost"
PORT = 9051

def get_service_replicas(service_name):
    """Get the current number of replicas for a Docker service."""
    try:
        output = subprocess.check_output(
            ["docker", "service", "inspect", "--format", "{{.Spec.Mode.Replicated.Replicas}}", service_name],
            stderr=subprocess.STDOUT
        )
        return int(output.strip())
    except subprocess.CalledProcessError as e:
        print(f"Error checking replicas for service {service_name}: {e.output.decode()}")
        return None

def scale_service(service_name, replicas):
    """Scale a Docker service to the specified number of replicas."""
    try:
        subprocess.check_call(["docker", "service", "scale", f"{service_name}={replicas}"])
        print(f"Scaled service {service_name} to {replicas} replicas.")
    except subprocess.CalledProcessError as e:
        print(f"Error scaling service {service_name}: {e.output.decode()}")

def connect_to_database():
    """Connect to the database and perform a simple query."""
    try:
        conn = psycopg2.connect(
            dbname=DATABASE,
            user=USER,
            password=PASSWORD,
            host=HOST,
            port=PORT
        )
        cursor = conn.cursor()
        cursor.execute(sql.SQL("SELECT version();"))
        version = cursor.fetchone()
        print(f"Connected to the database. Version: {version[0]}")
        conn.close()
    except Exception as e:
        print(f"Error connecting to the database: {e}")

def main():
    # Step 1: Check if the service is scaled to 1
    replicas = get_service_replicas(SERVICE_NAME)
    if replicas is None:
        print(f"Service {SERVICE_NAME} does not exist or an error occurred.")
        return
    if replicas != 1:
        print(f"Service {SERVICE_NAME} is not scaled to 1. Scaling it to 1...")
        scale_service(SERVICE_NAME, 1)
    else:
        print(f"Service {SERVICE_NAME} is already scaled to 1.")

    # Step 2: Connect to the database
    print("Connecting to the database...")
    connect_to_database()

    # Step 3: Scale the service back to 0
    print(f"Scaling service {SERVICE_NAME} back to 0...")
    scale_service(SERVICE_NAME, 0)

if __name__ == "__main__":
    main()
