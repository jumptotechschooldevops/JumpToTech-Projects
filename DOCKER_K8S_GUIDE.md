# Docker and Kubernetes Deployment Guide

Complete guide for deploying Task Manager API using Docker and Kubernetes.

---

## 📋 Table of Contents

1. [Docker Deployment](#docker-deployment)
2. [Docker Compose Deployment](#docker-compose-deployment)
3. [Kubernetes Deployment](#kubernetes-deployment)
4. [Configuration Management](#configuration-management)
5. [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)

---

## 🐳 Docker Deployment

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+ (for multi-container setup)

### Build Docker Image

```bash
# Build the image
docker build -t task-manager-api:latest .

# Verify the image
docker images | grep task-manager-api

# Check image size
docker images task-manager-api:latest
```

### Run Single Container (H2 Database)

```bash
# Run with H2 in-memory database
docker run -d \
  --name task-manager \
  -p 8080:8080 \
  -e SPRING_PROFILE=local \
  -e DB_URL=jdbc:h2:mem:taskdb \
  -e CACHE_ENABLED=false \
  task-manager-api:latest

# Check logs
docker logs -f task-manager

# Test the application
curl http://localhost:8080/actuator/health

# Stop and remove
docker stop task-manager
docker rm task-manager
```

### Advanced Docker Run with Environment Variables

```bash
docker run -d \
  --name task-manager \
  -p 8080:8080 \
  -e SPRING_PROFILE=docker \
  -e DB_URL=jdbc:postgresql://your-db-host:5432/taskdb \
  -e DB_USERNAME=taskuser \
  -e DB_PASSWORD=taskpass123 \
  -e REDIS_HOST=your-redis-host \
  -e REDIS_PORT=6379 \
  -e LOG_LEVEL_APP=DEBUG \
  task-manager-api:latest
```

### Docker Image Details

**Multi-stage Build:**
- **Stage 1 (Builder)**: Maven build with dependencies cached
- **Stage 2 (Runtime)**: Minimal JRE image with only the JAR

**Security Features:**
- Non-root user (`appuser`)
- Minimal base image (`openjdk:11-jre-slim`)
- Health check included

**Image Optimization:**
- Layer caching for dependencies
- `.dockerignore` to reduce context size
- Only JAR file in final image

---

## 🐙 Docker Compose Deployment

### Quick Start

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps

# Stop all services
docker-compose down

# Stop and remove volumes (clean slate)
docker-compose down -v
```

### Services Included

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| **postgres** | postgres:15-alpine | 5432 | PostgreSQL database |
| **redis** | redis:7-alpine | 6379 | Redis cache |
| **app** | task-manager-api:latest | 8080 | Application |

### Access Application

```bash
# Health check
curl http://localhost:8080/actuator/health

# API endpoint
curl http://localhost:8080/api/v1/tasks

# Create a task
curl -X POST http://localhost:8080/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Docker Task",
    "description": "Running in Docker Compose",
    "status": "TODO",
    "priority": "HIGH"
  }'
```

### Connect to Services

```bash
# PostgreSQL
docker exec -it task-manager-db psql -U taskuser -d taskdb

# Redis
docker exec -it task-manager-redis redis-cli

# Application logs
docker logs -f task-manager-api
```

### Customize Configuration

Edit `docker-compose.yml` to change:
- Database credentials
- Redis password
- Application environment variables
- Resource limits

---

## ⚓ Kubernetes Deployment

### Prerequisites

**Required:**
- Kubernetes cluster (Minikube, kind, EKS, GKE, AKS, etc.)
- kubectl configured
- Docker (for building images)

**Optional:**
- Minikube (for local testing)
- Helm (for advanced deployments)

### Setup Local Kubernetes (Minikube)

```bash
# Install Minikube (if not installed)
# macOS
brew install minikube

# Start Minikube
minikube start --cpus=4 --memory=8192

# Verify cluster
kubectl cluster-info
kubectl get nodes

# Enable Ingress (optional)
minikube addons enable ingress

# Enable metrics server (for HPA)
minikube addons enable metrics-server
```

### Build and Load Image

```bash
# Build the Docker image
docker build -t task-manager-api:latest .

# Load image to Minikube
minikube image load task-manager-api:latest

# Verify image in Minikube
minikube image ls | grep task-manager
```

### Deploy Using Script (Recommended)

```bash
# Build and deploy everything
./deploy.sh all

# Or step by step
./deploy.sh build      # Build image
./deploy.sh k8s        # Deploy to K8s
```

### Manual Deployment Steps

#### 1. Create Namespace

```bash
kubectl apply -f k8s/namespace.yaml
kubectl get namespaces
```

#### 2. Apply ConfigMap and Secret

```bash
# ConfigMap (non-sensitive config)
kubectl apply -f k8s/configmap.yaml

# Secret (sensitive data)
kubectl apply -f k8s/secret.yaml

# Verify
kubectl get configmap -n task-manager
kubectl get secret -n task-manager
```

#### 3. Deploy PostgreSQL

```bash
kubectl apply -f k8s/postgres-deployment.yaml

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n task-manager --timeout=120s

# Check status
kubectl get pods -n task-manager -l app=postgres
kubectl logs -l app=postgres -n task-manager
```

#### 4. Deploy Redis

```bash
kubectl apply -f k8s/redis-deployment.yaml

# Wait for Redis to be ready
kubectl wait --for=condition=ready pod -l app=redis -n task-manager --timeout=120s

# Verify
kubectl get pods -n task-manager -l app=redis
```

#### 5. Deploy Application

```bash
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml

# Wait for application
kubectl wait --for=condition=ready pod -l app=task-manager-api -n task-manager --timeout=180s

# Check deployment
kubectl get deployments -n task-manager
kubectl get pods -n task-manager
kubectl get services -n task-manager
```

#### 6. Deploy HPA (Optional)

```bash
kubectl apply -f k8s/hpa.yaml

# Check HPA status
kubectl get hpa -n task-manager
kubectl describe hpa task-manager-hpa -n task-manager
```

### Access the Application

#### Option 1: NodePort (Local/Minikube)

```bash
# Get Minikube IP
minikube ip

# Access via NodePort (30080)
curl http://$(minikube ip):30080/api/v1/health

# Or use Minikube service
minikube service task-manager-service -n task-manager
```

#### Option 2: Port Forward

```bash
# Forward local port to service
kubectl port-forward svc/task-manager-service-internal 8080:8080 -n task-manager

# Access locally
curl http://localhost:8080/api/v1/tasks
```

#### Option 3: LoadBalancer (Cloud Providers)

```bash
# Get external IP (may take a few minutes)
kubectl get svc task-manager-service -n task-manager

# Access via external IP
curl http://<EXTERNAL-IP>/api/v1/health
```

#### Option 4: Ingress

```bash
# Apply Ingress
kubectl apply -f k8s/ingress.yaml

# For Minikube, get Ingress URL
minikube service list

# Add to /etc/hosts
echo "$(minikube ip) task-manager.local" | sudo tee -a /etc/hosts

# Access
curl http://task-manager.local/api/v1/health
```

### Verify Deployment

```bash
# Check all resources
kubectl get all -n task-manager

# Check pod status
kubectl get pods -n task-manager -o wide

# Check events
kubectl get events -n task-manager --sort-by='.lastTimestamp'

# Describe deployment
kubectl describe deployment task-manager-api -n task-manager
```

---

## 🔧 Configuration Management

### Environment-Specific Configuration

| Environment | Config File | Database | Cache |
|-------------|-------------|----------|-------|
| **Local** | application-local.yml | H2 (in-memory) | Redis (local) |
| **Docker** | application-docker.yml | PostgreSQL | Redis |
| **Kubernetes** | application-k8s.yml | PostgreSQL | Redis |

### ConfigMap vs Secret

**ConfigMap** (non-sensitive):
- Database URL
- Redis host/port
- Feature flags
- Log levels

**Secret** (sensitive):
- Database password
- Redis password
- API keys
- Certificates

### Update Configuration

#### Update ConfigMap

```bash
# Edit ConfigMap
kubectl edit configmap task-manager-config -n task-manager

# Or apply updated file
kubectl apply -f k8s/configmap.yaml

# Restart pods to pick up changes
kubectl rollout restart deployment/task-manager-api -n task-manager
```

#### Update Secret

```bash
# Create new secret value
echo -n 'new-password' | base64

# Edit Secret
kubectl edit secret task-manager-secret -n task-manager

# Restart deployment
kubectl rollout restart deployment/task-manager-api -n task-manager
```

---

## 📊 Monitoring and Troubleshooting

### View Logs

```bash
# All application logs
kubectl logs -f -l app=task-manager-api -n task-manager

# Specific pod
kubectl logs -f <pod-name> -n task-manager

# Previous pod (if crashed)
kubectl logs --previous <pod-name> -n task-manager

# All containers in pod
kubectl logs -f <pod-name> --all-containers -n task-manager
```

### Health Checks

```bash
# Via kubectl port-forward
kubectl port-forward svc/task-manager-service-internal 8080:8080 -n task-manager

# In another terminal
curl http://localhost:8080/actuator/health | jq

# Check specific probe endpoints
curl http://localhost:8080/actuator/health/liveness
curl http://localhost:8080/actuator/health/readiness
```

### Debugging Pods

```bash
# Exec into pod
kubectl exec -it <pod-name> -n task-manager -- /bin/sh

# Describe pod (see events)
kubectl describe pod <pod-name> -n task-manager

# Check resource usage
kubectl top pods -n task-manager

# Check node resources
kubectl top nodes
```

### Database Debugging

```bash
# Connect to PostgreSQL
kubectl exec -it <postgres-pod> -n task-manager -- psql -U taskuser -d taskdb

# Sample queries
SELECT * FROM tasks;
SELECT COUNT(*) FROM tasks;
\dt  # List tables
\q   # Quit
```

### Redis Debugging

```bash
# Connect to Redis
kubectl exec -it <redis-pod> -n task-manager -- redis-cli

# Redis commands
KEYS *
GET "tasks::1"
DBSIZE
INFO
FLUSHALL  # Clear all cache (use carefully!)
```

### Common Issues and Solutions

#### Issue: Pods not starting

```bash
# Check pod status
kubectl get pods -n task-manager

# Check events
kubectl describe pod <pod-name> -n task-manager

# Common causes:
# - Image not found: Load image to Minikube
# - Init containers failing: Check postgres/redis readiness
# - Resource limits: Adjust requests/limits
```

#### Issue: Application not healthy

```bash
# Check logs
kubectl logs -f -l app=task-manager-api -n task-manager

# Common causes:
# - Database connection: Check postgres service
# - Redis connection: Check redis service
# - Config errors: Verify ConfigMap/Secret
```

#### Issue: Cannot access service

```bash
# Check service
kubectl get svc -n task-manager

# Test from inside cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n task-manager -- \
  curl task-manager-service-internal:8080/actuator/health

# Check Ingress (if using)
kubectl get ingress -n task-manager
kubectl describe ingress task-manager-ingress -n task-manager
```

### Scaling

```bash
# Manual scaling
kubectl scale deployment task-manager-api --replicas=5 -n task-manager

# Check HPA
kubectl get hpa -n task-manager

# Generate load (test autoscaling)
kubectl run -it --rm load-generator --image=busybox --restart=Never -- /bin/sh -c \
  "while true; do wget -q -O- http://task-manager-service-internal:8080/api/v1/tasks; done"
```

### Cleanup

```bash
# Delete specific resources
kubectl delete -f k8s/app-deployment.yaml
kubectl delete -f k8s/app-service.yaml

# Delete entire namespace (everything)
kubectl delete namespace task-manager

# Or use script
./deploy.sh cleanup

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete
```

---

## 🎓 Learning Exercises

### Exercise 1: Change Database Configuration

1. Edit `k8s/configmap.yaml` - change `DDL_AUTO` to `validate`
2. Apply: `kubectl apply -f k8s/configmap.yaml`
3. Restart: `kubectl rollout restart deployment/task-manager-api -n task-manager`
4. Observe behavior

### Exercise 2: Scale Application

1. Scale to 5 replicas: `kubectl scale deployment task-manager-api --replicas=5 -n task-manager`
2. Watch pods: `kubectl get pods -n task-manager -w`
3. Create tasks and observe load distribution

### Exercise 3: Simulate Pod Failure

1. Delete a pod: `kubectl delete pod <pod-name> -n task-manager`
2. Watch Kubernetes recreate it automatically
3. Verify application still works

### Exercise 4: Update Image

1. Make a code change
2. Build new image: `docker build -t task-manager-api:v2 .`
3. Load to Minikube: `minikube image load task-manager-api:v2`
4. Update deployment image
5. Rolling update will occur automatically

---

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Minikube Guide](https://minikube.sigs.k8s.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

**Next Steps:**
- Helm Charts for easier deployment
- CI/CD with Jenkins
- ArgoCD for GitOps
- Terraform for infrastructure

