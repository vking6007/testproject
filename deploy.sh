#!/bin/bash

# Deployment script for testproject Spring Boot application
# Usage: ./deploy.sh [environment] [version]

set -e

# Configuration
APP_NAME="testproject"
DOCKER_REGISTRY="your-docker-registry.com"  # Update with your registry
DEFAULT_VERSION="latest"
DEFAULT_ENV="staging"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    log_success "Docker is running"
}

# Check if required tools are installed
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed"
        exit 1
    fi
    
    log_success "All prerequisites are met"
}

# Build Docker image
build_image() {
    local version=$1
    log_info "Building Docker image for version: $version"
    
    docker build -t ${APP_NAME}:${version} .
    docker tag ${APP_NAME}:${version} ${APP_NAME}:latest
    
    log_success "Docker image built successfully"
}

# Push image to registry
push_image() {
    local version=$1
    log_info "Pushing image to registry..."
    
    # Login to registry (you may need to configure credentials)
    # docker login ${DOCKER_REGISTRY}
    
    docker tag ${APP_NAME}:${version} ${DOCKER_REGISTRY}/${APP_NAME}:${version}
    docker tag ${APP_NAME}:${version} ${DOCKER_REGISTRY}/${APP_NAME}:latest
    
    docker push ${DOCKER_REGISTRY}/${APP_NAME}:${version}
    docker push ${DOCKER_REGISTRY}/${APP_NAME}:latest
    
    log_success "Image pushed to registry"
}

# Deploy to environment
deploy() {
    local environment=$1
    local version=$2
    local container_name="${APP_NAME}-${environment}"
    
    log_info "Deploying to ${environment} environment with version ${version}"
    
    # Stop existing container
    if docker ps -q -f name=${container_name} | grep -q .; then
        log_info "Stopping existing container: ${container_name}"
        docker stop ${container_name}
        docker rm ${container_name}
    fi
    
    # Set environment-specific configurations
    case $environment in
        "staging")
            local port="8086"
            local profile="staging"
            ;;
        "production")
            local port="8085"
            local profile="prod"
            ;;
        "development")
            local port="8087"
            local profile="dev"
            ;;
        *)
            log_error "Unknown environment: $environment"
            exit 1
            ;;
    esac
    
    # Run new container
    log_info "Starting new container: ${container_name}"
    docker run -d \
        --name ${container_name} \
        -p ${port}:8085 \
        -e SPRING_PROFILES_ACTIVE=${profile} \
        -e SPRING_DATASOURCE_URL=${DB_URL:-"jdbc:postgresql://168.220.248.40:5432/team_1_db?timezone=UTC&useSSL=false&serverTimezone=UTC"} \
        -e SPRING_DATASOURCE_USERNAME=${DB_USERNAME:-"team_1"} \
        -e SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD:-"team_1"} \
        --restart unless-stopped \
        ${APP_NAME}:${version}
    
    # Wait for application to start
    log_info "Waiting for application to start..."
    sleep 30
    
    # Health check
    if curl -f http://localhost:${port}/api/test/health > /dev/null 2>&1; then
        log_success "Application is healthy and running on port ${port}"
    else
        log_error "Application health check failed"
        docker logs ${container_name}
        exit 1
    fi
}

# Rollback deployment
rollback() {
    local environment=$1
    local container_name="${APP_NAME}-${environment}"
    
    log_info "Rolling back ${environment} environment"
    
    # Get previous image version (you might want to implement version tracking)
    local previous_version="previous"  # This should be tracked in a file or database
    
    if docker images | grep -q "${APP_NAME}:${previous_version}"; then
        deploy $environment $previous_version
        log_success "Rollback completed"
    else
        log_error "Previous version not found for rollback"
        exit 1
    fi
}

# Show application status
status() {
    local environment=$1
    local container_name="${APP_NAME}-${environment}"
    
    log_info "Checking status of ${environment} environment"
    
    if docker ps -q -f name=${container_name} | grep -q .; then
        log_success "Container ${container_name} is running"
        docker ps -f name=${container_name}
        
        # Check health endpoint
        case $environment in
            "staging") local port="8086" ;;
            "production") local port="8085" ;;
            "development") local port="8087" ;;
        esac
        
        if curl -f http://localhost:${port}/api/test/health > /dev/null 2>&1; then
            log_success "Application is healthy"
        else
            log_warning "Application health check failed"
        fi
    else
        log_warning "Container ${container_name} is not running"
    fi
}

# Show logs
logs() {
    local environment=$1
    local container_name="${APP_NAME}-${environment}"
    
    log_info "Showing logs for ${container_name}"
    docker logs -f ${container_name}
}

# Clean up old images
cleanup() {
    log_info "Cleaning up old Docker images"
    
    # Remove dangling images
    docker image prune -f
    
    # Remove old versions (keep last 3)
    docker images ${APP_NAME} --format "table {{.Tag}}\t{{.ID}}" | \
    grep -v "latest" | \
    tail -n +4 | \
    awk '{print $2}' | \
    xargs -r docker rmi
    
    log_success "Cleanup completed"
}

# Main script
main() {
    local action=${1:-"deploy"}
    local environment=${2:-$DEFAULT_ENV}
    local version=${3:-$DEFAULT_VERSION}
    
    case $action in
        "build")
            check_docker
            check_prerequisites
            build_image $version
            ;;
        "deploy")
            check_docker
            check_prerequisites
            build_image $version
            deploy $environment $version
            ;;
        "push")
            check_docker
            push_image $version
            ;;
        "rollback")
            check_docker
            rollback $environment
            ;;
        "status")
            status $environment
            ;;
        "logs")
            logs $environment
            ;;
        "cleanup")
            cleanup
            ;;
        *)
            echo "Usage: $0 {build|deploy|push|rollback|status|logs|cleanup} [environment] [version]"
            echo ""
            echo "Examples:"
            echo "  $0 deploy staging v1.0.0"
            echo "  $0 deploy production latest"
            echo "  $0 status staging"
            echo "  $0 logs production"
            echo "  $0 rollback staging"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"

