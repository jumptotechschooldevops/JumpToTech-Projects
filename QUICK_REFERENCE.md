# Task Manager API - Quick Reference Card

## 🚀 Getting Started

### Prerequisites
```bash
# Check Java version (need 11+)
java -version

# Check Maven
mvn -version

# Install Redis (optional)
brew install redis          # macOS
sudo apt install redis      # Linux
```

### Run Application
```bash
# Extract the archive
tar -xzf task-manager-api.tar.gz
cd task-manager-api

# Method 1: Using script
./start.sh

# Method 2: Using Maven
mvn spring-boot:run

# Method 3: Build and run JAR
mvn clean package
java -jar target/task-manager-api-1.0.0.jar
```

## 🔧 Configuration Cheat Sheet

### Change Server Port
```bash
SERVER_PORT=9090 mvn spring-boot:run
```

### Disable Redis Cache
```bash
CACHE_ENABLED=false mvn spring-boot:run
```

### Change Log Level
```bash
LOG_LEVEL_APP=TRACE mvn spring-boot:run
```

### Multiple Variables
```bash
SERVER_PORT=9090 CACHE_ENABLED=false mvn spring-boot:run
```

## 📡 API Endpoints Quick Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/tasks` | Get all tasks |
| GET | `/api/v1/tasks/{id}` | Get task by ID |
| GET | `/api/v1/tasks/status/{status}` | Filter by status |
| GET | `/api/v1/tasks/search?title=X` | Search by title |
| POST | `/api/v1/tasks` | Create new task |
| PUT | `/api/v1/tasks/{id}` | Update task |
| DELETE | `/api/v1/tasks/{id}` | Delete task |
| GET | `/api/v1/health` | Health check |
| GET | `/actuator/health` | Detailed health |

## 🧪 Quick Test Commands

### Create a Task
```bash
curl -X POST http://localhost:8080/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"My First Task","description":"Testing API","status":"TODO","priority":"HIGH"}'
```

### Get All Tasks
```bash
curl http://localhost:8080/api/v1/tasks | jq
```

### Update Task (change status to IN_PROGRESS)
```bash
curl -X PUT http://localhost:8080/api/v1/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{"title":"My First Task","description":"Testing API","status":"IN_PROGRESS","priority":"HIGH"}'
```

### Delete Task
```bash
curl -X DELETE http://localhost:8080/api/v1/tasks/1
```

## 🗄️ H2 Database Console

**URL**: http://localhost:8080/api/h2-console

**Settings**:
- JDBC URL: `jdbc:h2:mem:taskdb`
- Username: `sa`
- Password: (leave empty)

**Useful SQL**:
```sql
-- See all tasks
SELECT * FROM TASKS;

-- Count tasks by status
SELECT status, COUNT(*) FROM TASKS GROUP BY status;

-- Tasks created today
SELECT * FROM TASKS WHERE created_at >= CURRENT_DATE;
```

## 🔍 Redis Commands

```bash
# Connect to Redis
redis-cli

# See all keys
KEYS *

# Get specific task from cache
GET "tasks::1"

# See all task caches
KEYS tasks*

# Clear all cache
FLUSHALL

# Exit Redis CLI
exit
```

## 📊 Monitoring

### Health Check
```bash
curl http://localhost:8080/actuator/health | jq
```

### Metrics
```bash
# All available metrics
curl http://localhost:8080/actuator/metrics

# HTTP request metrics
curl http://localhost:8080/actuator/metrics/http.server.requests | jq

# JVM memory
curl http://localhost:8080/actuator/metrics/jvm.memory.used | jq
```

## 🐛 Troubleshooting

### Issue: Port 8080 already in use
```bash
# Solution 1: Use different port
SERVER_PORT=9090 mvn spring-boot:run

# Solution 2: Kill process on port 8080
lsof -ti:8080 | xargs kill -9
```

### Issue: Redis connection failed
```bash
# Check if Redis is running
redis-cli ping

# Start Redis
brew services start redis      # macOS
sudo systemctl start redis     # Linux

# Or run without cache
CACHE_ENABLED=false mvn spring-boot:run
```

### Issue: Build failed
```bash
# Clean and rebuild
mvn clean install

# Skip tests if they fail
mvn clean package -DskipTests
```

## 📝 Valid Values

### Task Status
- `TODO`
- `IN_PROGRESS`
- `COMPLETED`
- `CANCELLED`

### Task Priority
- `LOW`
- `MEDIUM`
- `HIGH`
- `CRITICAL`

## 📁 Important Files

| File | Purpose |
|------|---------|
| `pom.xml` | Maven dependencies |
| `application.yml` | Main configuration |
| `application-local.yml` | Local profile config |
| `.env.example` | Environment variables reference |
| `README.md` | Full documentation |
| `TRAINING_GUIDE.md` | Learning exercises |

## 🎓 Next Steps

1. ✅ **Local Setup** - You are here!
2. 🐳 **Docker** - Containerize the app
3. 🐙 **Docker Compose** - Multi-container setup
4. 🔄 **Jenkins** - CI/CD pipeline
5. ☁️ **Terraform** - Infrastructure as Code
6. ⚓ **Kubernetes** - Orchestration
7. 📦 **Helm** - K8s package manager
8. 🔁 **ArgoCD** - GitOps

## 💡 Pro Tips

1. **Always check logs** when something doesn't work
2. **Use H2 console** to verify database state
3. **Test with curl** before using UI/Postman
4. **Read error messages** - they're usually helpful!
5. **Start Redis first** if using cache
6. **Use jq** to format JSON: `curl ... | jq`

---

**Need help?** Check:
- `README.md` - Full documentation
- `TRAINING_GUIDE.md` - Detailed learning exercises
- Application logs - `logs/task-manager.log`
