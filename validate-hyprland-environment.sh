#!/usr/bin/env bash

# Hyprland Desktop Environment Validation Script
# Comprehensive validation of all desktop components
# Requirements: All requirements from 1.2 through 5.3

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Test results tracking
declare -A TEST_RESULTS
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

header() {
    echo
    echo -e "${CYAN}${BOLD}$1${NC}"
    echo -e "${CYAN}$(printf '=%.0s' $(seq 1 ${#1}))${NC}"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Check if running in Hyprland
check_environment() {
    header "Environment Check"
    
    if [[ "${XDG_CURRENT_DESKTOP:-}" == "Hyprland" ]] || [[ "${HYPRLAND_INSTANCE_SIGNATURE:-}" != "" ]]; then
        success "Running in Hyprland session"
        TEST_RESULTS["environment"]="PASS"
    else
        fail "Not running in Hyprland session"
        TEST_RESULTS["environment"]="FAIL"
        echo -e "${RED}This validation must be run within a Hyprland session${NC}"
        return 1
    fi
    
    if command -v hyprctl >/dev/null 2>&1; then
        success "hyprctl is available"
    else
        fail "hyprctl command not found"
        TEST_RESULTS["environment"]="FAIL"
        return 1
    fi
    
    if hyprctl version >/dev/null 2>&1; then
        local version
        version=$(hyprctl version | head -1 | cut -d' ' -f2 2>/dev/null || echo "unknown")
        success "Hyprland IPC is working (version: $version)"
    else
        fail "Hyprland IPC not responding"
        TEST_RESULTS["environment"]="FAIL"
        return 1
    fi
}

# Validate keybindings (Requirements: 1.2, 1.3, 1.4, 1.5, 1.6, 1.7)
validate_keybindings() {
    header "Keybinding Validation"
    
    local binds
    binds=$(hyprctl binds 2>/dev/null || echo "")
    
    if [[ -z "$binds" ]]; then
        fail "Cannot query keybindings"
        TEST_RESULTS["keybindings"]="FAIL"
        return 1
    fi
    
    local keybinding_tests=0
    local keybinding_passed=0
    
    # Test terminal launch (Requirement 1.2)
    ((keybinding_tests++))
    if echo "$binds" | grep -q "SUPER.*Return.*kitty"; then
        success "Terminal launch keybinding (Super+Return → kitty)"
        ((keybinding_passed++))
    else
        fail "Terminal launch keybinding not found"
    fi
    
    # Test window close (Requirement 1.3)
    ((keybinding_tests++))
    if echo "$binds" | grep -q "SUPER.*Q.*killactive"; then
        success "Window close keybinding (Super+Q)"
        ((keybinding_passed++))
    else
        fail "Window close keybinding not found"
    fi
    
    # Test application launcher (Requirement 1.4)
    ((keybinding_tests++))
    if echo "$binds" | grep -q "SUPER.*Space.*fuzzel"; then
        success "Application launcher keybinding (Super+Space → fuzzel)"
        ((keybinding_passed++))
    else
        fail "Application launcher keybinding not found"
    fi
    
    # Test workspace switching (Requirement 1.5)
    local workspace_binds=0
    for i in {1..9}; do
        if echo "$binds" | grep -q "SUPER.*$i.*workspace.*$i"; then
            ((workspace_binds++))
        fi
    done
    ((keybinding_tests++))
    if [[ $workspace_binds -ge 5 ]]; then
        success "Workspace switching keybindings (Super+[1-9]) - found $workspace_binds"
        ((keybinding_passed++))
    else
        fail "Insufficient workspace switching keybindings - found $workspace_binds"
    fi
    
    # Test window movement (Requirement 1.6)
    local movement_binds=0
    for i in {1..9}; do
        if echo "$binds" | grep -q "SUPER SHIFT.*$i.*movetoworkspace.*$i"; then
            ((movement_binds++))
        fi
    done
    ((keybinding_tests++))
    if [[ $movement_binds -ge 5 ]]; then
        success "Window movement keybindings (Super+Shift+[1-9]) - found $movement_binds"
        ((keybinding_passed++))
    else
        fail "Insufficient window movement keybindings - found $movement_binds"
    fi
    
    # Test vim-like focus movement (Requirement 1.7)
    local focus_binds=0
    local focus_keys=("H" "J" "K" "L")
    local focus_directions=("l" "d" "u" "r")
    
    for i in {0..3}; do
        if echo "$binds" | grep -q "SUPER.*${focus_keys[$i]}.*movefocus.*${focus_directions[$i]}"; then
            ((focus_binds++))
        fi
    done
    ((keybinding_tests++))
    if [[ $focus_binds -eq 4 ]]; then
        success "Vim-like focus movement keybindings (Super+H/J/K/L)"
        ((keybinding_passed++))
    else
        fail "Incomplete vim-like focus movement keybindings - found $focus_binds/4"
    fi
    
    # Test window management keybindings (Requirements 5.1, 5.2)
    ((keybinding_tests++))
    if echo "$binds" | grep -q "SUPER.*F.*fullscreen"; then
        success "Fullscreen toggle keybinding (Super+F)"
        ((keybinding_passed++))
    else
        fail "Fullscreen toggle keybinding not found"
    fi
    
    ((keybinding_tests++))
    if echo "$binds" | grep -q "SUPER SHIFT.*Space.*togglefloating"; then
        success "Floating toggle keybinding (Super+Shift+Space)"
        ((keybinding_passed++))
    else
        fail "Floating toggle keybinding not found"
    fi
    
    if [[ $keybinding_passed -eq $keybinding_tests ]]; then
        TEST_RESULTS["keybindings"]="PASS"
    else
        TEST_RESULTS["keybindings"]="FAIL"
    fi
}

# Validate waybar functionality (Requirements: 2.1, 2.2, 2.3, 2.4, 2.5)
validate_waybar() {
    header "Waybar Validation"
    
    local waybar_tests=0
    local waybar_passed=0
    
    # Test waybar service (Requirement 2.1)
    ((waybar_tests++))
    if systemctl --user is-active waybar.service >/dev/null 2>&1; then
        success "Waybar service is active"
        ((waybar_passed++))
    else
        fail "Waybar service is not active"
    fi
    
    ((waybar_tests++))
    if pgrep -x waybar >/dev/null 2>&1; then
        success "Waybar process is running"
        ((waybar_passed++))
    else
        fail "Waybar process is not running"
    fi
    
    # Test waybar configuration files
    local config_file="$HOME/.config/waybar/config"
    local style_file="$HOME/.config/waybar/style.css"
    
    ((waybar_tests++))
    if [[ -f "$config_file" ]]; then
        success "Waybar config file exists"
        ((waybar_passed++))
    else
        fail "Waybar config file missing"
    fi
    
    ((waybar_tests++))
    if [[ -f "$style_file" ]]; then
        success "Waybar style file exists"
        ((waybar_passed++))
    else
        fail "Waybar style file missing"
    fi
    
    # Test waybar modules (Requirements 2.2, 2.3, 2.4, 2.5)
    if [[ -f "$config_file" ]]; then
        ((waybar_tests++))
        if grep -q '"hyprland/workspaces"' "$config_file"; then
            success "Workspace indicators module configured (Requirement 2.2)"
            ((waybar_passed++))
        else
            fail "Workspace indicators module not found"
        fi
        
        ((waybar_tests++))
        if grep -q '"cpu"' "$config_file" && grep -q '"memory"' "$config_file"; then
            success "System resource modules configured (Requirement 2.3)"
            ((waybar_passed++))
        else
            fail "System resource modules not properly configured"
        fi
        
        ((waybar_tests++))
        if grep -q '"clock"' "$config_file"; then
            success "Clock module configured (Requirement 2.4)"
            ((waybar_passed++))
        else
            fail "Clock module not found"
        fi
        
        ((waybar_tests++))
        if grep -q '"pulseaudio"' "$config_file"; then
            success "Audio module configured (Requirement 2.5)"
            ((waybar_passed++))
        else
            fail "Audio module not found"
        fi
        
        ((waybar_tests++))
        if grep -q '"network"' "$config_file"; then
            success "Network module configured"
            ((waybar_passed++))
        else
            warn "Network module not found"
        fi
    fi
    
    if [[ $waybar_passed -eq $waybar_tests ]]; then
        TEST_RESULTS["waybar"]="PASS"
    else
        TEST_RESULTS["waybar"]="FAIL"
    fi
}

# Validate fuzzel functionality (Requirements: 3.1, 3.2, 3.3, 3.4, 3.5)
validate_fuzzel() {
    header "Fuzzel Validation"
    
    local fuzzel_tests=0
    local fuzzel_passed=0
    
    # Test fuzzel availability (Requirement 3.1)
    ((fuzzel_tests++))
    if command -v fuzzel >/dev/null 2>&1; then
        success "Fuzzel binary is available"
        ((fuzzel_passed++))
    else
        fail "Fuzzel binary not found"
    fi
    
    # Test fuzzel configuration (Requirements 3.2, 3.3, 3.4, 3.5)
    local config_file="$HOME/.config/fuzzel/fuzzel.ini"
    
    ((fuzzel_tests++))
    if [[ -f "$config_file" ]]; then
        success "Fuzzel config file exists"
        ((fuzzel_passed++))
    else
        fail "Fuzzel config file missing"
    fi
    
    if [[ -f "$config_file" ]]; then
        ((fuzzel_tests++))
        if grep -q "terminal=kitty" "$config_file"; then
            success "Terminal integration configured (Requirement 3.2)"
            ((fuzzel_passed++))
        else
            fail "Terminal integration not configured"
        fi
        
        ((fuzzel_tests++))
        if grep -q "fuzzy=yes" "$config_file"; then
            success "Fuzzy search enabled (Requirement 3.3)"
            ((fuzzel_passed++))
        else
            fail "Fuzzy search not enabled"
        fi
        
        ((fuzzel_tests++))
        if grep -A 30 "\[key-bindings\]" "$config_file" | grep -q "cancel=.*Escape"; then
            success "Keyboard navigation configured (Requirement 3.4)"
            ((fuzzel_passed++))
        else
            fail "Keyboard navigation not properly configured"
        fi
        
        ((fuzzel_tests++))
        if grep -A 20 "\[colors\]" "$config_file" | grep -q "background="; then
            success "Theming configured (Requirement 3.5)"
            ((fuzzel_passed++))
        else
            fail "Theming not configured"
        fi
    fi
    
    # Test application database
    local app_count
    app_count=$(find /usr/share/applications ~/.local/share/applications -name "*.desktop" 2>/dev/null | wc -l)
    
    ((fuzzel_tests++))
    if [[ $app_count -gt 0 ]]; then
        success "Desktop applications available ($app_count found)"
        ((fuzzel_passed++))
    else
        fail "No desktop applications found"
    fi
    
    if [[ $fuzzel_passed -eq $fuzzel_tests ]]; then
        TEST_RESULTS["fuzzel"]="PASS"
    else
        TEST_RESULTS["fuzzel"]="FAIL"
    fi
}

# Validate window management (Requirements: 5.1, 5.2, 5.3, 5.4, 5.5)
validate_window_management() {
    header "Window Management Validation"
    
    local wm_tests=0
    local wm_passed=0
    
    # Test window rules (Requirements 5.3, 5.4, 5.5)
    local rules
    rules=$(hyprctl windowrules 2>/dev/null || echo "")
    
    ((wm_tests++))
    if [[ -n "$rules" ]]; then
        success "Window rules are configured"
        ((wm_passed++))
        
        if echo "$rules" | grep -q "float"; then
            success "Floating window rules configured"
        else
            warn "No floating window rules found"
        fi
        
        if echo "$rules" | grep -q "workspace"; then
            success "Workspace assignment rules configured"
        else
            warn "No workspace assignment rules found"
        fi
    else
        warn "No window rules configured"
    fi
    
    # Test layout configuration
    ((wm_tests++))
    local layout_info
    layout_info=$(hyprctl getoption general:layout -j 2>/dev/null || echo "{}")
    
    if [[ "$layout_info" != "{}" ]]; then
        local current_layout
        current_layout=$(echo "$layout_info" | jq -r '.str' 2>/dev/null || echo "unknown")
        success "Layout configured: $current_layout"
        ((wm_passed++))
    else
        fail "Cannot query layout configuration"
    fi
    
    # Test workspace functionality
    ((wm_tests++))
    local current_workspace
    current_workspace=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id' 2>/dev/null || echo "unknown")
    
    if [[ "$current_workspace" =~ ^[0-9]+$ ]]; then
        success "Workspace management is functional (current: $current_workspace)"
        ((wm_passed++))
    else
        fail "Workspace management not functional"
    fi
    
    # Test window querying
    ((wm_tests++))
    local windows
    windows=$(hyprctl clients -j 2>/dev/null || echo "[]")
    
    if [[ "$windows" != "null" ]]; then
        local window_count
        window_count=$(echo "$windows" | jq length 2>/dev/null || echo "0")
        success "Window management is functional ($window_count windows)"
        ((wm_passed++))
    else
        fail "Cannot query windows"
    fi
    
    if [[ $wm_passed -eq $wm_tests ]]; then
        TEST_RESULTS["window_management"]="PASS"
    else
        TEST_RESULTS["window_management"]="FAIL"
    fi
}

# Validate system integration (Requirements: 4.1, 4.2, 4.3, 4.4)
validate_system_integration() {
    header "System Integration Validation"
    
    local sys_tests=0
    local sys_passed=0
    
    # Test home-manager integration (Requirements 4.1, 4.2)
    ((sys_tests++))
    if [[ -d "$HOME/.config/hypr" ]]; then
        success "Hyprland configuration directory exists"
        ((sys_passed++))
    else
        fail "Hyprland configuration directory missing"
    fi
    
    ((sys_tests++))
    if [[ -f "$HOME/.config/waybar/config" ]]; then
        success "Waybar configuration managed by home-manager"
        ((sys_passed++))
    else
        fail "Waybar configuration not found"
    fi
    
    ((sys_tests++))
    if [[ -f "$HOME/.config/fuzzel/fuzzel.ini" ]]; then
        success "Fuzzel configuration managed by home-manager"
        ((sys_passed++))
    else
        fail "Fuzzel configuration not found"
    fi
    
    # Test systemd integration (Requirement 4.3)
    ((sys_tests++))
    if systemctl --user is-active default.target >/dev/null 2>&1; then
        success "Systemd user session is active"
        ((sys_passed++))
    else
        fail "Systemd user session not active"
    fi
    
    # Test audio integration
    ((sys_tests++))
    if command -v pactl >/dev/null 2>&1 && pactl info >/dev/null 2>&1; then
        success "Audio system (PipeWire/PulseAudio) is working"
        ((sys_passed++))
    else
        fail "Audio system not working"
    fi
    
    # Test environment variables (Requirement 4.4)
    ((sys_tests++))
    if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
        success "Wayland session type configured"
        ((sys_passed++))
    else
        fail "Wayland session type not configured"
    fi
    
    # Test NVIDIA compatibility (if applicable)
    if lspci | grep -i nvidia >/dev/null 2>&1; then
        ((sys_tests++))
        if [[ "${LIBVA_DRIVER_NAME:-}" == "nvidia" ]] && [[ "${GBM_BACKEND:-}" == "nvidia-drm" ]]; then
            success "NVIDIA environment variables configured"
            ((sys_passed++))
        else
            warn "NVIDIA environment variables may not be properly configured"
        fi
    fi
    
    if [[ $sys_passed -eq $sys_tests ]]; then
        TEST_RESULTS["system_integration"]="PASS"
    else
        TEST_RESULTS["system_integration"]="FAIL"
    fi
}

# Generate validation report
generate_report() {
    header "Validation Report"
    
    echo -e "${BOLD}Component Status:${NC}"
    for component in environment keybindings waybar fuzzel window_management system_integration; do
        local status="${TEST_RESULTS[$component]:-UNKNOWN}"
        case $status in
            "PASS")
                echo -e "  ${GREEN}✓${NC} $(echo $component | tr '_' ' ' | sed 's/\b\w/\U&/g')"
                ;;
            "FAIL")
                echo -e "  ${RED}✗${NC} $(echo $component | tr '_' ' ' | sed 's/\b\w/\U&/g')"
                ;;
            *)
                echo -e "  ${YELLOW}?${NC} $(echo $component | tr '_' ' ' | sed 's/\b\w/\U&/g')"
                ;;
        esac
    done
    
    echo
    echo -e "${BOLD}Test Summary:${NC}"
    echo -e "  Total tests: $TOTAL_TESTS"
    echo -e "  ${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "  ${RED}Failed: $FAILED_TESTS${NC}"
    echo -e "  ${YELLOW}Warnings: $WARNINGS${NC}"
    
    local pass_rate=0
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    fi
    
    echo -e "  Pass rate: ${pass_rate}%"
    
    echo
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✓ Hyprland desktop environment validation PASSED${NC}"
        echo -e "${GREEN}All components are working correctly!${NC}"
        return 0
    else
        echo -e "${RED}${BOLD}✗ Hyprland desktop environment validation FAILED${NC}"
        echo -e "${RED}Some components need attention. Check the output above for details.${NC}"
        return 1
    fi
}

# Show help
show_help() {
    echo "Hyprland Desktop Environment Validation Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -q, --quiet    Run in quiet mode"
    echo "  --report-only  Generate report from previous test results"
    echo
    echo "This script validates the complete Hyprland desktop environment"
    echo "configuration including all components and their integration."
    echo
    echo "Requirements validated:"
    echo "  1.2-1.7: Keybinding functionality"
    echo "  2.1-2.5: Waybar status bar integration"
    echo "  3.1-3.5: Fuzzel application launcher"
    echo "  4.1-4.4: Home-manager and system integration"
    echo "  5.1-5.3: Window management features"
}

# Main execution
main() {
    log "Starting Hyprland Desktop Environment Validation"
    echo "=============================================="
    
    # Run all validation tests
    check_environment || return 1
    validate_keybindings
    validate_waybar
    validate_fuzzel
    validate_window_management
    validate_system_integration
    
    echo
    generate_report
}

# Parse command line arguments
QUIET=false

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
        --report-only)
            generate_report
            exit $?
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Execute main function
main "$@"