#!/usr/bin/env bash

# Waybar Functionality Test Script
# Tests waybar system information display and integration
# Requirements: 2.1, 2.2, 2.3, 2.4, 2.5

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Test waybar workspace integration
test_workspace_integration() {
    log "Testing waybar workspace integration..."
    
    if ! command -v hyprctl >/dev/null 2>&1; then
        fail "hyprctl not available - cannot test workspace integration"
        return 1
    fi
    
    # Get current workspace
    local current_workspace
    current_workspace=$(hyprctl activeworkspace -j | jq -r '.id' 2>/dev/null || echo "unknown")
    
    if [[ "$current_workspace" =~ ^[0-9]+$ ]]; then
        success "Waybar can access workspace information (current: $current_workspace)"
    else
        fail "Cannot access workspace information"
    fi
    
    # Test workspace switching and waybar update
    log "Testing workspace switching updates in waybar..."
    echo "Switch to different workspaces and observe waybar workspace indicators"
    echo "The active workspace should be highlighted in waybar"
}

# Test system resource monitoring
test_system_monitoring() {
    log "Testing waybar system resource monitoring..."
    
    # Test CPU monitoring
    if [[ -r /proc/stat ]]; then
        success "CPU information is accessible for waybar"
    else
        fail "CPU information not accessible"
    fi
    
    # Test memory monitoring
    if [[ -r /proc/meminfo ]]; then
        success "Memory information is accessible for waybar"
    else
        fail "Memory information not accessible"
    fi
    
    # Test network monitoring
    if [[ -r /proc/net/dev ]]; then
        success "Network information is accessible for waybar"
    else
        fail "Network information not accessible"
    fi
    
    # Test if waybar modules are configured
    local config_file="$HOME/.config/waybar/config"
    if [[ -f "$config_file" ]]; then
        if grep -q '"cpu"' "$config_file"; then
            success "CPU module is configured in waybar"
        else
            warn "CPU module not found in waybar config"
        fi
        
        if grep -q '"memory"' "$config_file"; then
            success "Memory module is configured in waybar"
        else
            warn "Memory module not found in waybar config"
        fi
        
        if grep -q '"network"' "$config_file"; then
            success "Network module is configured in waybar"
        else
            warn "Network module not found in waybar config"
        fi
    else
        fail "Waybar config file not found"
    fi
}

# Test audio integration
test_audio_integration() {
    log "Testing waybar audio integration..."
    
    # Test PulseAudio/PipeWire connectivity
    if command -v pactl >/dev/null 2>&1; then
        if pactl info >/dev/null 2>&1; then
            success "PulseAudio/PipeWire is accessible for waybar"
            
            # Test volume control
            local current_volume
            current_volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1 2>/dev/null || echo "unknown")
            if [[ "$current_volume" != "unknown" ]]; then
                success "Can read current volume: $current_volume"
            else
                warn "Cannot read current volume"
            fi
            
        else
            fail "PulseAudio/PipeWire not responding"
        fi
    else
        fail "pactl command not available"
    fi
    
    # Test waybar pulseaudio module configuration
    local config_file="$HOME/.config/waybar/config"
    if [[ -f "$config_file" ]]; then
        if grep -q '"pulseaudio"' "$config_file"; then
            success "PulseAudio module is configured in waybar"
        else
            warn "PulseAudio module not found in waybar config"
        fi
    fi
}

# Test clock and date display
test_clock_display() {
    log "Testing waybar clock and date display..."
    
    local config_file="$HOME/.config/waybar/config"
    if [[ -f "$config_file" ]]; then
        if grep -q '"clock"' "$config_file"; then
            success "Clock module is configured in waybar"
            
            # Check timezone configuration
            if grep -q '"timezone"' "$config_file"; then
                local timezone
                timezone=$(grep -A 5 '"clock"' "$config_file" | grep '"timezone"' | cut -d'"' -f4 2>/dev/null || echo "not set")
                success "Timezone configured: $timezone"
            else
                warn "No specific timezone configured (using system default)"
            fi
            
        else
            fail "Clock module not found in waybar config"
        fi
    else
        fail "Waybar config file not found"
    fi
    
    # Test system time
    local current_time
    current_time=$(date '+%Y-%m-%d %H:%M:%S')
    success "System time: $current_time"
}

# Test waybar styling and theming
test_waybar_styling() {
    log "Testing waybar styling and theming..."
    
    local style_file="$HOME/.config/waybar/style.css"
    if [[ -f "$style_file" ]]; then
        success "Waybar CSS style file exists"
        
        # Check for key styling elements
        if grep -q "workspaces" "$style_file"; then
            success "Workspace styling is configured"
        else
            warn "Workspace styling not found"
        fi
        
        if grep -q "window#waybar" "$style_file"; then
            success "Main waybar styling is configured"
        else
            warn "Main waybar styling not found"
        fi
        
        if grep -q "background-color" "$style_file"; then
            success "Background colors are configured"
        else
            warn "Background colors not configured"
        fi
        
    else
        fail "Waybar CSS style file not found"
    fi
}

# Test waybar responsiveness
test_waybar_responsiveness() {
    log "Testing waybar responsiveness..."
    
    if pgrep -x waybar >/dev/null 2>&1; then
        success "Waybar process is running"
        
        # Test if waybar responds to signals
        local waybar_pid
        waybar_pid=$(pgrep -x waybar)
        
        if kill -USR1 "$waybar_pid" 2>/dev/null; then
            success "Waybar responds to reload signal"
        else
            warn "Waybar may not respond to reload signal"
        fi
        
    else
        fail "Waybar process is not running"
    fi
}

# Interactive waybar test
interactive_waybar_test() {
    log "Starting interactive waybar test..."
    
    echo
    echo "This will test waybar functionality interactively."
    echo "Look at your waybar (top of screen) during these tests."
    echo
    read -p "Press Enter to continue..."
    
    # Test workspace indicators
    echo "1. Testing workspace indicators:"
    echo "   Switch between workspaces (Super+1, Super+2, etc.)"
    echo "   The active workspace should be highlighted in waybar"
    read -p "Do the workspace indicators update correctly? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        success "Workspace indicators work correctly"
    else
        fail "Workspace indicators not working"
    fi
    
    # Test system resource display
    echo
    echo "2. Testing system resource display:"
    echo "   Look at the CPU, memory, and network indicators in waybar"
    echo "   They should show current system usage"
    read -p "Are system resources displayed correctly? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        success "System resource display works correctly"
    else
        fail "System resource display not working"
    fi
    
    # Test audio controls
    echo
    echo "3. Testing audio controls:"
    echo "   Click on the volume indicator in waybar"
    echo "   It should open pavucontrol or show volume controls"
    read -p "Do the audio controls work? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        success "Audio controls work correctly"
    else
        fail "Audio controls not working"
    fi
    
    # Test clock display
    echo
    echo "4. Testing clock display:"
    echo "   Look at the clock in waybar"
    echo "   It should show the current time and date"
    read -p "Is the clock displaying correctly? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        success "Clock display works correctly"
    else
        fail "Clock display not working"
    fi
}

# Main test function
main() {
    log "Starting Waybar Functionality Test"
    echo "=================================="
    echo
    
    test_waybar_styling
    test_workspace_integration
    test_system_monitoring
    test_audio_integration
    test_clock_display
    test_waybar_responsiveness
    
    echo
    read -p "Run interactive waybar tests? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        interactive_waybar_test
    else
        warn "Skipping interactive waybar tests"
    fi
    
    echo
    log "Waybar functionality test completed"
}

# Show help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Waybar Functionality Test Script"
    echo
    echo "Usage: $0"
    echo
    echo "This script tests waybar functionality including:"
    echo "- Workspace integration with Hyprland"
    echo "- System resource monitoring (CPU, memory, network)"
    echo "- Audio integration with PipeWire"
    echo "- Clock and date display"
    echo "- Styling and theming"
    echo "- Interactive functionality"
    exit 0
fi

main "$@"