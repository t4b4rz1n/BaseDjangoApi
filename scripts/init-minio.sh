#!/bin/bash

# Wait for MinIO to start
echo "Waiting for MinIO to start..."
sleep 5

# Create bucket if it doesn't exist
mc config host add myminio http://minio:9000 minio minio123
mc mb --ignore-existing myminio/samtract

echo "MinIO initialized successfully!"
