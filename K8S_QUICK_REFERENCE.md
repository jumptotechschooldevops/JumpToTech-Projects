# Kubernetes Quick Reference - Task Manager API

## 🚀 Quick Deploy Commands

```bash
# One-line deploy (using script)
./deploy.sh all

# Manual deploy (step by step)
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml
kubectl apply -f k8s/hpa.yaml
```

## 📋 Essential kubectl Commands

### Viewing Resources

```bash
# All resources in namespace
kubectl get all -n task-manager

# Pods
kubectl get pods -n task-manager
kubectl get pods -n task-manager -o wide
kubectl get pods -n task-manager -w  # Watch mode

# Services
kubectl get svc -n task-manager

# Deployments
kubectl get deployments -n task-manager

# ConfigMaps and Secrets
kubectl get configmap -n task-manager
kubectl get secrets -n task-manager
```

### Logs and Debugging

```bash
# Follow logs
kubectl logs -f -l app=task-manager-api -n task-manager

# Logs from specific pod
kubectl logs -f <pod-name> -n task-manager

# Previous container logs (if crashed)
kubectl logs --previous <pod-name> -n task-manager

# Exec into pod
kubectl exec -it <pod-name> -n task-manager -- /bin/sh

# Describe resources
kubectl describe pod <pod-name> -n task-manager
kubectl describe deployment task-manager-api -n task-manager
```

### Access Application

```bash
# Port forward (easiest for testing)
kubectl port-forward svc/task-manager-service-internal 8080:8080 -n task-manager

# Via NodePort (Minikube)
curl http://$(minikube ip):30080/api/v1/health

# Via Minikube service
minikube service task-manager-service -n task-manager --url
```

## 🔧 Common Operations

### Update Configuration

```bash
# Edit ConfigMap
kubectl edit configmap task-manager-config -n task-manager

# Restart deployment to pick up changes
kubectl rollout restart deployment/task-manager-api -n task-manager

# Check rollout status
kubectl rollout status deployment/task-manager-api -n task-manager
```

### Scaling

```bash
# Manual scale
kubectl scale deployment task-manager-api --replicas=5 -n task-manager

# Check HPA
kubectl get hpa -n task-manager
kubectl describe hpa task-manager-hpa -n task-manager

# Watch autoscaling
kubectl get hpa -n task-manager -w
```

### Update Image

```bash
# Set new image
kubectl set image deployment/task-manager-api \
  task-manager-api=task-manager-api:v2 \
  -n task-manager

# Check rollout
kubectl rollout status deployment/task-manager-api -n task-manager

# Rollback if needed
kubectl rollout undo deployment/task-manager-api -n task-manager
```

## 🐛 Troubleshooting

### Check Pod Health

```bash
# Pod status
kubectl get pods -n task-manager

# Events
kubectl get events -n task-manager --sort-by='.lastTimestamp'

# Pod details
kubectl describe pod <pod-name> -n task-manager

# Resource usage
kubectl top pods -n task-manager
```

### Test Connectivity

```bash
# Test from debug pod
kubectl run -it --rm debug \
  --image=curlimages/curl \
  --restart=Never \
  -n task-manager -- \
  curl task-manager-service-internal:8080/actuator/health

# Test database connection
kubectl exec -it <postgres-pod> -n task-manager -- \
  psql -U taskuser -d taskdb -c "SELECT 1;"

# Test Redis
kubectl exec -it <redis-pod> -n task-manager -- \
  redis-cli ping
```

## 🗑️ Cleanup

```bash
# Delete specific resources
kubectl delete -f k8s/app-deployment.yaml

# Delete entire namespace
kubectl delete namespace task-manager

# Or use script
./deploy.sh cleanup
```

## 📊 Monitoring

```bash
# Watch resources
kubectl get pods -n task-manager -w

# Resource usage
kubectl top pods -n task-manager
kubectl top nodes

# Events
kubectl get events -n task-manager

# Logs streaming
stern task-manager-api -n task-manager  # If stern installed
```

## 🔐 Secrets Management

```bash
# View secret (base64 encoded)
kubectl get secret task-manager-secret -n task-manager -o yaml

# Decode secret
kubectl get secret task-manager-secret -n task-manager \
  -o jsonpath='{.data.DB_PASSWORD}' | base64 -d

# Create secret from literal
kubectl create secret generic my-secret \
  --from-literal=password=mysecret \
  -n task-manager
```

## 🌐 Network Testing

```bash
# Service endpoints
kubectl get endpoints -n task-manager

# DNS test
kubectl run -it --rm dnsutils \
  --image=tutum/dnsutils \
  --restart=Never \
  -- nslookup task-manager-service-internal.task-manager.svc.cluster.local
```

## 📦 Useful One-Liners

```bash
# Get all pod names
kubectl get pods -n task-manager -o name

# Delete all pods (force restart)
kubectl delete pods -l app=task-manager-api -n task-manager

# Copy file from pod
kubectl cp task-manager/<pod-name>:/app/logs/app.log ./local-app.log

# Execute SQL on postgres
kubectl exec -it <postgres-pod> -n task-manager -- \
  psql -U taskuser -d taskdb -c "SELECT COUNT(*) FROM tasks;"

# Check which node pods are on
kubectl get pods -n task-manager -o wide

# Force delete stuck pod
kubectl delete pod <pod-name> -n task-manager --grace-period=0 --force
```

## 🎯 Testing Scenarios

### Load Testing

```bash
# Create load
kubectl run -it --rm load-generator \
  --image=busybox \
  --restart=Never \
  -n task-manager -- /bin/sh -c \
  "while true; do wget -q -O- http://task-manager-service-internal:8080/api/v1/tasks; done"
```

### Chaos Testing

```bash
# Kill random pod
kubectl delete pod $(kubectl get pods -n task-manager -l app=task-manager-api -o name | shuf -n 1)

# Watch recovery
kubectl get pods -n task-manager -w
```

## 🏷️ Label and Selector Commands

```bash
# Get pods by label
kubectl get pods -l app=task-manager-api -n task-manager

# Add label to pod
kubectl label pod <pod-name> version=v2 -n task-manager

# Remove label
kubectl label pod <pod-name> version- -n task-manager
```

## 📝 Cheat Sheet Summary

| Operation | Command |
|-----------|---------|
| View all | `kubectl get all -n task-manager` |
| View logs | `kubectl logs -f -l app=task-manager-api -n task-manager` |
| Port forward | `kubectl port-forward svc/task-manager-service-internal 8080:8080 -n task-manager` |
| Scale | `kubectl scale deployment/task-manager-api --replicas=5 -n task-manager` |
| Restart | `kubectl rollout restart deployment/task-manager-api -n task-manager` |
| Debug | `kubectl describe pod <pod-name> -n task-manager` |
| Exec | `kubectl exec -it <pod-name> -n task-manager -- /bin/sh` |
| Delete all | `kubectl delete namespace task-manager` |

---

**Pro Tip:** Create aliases in your `.bashrc` or `.zshrc`:

```bash
alias k='kubectl'
alias kgp='kubectl get pods -n task-manager'
alias kgpw='kubectl get pods -n task-manager -w'
alias klf='kubectl logs -f -l app=task-manager-api -n task-manager'
alias kpf='kubectl port-forward svc/task-manager-service-internal 8080:8080 -n task-manager'
```
