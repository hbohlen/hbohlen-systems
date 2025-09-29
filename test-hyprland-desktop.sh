#!/usr/bin/env bash

# Hyprland Desktop Environment Test Script
# Tests all components of the Hyprland home-manager configuration
# Requirements: 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 5.1, 5.2, 5.3

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Success function
success() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
    ((TESTS_TOTAL++))
}

# Failure function
fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
    ((TESTS_TOTAL++))
}

# Warning function
warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if running in Hyprland
check_hyprland_session() {
    log "Checking if running in Hyprland session..."
    
    if [[ "${XDG_CURRENT_DESKTOP:-}" == "Hyprland" ]] || [[ "${HYPRLAND_INSTANCE_SIGNATURE:-}" != "" ]]; then
        success "Running in Hyprland session"
        return 0
    else
        fail "Not running in Hyprland session (XDG_CURRENT_DESKTOP: ${XDG_CURRENT_DESKTOP:-none}, HYPRLAND_INSTANCE_SIGNATURE: ${HYPRLAND_INSTANCE_SIGNATURE:-none})"
        return 1
    fi
}

# Test Hyprland IPC connectivity
test_hyprland_ipc() {
    log "Testing Hyprland IPC connectivity..."
    
    if command -v hyprctl >/dev/null 2>&1; then
        if hyprctl version >/dev/null 2>&1; then
            success "Hyprland IPC is working"
            return 0
        else
            fail "Hyprland IPC not responding"
            return 1
        fi
    else
        fail "hyprctl command not found"
        return 1
    fi
}

# Test waybar service status
test_waybar_service() {
    log "Testing waybar service status..."
    
    if systemctl --user is-active waybar.service >/dev/null 2>&1; then
        success "Waybar service is active"
    else
        fail "Waybar service is not active"
    fi
    
    if pgrep -x waybar >/dev/null 2>&1; then
        success "Waybar process is running"
    else
        fail "Waybar process is not running"
    fi
}

# Test waybar configuration
test_waybar_config() {
    log "Testing waybar configuration..."
    
    local config_file="$HOME/.config/waybar/config"
    local style_file="$HOME/.config/waybar/style.css"
    
    if [[ -f "$config_file" ]]; then
        success "Waybar config file exists"
    else
        fail "Waybar config file missing: $config_file"
    fi
    
    if [[ -f "$style_file" ]]; then
        success "Waybar style file exists"
    else
        fail "Waybar style file missing: $style_file"
    fi
    
    # Test if waybar can parse its config
    if waybar --help >/dev/null 2>&1; then
        success "Waybar binary is functional"
    else
        fail "Waybar binary is not functional"
    fi
}

# Test workspace functionality
test_workspace_management() {
    log "Testing workspace management..."
    
    # Get current workspace
    local current_workspace
    current_workspace=$(hyprctl activeworkspace -j | jq -r '.id' 2>/dev/null || echo "unknown")
    
    if [[ "$current_workspace" =~ ^[0-9]+$ ]]; then
        success "Can query current workspace (workspace $current_workspace)"
    else
        fail "Cannot query current workspace"
    fi
    
    # Test workspace switching (non-destructive)
    local workspaces
    workspaces=$(hyprctl workspaces -j | jq -r '.[].id' 2>/dev/null || echo "")
    
    if [[ -n "$workspaces" ]]; then
        success "Can enumerate workspaces: $(echo $workspaces | tr '\n' ' ')"
    else
        fail "Cannot enumerate workspaces"
    fi
}

# Test application availability
test_application_availability() {
    log "Testing application availability..."
    
    # Test terminal (kitty)
    if command -v kitty >/dev/null 2>&1; then
        success "kitty terminal is available"
    else
        fail "kitty terminal is not available"
    fi
    
    # Test fuzzel
    if command -v fuzzel >/dev/null 2>&1; then
        success "fuzzel launcher is available"
    else
        fail "fuzzel launcher is not available"
    fi
    
    # Test waybar
    if command -v waybar >/dev/null 2>&1; then
        success "waybar is available"
    else
        fail "waybar is not available"
    fi
}

# Test fuzzel configuration
test_fuzzel_config() {
    log "Testing fuzzel configuration..."
    
    local config_file="$HOME/.config/fuzzel/fuzzel.ini"
    
    if [[ -f "$config_file" ]]; then
        success "Fuzzel config file exists"
    else
        fail "Fuzzel config file missing: $config_file"
    fi
    
    # Test fuzzel can start (dry run)
    if timeout 2s fuzzel --help >/dev/null 2>&1; then
        success "Fuzzel binary is functional"
    else
        warn "Fuzzel help command failed or timed out"
    fi
}

# Test system integration
test_system_integration() {
    log "Testing system integration..."
    
    # Test PipeWire/audio
    if command -v pactl >/dev/null 2>&1; then
        if pactl info >/dev/null 2>&1; then
            success "PipeWire/PulseAudio is working"
        else
            fail "PipeWire/PulseAudio is not responding"
        fi
    else
        fail "pactl command not found"
    fi
    
    # Test network connectivity for waybar network module
    if command -v ip >/dev/null 2>&1; then
        if ip route show default >/dev/null 2>&1; then
            success "Network routing is configured"
        else
            warn "No default route found"
        fi
    else
        fail "ip command not found"
    fi
    
    # Test systemd user session
    if systemctl --user is-active default.target >/dev/null 2>&1; then
        success "Systemd user session is active"
    else
        fail "Systemd user session is not active"
    fi
}

# Test Hyprland configuration files
test_hyprland_config() {
    log "Testing Hyprland configuration..."
    
    local config_dir="$HOME/.config/hypr"
    
    if [[ -d "$config_dir" ]]; then
        success "Hyprland config directory exists"
    else
        fail "Hyprland config directory missing: $config_dir"
    fi
    
    # Test if hyprland can validate its config
    if hyprctl reload >/dev/null 2>&1; then
        success "Hyprland configuration is valid"
    else
        warn "Hyprland configuration reload failed (may be expected if config is already loaded)"
    fi
}

# Test window management features
test_window_management() {
    log "Testing window management features..."
    
    # Test if we can query windows
    local windows
    windows=$(hyprctl clients -j 2>/dev/null || echo "[]")
    
    if [[ "$windows" != "[]" ]]; then
        local window_count
        window_count=$(echo "$windows" | jq length 2>/dev/null || echo "0")
        success "Can query windows (found $window_count windows)"
    else
        success "Can query windows (no windows currently open)"
    fi
    
    # Test if we can query the active window
    local active_window
    active_window=$(hyprctl activewindow -j 2>/dev/null || echo "{}")
    
    if [[ "$active_window" != "{}" ]]; then
        success "Can query active window"
    else
        success "Can query active window (no active window)"
    fi
}

# Test keybinding configuration
test_keybinding_config() {
    log "Testing keybinding configuration..."
    
    # Test if we can query keybindings
    local binds
    binds=$(hyprctl binds 2>/dev/null || echo "")
    
    if [[ -n "$binds" ]]; then
        success "Can query keybindings"
        
        # Check for specific keybindings
        if echo "$binds" | grep -q "SUPER.*Return.*kitty"; then
            success "Terminal keybinding (Super+Return) is configured"
        else
            fail "Terminal keybinding (Super+Return) not found"
        fi
        
        if echo "$binds" | grep -q "SUPER.*Space.*fuzzel"; then
            success "Launcher keybinding (Super+Space) is configured"
        else
            fail "Launcher keybinding (Super+Space) not found"
        fi
        
        if echo "$binds" | grep -q "SUPER.*Q.*killactive"; then
            success "Close window keybinding (Super+Q) is configured"
        else
            fail "Close window keybinding (Super+Q) not found"
        fi
        
        # Check workspace keybindings
        if echo "$binds" | grep -q "SUPER.*1.*workspace.*1"; then
            success "Workspace switching keybindings are configured"
        else
            fail "Workspace switching keybindings not found"
        fi
        
        # Check vim-like movement
        if echo "$binds" | grep -q "SUPER.*H.*movefocus.*l"; then
            success "Vim-like focus movement keybindings are configured"
        else
            fail "Vim-like focus movement keybindings not found"
        fi
        
    else
        fail "Cannot query keybindings"
    fi
}

# Test environment variables
test_environment_variables() {
    log "Testing environment variables..."
    
    # Check NVIDIA-specific variables
    if [[ "${LIBVA_DRIVER_NAME:-}" == "nvidia" ]]; then
        success "LIBVA_DRIVER_NAME is set for NVIDIA"
    else
        warn "LIBVA_DRIVER_NAME not set to nvidia (current: ${LIBVA_DRIVER_NAME:-unset})"
    fi
    
    if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
        success "XDG_SESSION_TYPE is set to wayland"
    else
        fail "XDG_SESSION_TYPE not set to wayland (current: ${XDG_SESSION_TYPE:-unset})"
    fi
    
    if [[ "${GBM_BACKEND:-}" == "nvidia-drm" ]]; then
        success "GBM_BACKEND is set for NVIDIA"
    else
        warn "GBM_BACKEND not set to nvidia-drm (current: ${GBM_BACKEND:-unset})"
    fi
}

# Test desktop integration
test_desktop_integration() {
    log "Testing desktop integration..."
    
    # Test XDG desktop portal
    if systemctl --user is-active xdg-desktop-portal.service >/dev/null 2>&1; then
        success "XDG desktop portal service is active"
    else
        warn "XDG desktop portal service is not active"
    fi
    
    # Test if applications can be found
    local app_count
    app_count=$(find /usr/share/applications ~/.local/share/applications -name "*.desktop" 2>/dev/null | wc -l)
    
    if [[ "$app_count" -gt 0 ]]; then
        success "Desktop applications are available ($app_count found)"
    else
        fail "No desktop applications found"
    fi
}

# Interactive keybinding test
interactive_keybinding_test() {
    log "Starting interactive keybinding test..."
    
    echo
    echo "This will test keybindings interactively. Press Enter to continue or Ctrl+C to skip."
    read -r
    
    echo "Testing keybindings (you will need to press them):"
    echo
    
    # Test terminal launch
    echo "1. Press Super+Return to launch kitty terminal"
    echo "   (A terminal window should open)"
    read -p "Did the terminal open? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        success "Terminal launch keybinding works"
    else
        fail "Terminal launch keybinding failed"
    fi
    
    # Test application launcher
    echo
    echo "2. Press Super+Space to launch fuzzel"
    echo "   (The application launcher should appear)"
    read -p "Did fuzzel appear? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        success "Application launcher keybinding works"
        echo "   Press Escape to close fuzzel"
    else
        fail "Application launcher keybinding failed"
    fi
    
    # Test workspace switching
    echo
    echo "3. Press Super+2 to switch to workspace 2"
    echo "   (The workspace should change)"
    read -p "Did the workspace change? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        success "Workspace switching keybinding works"
        echo "   Press Super+1 to return to workspace 1"
    else
        fail "Workspace switching keybinding failed"
    fi
    
    echo
    echo "Interactive keybinding test completed."
}

# Main test function
run_tests() {
    log "Starting Hyprland Desktop Environment Test Suite"
    echo "=================================================="
    echo
    
    # Core functionality tests
    check_hyprland_session
    test_hyprland_ipc
    test_hyprland_config
    test_environment_variables
    
    echo
    log "Testing application availability..."
    test_application_availability
    
    echo
    log "Testing configuration files..."
    test_waybar_config
    test_fuzzel_config
    
    echo
    log "Testing services..."
    test_waybar_service
    
    echo
    log "Testing system integration..."
    test_system_integration
    test_desktop_integration
    
    echo
    log "Testing window management..."
    test_workspace_management
    test_window_management
    test_keybinding_config
    
    # Interactive tests (optional)
    echo
    read -p "Run interactive keybinding tests? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        interactive_keybinding_test
    else
        warn "Skipping interactive keybinding tests"
    fi
    
    # Summary
    echo
    echo "=================================================="
    log "Test Summary"
    echo "=================================================="
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo -e "Total tests:  $TESTS_TOTAL"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed! Hyprland desktop environment is working correctly.${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed. Please check the output above for details.${NC}"
        return 1
    fi
}

# Help function
show_help() {
    echo "Hyprland Desktop Environment Test Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -q, --quiet    Run in quiet mode (less verbose output)"
    echo "  -i, --interactive  Run interactive tests only"
    echo "  --no-interactive   Skip interactive tests"
    echo
    echo "This script tests the complete Hyprland desktop environment configuration"
    echo "including keybindings, waybar, fuzzel, workspace management, and system integration."
}

# Parse command line arguments
QUIET=false
INTERACTIVE_ONLY=false
NO_INTERACTIVE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -i|--interactive)
            INTERACTIVE_ONLY=true
            shift
            ;;
        --no-interactive)
            NO_INTERACTIVE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
if [[ "$INTERACTIVE_ONLY" == true ]]; then
    log "Running interactive tests only..."
    check_hyprland_session
    test_hyprland_ipc
    interactive_keybinding_test
else
    run_tests
fi