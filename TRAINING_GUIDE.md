# DevOps Training Guide - Task Manager API

## 🎓 Learning Objectives

This guide will help you understand:
1. **Externalized Configuration** - How to manage config across environments
2. **Database Integration** - JPA/Hibernate with H2
3. **Distributed Caching** - Redis for performance
4. **REST API Design** - Best practices
5. **Observability** - Health checks, metrics, logging

---

## 📚 Module 1: Understanding the Project Structure

### What Each Component Does

#### 1. **Entity Layer** (`Task.java`)
- Represents database table structure
- Uses JPA annotations (`@Entity`, `@Table`, `@Column`)
- Contains business logic in `@PrePersist` and `@PreUpdate`
- **Key Learning**: ORM mapping, database design

#### 2. **Repository Layer** (`TaskRepository.java`)
- Interface extending `JpaRepository`
- Spring Data JPA auto-implements CRUD methods
- Custom query methods using naming conventions
- **Key Learning**: Data access patterns, Spring Data magic

#### 3. **Service Layer** (`TaskService.java`)
- Business logic and caching annotations
- `@Cacheable` - Reads from cache
- `@CachePut` - Updates cache
- `@CacheEvict` - Removes from cache
- **Key Learning**: Service design, caching strategies

#### 4. **Controller Layer** (`TaskController.java`)
- REST endpoints using `@RestController`
- Request validation with `@Valid`
- HTTP status codes and response wrapping
- **Key Learning**: RESTful API design

#### 5. **Configuration Layer** (`RedisConfig.java`, `WebConfig.java`)
- Bean definitions for Redis
- CORS configuration
- **Key Learning**: Spring configuration, dependency injection

---

## 🔧 Module 2: Configuration Management Deep Dive

### Why Externalized Configuration?

**Problem**: Hard-coded values make apps inflexible
```java
// ❌ BAD - Hard-coded
String dbUrl = "jdbc:h2:mem:taskdb";
```

**Solution**: Environment-driven configuration
```yaml
# ✅ GOOD - Externalized
datasource:
  url: ${DB_URL:jdbc:h2:mem:taskdb}
```

### Configuration Hierarchy

Spring Boot loads configuration in this order (later overrides earlier):
1. Default values in `application.yml`
2. Profile-specific files (`application-local.yml`)
3. Environment variables
4. Command-line arguments

### Practice Exercise 1: Change the Server Port

**Method 1: Environment Variable**
```bash
export SERVER_PORT=9090
mvn spring-boot:run
```

**Method 2: Command Line**
```bash
mvn spring-boot:run -Dspring-boot.run.arguments="--server.port=9090"
```

**Method 3: JAR execution**
```bash
java -jar target/task-manager-api-1.0.0.jar --server.port=9090
```

**Verify**: Application should start on port 9090

---

## 🗄️ Module 3: Database Configuration

### H2 Database (Local Development)

**Why H2 for local?**
- ✅ In-memory, fast startup
- ✅ No installation needed
- ✅ Built-in web console
- ✅ Perfect for testing

**Connection Details:**
```yaml
datasource:
  url: jdbc:h2:mem:taskdb  # In-memory database
  username: sa
  password: 
```

### Practice Exercise 2: Explore H2 Console

1. Start the application
2. Navigate to: `http://localhost:8080/api/h2-console`
3. Enter connection details:
   - JDBC URL: `jdbc:h2:mem:taskdb`
   - Username: `sa`
   - Password: (empty)
4. Run SQL query:
```sql
SELECT * FROM TASKS;
```

### Understanding JPA DDL Modes

```yaml
jpa:
  hibernate:
    ddl-auto: update  # Options: create, create-drop, update, validate, none
```

| Mode | Description | Use Case |
|------|-------------|----------|
| `create` | Drops and recreates tables | Testing (data loss) |
| `create-drop` | Creates on start, drops on shutdown | Integration tests |
| `update` | Updates schema without data loss | Development |
| `validate` | Only validates schema | Production |
| `none` | No schema management | Production with migrations |

### Practice Exercise 3: Switch DDL Mode

1. Edit `application.yml`:
```yaml
jpa:
  hibernate:
    ddl-auto: create-drop
```

2. Restart application
3. Create some tasks via API
4. Stop application
5. Start again - **Tasks are gone!** (create-drop deleted them)

**Learning**: Use `update` for development, `validate` for production

---

## 🚀 Module 4: Redis Caching

### Why Redis?

**Without Cache:**
```
Request → Controller → Service → Database → Response
Time: ~50-100ms
```

**With Cache:**
```
Request → Controller → Service → Redis → Response
Time: ~1-5ms (10-100x faster!)
```

### Caching Annotations Explained

#### @Cacheable
```java
@Cacheable(value = "tasks", key = "#id")
public TaskDTO getTaskById(Long id) {
    // Only called if NOT in cache
}
```
- **First call**: Fetches from DB, stores in Redis
- **Subsequent calls**: Returns from Redis directly

#### @CachePut
```java
@CachePut(value = "tasks", key = "#result.id")
public TaskDTO createTask(TaskDTO taskDTO) {
    // Always executes, updates cache
}
```
- **Always executes** the method
- **Updates cache** with new value

#### @CacheEvict
```java
@CacheEvict(value = "tasks", allEntries = true)
public void deleteTask(Long id) {
    // Clears cache entries
}
```
- **Removes entries** from cache
- Use `allEntries=true` to clear entire cache

### Practice Exercise 4: Observe Caching in Action

1. **Install Redis** (if not installed):
```bash
# macOS
brew install redis
brew services start redis

# Ubuntu
sudo apt install redis-server
sudo systemctl start redis

# Windows (use Docker)
docker run -d -p 6379:6379 redis:alpine
```

2. **Create a task**:
```bash
curl -X POST http://localhost:8080/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Cache","description":"Testing Redis","status":"TODO","priority":"HIGH"}'
```

3. **First GET (Cache MISS)**:
```bash
curl http://localhost:8080/api/v1/tasks/1
```
Check logs: `Fetching task from database with id: 1`

4. **Second GET (Cache HIT)**:
```bash
curl http://localhost:8080/api/v1/tasks/1
```
No database log! Served from cache.

5. **Verify in Redis**:
```bash
redis-cli
127.0.0.1:6379> KEYS *
1) "tasks::1"

127.0.0.1:6379> GET "tasks::1"
# Shows serialized JSON
```

6. **Update Task (Cache UPDATE)**:
```bash
curl -X PUT http://localhost:8080/api/v1/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated","description":"Cache Updated","status":"IN_PROGRESS","priority":"HIGH"}'
```

7. **GET again** - Cache has new value!

### Cache Configuration Tuning

```yaml
cache:
  redis:
    time-to-live: 600000  # 10 minutes in milliseconds
```

**Practice Exercise 5**: Change TTL to 60 seconds and observe expiration

---

## 🔍 Module 5: API Testing and Monitoring

### Using cURL for Testing

**Create Task**:
```bash
curl -X POST http://localhost:8080/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Learn Docker",
    "description": "Containerize this application",
    "status": "TODO",
    "priority": "HIGH"
  }'
```

**Get All Tasks**:
```bash
curl http://localhost:8080/api/v1/tasks | jq
```

**Filter by Status**:
```bash
curl http://localhost:8080/api/v1/tasks/status/TODO | jq
```

**Search**:
```bash
curl "http://localhost:8080/api/v1/tasks/search?title=docker" | jq
```

### Using Postman

1. Import `postman_collection.json`
2. Set environment variable: `base_url = http://localhost:8080/api`
3. Execute requests in order

### Actuator Endpoints

**Health Check**:
```bash
curl http://localhost:8080/actuator/health | jq
```

**Response**:
```json
{
  "status": "UP",
  "components": {
    "db": { "status": "UP" },
    "redis": { "status": "UP" },
    "diskSpace": { "status": "UP" }
  }
}
```

**Metrics**:
```bash
# All metrics
curl http://localhost:8080/actuator/metrics

# Specific metric
curl http://localhost:8080/actuator/metrics/http.server.requests | jq
```

**Prometheus Format** (for Grafana):
```bash
curl http://localhost:8080/actuator/prometheus
```

---

## 🧪 Module 6: Hands-On Exercises

### Exercise 1: Add New Field to Task

**Goal**: Add a `tags` field to tasks

1. **Update Entity**:
```java
@ElementCollection
@CollectionTable(name = "task_tags")
private List<String> tags;
```

2. **Update DTO**:
```java
private List<String> tags;
```

3. **Update mapping** in Service

4. **Test**:
```bash
curl -X POST http://localhost:8080/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Tagged Task",
    "tags": ["devops", "kubernetes"],
    "status": "TODO",
    "priority": "MEDIUM"
  }'
```

### Exercise 2: Create Custom Query

**Goal**: Find tasks created in last 24 hours

1. **Add to Repository**:
```java
@Query("SELECT t FROM Task t WHERE t.createdAt >= :since")
List<Task> findRecentTasks(@Param("since") LocalDateTime since);
```

2. **Add Service method**:
```java
public List<TaskDTO> getRecentTasks() {
    LocalDateTime yesterday = LocalDateTime.now().minusDays(1);
    return taskRepository.findRecentTasks(yesterday).stream()
            .map(this::mapToDTO)
            .collect(Collectors.toList());
}
```

3. **Add Controller endpoint**:
```java
@GetMapping("/recent")
public ResponseEntity<ApiResponse<List<TaskDTO>>> getRecentTasks() {
    return ResponseEntity.ok(
        ApiResponse.success(taskService.getRecentTasks())
    );
}
```

### Exercise 3: Environment-Specific Logging

**Goal**: Different log levels for different environments

1. **Create `application-dev.yml`**:
```yaml
logging:
  level:
    root: DEBUG
    com.devops.training: TRACE
```

2. **Run with dev profile**:
```bash
SPRING_PROFILE=dev mvn spring-boot:run
```

3. **Observe** verbose logs

---

## 🚧 Module 7: Common Issues and Troubleshooting

### Issue 1: Redis Connection Refused

**Error**:
```
Unable to connect to Redis; nested exception is io.lettuce.core.RedisConnectionException
```

**Solutions**:

1. **Check if Redis is running**:
```bash
redis-cli ping
# Expected: PONG
```

2. **Start Redis**:
```bash
# macOS
brew services start redis

# Linux
sudo systemctl start redis
```

3. **Run without Redis**:
```bash
CACHE_ENABLED=false mvn spring-boot:run
```

### Issue 2: Port Already in Use

**Error**:
```
Port 8080 was already in use
```

**Solution**:
```bash
# Use different port
SERVER_PORT=9090 mvn spring-boot:run

# Or kill process using port 8080
lsof -ti:8080 | xargs kill -9
```

### Issue 3: H2 Console Not Loading

**Check**:
```yaml
spring:
  h2:
    console:
      enabled: true  # Must be true
```

**Verify URL**: `http://localhost:8080/api/h2-console` (note the `/api` context path)

---

## 📝 Module 8: Configuration Best Practices

### 1. Never Hard-Code Secrets
```yaml
# ❌ BAD
datasource:
  password: supersecret123

# ✅ GOOD
datasource:
  password: ${DB_PASSWORD}
```

### 2. Use Meaningful Defaults
```yaml
# Good - defaults for local dev
server:
  port: ${SERVER_PORT:8080}  # Defaults to 8080 if not set
```

### 3. Document Required Variables
Use `.env.example`:
```bash
# Required
DB_URL=jdbc:postgresql://localhost:5432/taskdb
DB_USERNAME=postgres
DB_PASSWORD=changeme

# Optional (has defaults)
SERVER_PORT=8080
CACHE_TTL=600
```

### 4. Group Related Config
```yaml
app:
  cache:
    enabled: ${CACHE_ENABLED:true}
    ttl: ${CACHE_TTL:600}
  security:
    jwt-secret: ${JWT_SECRET}
    jwt-expiration: ${JWT_EXPIRATION:3600}
```

---

## 🎯 Module 9: Next Steps - Multi-Environment Setup

### Upcoming Configurations

| Environment | Database | Cache | Config Source |
|-------------|----------|-------|---------------|
| **Local** | H2 (in-memory) | Redis (local) | application-local.yml |
| **Docker** | PostgreSQL (container) | Redis (container) | docker-compose.yml |
| **EC2** | RDS PostgreSQL | ElastiCache | Environment variables |
| **K8s** | Cloud SQL | Redis cluster | ConfigMaps/Secrets |

### Configuration Files You'll Create

1. **Docker**:
   - `Dockerfile`
   - `docker-compose.yml`
   - `application-docker.yml`

2. **Kubernetes**:
   - `deployment.yml`
   - `service.yml`
   - `configmap.yml`
   - `secret.yml`

3. **Terraform**:
   - `main.tf` (EC2, RDS, Security Groups)
   - `variables.tf`
   - `outputs.tf`

4. **Helm**:
   - `Chart.yaml`
   - `values.yaml`
   - `templates/deployment.yaml`

---

## 📖 Additional Resources

### Spring Boot Documentation
- [Externalized Configuration](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.external-config)
- [Spring Data JPA](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/)
- [Spring Cache](https://docs.spring.io/spring-framework/docs/current/reference/html/integration.html#cache)

### Best Practices
- [12-Factor App](https://12factor.net/)
- [REST API Design](https://restfulapi.net/)
- [Redis Caching Patterns](https://redis.io/docs/manual/patterns/)

---

## ✅ Self-Assessment Checklist

After completing this module, you should be able to:

- [ ] Explain why externalized configuration is important
- [ ] Switch between different configuration profiles
- [ ] Modify database connection settings
- [ ] Enable/disable Redis caching
- [ ] Create and test REST endpoints
- [ ] Read and interpret application logs
- [ ] Use Actuator for health monitoring
- [ ] Understand JPA entity relationships
- [ ] Implement custom repository queries
- [ ] Configure environment-specific settings

---

**Ready for the next level? Let's containerize this application with Docker! 🐳**
