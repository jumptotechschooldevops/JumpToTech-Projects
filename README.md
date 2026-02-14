# Task Manager API - DevOps Training Project

A Spring Boot REST API for task management, designed for DevOps training with externalized configuration support for multiple deployment environments.

## 🎯 Project Goals

This project demonstrates:
- **Externalized Configuration**: Same artifact, different configs for local, Docker, EC2, Kubernetes
- **Cloud-Native Patterns**: Health checks, metrics, distributed caching
- **DevOps Best Practices**: 12-factor app principles, environment parity

## 🏗️ Architecture

- **Framework**: Spring Boot 2.7.18 (Java 11)
- **Database**: H2 (local), PostgreSQL/MySQL (production)
- **Cache**: Redis
- **Monitoring**: Spring Actuator + Prometheus metrics

## 📋 Prerequisites

- Java 11 or higher
- Maven 3.6+
- Redis (optional for local, can disable caching)

## 🚀 Quick Start - Local Environment

### 1. Clone and Navigate
```bash
cd task-manager-api
```

### 2. Install Redis (Optional)

**On macOS:**
```bash
brew install redis
brew services start redis
```

**On Ubuntu/Debian:**
```bash
sudo apt-get install redis-server
sudo systemctl start redis
```

**On Windows:**
```bash
# Use Docker
docker run -d -p 6379:6379 redis:alpine
```

**Skip Redis:** Set `CACHE_ENABLED=false` to run without Redis

### 3. Run the Application

**Using Maven:**
```bash
mvn spring-boot:run
```

**Using Maven with custom profile:**
```bash
mvn spring-boot:run -Dspring-boot.run.profiles=local
```

**Build JAR and run:**
```bash
mvn clean package
java -jar target/task-manager-api-1.0.0.jar
```

### 4. Verify Application

The application will start on `http://localhost:8080`

**Health Check:**
```bash
curl http://localhost:8080/actuator/health
```

**Custom Health Endpoint:**
```bash
curl http://localhost:8080/api/v1/health
```

## 📊 H2 Database Console

Access H2 console at: `http://localhost:8080/api/h2-console`

- **JDBC URL**: `jdbc:h2:mem:taskdb`
- **Username**: `sa`
- **Password**: (leave empty)

## 🔌 API Endpoints

Base URL: `http://localhost:8080/api/v1`

### Task Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/tasks` | Get all tasks |
| GET | `/tasks/{id}` | Get task by ID |
| GET | `/tasks/status/{status}` | Get tasks by status |
| GET | `/tasks/search?title={title}` | Search tasks by title |
| GET | `/tasks/count` | Get task count |
| POST | `/tasks` | Create new task |
| PUT | `/tasks/{id}` | Update task |
| DELETE | `/tasks/{id}` | Delete task |

### Health & Monitoring

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Custom health check |
| GET | `/actuator/health` | Spring health check |
| GET | `/actuator/metrics` | Application metrics |
| GET | `/actuator/prometheus` | Prometheus metrics |

## 📝 Sample API Requests

### Create Task
```bash
curl -X POST http://localhost:8080/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Learn Kubernetes",
    "description": "Complete K8s fundamentals course",
    "status": "TODO",
    "priority": "HIGH"
  }'
```

### Get All Tasks
```bash
curl http://localhost:8080/api/v1/tasks
```

### Get Task by ID
```bash
curl http://localhost:8080/api/v1/tasks/1
```

### Update Task
```bash
curl -X PUT http://localhost:8080/api/v1/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Learn Kubernetes",
    "description": "Complete K8s fundamentals course",
    "status": "IN_PROGRESS",
    "priority": "HIGH"
  }'
```

### Delete Task
```bash
curl -X DELETE http://localhost:8080/api/v1/tasks/1
```

### Search Tasks
```bash
curl http://localhost:8080/api/v1/tasks/search?title=kubernetes
```

### Get Tasks by Status
```bash
curl http://localhost:8080/api/v1/tasks/status/TODO
```

## 🎛️ Configuration Management

### Environment Variables

All configuration is externalized via environment variables. See `.env.example` for all available variables.

**Key Configuration Points:**

1. **Database**: 
   - `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`
   
2. **Redis**: 
   - `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`
   
3. **Application**: 
   - `SERVER_PORT`, `SPRING_PROFILE`, `APP_ENVIRONMENT`

### Running with Different Configurations

**Override specific values:**
```bash
SERVER_PORT=9090 CACHE_ENABLED=false mvn spring-boot:run
```

**Using environment file:**
```bash
export $(cat .env.example | xargs)
mvn spring-boot:run
```

## 📦 Build Artifacts

**Build JAR:**
```bash
mvn clean package
```

**JAR location:**
```
target/task-manager-api-1.0.0.jar
```

**Run JAR with custom config:**
```bash
java -jar target/task-manager-api-1.0.0.jar \
  --server.port=9090 \
  --spring.profiles.active=local
```

## 🧪 Testing the Cache

### Test Redis Caching

1. **First call** (cache miss - fetches from DB):
```bash
curl http://localhost:8080/api/v1/tasks/1
# Check logs: "Fetching task from database with id: 1"
```

2. **Second call** (cache hit - served from Redis):
```bash
curl http://localhost:8080/api/v1/tasks/1
# No database log - served from cache
```

3. **Verify Redis:**
```bash
redis-cli
> KEYS *
> GET "tasks::1"
```

## 📊 Task Status & Priority Values

### Status
- `TODO`
- `IN_PROGRESS`
- `COMPLETED`
- `CANCELLED`

### Priority
- `LOW`
- `MEDIUM`
- `HIGH`
- `CRITICAL`

## 🔍 Monitoring

### Actuator Endpoints

```bash
# Application health
curl http://localhost:8080/actuator/health

# Detailed health (includes Redis, DB)
curl http://localhost:8080/actuator/health | jq

# Metrics
curl http://localhost:8080/actuator/metrics

# Specific metric
curl http://localhost:8080/actuator/metrics/http.server.requests

# Prometheus metrics (for Grafana)
curl http://localhost:8080/actuator/prometheus
```

## 🐛 Troubleshooting

### Redis Connection Issues

If Redis is not running:
```bash
# Check Redis status
redis-cli ping

# Start Redis
brew services start redis  # macOS
sudo systemctl start redis # Linux
```

**Run without Redis:**
```bash
CACHE_ENABLED=false mvn spring-boot:run
```

### Port Already in Use
```bash
# Change port
SERVER_PORT=9090 mvn spring-boot:run
```

### H2 Console Not Accessible
```bash
# Ensure H2 console is enabled
H2_CONSOLE_ENABLED=true mvn spring-boot:run
```

## 📁 Project Structure

```
task-manager-api/
├── src/
│   ├── main/
│   │   ├── java/com/devops/training/
│   │   │   ├── TaskManagerApplication.java
│   │   │   ├── config/
│   │   │   │   ├── RedisConfig.java
│   │   │   │   └── WebConfig.java
│   │   │   ├── controller/
│   │   │   │   ├── TaskController.java
│   │   │   │   └── HealthController.java
│   │   │   ├── service/
│   │   │   │   └── TaskService.java
│   │   │   ├── repository/
│   │   │   │   └── TaskRepository.java
│   │   │   ├── entity/
│   │   │   │   └── Task.java
│   │   │   ├── dto/
│   │   │   │   ├── TaskDTO.java
│   │   │   │   └── ApiResponse.java
│   │   │   └── exception/
│   │   │       ├── ResourceNotFoundException.java
│   │   │       └── GlobalExceptionHandler.java
│   │   └── resources/
│   │       ├── application.yml
│   │       └── application-local.yml
├── pom.xml
├── .env.example
└── README.md
```

## 🛣️ Your DevOps Journey

This same codebase will be deployed to:
1. ✅ **Local** (H2 + local Redis) ← Start here
2. 🐳 **Docker** (Single container)
3. 🐙 **Docker Compose** (Multi-container with PostgreSQL + Redis)
4. ⚓ **Kubernetes** (Orchestrated deployment with replicas)
5. 📦 **Helm** (Kubernetes package manager)
6. 🔄 **Jenkins** (CI/CD pipeline)
7. ☁️ **Terraform** (Infrastructure as Code)
8. 🔁 **ArgoCD** (GitOps continuous deployment)

Each stage teaches configuration management for that environment!

---

## 🐳 Docker & Kubernetes Deployment

### Docker Quick Start

```bash
# Build image
docker build -t task-manager-api:latest .

# Run container
docker run -d -p 8080:8080 \
  -e SPRING_PROFILE=local \
  -e CACHE_ENABLED=false \
  task-manager-api:latest
```

### Docker Compose

```bash
# Start all services (app + PostgreSQL + Redis)
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Kubernetes Deployment

```bash
# Using the deployment script (recommended)
./deploy.sh all

# Or manually
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml

# Access the application
kubectl port-forward svc/task-manager-service-internal 8080:8080 -n task-manager
```

For detailed deployment instructions, see:
- **[DOCKER_K8S_GUIDE.md](DOCKER_K8S_GUIDE.md)** - Complete deployment guide
- **[K8S_QUICK_REFERENCE.md](K8S_QUICK_REFERENCE.md)** - Kubectl cheat sheet
- **[DOCKER_K8S_EXERCISES.md](DOCKER_K8S_EXERCISES.md)** - Hands-on training exercises

---

## 📁 Project Structure (Updated)

```
task-manager-api/
├── src/                                    # Application source code
│   ├── main/
│   │   ├── java/com/devops/training/
│   │   │   ├── TaskManagerApplication.java
│   │   │   ├── config/
│   │   │   ├── controller/
│   │   │   ├── service/
│   │   │   ├── repository/
│   │   │   ├── entity/
│   │   │   ├── dto/
│   │   │   └── exception/
│   │   └── resources/
│   │       ├── application.yml            # Main configuration
│   │       ├── application-local.yml      # Local profile
│   │       ├── application-docker.yml     # Docker profile
│   │       └── application-k8s.yml        # Kubernetes profile
├── k8s/                                   # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── postgres-deployment.yaml
│   ├── redis-deployment.yaml
│   ├── app-deployment.yaml
│   ├── app-service.yaml
│   ├── ingress.yaml
│   └── hpa.yaml
├── Dockerfile                             # Multi-stage Docker build
├── .dockerignore                          # Docker build exclusions
├── docker-compose.yml                     # Multi-container setup
├── deploy.sh                              # Automated deployment script
├── pom.xml                                # Maven dependencies
├── README.md                              # This file
├── TRAINING_GUIDE.md                      # Learning exercises
├── DOCKER_K8S_GUIDE.md                    # Docker/K8s deployment guide
├── K8S_QUICK_REFERENCE.md                 # Kubectl cheat sheet
├── DOCKER_K8S_EXERCISES.md                # Hands-on exercises
└── QUICK_REFERENCE.md                     # Quick commands reference
```

---

---

**Happy Learning! 🚀**
