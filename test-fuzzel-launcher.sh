#!/usr/bin/env bash

# Fuzzel Application Launcher Test Script
# Tests fuzzel application launching and search functionality
# Requirements: 3.1, 3.2, 3.3, 3.4, 3.5

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

# Test fuzzel configuration
test_fuzzel_config() {
    log "Testing fuzzel configuration..."
    
    local config_file="$HOME/.config/fuzzel/fuzzel.ini"
    
    if [[ -f "$config_file" ]]; then
        success "Fuzzel config file exists: $config_file"
        
        # Test key configuration options
        if grep -q "terminal=kitty" "$config_file"; then
            success "Terminal is configured as kitty"
        else
            warn "Terminal not configured as kitty"
        fi
        
        if grep -q "layer=overlay" "$config_file"; then
            success "Layer is configured as overlay"
        else
            warn "Layer not configured as overlay"
        fi
        
        if grep -q "fuzzy=yes" "$config_file"; then
            success "Fuzzy search is enabled"
        else
            warn "Fuzzy search not enabled"
        fi
        
        if grep -q "show-recent=yes" "$config_file"; then
            success "Recent applications feature is enabled"
        else
            warn "Recent applications feature not enabled"
        fi
        
    else
        fail "Fuzzel config file not found: $config_file"
    fi
}

# Test application database
test_application_database() {
    log "Testing application database..."
    
    # Check for desktop files in standard locations
    local app_dirs=(
        "/usr/share/applications"
        "/usr/local/share/applications"
        "$HOME/.local/share/applications"
    )
    
    local total_apps=0
    for dir in "${app_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local app_count
            app_count=$(find "$dir" -name "*.desktop" 2>/dev/null | wc -l)
            total_apps=$((total_apps + app_count))
            success "Found $app_count applications in $dir"
        else
            warn "Application directory not found: $dir"
        fi
    done
    
    if [[ $total_apps -gt 0 ]]; then
        success "Total applications available: $total_apps"
    else
        fail "No desktop applications found"
    fi
    
    # Test for common applications
    local common_apps=("kitty" "firefox" "code" "nautilus" "calculator")
    for app in "${common_apps[@]}"; do
        if find "${app_dirs[@]}" -name "*${app}*.desktop" 2>/dev/null | grep -q .; then
            success "Found $app application"
        else
            warn "$app application not found"
        fi
    done
}

# Test fuzzel binary functionality
test_fuzzel_binary() {
    log "Testing fuzzel binary functionality..."
    
    if command -v fuzzel >/dev/null 2>&1; then
        success "Fuzzel binary is available"
        
        # Test fuzzel version
        local version
        version=$(fuzzel --version 2>&1 | head -1 || echo "unknown")
        success "Fuzzel version: $version"
        
        # Test fuzzel help
        if fuzzel --help >/dev/null 2>&1; then
            success "Fuzzel help command works"
        else
            warn "Fuzzel help command failed"
        fi
        
    else
        fail "Fuzzel binary not found"
    fi
}

# Test fuzzel theming
test_fuzzel_theming() {
    log "Testing fuzzel theming..."
    
    local config_file="$HOME/.config/fuzzel/fuzzel.ini"
    
    if [[ -f "$config_file" ]]; then
        # Check color configuration
        if grep -A 20 "\[colors\]" "$config_file" | grep -q "background="; then
            success "Background color is configured"
        else
            warn "Background color not configured"
        fi
        
        if grep -A 20 "\[colors\]" "$config_file" | grep -q "text="; then
            success "Text color is configured"
        else
            warn "Text color not configured"
        fi
        
        if grep -A 20 "\[colors\]" "$config_file" | grep -q "match="; then
            success "Match highlight color is configured"
        else
            warn "Match highlight color not configured"
        fi
        
        if grep -A 20 "\[colors\]" "$config_file" | grep -q "selection="; then
            success "Selection color is configured"
        else
            warn "Selection color not configured"
        fi
        
        # Check border configuration
        if grep -A 10 "\[border\]" "$config_file" | grep -q "width="; then
            success "Border width is configured"
        else
            warn "Border width not configured"
        fi
        
        if grep -A 10 "\[border\]" "$config_file" | grep -q "radius="; then
            success "Border radius is configured"
        else
            warn "Border radius not configured"
        fi
        
    else
        fail "Cannot test theming - config file not found"
    fi
}

# Test keyboard navigation
test_keyboard_navigation() {
    log "Testing keyboard navigation configuration..."
    
    local config_file="$HOME/.config/fuzzel/fuzzel.ini"
    
    if [[ -f "$config_file" ]]; then
        # Check key bindings section
        if grep -q "\[key-bindings\]" "$config_file"; then
            success "Key bindings section exists"
            
            # Check essential key bindings
            if grep -A 30 "\[key-bindings\]" "$config_file" | grep -q "cancel="; then
                success "Cancel key binding is configured"
            else
                warn "Cancel key binding not configured"
            fi
            
            if grep -A 30 "\[key-bindings\]" "$config_file" | grep -q "execute="; then
                success "Execute key binding is configured"
            else
                warn "Execute key binding not configured"
            fi
            
            if grep -A 30 "\[key-bindings\]" "$config_file" | grep -q "prev="; then
                success "Previous item key binding is configured"
            else
                warn "Previous item key binding not configured"
            fi
            
            if grep -A 30 "\[key-bindings\]" "$config_file" | grep -q "next="; then
                success "Next item key binding is configured"
            else
                warn "Next item key binding not configured"
            fi
            
        else
            warn "Key bindings section not found"
        fi
    else
        fail "Cannot test keyboard navigation - config file not found"
    fi
}

# Test integration with Hyprland
test_hyprland_integration() {
    log "Testing Hyprland integration..."
    
    if command -v hyprctl >/dev/null 2>&1; then
        # Check if fuzzel keybinding is configured in Hyprland
        local binds
        binds=$(hyprctl binds 2>/dev/null || echo "")
        
        if echo "$binds" | grep -q "SUPER.*Space.*fuzzel"; then
            success "Fuzzel keybinding (Super+Space) is configured in Hyprland"
        else
            fail "Fuzzel keybinding not found in Hyprland configuration"
        fi
        
        # Check if fuzzel window rules are configured
        local rules
        rules=$(hyprctl windowrules 2>/dev/null || echo "")
        
        if echo "$rules" | grep -q "fuzzel"; then
            success "Fuzzel window rules are configured"
        else
            warn "No specific fuzzel window rules found"
        fi
        
    else
        warn "Cannot test Hyprland integration - hyprctl not available"
    fi
}

# Test search functionality
test_search_functionality() {
    log "Testing search functionality..."
    
    local config_file="$HOME/.config/fuzzel/fuzzel.ini"
    
    if [[ -f "$config_file" ]]; then
        # Check search configuration
        if grep -q "fields=.*filename" "$config_file"; then
            success "Filename search is enabled"
        else
            warn "Filename search not enabled"
        fi
        
        if grep -q "fields=.*name" "$config_file"; then
            success "Application name search is enabled"
        else
            warn "Application name search not enabled"
        fi
        
        if grep -q "fields=.*generic" "$config_file"; then
            success "Generic name search is enabled"
        else
            warn "Generic name search not enabled"
        fi
        
        if grep -q "sort-result=yes" "$config_file"; then
            success "Result sorting is enabled"
        else
            warn "Result sorting not enabled"
        fi
        
    else
        fail "Cannot test search functionality - config file not found"
    fi
}

# Interactive fuzzel test
interactive_fuzzel_test() {
    log "Starting interactive fuzzel test..."
    
    echo
    echo "This will test fuzzel functionality interactively."
    echo "You will need to use the keyboard to interact with fuzzel."
    echo
    read -p "Press Enter to continue..."
    
    # Test basic launch
    echo "1. Testing fuzzel launch:"
    echo "   Press Super+Space to launch fuzzel"
    echo "   The application launcher should appear"
    read -p "Did fuzzel appear? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        success "Fuzzel launches correctly"
    else
        fail "Fuzzel launch failed"
        return 1
    fi
    
    # Test search functionality
    echo
    echo "2. Testing search functionality:"
    echo "   With fuzzel open, type 'term' or 'kitty'"
    echo "   Terminal applications should appear in the list"
    read -p "Do search results appear correctly? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        success "Search functionality works"
    else
        fail "Search functionality not working"
    fi
    
    # Test keyboard navigation
    echo
    echo "3. Testing keyboard navigation:"
    echo "   Use arrow keys (Up/Down) to navigate through results"
    echo "   The selection should move between applications"
    read -p "Does keyboard navigation work? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        success "Keyboard navigation works"
    else
        fail "Keyboard navigation not working"
    fi
    
    # Test application launch
    echo
    echo "4. Testing application launch:"
    echo "   Select an application and press Enter"
    echo "   The application should launch and fuzzel should close"
    read -p "Does application launching work? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        success "Application launching works"
    else
        fail "Application launching not working"
    fi
    
    # Test cancel functionality
    echo
    echo "5. Testing cancel functionality:"
    echo "   Launch fuzzel again (Super+Space)"
    echo "   Press Escape to close without launching anything"
    read -p "Does the Escape key close fuzzel? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        success "Cancel functionality works"
    else
        fail "Cancel functionality not working"
    fi
}

# Main test function
main() {
    log "Starting Fuzzel Application Launcher Test"
    echo "========================================"
    echo
    
    test_fuzzel_binary
    test_fuzzel_config
    test_fuzzel_theming
    test_keyboard_navigation
    test_application_database
    test_search_functionality
    test_hyprland_integration
    
    echo
    read -p "Run interactive fuzzel tests? (y/n): " -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        interactive_fuzzel_test
    else
        warn "Skipping interactive fuzzel tests"
    fi
    
    echo
    log "Fuzzel application launcher test completed"
}

# Show help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Fuzzel Application Launcher Test Script"
    echo
    echo "Usage: $0"
    echo
    echo "This script tests fuzzel functionality including:"
    echo "- Configuration validation"
    echo "- Application database access"
    echo "- Search functionality"
    echo "- Keyboard navigation"
    echo "- Theming and appearance"
    echo "- Integration with Hyprland"
    echo "- Interactive functionality"
    exit 0
fi

main "$@"