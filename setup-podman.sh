#!/usr/bin/env bash
# Podman Setup Helper Script for hbohlen-systems
# This script helps initialize Podman after installation and provides useful commands

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log_error "This script should not be run as root!"
    exit 1
fi

# Function to check Podman installation
check_podman() {
    log_info "Checking Podman installation..."

    if ! command -v podman &> /dev/null; then
        log_error "Podman is not installed. Please rebuild your NixOS configuration first:"
        echo "  sudo nixos-rebuild switch --flake ."
        exit 1
    fi

    log_success "Podman is installed: $(podman --version)"
}

# Function to initialize Podman
init_podman() {
    log_info "Initializing Podman for user $(whoami)..."

    # Check if user is in podman group
    if ! groups | grep -q podman; then
        log_error "User $(whoami) is not in the 'podman' group."
        log_info "Please rebuild your NixOS configuration and reboot, or add yourself to the group:"
        echo "  sudo usermod -aG podman $(whoami)"
        echo "  # Then log out and back in"
        exit 1
    fi

    # Initialize podman machine if needed (for macOS-like experience, optional on Linux)
    if podman machine list 2>/dev/null | grep -q "No machines"; then
        log_info "No Podman machines found, but this is normal on Linux"
    fi

    log_success "Podman initialization complete!"
}

# Function to test Podman
test_podman() {
    log_info "Testing Podman with a simple container..."

    # Pull a small test image
    log_info "Pulling hello-world container..."
    if podman pull hello-world; then
        log_success "Successfully pulled hello-world image"
    else
        log_error "Failed to pull hello-world image"
        return 1
    fi

    # Run the test container
    log_info "Running hello-world container..."
    if podman run --rm hello-world; then
        log_success "Hello-world container ran successfully!"
    else
        log_error "Failed to run hello-world container"
        return 1
    fi
}

# Function to show useful Podman commands
show_commands() {
    log_info "Useful Podman commands:"
    echo ""
    echo "Basic container operations:"
    echo "  podman pull <image>          # Pull an image"
    echo "  podman run <image>           # Run a container"
    echo "  podman run -it <image> bash  # Run interactive container"
    echo "  podman ps                    # List running containers"
    echo "  podman ps -a                 # List all containers"
    echo "  podman images                # List images"
    echo "  podman rm <container>        # Remove container"
    echo "  podman rmi <image>           # Remove image"
    echo ""
    echo "Docker-compose equivalent:"
    echo "  podman-compose up            # Start services (if docker-compose.yml exists)"
    echo "  podman-compose down          # Stop services"
    echo ""
    echo "System management:"
    echo "  podman system info           # Show system info"
    echo "  podman system prune          # Clean up unused data"
    echo "  podman volume ls             # List volumes"
    echo ""
    echo "Advanced tools (installed in home.nix):"
    echo "  dive <image>                 # Explore image layers"
    echo "  ctop                         # Monitor container resources"
    echo "  lazydocker                   # Terminal UI for containers"
    echo ""
    echo "Podman Desktop:"
    echo "  podman-desktop               # Launch GUI application"
    echo "    or find 'Podman Desktop' in your application launcher"
}

# Function to setup rootless networking (if needed)
setup_networking() {
    log_info "Checking rootless networking setup..."

    # Check if slirp4netns is available (should be with NixOS podman)
    if command -v slirp4netns &> /dev/null; then
        log_success "slirp4netns is available for rootless networking"
    else
        log_warning "slirp4netns not found - networking might be limited"
    fi

    # Test basic networking
    log_info "Testing container networking..."
    if podman run --rm alpine:latest ping -c 1 8.8.8.8 &>/dev/null; then
        log_success "Container networking is working"
    else
        log_warning "Container networking test failed - this might be expected in some environments"
    fi
}

# Function to create sample containers
create_samples() {
    log_info "Would you like to create some sample containers? (y/N)"
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        log_info "Creating sample containers..."

        # Nginx web server
        log_info "Creating Nginx web server (port 8080)..."
        podman run -d --name nginx-sample -p 8080:80 nginx:alpine
        log_success "Nginx running at http://localhost:8080"

        # Redis cache
        log_info "Creating Redis cache..."
        podman run -d --name redis-sample redis:alpine
        log_success "Redis container created"

        echo ""
        log_info "Sample containers created! Manage them with:"
        echo "  podman ps                    # See running containers"
        echo "  podman stop nginx-sample     # Stop nginx"
        echo "  podman stop redis-sample     # Stop redis"
        echo "  podman rm nginx-sample redis-sample  # Remove containers"
    fi
}

# Main function
main() {
    echo ""
    log_info "=== Podman Setup Helper for hbohlen-systems ==="
    echo ""

    check_podman
    init_podman
    setup_networking
    test_podman

    echo ""
    log_success "Podman setup complete!"
    echo ""

    show_commands
    echo ""
    create_samples

    echo ""
    log_success "All done! Podman is ready to use."
    log_info "You can now launch Podman Desktop from your application launcher or run 'podman-desktop'"
}

# Run main function
main "$@"
