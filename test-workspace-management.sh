#!/usr/bin/env bash

# Workspace Management Test Script
# Tests Hyprland workspace switching and window movement features
# Requirements: 1.5, 1.6, 5.1, 5.2, 5.3

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

# Test workspace enumeration
test_workspace_enumeration() {
    log "Testing workspace enumeration..."
    
    if ! command -v hyprctl >/dev/null 2>&1; then
        fail "hyprctl not available"
        return 1
    fi
    
    # Get list of workspaces
    local workspaces
    workspaces=$(hyprctl workspaces -j 2>/dev/null || echo "[]")
    
    if [[ "$workspaces" != "[]" ]]; then
        local workspace_count
        workspace_count=$(echo "$workspaces" | jq length 2>/dev/null || echo "0")
        success "Found $workspace_count active workspaces"
        
        # List workspace IDs
        local workspace_ids
        workspace_ids=$(echo "$workspaces" | jq -r '.[].id' 2>/dev/null | tr '\n' ' ' || echo "none")
        success "Active workspace IDs: $workspace_ids"
    else
        success "No active workspaces found (this is normal if no windows are open)"
    fi
}

# Test current workspace detection
test_current_workspace() {
    log "Testing current workspace detection..."
    
    local current_workspace
    current_workspace=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id' 2>/dev/null || echo "unknown")
    
    if [[ "$current_workspace" =~ ^[0-9]+$ ]]; then
        success "Current workspace: $current_workspace"
        
        # Get workspace name if available
        local workspace_name
        workspace_name=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.name' 2>/dev/null || echo "unnamed")
        success "Workspace name: $workspace_name"
        
    else
        fail "Cannot detect current workspace"
    fi
}

# Test workspace switching keybindings
test_workspace_keybindings() {
    log "Testing workspace switching keybindings..."
    
    local binds
    binds=$(hyprctl binds 2>/dev/null || echo "")
    
    if [[ -n "$binds" ]]; then
        # Check for workspace switching bindings (Super+[1-9])
        local workspace_binds=0
        for i in {1..9}; do
            if echo "$binds" | grep -q "SUPER.*$i.*workspace.*$i"; then
                ((workspace_binds++))
            fi
        done
        
        if [[ $workspace_binds -gt 0 ]]; then
            success "Found $workspace_binds workspace switching keybindings"
        else
            fail "No workspace switching keybindings found"
        fi
        
        # Check for window movement bindings (Super+Shift+[1-9])
        local movement_binds=0
        for i in {1..9}; do
            if echo "$binds" | grep -q "SUPER SHIFT.*$i.*movetoworkspace.*$i"; then
                ((movement_binds++))
            fi
        done
        
        if [[ $movement_binds -gt 0 ]]; then
            success "Found $movement_binds window movement keybindings"
        else
            fail "No window movement keybindings found"
        fi
        
    else
        fail "Cannot query keybindings"
    fi
}

# Test window management keybindings
test_window_management_keybindings() {
    log "Testing window management keybindings..."
    
    local binds
    binds=$(hyprctl binds 2>/dev/null || echo "")
    
    if [[ -n "$binds" ]]; then
        # Check for fullscreen toggle
        if echo "$binds" | grep -q "SUPER.*F.*fullscreen"; then
            success "Fullscreen toggle keybinding found (Super+F)"
        else
            fail "Fullscreen toggle keybinding not found"
        fi
        
        # Check for floating toggle
        if echo "$binds" | grep -q "SUPER SHIFT.*Space.*togglefloating"; then
            success "Floating toggle keybinding found (Super+Shift+Space)"
        else
            fail "Floating toggle keybinding not found"
        fi
        
        # Check for vim-like focus movement
        local focus_binds=0
        local focus_keys=("H" "J" "K" "L")
        local focus_directions=("l" "d" "u" "r")
        
        for i in {0..3}; do
            if echo "$binds" | grep -q "SUPER.*${focus_keys[$i]}.*movefocus.*${focus_directions[$i]}"; then
                ((focus_binds++))
            fi
        done
        
        if [[ $focus_binds -eq 4 ]]; then
            success "All vim-like focus movement keybindings found"
        elif [[ $focus_binds -gt 0 ]]; then
            warn "Found $focus_binds/4 vim-like focus movement keybindings"
        else
            fail "No vim-like focus movement keybindings found"
        fi
        
    else
        fail "Cannot query keybindings"
    fi
}

# Test window rules and workspace assignments
test_window_rules() {
    log "Testing window rules and workspace assignments..."
    
    local rules
    rules=$(hyprctl windowrules 2>/dev/null || echo "")
    
    if [[ -n "$rules" ]]; then
        success "Window rules are configured"
        
        # Check for workspace assignment rules
        if echo "$rules" | grep -q "workspace"; then
            local workspace_rules
            workspace_rules=$(echo "$rules" | grep -c "workspace" || echo "0")
            success "Found $workspace_rules workspace assignment rules"
        else
            warn "No workspace assignment rules found"
        fi
        
        # Check for floating rules
        if echo "$rules" | grep -q "float"; then
            local float_rules
            float_rules=$(echo "$rules" | grep -c "float" || echo "0")
            success "Found $float_rules floating window rules"
        else
            warn "No floating window rules found"
        fi
        
        # Check for tiling rules
        if echo "$rules" | grep -q "tile"; then
            local tile_rules
            tile_rules=$(echo "$rules" | grep -c "tile" || echo "0")
            success "Found $tile_rules explicit tiling rules"
        else
            warn "No explicit tiling rules found (using default behavior)"
        fi
        
    else
        warn "No window rules configured or cannot query rules"
    fi
}

# Test workspace configuration
test_workspace_configuration() {
    log "Testing workspace configuration..."
    
    # Check Hyprland config for workspace settings
    local config_files=(
        "$HOME/.config/hypr/hyprland.conf"
        "$HOME/.config/hypr/hyprland/hyprland.conf"
    )
    
    local config_found=false
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            config_found=true
            success "Found Hyprland config: $config_file"
            
            # Check for workspace definitions
            if grep -q "^workspace" "$config_file"; then
                local workspace_configs
                workspace_configs=$(grep -c "^workspace" "$config_file" || echo "0")
                success "Found $workspace_configs workspace configurations"
            else
                warn "No explicit workspace configurations found"
            fi
            
            # Check for window rules
            if grep -q "windowrule" "$config_file"; then
                local window_rules
                window_rules=$(grep -c "windowrule" "$config_file" || echo "0")
                success "Found $window_rules window rules in config"
            else
                warn "No window rules found in config file"
            fi
            
            break
        fi
    done
    
    if [[ "$config_found" == false ]]; then
        warn "No Hyprland config file found in expected locations"
    fi
}

# Test layout configuration
test_layout_configuration() {
    log "Testing layout configuration..."
    
    # Get current layout
    local layout_info
    layout_info=$(hyprctl getoption general:layout -j 2>/dev/null || echo "{}")
    
    if [[ "$layout_info" != "{}" ]]; then
        local current_layout
        current_layout=$(echo "$layout_info" | jq -r '.str' 2>/dev/null || echo "unknown")
        success "Current layout: $current_layout"
    else
        warn "Cannot query current layout"
    fi
    
    # Check dwindle layout settings if applicable
    local dwindle_info
    dwindle_info=$(hyprctl getoption dwindle:pseudotile -j 2>/dev/null || echo "{}")
    
    if [[ "$dwindle_info" != "{}" ]]; then
        local pseudotile
        pseudotile=$(echo "$dwindle_info" | jq -r '.int' 2>/dev/null || echo "unknown")
        success "Dwindle pseudotile setting: $pseudotile"
    else
        warn "Cannot query dwindle settings"
    fi
}

# Interactive workspace test
interactive_workspace_test() {
    log "Starting interactive workspace test..."
    
    echo
    echo "This will test workspace management interactively."
    echo "You will need to use keyboard shortcuts to test functionality."
    echo
    read -p "Press Enter to continue..."
    
    # Test workspace switching
    echo "1. Testing workspace switching:"
    echo "   Current workspace: $(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id' 2>/dev/null || echo 'unknown')"
    echo "   Press Super+2 to switch to workspace 2"
    read -p "Did you switch to workspace 2? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        success "Workspace switching works"
        echo "   Press Super+1 to return to workspace 1"
    else
        fail "Workspace switching not working"
    fi
    
    # Test window movement (if windows are available)
    local window_count
    window_count=$(hyprctl clients -j 2>/dev/null | jq length 2>/dev/null || echo "0")
    
    if [[ "$window_count" -gt 0 ]]; then
        echo
        echo "2. Testing window movement:"
        echo "   Focus a window and press Super+Shift+3"
        echo "   The window should move to workspace 3"
        read -p "Did the window move to workspace 3? (y/n): " -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            success "Window movement works"
            echo "   Press Super+3 to follow the window to workspace 3"
        else
            fail "Window movement not working"
        fi
    else
        warn "No windows available to test window movement"
    fi
    
    # Test fullscreen toggle
    if [[ "$window_count" -gt 0 ]]; then
        echo
        echo "3. Testing fullscreen toggle:"
        echo "   Focus a window and press Super+F"
        echo "   The window should toggle fullscreen mode"
        read -p "Did the window toggle fullscreen? (y/n): " -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            success "Fullscreen toggle works"
            echo "   Press Super+F again to exit fullscreen"
        else
            fail "Fullscreen toggle not working"
        fi
    else
        warn "No windows available to test fullscreen toggle"
    fi
    
    # Test floating toggle
    if [[ "$window_count" -gt 0 ]]; then
        echo
        echo "4. Testing floating toggle:"
        echo "   Focus a window and press Super+Shift+Space"
        echo "   The window should toggle between tiling and floating"
        read -p "Did the window toggle floating mode? (y/n): " -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            success "Floating toggle works"
        else
            fail "Floating toggle not working"
        fi
    else
        warn "No windows available to test floating toggle"
    fi
    
    # Test vim-like focus movement
    if [[ "$window_count" -gt 1 ]]; then
        echo
        echo "5. Testing vim-like focus movement:"
        echo "   With multiple windows open, use Super+H/J/K/L"
        echo "   Focus should move between windows in vim-like directions"
        read -p "Does vim-like focus movement work? (y/n): " -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            success "Vim-like focus movement works"
        else
            fail "Vim-like focus movement not working"
        fi
    else
        warn "Need multiple windows to test vim-like focus movement"
    fi
}

# Main test function
main() {
    log "Starting Workspace Management Test"
    echo "================================="
    echo
    
    test_workspace_enumeration
    test_current_workspace
    test_workspace_keybindings
    test_window_management_keybindings
    test_window_rules
    test_workspace_configuration
    test_layout_configuration
    
    echo
    read -p "Run interactive workspace tests? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        interactive_workspace_test
    else
        warn "Skipping interactive workspace tests"
    fi
    
    echo
    log "Workspace management test completed"
}

# Show help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Workspace Management Test Script"
    echo
    echo "Usage: $0"
    echo
    echo "This script tests workspace management functionality including:"
    echo "- Workspace enumeration and detection"
    echo "- Workspace switching keybindings"
    echo "- Window movement between workspaces"
    echo "- Window management features (fullscreen, floating)"
    echo "- Vim-like focus movement"
    echo "- Window rules and workspace assignments"
    echo "- Layout configuration"
    exit 0
fi

main "$@"