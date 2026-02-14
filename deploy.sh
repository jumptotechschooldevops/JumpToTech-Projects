#!/bin/bash

# Task Manager API - Deployment Script
# Supports: Docker, Docker Compose, and Kubernetes deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="task-manager-api"
IMAGE_TAG="${IMAGE_TAG:-latest}"
NAMESPACE="task-manager"

# Functions
print_header() {
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}=========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
check_docker() {
    if command -v docker &> /dev/null; then
        print_success "Docker is installed"
        return 0
    else
        print_error "Docker is not installed"
        return 1
    fi
}

check_kubernetes() {
    if command -v kubectl &> /dev/null; then
        print_success "kubectl is installed"
        return 0
    else
        print_error "kubectl is not installed"
        return 1
    fi
}

check_minikube() {
    if command -v minikube &> /dev/null; then
        print_success "Minikube is installed"
        return 0
    else
        print_warning "Minikube is not installed (optional for local K8s)"
        return 1
    fi
}

# Build Docker image
build_image() {
    print_header "Building Docker Image"
    
    print_info "Building $IMAGE_NAME:$IMAGE_TAG..."
    docker build -t $IMAGE_NAME:$IMAGE_TAG .
    
    print_success "Docker image built successfully"
    docker images | grep $IMAGE_NAME
}

# Test Docker image locally
test_docker() {
    print_header "Testing Docker Image"
    
    print_info "Running container locally..."
    docker run -d \
        --name task-manager-test \
        -p 8080:8080 \
        -e SPRING_PROFILE=local \
        -e DB_URL=jdbc:h2:mem:testdb \
        -e CACHE_ENABLED=false \
        $IMAGE_NAME:$IMAGE_TAG
    
    print_info "Waiting for application to start..."
    sleep 20
    
    if curl -s http://localhost:8080/actuator/health | grep -q "UP"; then
        print_success "Application is healthy!"
        docker logs task-manager-test | tail -20
    else
        print_error "Application failed health check"
        docker logs task-manager-test
    fi
    
    print_info "Cleaning up test container..."
    docker stop task-manager-test
    docker rm task-manager-test
}

# Deploy using Docker Compose
deploy_compose() {
    print_header "Deploying with Docker Compose"
    
    print_info "Starting services..."
    docker-compose up -d
    
    print_info "Waiting for services to be healthy..."
    sleep 30
    
    docker-compose ps
    
    print_success "Services deployed!"
    print_info "Application available at: http://localhost:8080/api"
    print_info "To view logs: docker-compose logs -f app"
    print_info "To stop: docker-compose down"
}

# Deploy to Kubernetes
deploy_k8s() {
    print_header "Deploying to Kubernetes"
    
    # Check if kubectl is connected
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        print_info "If using Minikube, run: minikube start"
        exit 1
    fi
    
    print_success "Connected to Kubernetes cluster"
    kubectl cluster-info
    
    # Create namespace
    print_info "Creating namespace: $NAMESPACE"
    kubectl apply -f k8s/namespace.yaml
    
    # Apply ConfigMap and Secret
    print_info "Applying ConfigMap and Secret..."
    kubectl apply -f k8s/configmap.yaml
    kubectl apply -f k8s/secret.yaml
    
    # Deploy PostgreSQL
    print_info "Deploying PostgreSQL..."
    kubectl apply -f k8s/postgres-deployment.yaml
    
    # Deploy Redis
    print_info "Deploying Redis..."
    kubectl apply -f k8s/redis-deployment.yaml
    
    # Wait for database to be ready
    print_info "Waiting for PostgreSQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=120s || true
    
    print_info "Waiting for Redis to be ready..."
    kubectl wait --for=condition=ready pod -l app=redis -n $NAMESPACE --timeout=120s || true
    
    # Load image to Minikube if using Minikube
    if command -v minikube &> /dev/null && minikube status &> /dev/null; then
        print_info "Loading image to Minikube..."
        minikube image load $IMAGE_NAME:$IMAGE_TAG
    fi
    
    # Deploy application
    print_info "Deploying application..."
    kubectl apply -f k8s/app-deployment.yaml
    kubectl apply -f k8s/app-service.yaml
    
    # Optional: Deploy HPA
    print_info "Deploying HorizontalPodAutoscaler..."
    kubectl apply -f k8s/hpa.yaml || print_warning "HPA deployment failed (metrics-server may not be installed)"
    
    # Wait for application to be ready
    print_info "Waiting for application to be ready..."
    kubectl wait --for=condition=ready pod -l app=task-manager-api -n $NAMESPACE --timeout=180s || true
    
    # Show deployment status
    print_header "Deployment Status"
    kubectl get all -n $NAMESPACE
    
    print_success "Deployment complete!"
    
    # Show access information
    print_header "Access Information"
    
    if command -v minikube &> /dev/null && minikube status &> /dev/null; then
        MINIKUBE_IP=$(minikube ip)
        print_info "NodePort Service: http://$MINIKUBE_IP:30080/api"
        print_info "To get LoadBalancer URL: minikube service task-manager-service -n $NAMESPACE --url"
    else
        print_info "LoadBalancer Service IP:"
        kubectl get svc task-manager-service -n $NAMESPACE
        print_info "NodePort access: kubectl get svc task-manager-service-nodeport -n $NAMESPACE"
    fi
    
    print_info ""
    print_info "Useful commands:"
    print_info "  View logs: kubectl logs -f -l app=task-manager-api -n $NAMESPACE"
    print_info "  Check pods: kubectl get pods -n $NAMESPACE"
    print_info "  Port forward: kubectl port-forward svc/task-manager-service-internal 8080:8080 -n $NAMESPACE"
}

# Cleanup Kubernetes resources
cleanup_k8s() {
    print_header "Cleaning up Kubernetes Resources"
    
    print_warning "This will delete all resources in namespace: $NAMESPACE"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deleting namespace: $NAMESPACE"
        kubectl delete namespace $NAMESPACE || true
        print_success "Cleanup complete!"
    else
        print_info "Cleanup cancelled"
    fi
}

# Show help
show_help() {
    cat << EOF
Task Manager API - Deployment Script

Usage: ./deploy.sh [COMMAND]

Commands:
    build           Build Docker image
    test            Build and test Docker image locally
    compose         Deploy using Docker Compose
    k8s             Deploy to Kubernetes
    cleanup         Remove Kubernetes resources
    all             Build image and deploy to Kubernetes
    help            Show this help message

Environment Variables:
    IMAGE_TAG       Docker image tag (default: latest)
    NAMESPACE       Kubernetes namespace (default: task-manager)

Examples:
    ./deploy.sh build
    ./deploy.sh compose
    IMAGE_TAG=v1.0.0 ./deploy.sh k8s
    ./deploy.sh all

EOF
}

# Main script
main() {
    print_header "Task Manager API - Deployment Tool"
    
    case "${1:-help}" in
        build)
            check_docker || exit 1
            build_image
            ;;
        test)
            check_docker || exit 1
            build_image
            test_docker
            ;;
        compose)
            check_docker || exit 1
            deploy_compose
            ;;
        k8s)
            check_kubernetes || exit 1
            deploy_k8s
            ;;
        cleanup)
            check_kubernetes || exit 1
            cleanup_k8s
            ;;
        all)
            check_docker || exit 1
            check_kubernetes || exit 1
            build_image
            deploy_k8s
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
