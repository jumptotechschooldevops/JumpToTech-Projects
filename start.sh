#!/bin/bash

# Task Manager API - Quick Start Script
# This script helps you run the application with different configurations

set -e

echo "========================================="
echo "  Task Manager API - DevOps Training"
echo "========================================="
echo ""

# Function to check if Redis is running
check_redis() {
    if command -v redis-cli &> /dev/null; then
        if redis-cli ping &> /dev/null; then
            echo "✓ Redis is running"
            return 0
        else
            echo "✗ Redis is not running"
            return 1
        fi
    else
        echo "✗ Redis CLI not found"
        return 1
    fi
}

# Function to start Redis if not running
start_redis() {
    echo "Attempting to start Redis..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew services start redis
            echo "✓ Redis started via Homebrew"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v systemctl &> /dev/null; then
            sudo systemctl start redis
            echo "✓ Redis started via systemctl"
        fi
    fi
    
    sleep 2
}

# Check Java version
echo "Checking prerequisites..."
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
    echo "✓ Java version: $JAVA_VERSION"
    if [ "$JAVA_VERSION" -lt 11 ]; then
        echo "✗ Java 11 or higher required"
        exit 1
    fi
else
    echo "✗ Java not found. Please install Java 11 or higher"
    exit 1
fi

# Check Maven
if command -v mvn &> /dev/null; then
    echo "✓ Maven is installed"
else
    echo "✗ Maven not found. Please install Maven 3.6+"
    exit 1
fi

echo ""

# Check Redis and offer to start
if ! check_redis; then
    echo ""
    read -p "Do you want to try starting Redis? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_redis
        if ! check_redis; then
            echo ""
            echo "Could not start Redis. You can either:"
            echo "  1. Install and start Redis manually"
            echo "  2. Run without cache (set CACHE_ENABLED=false)"
            echo ""
            read -p "Run without cache? (y/n) " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                export CACHE_ENABLED=false
                echo "Running with cache disabled..."
            else
                echo "Exiting. Please start Redis and try again."
                exit 1
            fi
        fi
    else
        export CACHE_ENABLED=false
        echo "Running with cache disabled..."
    fi
fi

echo ""
echo "========================================="
echo "  Starting Application"
echo "========================================="
echo ""
echo "Configuration:"
echo "  Profile: ${SPRING_PROFILE:-local}"
echo "  Port: ${SERVER_PORT:-8080}"
echo "  Cache: ${CACHE_ENABLED:-true}"
echo ""

# Clean and build
echo "Building application..."
mvn clean package -DskipTests

echo ""
echo "Starting application..."
echo ""

# Run the application
mvn spring-boot:run

echo ""
echo "Application stopped."
