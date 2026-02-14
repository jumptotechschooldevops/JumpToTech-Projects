# Docker & Kubernetes Training Exercises

Hands-on exercises for learning containerization and orchestration with the Task Manager API.

---

## 🎯 Module 1: Docker Fundamentals

### Exercise 1.1: Build and Run Your First Container

**Objective**: Build the Docker image and run a container

```bash
# 1. Navigate to project directory
cd task-manager-api

# 2. Build the image
docker build -t task-manager-api:latest .

# 3. Verify the image
docker images | grep task-manager-api

# 4. Run the container
docker run -d \
  --name my-first-container \
  -p 8080:8080 \
  -e SPRING_PROFILE=local \
  -e CACHE_ENABLED=false \
  task-manager-api:latest

# 5. Check if it's running
docker ps

# 6. View logs
docker logs -f my-first-container

# 7. Test the API
curl http://localhost:8080/actuator/health

# 8. Cleanup
docker stop my-first-container
docker rm my-first-container
```

**Questions to Answer:**
- What is the size of your Docker image?
- How long did the build take?
- How many layers does the image have? (Hint: `docker history task-manager-api:latest`)

---

### Exercise 1.2: Understand Docker Layers

**Objective**: Explore multi-stage builds and layer caching

```bash
# 1. Time your first build
time docker build -t task-manager-api:v1 .

# 2. Make a small code change (e.g., edit README.md)
echo "# Test change" >> README.md

# 3. Rebuild and time it
time docker build -t task-manager-api:v2 .

# 4. Compare build times
```

**Challenge:**
- Why is the second build faster?
- Which layers are cached?
- What happens if you modify `pom.xml`?

**Deep Dive:**
```bash
# Inspect image layers
docker history task-manager-api:latest

# Build without cache
docker build --no-cache -t task-manager-api:no-cache .
```

---

### Exercise 1.3: Environment Variables Deep Dive

**Objective**: Learn configuration management in Docker

```bash
# Run with different configurations

# 1. High logging level
docker run -d --name app-debug \
  -p 8081:8080 \
  -e LOG_LEVEL_APP=TRACE \
  -e CACHE_ENABLED=false \
  task-manager-api:latest

# 2. Different port
docker run -d --name app-custom-port \
  -p 9090:9090 \
  -e SERVER_PORT=9090 \
  -e CACHE_ENABLED=false \
  task-manager-api:latest

# 3. View environment inside container
docker exec app-debug env | grep -E '(SPRING|LOG|SERVER)'
```

**Assignment:**
Create a container that:
- Runs on port 8888
- Has DEBUG logging for the app
- Disables cache
- Runs with a custom app name

---

### Exercise 1.4: Container Debugging

**Objective**: Learn to debug containerized applications

```bash
# 1. Run a container
docker run -d --name debug-exercise \
  -p 8080:8080 \
  -e CACHE_ENABLED=false \
  task-manager-api:latest

# 2. Check if it's healthy
docker ps
docker inspect debug-exercise | grep -i health

# 3. View logs
docker logs debug-exercise

# 4. Exec into the container
docker exec -it debug-exercise /bin/sh

# Inside container:
ps aux              # See processes
ls -la /app         # Check files
env | grep SPRING   # Check environment
curl localhost:8080/actuator/health
exit

# 5. Check resource usage
docker stats debug-exercise

# 6. Cleanup
docker stop debug-exercise
docker rm debug-exercise
```

---

## 🐙 Module 2: Docker Compose

### Exercise 2.1: Multi-Container Application

**Objective**: Run the complete stack with Docker Compose

```bash
# 1. Start all services
docker-compose up -d

# 2. Check status
docker-compose ps

# 3. View logs
docker-compose logs -f app

# 4. Test the application
curl http://localhost:8080/api/v1/tasks

# 5. Create a task
curl -X POST http://localhost:8080/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Docker Compose Task",
    "description": "Created in multi-container setup",
    "status": "TODO",
    "priority": "HIGH"
  }'

# 6. Check PostgreSQL
docker exec -it task-manager-db psql -U taskuser -d taskdb -c "SELECT * FROM tasks;"

# 7. Check Redis cache
docker exec -it task-manager-redis redis-cli KEYS "*"

# 8. Cleanup
docker-compose down
```

**Questions:**
- How do containers communicate with each other?
- What happens when you run `docker-compose down -v`?
- Where is the database data stored?

---

### Exercise 2.2: Service Dependencies

**Objective**: Understand service dependencies and health checks

```bash
# 1. Edit docker-compose.yml - remove depends_on from app service

# 2. Start services
docker-compose up -d

# 3. Watch what happens
docker-compose logs -f

# 4. Restore depends_on

# 5. Add healthcheck intervals:
# Change postgres healthcheck interval to 5s

# 6. Restart and observe
docker-compose down
docker-compose up -d
docker-compose logs -f
```

**Challenge:**
What happens if:
- PostgreSQL starts but isn't ready?
- Redis fails to start?
- The app starts before the database?

---

### Exercise 2.3: Scaling Services

**Objective**: Scale application horizontally

```bash
# 1. Scale application to 3 instances
docker-compose up -d --scale app=3

# 2. Check running containers
docker-compose ps

# 3. Send requests and observe load distribution
for i in {1..10}; do
  curl http://localhost:8080/api/v1/tasks
  sleep 1
done

# 4. Check logs from all instances
docker-compose logs -f app

# 5. Scale back down
docker-compose up -d --scale app=1
```

**Note**: You'll need to remove the `container_name` from docker-compose.yml for scaling to work.

---

## ⚓ Module 3: Kubernetes Basics

### Exercise 3.1: Deploy to Kubernetes

**Objective**: Deploy the application to a Kubernetes cluster

```bash
# 1. Start Minikube
minikube start

# 2. Build and load image
docker build -t task-manager-api:latest .
minikube image load task-manager-api:latest

# 3. Deploy using script
./deploy.sh k8s

# 4. Verify deployment
kubectl get all -n task-manager

# 5. Check pod status
kubectl get pods -n task-manager -w
```

**Expected Result**: All pods should be Running and Ready (2/2).

---

### Exercise 3.2: Explore Kubernetes Resources

**Objective**: Understand different Kubernetes objects

```bash
# 1. Explore namespace
kubectl describe namespace task-manager

# 2. View ConfigMap
kubectl get configmap task-manager-config -n task-manager -o yaml

# 3. View Secret (notice it's base64 encoded)
kubectl get secret task-manager-secret -n task-manager -o yaml

# 4. Describe a pod
kubectl describe pod $(kubectl get pods -n task-manager -l app=task-manager-api -o name | head -1) -n task-manager

# 5. View service endpoints
kubectl get endpoints -n task-manager
```

**Assignment:**
Answer these questions:
- How many replicas of the app are running?
- What is the database password? (decode the secret)
- Which node is each pod running on?
- What is the ClusterIP of the app service?

---

### Exercise 3.3: Access the Application

**Objective**: Learn different ways to access a Kubernetes service

**Method 1: Port Forward**
```bash
kubectl port-forward svc/task-manager-service-internal 8080:8080 -n task-manager

# In another terminal
curl http://localhost:8080/api/v1/health
```

**Method 2: NodePort**
```bash
# Get Minikube IP
minikube ip

# Access via NodePort
curl http://$(minikube ip):30080/api/v1/health
```

**Method 3: Minikube Service**
```bash
minikube service task-manager-service -n task-manager --url
```

**Challenge**: Access the app using all three methods and explain when you'd use each.

---

### Exercise 3.4: View Logs and Debug

**Objective**: Debug applications running in Kubernetes

```bash
# 1. View application logs
kubectl logs -f -l app=task-manager-api -n task-manager

# 2. View logs from specific pod
POD_NAME=$(kubectl get pods -n task-manager -l app=task-manager-api -o jsonpath='{.items[0].metadata.name}')
kubectl logs -f $POD_NAME -n task-manager

# 3. Exec into pod
kubectl exec -it $POD_NAME -n task-manager -- /bin/sh

# Inside pod:
ls -la /app
env | grep SPRING
curl localhost:8080/actuator/health
exit

# 4. Check events
kubectl get events -n task-manager --sort-by='.lastTimestamp'

# 5. Describe pod
kubectl describe pod $POD_NAME -n task-manager
```

---

### Exercise 3.5: Update Configuration

**Objective**: Learn to update configuration without redeploying

```bash
# 1. Current log level
kubectl port-forward svc/task-manager-service-internal 8080:8080 -n task-manager &
curl http://localhost:8080/actuator/loggers/com.devops.training

# 2. Edit ConfigMap
kubectl edit configmap task-manager-config -n task-manager
# Change LOG_LEVEL_APP: "DEBUG" to "TRACE"

# 3. Restart deployment
kubectl rollout restart deployment/task-manager-api -n task-manager

# 4. Wait for rollout
kubectl rollout status deployment/task-manager-api -n task-manager

# 5. Verify new log level
kubectl logs -f -l app=task-manager-api -n task-manager | grep TRACE
```

---

### Exercise 3.6: Scaling in Kubernetes

**Objective**: Manual and automatic scaling

**Manual Scaling:**
```bash
# 1. Scale to 5 replicas
kubectl scale deployment task-manager-api --replicas=5 -n task-manager

# 2. Watch pods being created
kubectl get pods -n task-manager -w

# 3. Create some tasks
kubectl port-forward svc/task-manager-service-internal 8080:8080 -n task-manager &

for i in {1..10}; do
  curl -X POST http://localhost:8080/api/v1/tasks \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"Task $i\",\"status\":\"TODO\",\"priority\":\"MEDIUM\"}"
done

# 4. Check cache across pods
kubectl exec -it $(kubectl get pods -n task-manager -l app=task-manager-api -o name | head -1) -n task-manager -- env | grep REDIS
```

**Auto Scaling (HPA):**
```bash
# 1. Check HPA status
kubectl get hpa -n task-manager

# 2. Generate load
kubectl run -it --rm load-generator \
  --image=busybox \
  --restart=Never \
  -n task-manager -- /bin/sh -c \
  "while true; do wget -q -O- http://task-manager-service-internal:8080/api/v1/tasks; done"

# 3. Watch HPA in another terminal
kubectl get hpa -n task-manager -w

# 4. Watch pods scale
kubectl get pods -n task-manager -w
```

---

### Exercise 3.7: Rolling Updates

**Objective**: Perform zero-downtime updates

```bash
# 1. Make a code change (e.g., change app version in application.yml)
# APP_VERSION: "1.0.1"

# 2. Build new image
docker build -t task-manager-api:v1.0.1 .

# 3. Load to Minikube
minikube image load task-manager-api:v1.0.1

# 4. Update deployment
kubectl set image deployment/task-manager-api \
  task-manager-api=task-manager-api:v1.0.1 \
  -n task-manager

# 5. Watch the rolling update
kubectl rollout status deployment/task-manager-api -n task-manager

# 6. Check rollout history
kubectl rollout history deployment/task-manager-api -n task-manager

# 7. Verify new version
kubectl port-forward svc/task-manager-service-internal 8080:8080 -n task-manager &
curl http://localhost:8080/api/v1/health
```

**Rollback (if needed):**
```bash
# Rollback to previous version
kubectl rollout undo deployment/task-manager-api -n task-manager

# Watch rollback
kubectl rollout status deployment/task-manager-api -n task-manager
```

---

### Exercise 3.8: Persistent Data

**Objective**: Understand data persistence in Kubernetes

```bash
# 1. Create some tasks
kubectl port-forward svc/task-manager-service-internal 8080:8080 -n task-manager &

for i in {1..5}; do
  curl -X POST http://localhost:8080/api/v1/tasks \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"Persistent Task $i\",\"status\":\"TODO\",\"priority\":\"HIGH\"}"
done

# 2. Delete the postgres pod (not the PVC)
kubectl delete pod -l app=postgres -n task-manager

# 3. Wait for new pod
kubectl wait --for=condition=ready pod -l app=postgres -n task-manager --timeout=120s

# 4. Verify data still exists
curl http://localhost:8080/api/v1/tasks

# 5. Check PVC
kubectl get pvc -n task-manager
```

**Challenge**: What happens if you delete the PVC and then recreate the postgres pod?

---

## 🎓 Advanced Challenges

### Challenge 1: Multi-Environment Deployment

Create separate namespaces for dev, staging, and prod:
- Different resource limits
- Different replica counts
- Different ConfigMaps

### Challenge 2: Health Check Tuning

Modify the liveness and readiness probes:
- Change intervals
- Add startup probe
- Test failure scenarios

### Challenge 3: Network Policies

Implement network policies to:
- Restrict app to only access postgres and redis
- Block external access to postgres
- Allow only specific ingress to the app

### Challenge 4: Resource Management

Configure:
- Resource requests and limits
- QoS classes
- PriorityClasses
- LimitRanges

---

## 📊 Assessment Checklist

After completing these exercises, you should be able to:

- [ ] Build Docker images using multi-stage builds
- [ ] Run containers with environment variables
- [ ] Use Docker Compose for multi-container apps
- [ ] Deploy applications to Kubernetes
- [ ] Manage ConfigMaps and Secrets
- [ ] Scale applications manually and automatically
- [ ] Perform rolling updates
- [ ] Debug pods and view logs
- [ ] Access services in different ways
- [ ] Understand persistent storage in K8s
- [ ] Monitor application health
- [ ] Troubleshoot common issues

---

## 📚 Next Steps

1. **Helm**: Package these K8s manifests into Helm charts
2. **CI/CD**: Automate builds with Jenkins
3. **GitOps**: Deploy using ArgoCD
4. **Monitoring**: Add Prometheus and Grafana
5. **Service Mesh**: Implement Istio
6. **Security**: Add image scanning, RBAC, policies

---

**Happy Learning! 🚀**
