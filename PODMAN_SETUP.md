# Podman Setup Guide for hbohlen-systems

This guide will help you complete the Podman and Podman Desktop setup in your NixOS configuration.

## What's Been Configured

Your NixOS system now includes:

### System-Level Configuration (NixOS)
- **Podman container runtime** with Docker compatibility
- **User permissions** - `hbohlen` user added to `podman` group
- **Container networking** with DNS resolution enabled
- **Podman Desktop** GUI application
- **Podman Compose** for Docker Compose compatibility

### User-Level Tools (Home Manager)
- **dive** - Docker/Podman image layer explorer
- **ctop** - Container resource monitor  
- **lazydocker** - Terminal UI for docker/podman management

## Required Next Steps

### 1. Complete Group Membership Setup

The system rebuild added you to the `podman` group, but you need to refresh your session:

```bash
# Option A: Log out and back in (recommended)
# This will ensure all your desktop environment sessions get the new group

# Option B: If you want to test immediately in terminal
newgrp podman
```

### 2. Initialize Podman

After logging back in, run the setup script:

```bash
cd ~/code/hbohlen-systems
./setup-podman.sh
```

This script will:
- Verify Podman installation
- Test basic functionality
- Show you useful commands
- Optionally create sample containers

## Manual Verification

If you prefer to test manually:

```bash
# Check Podman version
podman --version

# Test with hello-world container
podman run --rm hello-world

# Check system info
podman system info

# List available images
podman images
```

## Accessing Podman Desktop

After reboot/re-login, you can launch Podman Desktop:

```bash
# From terminal
podman-desktop

# Or find "Podman Desktop" in your application launcher (Fuzzel: Super+Space)
```

## Useful Commands Reference

### Basic Container Operations
```bash
podman pull nginx:alpine          # Pull an image
podman run -d -p 8080:80 nginx    # Run container in background
podman ps                         # List running containers  
podman ps -a                      # List all containers
podman stop <container>           # Stop container
podman rm <container>             # Remove container
podman images                     # List images
podman rmi <image>                # Remove image
```

### Docker Compose Equivalent
```bash
# If you have a docker-compose.yml file:
podman-compose up -d              # Start services
podman-compose ps                 # Show running services
podman-compose logs               # View logs
podman-compose down               # Stop and remove services
```

### Advanced Tools
```bash
dive nginx:alpine                 # Explore image layers
ctop                             # Monitor container resources
lazydocker                       # Terminal UI for containers
```

### System Management
```bash
podman system info              # Show detailed system info
podman system prune             # Clean up unused containers/images
podman volume ls                # List volumes
podman network ls               # List networks
```

## Integration with Your Desktop Environment

### Hyprland Integration
Podman Desktop will work seamlessly with your Hyprland setup:
- Launch with **Super+Space** → type "podman"
- Window management works with all your Hyprland keybindings
- Proper Wayland support with your NVIDIA configuration

### Waybar Integration (Optional)
If you want to add container status to your Waybar, you can create custom modules that show running container counts.

## Troubleshooting

### Permission Issues
If you get permission errors:
```bash
# Verify you're in the podman group
groups | grep podman

# If not, log out and back in, or run:
newgrp podman
```

### Networking Issues
If containers can't reach the internet:
```bash
# Check if slirp4netns is available
which slirp4netns

# Test basic networking
podman run --rm alpine ping -c 1 8.8.8.8
```

### Storage Issues
Podman stores data in `~/.local/share/containers/`. If you need to reset:
```bash
podman system reset  # WARNING: This removes all containers and images
```

## Sample Workflows

### Development Environment
```bash
# Run a PostgreSQL database for development
podman run -d --name postgres-dev \
  -e POSTGRES_PASSWORD=devpass \
  -p 5432:5432 \
  postgres:15

# Run Redis cache
podman run -d --name redis-dev \
  -p 6379:6379 \
  redis:alpine
```

### Web Development
```bash
# Run Nginx with custom config
podman run -d --name nginx-dev \
  -p 8080:80 \
  -v ./html:/usr/share/nginx/html:ro \
  nginx:alpine
```

### Using Podman Desktop
1. Launch Podman Desktop from your app launcher
2. Use the GUI to:
   - Pull images from registries
   - Create and manage containers
   - View logs and resource usage
   - Manage volumes and networks
   - Build images from Dockerfiles

## Next Steps

1. **Log out and back in** to activate group membership
2. **Run the setup script**: `./setup-podman.sh`
3. **Launch Podman Desktop** to explore the GUI
4. **Try the sample commands** above
5. **Start containerizing your projects!**

## Docker Compatibility

Thanks to the `dockerCompat = true` setting in your NixOS config, you can use `docker` commands that will be aliased to `podman`:

```bash
docker run hello-world    # Actually runs podman
docker ps                 # Actually runs podman ps
docker-compose up         # Actually runs podman-compose up
```

This makes it easy to follow Docker tutorials and use existing Docker workflows with Podman.